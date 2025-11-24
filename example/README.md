# DraftMode Notifier

DraftMode Notifier wraps `flutter_local_notifications` with a ready-made Yes/No workflow. The package wires notification categories, handles permission requests, and exposes a simple API for showing actionable alerts from Dart without touching any platform code.

## How it works

`Notifier` in `lib/notifier.dart` registers a single payload with `DraftModeNotifier` and exposes a dialog handler that proves the tap routing works. The home screen collects the notification title/subtitle/body from text fields and calls `showActionNotification` without an id—DraftMode Notifier auto-generates it—so you can tweak copy on the fly while testing.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final navigatorKey = GlobalKey<NavigatorState>();
  DraftModeUIContext.init(navigatorKey: navigatorKey);
  await DraftModeNotifier.instance.init();
  DraftModeNotifier.instance.registerNotificationConsumer(
    payload: Notifier.notifierKey,
    handler: Notifier().handleEnterTap,
  );
  runApp(App(navigatorKey: navigatorKey));
}

Future<void> sendNotification() {
  return DraftModeNotifier.instance.showActionNotification(
    title: _titleController.text,
    subtitle: _subtitleController.text,
    body: _messageController.text,
    payload: Notifier.notifierKey,
  );
}
```

## Example app
The UI is intentionally minimal: three text fields for title/subtitle/body followed by a single CTA. Press the button to post the notification, then tap the alert to see the dialog that proves routing worked. Pending taps are buffered—try tapping the notification before foregrounding the app to watch the dialog appear automatically when the navigator is ready.
