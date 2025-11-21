import 'package:draftmode_ui/context.dart';
import 'package:flutter/cupertino.dart';
//
import 'geofence/notifier.dart';
import 'app.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DraftModeUIContext.init(navigatorKey: _navigatorKey);
  await GeofenceNotifier().init();
/*
  await DraftModeNotifier.instance.init();
  DraftModeNotifier.instance.registerNotificationConsumer(
    payload: geofenceEnterPayload,
    handler: callbacks.handleEnterTap,
  );
  DraftModeNotifier.instance.registerNotificationConsumer(
    payload: geofenceExitPayload,
    handler: callbacks.handleExitTap,
  );
  DraftModeNotifier.instance.registerNotificationConsumer(
    payload: 'custom',
    handler: callbacks.handleCustomTap,
  );
*/
  runApp(App(navigatorKey: _navigatorKey));
}
