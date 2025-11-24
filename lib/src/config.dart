/// Configuration object that controls user-facing labels for DraftModeNotifier.
class DraftModeNotifierConfig {
  const DraftModeNotifierConfig({
    this.yesActionLabel = 'Yes',
    this.noActionLabel = 'No',
  });

  /// Display string for the affirmative action button on each platform.
  final String yesActionLabel;

  /// Display string for the negative action button on each platform.
  final String noActionLabel;

  DraftModeNotifierConfig copyWith({
    String? yesActionLabel,
    String? noActionLabel,
  }) {
    return DraftModeNotifierConfig(
      yesActionLabel: yesActionLabel ?? this.yesActionLabel,
      noActionLabel: noActionLabel ?? this.noActionLabel,
    );
  }
}
