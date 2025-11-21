/// Contract implemented by presenters that can surface a confirmation dialog.
abstract class DraftModeNotifierShowDialog {
  Future<bool> show({
    required String title,
    required String message,
  });
}

/// Callback signature passed into [XDraftModeNotifierDialog].
///
/// The first named parameter remains misspelled (`tite`) to avoid a breaking
/// API change until consumers migrate. Treat it as the dialog title.
typedef XDraftModeNotifierShowDialog = Future<bool> Function({
  required String tite,
  required String message,
});

/// Wrapper that promotes a callback to [DraftModeNotifierShowDialog].
class XDraftModeNotifierDialog implements DraftModeNotifierShowDialog {
  XDraftModeNotifierDialog({
    required this.notificationDialog,
  });

  final XDraftModeNotifierShowDialog notificationDialog;

  @override
  Future<bool> show({
    required String title,
    required String message,
  }) async {
    return notificationDialog(
      tite: title,
      message: message,
    );
  }

  /// Legacy helper maintained for backwards compatibility with callers that
  /// were previously wired to `showDialog`. Prefer [show] going forward.
  Future<bool> showDialog({
    required String title,
    required String content,
  }) {
    return show(title: title, message: content);
  }
}
