# DraftMode Notifier

DraftMode Notifier wraps `flutter_local_notifications` with a ready-made Yes/No workflow. The package wires notification categories, handles permission requests, and exposes a simple API for showing actionable alerts from Dart without touching any platform code.

## How it works

- `DraftModeNotifier.init()` configures the Darwin category with **YES/NO** actions, requests iOS/macOS permissions, and creates the Android channel only once per run.
- `registerNotificationConsumer` connects tap handlers to payloads. Use `DraftModeNotifier.confirmPayload` for the built-in YES flow, or pass custom payloads when showing notifications.
- `showActionNotification` posts a high-priority notification that includes an optional subtitle for extra emphasis on both Android and iOS; omit the `id` parameter to have the notifier auto-generate a timestamp-based id.
- Pass `DraftModeNotifierConfig` to `init` when localization is needed; the config lets each app override the YES/NO labels while DraftMode Notifier keeps the action identifiers stable.
- The included iOS plugin (`ios/Classes/DraftmodeNotifierPlugin.swift`) sets the `UNUserNotificationCenter` delegate so consumers never need to edit their own `AppDelegate`.
- The sample `GeofenceNotifier` under `example/lib/geofence/notifier.dart` shows how to route multiple payloads (ENTER/EXIT) into foreground dialogs without any platform code.

```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DraftModeNotifier.instance.init(
    config: const DraftModeNotifierConfig(
      yesActionLabel: 'Oui',
      noActionLabel: 'Non',
    ),
  );
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
    title: 'Leave Draft Mode?',
    subtitle: 'Syncing will stop in 30s',
    body: 'Tap yes to resume or no to stay in draft.',
  );
}
```

### Handling notification payloads

`registerNotificationConsumer` accepts three parameters:

- `payload`: the normalized key used when calling `showActionNotification`.
- `triggerFilter`: optional predicate that receives `DraftModeNotificationResponse` and can ignore taps (for example, only YES actions).
- `handler`: async callback invoked with the translated response that includes the payload, action id, response type, and optional input text.

`DraftModeNotifier.isConfirmResponse` is a ready-made filter that accepts both YES button presses and taps on the body of the notification. The notifier buffers taps received before registration so handlers never miss a response.

### Foreground dialogs & sample geofence workflow

Apps that need a visual confirmation when a notification is tapped can wrap an existing dialog presenter in `XDraftModeNotifierDialog`. The helper bridges the legacy `tite` argument (kept for backward compatibility) to the modern `title/message` pair so existing callbacks continue to work while newer widgets adopt the `DraftModeNotifierShowDialog` contract.

The included example under `example/` wires those pieces together for a kiosk-style geofence helper:

1. `GeofenceNotifier` registers two payloads (`DraftModeGeofenceMode.enter/exit`).
2. Each handler invokes `DraftModeUIDialog.show` with copy that matches the geofence intent so operators see the context immediately.
3. `showActionNotification` is reused for both payloads, with the payload string controlling which dialog runs when the notification is tapped.

## Example app
The sample under `example/` simulates a TimeTac geofence flow: tapping **Trigger ENTER** or **Trigger EXIT** posts a notification with the corresponding payload, and the app surfaces a Cupertino dialog in the foreground when the notification is tapped. Run it with `flutter run` (device or simulator) to see the full experience, including how background taps replay when the app becomes active.

## Development workflow

1. Install deps: `flutter pub get` (root) and `flutter pub get` inside `example/` if run separately.
2. Format all Dart sources: `dart format .`.
3. Static analysis: `flutter analyze`.
4. Run tests with coverage: `flutter test --coverage`.
5. Generate an HTML coverage report: `genhtml coverage/lcov.info -o coverage/html` and open `coverage/html/index.html` in a browser.

The `flutter.update.sh` script performs a clean build, refreshes dependencies, and regenerates `flutter gen-l10n` output when configured—use it when upgrading Flutter or packages.

## Testing guidance
Tests live under `test/` and mirror the `lib/` layout. Every behavior exposed by `DraftModeNotifier` has direct coverage, including notification id normalization, payload routing, dialog bridges, and buffering taps until a consumer is registered. CI should block merges unless `flutter test` passes and coverage remains at **100%**—lint and coverage gates offer fast feedback before a pull request ever leaves your machine.
