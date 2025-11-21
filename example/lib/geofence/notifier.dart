import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/components.dart';
//
import 'mode.dart';
import '../entity/geofence.dart';

/// High-level entry that configures DraftMode notifications for TimeTac.
class GeofenceNotifier {
  GeofenceNotifier();

  static GeofenceNotifier? _instance;

  static GeofenceNotifier get instance {
    final value = _instance;
    if (value == null) {
      throw StateError('Call TimeTacGeofenceNotifier.init() first.');
    }
    return value;
  }

  bool _isInitialized = false;
  late GeofenceConfig _geofenceConfig;

  Future<void> init() async {
    _instance ??= this;
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    // load timeTacConfig
    _geofenceConfig = GeofenceConfig();

    // initNotifier
    await _initNotifier();
  }

  Future<void> _initNotifier() async {
    await DraftModeNotifier.instance.init();
    DraftModeNotifier.instance.registerNotificationConsumer(
      payload: DraftModeGeofenceMode.enter.toString(),
      handler: _handleEnterTap
    );
    DraftModeNotifier.instance.registerNotificationConsumer(
      payload: DraftModeGeofenceMode.exit.toString(),
      handler: _handleExitTap
    );
  }

  // sendNotification
  Future<void> sendNotification(DraftModeGeofenceMode mode) async {
    if (!_shouldSendNotification(mode)) {
      return;
    }
    String title = "TimeTacGeofence";
    String subtitle;
    String message;
    switch (mode) {
      case DraftModeGeofenceMode.enter:
        subtitle = "You´ve entered the office";
        message = "Tracking has been started";
        break;
      default:
        subtitle = "You´ve left the office";
        message = "Please confirm submitting your tracking";
        break;
    }
    await DraftModeNotifier.instance.showActionNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      subtitle: subtitle,
      body: message,
      payload: mode.toString(),
    );
  }

  // shouldSendNotification
  bool _shouldSendNotification(DraftModeGeofenceMode mode) {
    switch (mode) {
      case DraftModeGeofenceMode.enter:
        return _geofenceConfig.sendNotificationOnEnter;
      case DraftModeGeofenceMode.exit:
        return _geofenceConfig.sendNotificationOnExit;
    }
  }

  // notificationDialogOnTabEnter
  Future<void> _handleEnterTap(DraftModeNotificationResponse response) async {
    await DraftModeUIDialog.show(
      title: 'TimeTacGeofence',
      message: "You've entered the building, tracking starts (${response.payload})",
    );
  }

  // notificationDialogOnTabExit
  Future<void> _handleExitTap(DraftModeNotificationResponse response) async {
    await DraftModeUIDialog.show(
      title: 'TimeTacGeofence',
      message:
      "You've left the building, confirm submit tracking (${response.payload})",
    );
  }
}
