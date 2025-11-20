import 'dart:async';
import 'package:draftmode_notifier/notifier.dart';
import 'package:flutter/cupertino.dart';
import 'app.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DraftModeNotifier.instance.init();
  DraftModeNotifier.instance.registerOnConfirmHandler(_handleConfirmAction);
  runApp(App(navigatorKey: _navigatorKey));
}

Future<BuildContext?> _waitForRootContext() async {
  BuildContext? ctx = _navigatorKey.currentContext;
  if (ctx != null) {
    return ctx;
  }
  final end = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    ctx = _navigatorKey.currentContext;
    if (ctx != null) {
      return ctx;
    }
  }
  return ctx;
}

Future<void> _handleConfirmAction() async {
  debugPrint('start:handleConfirmAction.');
  final ctx = await _waitForRootContext();
  if (ctx == null) {
    debugPrint('Unable to show confirmation dialog: no context.');
    return;
  }
  final navigatorState = _navigatorKey.currentState;
  if (navigatorState == null || !navigatorState.mounted) {
    return;
  }
  await showCupertinoDialog<void>(
    context: ctx,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('Confirmed'),
      content: const Text('Notification acknowledged.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
