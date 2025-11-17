import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const int _kMaxNotificationId = 0x7fffffff;

class DraftModeNotifier {
  DraftModeNotifier._();
  static final instance = DraftModeNotifier._();

  final _fln = FlutterLocalNotificationsPlugin();
  static const _channelId = 'confirm_channel';
  static const _iosCategoryId = 'CONFIRM_LEAVE';
  Future<void> Function()? _onConfirm;
  bool _pendingConfirm = false;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    // iOS categories with actions
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

    // Android channel
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

  // Post the action notification
  Future<void> showActionNotification({
    required int id,
    required String title,
    required String body,
    String? subtitle
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
      subtitle: subtitle
    );

    await _fln.show(
      safeId,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: 'confirm',
    );
  }

  Future<void> cancel(int id) => _fln.cancel(_normalizeNotificationId(id));
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  await DraftModeNotifier.instance._handleNotificationResponse(response);
}

@visibleForTesting
int normalizeNotificationId(int id) => _normalizeNotificationId(id);

int _normalizeNotificationId(int id) {
  final normalized = id & _kMaxNotificationId;
  return normalized == 0 ? 1 : normalized;
}
