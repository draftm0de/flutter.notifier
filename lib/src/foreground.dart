import 'package:draftmode_ui/components.dart';
import 'package:flutter/cupertino.dart';

/// Function signature used to present dialogs (overridden in tests).
typedef DraftModeDialogPresenter = Future<void> Function({
  required BuildContext context,
  required String title,
  required String message,
});

/// Waits for the root navigator context before showing Cupertino dialogs.
class DraftModeNotifierForegroundDialog {
  DraftModeNotifierForegroundDialog({
    required GlobalKey<NavigatorState> navigatorKey,
    this.waitTimeout = const Duration(seconds: 2),
    DraftModeDialogPresenter? presenter,
  })  : _navigatorKey = navigatorKey,
        _showDialog = presenter ?? DraftModeUIDialog.show;

  final GlobalKey<NavigatorState> _navigatorKey;
  final Duration waitTimeout;
  final DraftModeDialogPresenter _showDialog;

  Future<BuildContext?> _waitForRootContext() async {
    BuildContext? ctx = _navigatorKey.currentContext;
    if (ctx != null) {
      return ctx;
    }
    final end = DateTime.now().add(waitTimeout);
    while (DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        return ctx;
      }
    }
    return ctx;
  }

  Future<void> showSimpleDialog({
    required String title,
    required String content,
  }) async {
    final ctx = await _waitForRootContext();
    if (ctx == null) {
      debugPrint('Unable to show dialog: no context.');
      return;
    }
    final navigatorState = _navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted || !ctx.mounted) {
      return;
    }
    await _showDialog(context: ctx, title: title, message: content);
  }
}
