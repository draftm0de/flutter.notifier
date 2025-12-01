import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/context.dart';
import 'package:flutter/cupertino.dart';
//
import 'notifier.dart';
import 'app.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DraftModeUIContext.init(navigatorKey: _navigatorKey);
  await DraftModeNotifier.instance.init();
  DraftModeNotifier.instance.registerConsumer(
    payload: Notifier.notifierKeyEnter,
    handler: Notifier().handleEnter,
  );
  DraftModeNotifier.instance.registerConsumer(
    payload: Notifier.notifierKeyExit,
    handler: Notifier().handleExit,
  );
  runApp(App(navigatorKey: _navigatorKey));
}
