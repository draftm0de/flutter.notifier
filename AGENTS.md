# Repository Guidelines

## Project Structure & Module Organization
Source code lives in `lib/`, and each feature should keep its screens, widgets, and services under `lib/<feature>/` to make ownership clear; shared helpers (theme, routing, localization) belong in `lib/core/`. Tests mirror that layout under `test/` (`test/<feature>/..._test.dart`). Configuration such as package versions and localization generation sits in `pubspec.yaml`, while the `flutter.update.sh` script automates dependency refreshes and optional `flutter gen-l10n` output.

## Build, Test, and Development Commands
- `flutter pub get` installs or refreshes dependencies; run it before opening the project or after editing `pubspec.yaml`.
- `flutter run -d chrome` (or another device id) launches the app locally; keep hot reload active while iterating on UI.
- `flutter test` executes all unit and widget tests; add `--coverage` when validating reporting prior to a PR.
- `bash flutter.update.sh` performs a clean build, regenerates localizations when `l10n.yaml` exists, and upgrades packages to their latest compatible major releases.

## Coding Style & Naming Conventions
Use the Flutter 3.35 toolchain defined in `pubspec.yaml`. Format every Dart file with `dart format .`, and gate commits with `flutter analyze` to catch lint issues. Keep files and directories in lower_snake_case, classes in PascalCase, and non-public members in lowerCamelCase with a leading underscore for privacy. Widgets should remain small and composable; move cascading layouts into helper widgets under `lib/widgets/` when they exceed ~150 lines.

## Testing Guidelines
Adopt `flutter_test` with `group` and `testWidgets` for UI; name files `*_test.dart` to keep the runner discoverable. Each feature branch must add or adjust tests alongside code changes, targeting the same directory layout as production code. Favor golden tests for static visuals and mocked services for async flows. Block merges when `flutter test` fails or reports coverage regression on critical modules (navigation, localization, or shared services).

## Commit & Pull Request Guidelines
Write present-tense, scope-first commit messages (`appbar: add share action`) no longer than 72 characters, with optional body paragraphs describing rationale or follow-ups. Squash local fixups before opening a pull request. Every PR should describe the user-facing change, list testing performed (commands or screenshots for UI deltas), and link related issues. Include screenshots or screen recordings whenever a widget or animation changes, and highlight any dependency upgrades motivated by `flutter.update.sh`.
