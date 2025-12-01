# Changelog

## 1.0.2+1
- Added `DraftModeNotificationItem` plus `pendingNotificationCountListenable` / `pendingNotificationsListenable` so apps can badge and render inbox views sourced from native notifications.
- Introduced `DraftModeNotificationResponse.synthetic` and `triggerPendingNotification` to replay registered consumers whenever a pending inbox entry is tapped.
- Documented the new inbox workflow and sample UI in the README and ensured timestamp metadata (`createdAt`) is stored automatically on each notification item.
- Expanded tests to cover pending-notification tracking, the synthetic response factory, and the data model so coverage remains complete.

## 1.0.1+1
- DraftModeNotifier with YES/NO workflows, tap buffering, and consumer registration helpers.
- `DraftModeNotifierConfig` for localized action labels plus tests covering defaults, `copyWith`, and auto-generated notification ids.
- A Cupertino sample that posts notifications from text fields and replays taps via dialogs.
- Documentation calls out the sample, dialog bridge, and auto-id behavior for easy onboarding.
- API surface favors concise names (`registerConsumer`/`pushNotification`).
