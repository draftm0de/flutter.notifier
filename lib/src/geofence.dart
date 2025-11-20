import 'package:flutter/widgets.dart';
import 'foreground.dart';
import 'notifier.dart';

enum DraftModeGeofenceNotificationMode { enter, exit }

class DraftModeGeofenceNotification {
  DraftModeGeofenceNotification(
      {required GlobalKey<NavigatorState> navigatorKey})
      : _navigatorKey = navigatorKey {
    _instance ??= this;
  }

  final GlobalKey<NavigatorState> _navigatorKey;

  static DraftModeGeofenceNotification? _instance;

  static DraftModeGeofenceNotification get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('Call DraftModeGeofenceNotification.init() first.');
    }
    return value;
  }

  bool _isInitialized = false;
  DraftModeNotifierForegroundDialog? _dialogPresenter;

  Future<void> init({
    Future<void> Function(DraftModeNotificationResponse)? onEnter,
    Future<void> Function(DraftModeNotificationResponse)? onExit,
  }) async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    if (onEnter == null && onExit == null) {
      return;
    }

    _dialogPresenter ??=
        DraftModeNotifierForegroundDialog(navigatorKey: _navigatorKey);

    await DraftModeNotifier.instance.init();
    if (onEnter != null) {
      DraftModeNotifier.instance.registerNotificationConsumer(
        payload: DraftModeGeofenceNotificationMode.enter.name,
        handler: onEnter,
      );
    }
    if (onExit != null) {
      DraftModeNotifier.instance.registerNotificationConsumer(
        payload: DraftModeGeofenceNotificationMode.exit.name,
        handler: onExit,
      );
    }
  }

  Future<void> showDialog({
    required String title,
    required String content,
  }) async {
    final presenter = _dialogPresenter;
    if (presenter == null) {
      throw StateError('Call init() before presenting dialogs.');
    }
    await presenter.showSimpleDialog(title: title, content: content);
  }
}
