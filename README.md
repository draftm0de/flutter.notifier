# DraftMode Notifier

DraftMode Notifier wraps `flutter_local_notifications` with a ready-made Yes/No workflow. The package wires notification categories, handles permission requests, and exposes a simple API for showing actionable alerts from Dart without touching any platform code.

## How it works

- `DraftModeNotifier.init()` configures the Darwin category with **YES/NO** actions, requests iOS/macOS permissions, and creates the Android channel only once per run.
- `registerNotificationConsumer` connects tap handlers to payloads. Registering with `DraftModeNotifier.confirmPayload` replays pending taps even if the handler was added late.
- `showActionNotification` posts a high-priority notification that includes an optional subtitle for extra emphasis on both Android and iOS.
- The included iOS plugin (`ios/Classes/DraftmodeNotifierPlugin.swift`) sets the `UNUserNotificationCenter` delegate so consumers never need to edit their own `AppDelegate`.

```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DraftModeNotifier.instance.init();
  DraftModeNotifier.instance.registerNotificationConsumer(
    payload: DraftModeNotifier.confirmPayload,
    triggerFilter: DraftModeNotifier.isConfirmResponse,
    handler: (_) async {
      // React to the confirmation.
    },
  );
}

Future<void> pushReminder() {
  return DraftModeNotifier.instance.showActionNotification(
    id: 42,
    title: 'Leave Draft Mode?',
    subtitle: 'Syncing will stop in 30s',
    body: 'Tap yes to resume or no to stay in draft.',
  );
}
```

## Example app
The sample under `example/` demonstrates a countdown UI: enter title/message (+ optional subtitle), choose a delay, and the app shows the notification after counting down live on screen. Run it with `flutter run` (device or simulator) to see the complete flow, including handling taps while the app is in the background.

## Development workflow

1. Install deps: `flutter pub get` (root) and `flutter pub get` inside `example/` if run separately.
2. Format all Dart sources: `dart format .`.
3. Static analysis: `flutter analyze`.
4. Run tests with coverage: `flutter test --coverage`.
5. Generate an HTML coverage report: `genhtml coverage/lcov.info -o coverage/html` and open `coverage/html/index.html` in a browser.

The `flutter.update.sh` script performs a clean build, refreshes dependencies, and regenerates `flutter gen-l10n` output when configured—use it when upgrading Flutter or packages.

## Testing guidance
Tests live under `test/` and mirror the `lib/` layout. Every behavior exposed by `DraftModeNotifier` has direct coverage, including notification id normalization, tap handling, and countdown logic in the example utility code. CI should block merges unless `flutter test` passes and coverage remains at 100%.
