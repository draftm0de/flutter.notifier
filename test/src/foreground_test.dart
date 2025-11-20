import 'package:draftmode_notifier/notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraftModeNotifierForegroundDialog', () {
    testWidgets('returns early when context never arrives', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final calls = <String>[];
      final dialog = DraftModeNotifierForegroundDialog(
        navigatorKey: navigatorKey,
        waitTimeout: const Duration(milliseconds: 20),
        presenter: (
            {required context, required title, required message}) async {
          calls.add(title);
        },
      );

      await tester.runAsync(() async {
        await dialog.showSimpleDialog(title: 'Title', content: 'Body');
      });

      expect(calls, isEmpty);
    });

    testWidgets('shows dialog once navigator context is ready', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final calls = <String>[];
      final dialog = DraftModeNotifierForegroundDialog(
        navigatorKey: navigatorKey,
        presenter: (
            {required context, required title, required message}) async {
          calls.add('$title|$message|${context.mounted}');
        },
      );

      await tester.pumpWidget(CupertinoApp(
        navigatorKey: navigatorKey,
        home: const SizedBox.shrink(),
      ));

      await tester.runAsync(() async {
        await dialog.showSimpleDialog(title: 'Confirm', content: 'Proceed?');
      });

      expect(calls, ['Confirm|Proceed?|true']);
    });
  });
}
