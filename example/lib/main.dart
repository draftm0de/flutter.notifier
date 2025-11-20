import 'package:flutter/cupertino.dart';

import 'app.dart';
import 'config.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TimeTacGeofenceNotification(navigatorKey: _navigatorKey).init();
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
