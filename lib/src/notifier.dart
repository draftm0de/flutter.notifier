import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../flutter/notification.dart';

const int _kMaxNotificationId = 0x7fffffff;

/// Coordinates local notification set up and tap handling for DraftMode apps.
class DraftModeNotifier {
  DraftModeNotifier._({FlutterLocalNotificationsPlugin? plugin})
      : _fln = plugin ?? FlutterLocalNotificationsPlugin();

  /// Creates a notifier that wraps a custom notifications plugin (used in tests).
  @visibleForTesting
  factory DraftModeNotifier.test(FlutterLocalNotificationsPlugin plugin) {
    return DraftModeNotifier._(plugin: plugin);
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
  static const _channelId = 'confirm_channel';
  static const _iosCategoryId = 'CONFIRM_LEAVE';
  static const _confirmPayload = 'confirm';

  /// Payload automatically assigned to notifications when no payload is given.
  static const confirmPayload = _confirmPayload;
  final Map<String, _NotificationConsumer> _consumers = {};
  final Map<String, List<DraftModeNotificationResponse>> _pendingResponses = {};
  bool _isInitialized = false;

  /// Sets up categories, permissions, and the Android channel exactly once.
  Future<void> init() async {
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
              'Yes',
              options: const {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'NO',
              'No',
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
  void registerNotificationConsumer({
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
    final payload = _normalizePayload(resp.payload);
    final wrapped = DraftModeNotificationResponse._fromPlugin(
      normalizedPayload: payload,
      response: resp,
    );
    await _dispatchNotification(wrapped);
  }

  /// Posts an actionable alert with native Yes/No buttons.
  Future<void> showActionNotification({
    required int id,
    required String title,
    required String body,
    String? subtitle,
    String? payload,
  }) async {
    final safeId = _normalizeNotificationId(id);
    final android = AndroidNotificationDetails(
      _channelId,
      'Confirmations',
      subText: subtitle,
      channelDescription: 'Actionable confirmations',
      importance: Importance.high,
      priority: Priority.high,
      actions: const [
        AndroidNotificationAction(
          'YES',
          'Yes',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'NO',
          'No',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    final ios = DarwinNotificationDetails(
      categoryIdentifier: _iosCategoryId,
      subtitle: subtitle,
    );

    await _fln.show(
      safeId,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: _normalizePayload(payload),
    );
  }

  /// Cancels a notification, normalizing the id to stay within Android limits.
  Future<void> cancel(int id) => _fln.cancel(_normalizeNotificationId(id));

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

String _normalizePayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return DraftModeNotifier._confirmPayload;
  }
  return payload;
}

class _NotificationConsumer {
  const _NotificationConsumer({
    this.handler,
    this.filter,
  });

  final Future<void> Function(DraftModeNotificationResponse response)? handler;
  final bool Function(DraftModeNotificationResponse response)? filter;
}

extension on DraftModeNotifier {
  Future<void> _dispatchNotification(
      DraftModeNotificationResponse response) async {
    final consumer = _consumers[response.payload];
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

/// Provides payload and action context for a tapped local notification.
class DraftModeNotificationResponse {
  DraftModeNotificationResponse._({
    required this.payload,
    required this.notificationResponseType,
    this.actionId,
    this.input,
    this.notificationId,
  });

  factory DraftModeNotificationResponse._fromPlugin({
    required String normalizedPayload,
    required NotificationResponse response,
  }) {
    return DraftModeNotificationResponse._(
      payload: normalizedPayload,
      notificationResponseType:
          _mapResponseType(response.notificationResponseType),
      actionId: response.actionId,
      input: response.input,
      notificationId: response.id,
    );
  }

  /// Normalized payload string DraftModeNotifier uses for routing.
  final String payload;

  /// Translated response type describing how the notification was engaged.
  final DraftModeNotificationResponseType notificationResponseType;

  /// Native identifier for the action button, when present.
  final String? actionId;

  /// Freeform input text returned by text input actions.
  final String? input;

  /// Notification id provided when the alert was shown, if included.
  final int? notificationId;
}

enum DraftModeNotificationResponseType {
  selectedNotification,
  selectedNotificationAction,
}

DraftModeNotificationResponseType _mapResponseType(
    NotificationResponseType type) {
  switch (type) {
    case NotificationResponseType.selectedNotification:
      return DraftModeNotificationResponseType.selectedNotification;
    case NotificationResponseType.selectedNotificationAction:
      return DraftModeNotificationResponseType.selectedNotificationAction;
  }
}
