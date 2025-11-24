import 'package:draftmode_notifier/notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DraftModeNotifierConfig exposes sane defaults', () {
    const config = DraftModeNotifierConfig();
    expect(config.yesActionLabel, equals('Yes'));
    expect(config.noActionLabel, equals('No'));
  });

  test('DraftModeNotifierConfig.copyWith overrides individual labels', () {
    const original = DraftModeNotifierConfig(
      yesActionLabel: 'Si',
      noActionLabel: 'Nao',
    );

    final overrideYes = original.copyWith(yesActionLabel: 'Oui');
    expect(overrideYes.yesActionLabel, equals('Oui'));
    expect(overrideYes.noActionLabel, equals('Nao'));

    final overrideNo = original.copyWith(noActionLabel: 'Non');
    expect(overrideNo.yesActionLabel, equals('Si'));
    expect(overrideNo.noActionLabel, equals('Non'));
  });
}
