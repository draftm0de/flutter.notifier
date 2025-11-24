# Changelog

All notable changes to this project are tracked here. This file follows the
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/) convention.

## [1.0.1] - 2024-05-28
### Added
- DraftModeNotifier with YES/NO workflows, tap buffering, and consumer registration helpers.
- `DraftModeNotifierConfig` for localized action labels plus tests covering defaults, `copyWith`, and auto-generated notification ids.
- A Cupertino sample that posts notifications from text fields and replays taps via dialogs.

### Changed
- Documentation calls out the sample, dialog bridge, and auto-id behavior for easy onboarding.
- API surface favors concise names (`registerConsumer`/`pushNotification`).
