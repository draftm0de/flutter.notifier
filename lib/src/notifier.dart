import 'dart:async';
import 'package:flutter/foundation.dart';
//
import '../flutter/notification.dart';
import 'config.dart';
import 'response.dart';
import 'item.dart';

const int _kMaxNotificationId = 0x7fffffff;

/// Coordinates local notification set up and tap handling for DraftMode apps.
class DraftModeNotifier {
  DraftModeNotifier._({
    FlutterLocalNotificationsPlugin? plugin,
    DraftModeNotifierConfig? config,
  })  : _fln = plugin ?? FlutterLocalNotificationsPlugin(),
        _config = config ?? const DraftModeNotifierConfig();

  /// Creates a notifier that wraps a custom notifications plugin (used in tests).
  @visibleForTesting
  factory DraftModeNotifier.test(
    FlutterLocalNotificationsPlugin plugin, {
    DraftModeNotifierConfig? config,
  }) {
    return DraftModeNotifier._(plugin: plugin, config: config);
  }

  static DraftModeNotifier? _instance;

  /// Shared singleton used by production code.
  static DraftModeNotifier get instance {
    return _instance ??= DraftModeNotifier._();
  }

  /// Replaces the singleton for tests.
  @visibleForTesting
  static void debugResetInstance(DraftModeNotifier? notifier) {
    _instance = notifier;
  }

  final FlutterLocalNotificationsPlugin _fln;
  DraftModeNotifierConfig _config;
  static const _channelId = 'confirm_channel';
  static const _iosCategoryId = 'CONFIRM_LEAVE';
  static const _confirmPayload = 'confirm';

  /// Payload automatically assigned to notifications when no payload is given.
  static const confirmPayload = _confirmPayload;
  final Map<String, _NotificationConsumer> _consumers = {};
  final Map<String, List<DraftModeNotificationResponse>> _pendingResponses = {};
  final Map<int, DraftModeNotificationItem> _activeNotifications = {};
  final ValueNotifier<int> _pendingNotificationCount = ValueNotifier<int>(0);
  final ValueNotifier<List<DraftModeNotificationItem>> _pendingNotifications =
      ValueNotifier<List<DraftModeNotificationItem>>(const []);
  bool _isInitialized = false;

  /// Listen for the number of notifications that have been issued but not
  /// responded to or cancelled yet.
  ValueListenable<int> get pendingNotificationCountListenable =>
      _pendingNotificationCount;

  /// Synchronously reads the current pending notification total.
  int get pendingNotificationCount => _pendingNotificationCount.value;

  /// Listen for the collection of pending notifications, including metadata
  /// needed for inbox displays.
  ValueListenable<List<DraftModeNotificationItem>>
      get pendingNotificationsListenable => _pendingNotifications;

  /// Synchronously reads the current pending notification list.
  List<DraftModeNotificationItem> get pendingNotifications =>
      _pendingNotifications.value;

  /// Sets up categories, permissions, and the Android channel exactly once.
  Future<void> init({DraftModeNotifierConfig? config}) async {
    if (config != null) {
      _config = config;
    }
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    final darwinInit = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _iosCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'YES',
              _config.yesActionLabel,
              options: const {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'NO',
              _config.noActionLabel,
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
          options: const {DarwinNotificationCategoryOption.customDismissAction},
        ),
      ],
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _fln.initialize(
      InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _requestPermissions();

    const channel = AndroidNotificationChannel(
      _channelId,
      'Confirmations',
      description: 'Actionable confirmations',
      importance: Importance.high,
    );
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Registers a handler that fires when a notification with [payload] is tapped.
  ///
  /// If the notification was tapped before [handler] is registered, the tap
  /// will be replayed once registration completes. Use [triggerFilter] to accept
  /// only certain responses (for example, YES versus NO). Passing a `null`
  /// [handler] effectively clears the existing consumer for the payload.
  void registerConsumer({
    required String payload,
    Future<void> Function(DraftModeNotificationResponse response)? handler,
    bool Function(DraftModeNotificationResponse response)? triggerFilter,
  }) {
    final normalized = _normalizePayload(payload);
    _consumers[normalized] =
        _NotificationConsumer(handler: handler, filter: triggerFilter);
    _replayPendingResponses(normalized);
  }

  Future<void> _requestPermissions() async {
    final ios = _fln.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final mac = _fln.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await mac?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _handleNotificationResponse(NotificationResponse resp) async {
    _resolvePendingNotification(resp.id);
    final payload = _normalizePayload(resp.payload);
    final wrapped = DraftModeNotificationResponse.fromPlugin(
      normalizedPayload: payload,
      response: resp,
    );
    await _dispatchNotification(wrapped);
  }

  /// Generates the timestamp-based id used when callers omit [id].
  int get normalizedKey => DateTime.now().millisecondsSinceEpoch;

  /// Posts an actionable alert with native Yes/No buttons.
  ///
  /// When [id] is omitted, the notifier assigns a timestamp-based identifier so
  /// apps can fire-and-forget notifications without tracking ids manually.
  Future<void> pushNotification({
    required String title,
    required String body,
    String? subtitle,
    String? payload,
    int? id,
  }) async {
    final useId = id ?? normalizedKey;
    final safeId = _normalizeNotificationId(useId);
    final android = AndroidNotificationDetails(
      _channelId,
      'Confirmations',
      subText: subtitle,
      channelDescription: 'Actionable confirmations',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          'YES',
          _config.yesActionLabel,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'NO',
          _config.noActionLabel,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    final ios = DarwinNotificationDetails(
      categoryIdentifier: _iosCategoryId,
      subtitle: subtitle,
    );

    final normalizedPayload = _normalizePayload(payload);
    await _fln.show(
      safeId,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: normalizedPayload,
    );
    final item = DraftModeNotificationItem(
        id: safeId,
        title: title,
        subtitle: subtitle,
        body: body,
        payload: normalizedPayload);
    _trackPendingNotification(item);
  }

  /// Cancels a notification, normalizing the id to stay within Android limits.
  Future<void> cancel(int id) {
    final safeId = _normalizeNotificationId(id);
    _resolvePendingNotification(safeId);
    return _fln.cancel(safeId);
  }

  /// Invokes the registered consumer for a pending notification as if it were
  /// tapped from the system tray.
  Future<void> triggerPendingNotification(int id) async {
    final pending = _activeNotifications[id];
    if (pending == null) {
      return;
    }
    final payload = _normalizePayload(pending.payload);
    final consumer = _consumers[payload];
    if (consumer == null) {
      return;
    }
    final response = DraftModeNotificationResponse.synthetic(
      payload: payload,
      notificationResponseType:
          DraftModeNotificationResponseType.selectedNotification,
      notificationId: pending.id,
    );
    await _dispatchNotification(response);
    _resolvePendingNotification(id);
  }

  /// Default filter that accepts taps from the notification body or YES action.
  static bool isConfirmResponse(DraftModeNotificationResponse resp) {
    final type = resp.notificationResponseType;
    final fromNotification =
        type == DraftModeNotificationResponseType.selectedNotification;
    final isYesAction =
        type == DraftModeNotificationResponseType.selectedNotificationAction &&
            resp.actionId == 'YES';
    return fromNotification || isYesAction;
  }

  void _trackPendingNotification(DraftModeNotificationItem item) {
    final int id = item.id;
    _activeNotifications[id] = item;
    _syncPendingNotificationState();
  }

  void _resolvePendingNotification(int? id) {
    if (id == null) {
      return;
    }
    if (_activeNotifications.remove(id) != null) {
      _syncPendingNotificationState();
    }
  }

  void _syncPendingNotificationState() {
    _pendingNotificationCount.value = _activeNotifications.length;
    _pendingNotifications.value =
        List.unmodifiable(_activeNotifications.values.toList());
  }
}

/// Background entrypoint wired into [FlutterLocalNotificationsPlugin].
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await DraftModeNotifier.instance._handleNotificationResponse(response);
}

@visibleForTesting
int normalizeNotificationId(int id) => _normalizeNotificationId(id);

int _normalizeNotificationId(int id) {
  final normalized = id & _kMaxNotificationId;
  return normalized == 0 ? 1 : normalized;
}

/// Ensures payloads always have a routing value.
String _normalizePayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return DraftModeNotifier._confirmPayload;
  }
  return payload;
}

/// Holds callbacks registered for a normalized notification payload.
class _NotificationConsumer {
  const _NotificationConsumer({
    this.handler,
    this.filter,
  });

  final Future<void> Function(DraftModeNotificationResponse response)? handler;
  final bool Function(DraftModeNotificationResponse response)? filter;
}

extension on DraftModeNotifier {
  /// Dispatches a response to its handler or buffers it until registration.
  Future<void> _dispatchNotification(
      DraftModeNotificationResponse response) async {
    final normalized = _normalizePayload(response.payload);
    final consumer = _consumers[normalized];
    if (consumer == null) {
      _pendingResponses.putIfAbsent(response.payload, () => []).add(response);
      return;
    }
    final filter = consumer.filter;
    if (filter != null && !filter(response)) {
      return;
    }
    if (consumer.handler != null) {
      await consumer.handler!(response);
    }
  }

  /// Replays buffered responses for [payload] using fire-and-forget semantics.
  void _replayPendingResponses(String payload) {
    final pending = _pendingResponses.remove(payload);
    if (pending == null || pending.isEmpty) {
      return;
    }
    for (final response in pending) {
      unawaited(_dispatchNotification(response));
    }
  }
}
