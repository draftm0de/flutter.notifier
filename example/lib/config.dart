import 'package:draftmode_notifier/notifier.dart';
import 'package:flutter/cupertino.dart';

/// High-level entry that configures DraftMode notifications for TimeTac.
class TimeTacGeofenceNotification {
  TimeTacGeofenceNotification({required GlobalKey<NavigatorState> navigatorKey})
      : _navigatorKey = navigatorKey;

  final GlobalKey<NavigatorState> _navigatorKey;

  static TimeTacGeofenceNotification? _instance;

  static TimeTacGeofenceNotification get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('Call TimeTacGeofenceNotification.init() first.');
    }
    return value;
  }

  bool _isInitialized = false;

  /// Flags that would normally come from user/config service.
  bool onEnterNotify = false;
  bool onExitNotify = true;

  Future<void> init() async {
    _instance ??= this;
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    await _initializeNotification();
  }

  Future<void> _initializeNotification() async {
    final geofence = DraftModeGeofenceNotification(navigatorKey: _navigatorKey);
    await geofence.init(
      onEnter: _handleEnterTap,
      onExit: _handleExitTap,
    );
  }

  Future<void> sendNotification(DraftModeGeofenceNotificationMode mode) async {
    if (!_shouldSendNotification(mode)) {
      return;
    }
    await DraftModeNotifier.instance.showActionNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'title',
      subtitle: 'subtitle',
      body: 'body',
      payload: mode.name,
    );
  }

  bool _shouldSendNotification(DraftModeGeofenceNotificationMode mode) {
    switch (mode) {
      case DraftModeGeofenceNotificationMode.enter:
        return onEnterNotify;
      case DraftModeGeofenceNotificationMode.exit:
        return onExitNotify;
    }
  }

  Future<void> _handleEnterTap(DraftModeNotificationResponse response) async {
    await DraftModeGeofenceNotification.instance.showDialog(
      title: 'TimeTacGeofence',
      content:
          "You've entered the building, tracking starts (${response.payload})",
    );
  }

  Future<void> _handleExitTap(DraftModeNotificationResponse response) async {
    await DraftModeGeofenceNotification.instance.showDialog(
      title: 'TimeTacGeofence',
      content:
          "You've left the building, confirm submit tracking (${response.payload})",
    );
  }
}
