import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  Future<void> Function()? _onConfirm;
  bool _pendingConfirm = false;
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

  /// Stores the callback to run when a confirmation notification is tapped.
  void registerOnConfirmHandler(Future<void> Function() handler) {
    _onConfirm = handler;
    if (_pendingConfirm) {
      _pendingConfirm = false;
      unawaited(_onConfirm!.call());
    }
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
    final type = resp.notificationResponseType;
    final shouldConfirm =
        type == NotificationResponseType.selectedNotification ||
            (type == NotificationResponseType.selectedNotificationAction &&
                resp.actionId == 'YES');
    if (!shouldConfirm) {
      return;
    }
    if (_onConfirm != null) {
      await _onConfirm!();
    } else {
      _pendingConfirm = true;
    }
  }

  /// Posts an actionable alert with native Yes/No buttons.
  Future<void> showActionNotification({
    required int id,
    required String title,
    required String body,
    String? subtitle,
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
      payload: 'confirm',
    );
  }

  /// Cancels a notification, normalizing the id to stay within Android limits.
  Future<void> cancel(int id) => _fln.cancel(_normalizeNotificationId(id));
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
