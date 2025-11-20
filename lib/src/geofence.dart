import 'package:flutter/widgets.dart';
import 'foreground.dart';
import 'notifier.dart';

/// Modes used to differentiate ENTER versus EXIT notifications.
enum DraftModeGeofenceNotificationMode { enter, exit }

/// Ties [DraftModeNotifier] payloads to foreground dialog flows.
class DraftModeGeofenceNotification {
  DraftModeGeofenceNotification({
    required GlobalKey<NavigatorState> navigatorKey,
    DraftModeNotifier? notifier,
    DraftModeNotifierForegroundDialog? dialogPresenter,
  })  : _navigatorKey = navigatorKey,
        _notifier = notifier ?? DraftModeNotifier.instance,
        _dialogPresenter = dialogPresenter {
    _instance ??= this;
  }

  final GlobalKey<NavigatorState> _navigatorKey;
  final DraftModeNotifier _notifier;

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

  @visibleForTesting
  static void debugResetInstance() {
    _instance = null;
  }

  /// Registers optional tap handlers for enter/exit payloads.
  Future<void> init({
    Future<void> Function(DraftModeNotificationResponse)? onEnter,
    Future<void> Function(DraftModeNotificationResponse)? onExit,
  }) async {
    if (_isInitialized) {
      return;
    }
    if (onEnter == null && onExit == null) {
      return;
    }
    _isInitialized = true;

    _dialogPresenter ??=
        DraftModeNotifierForegroundDialog(navigatorKey: _navigatorKey);

    await _notifier.init();
    if (onEnter != null) {
      _notifier.registerNotificationConsumer(
        payload: DraftModeGeofenceNotificationMode.enter.name,
        handler: onEnter,
      );
    }
    if (onExit != null) {
      _notifier.registerNotificationConsumer(
        payload: DraftModeGeofenceNotificationMode.exit.name,
        handler: onExit,
      );
    }
  }

  /// Presents a Cupertino dialog routed through the supplied navigator.
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
