import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DraftModeNotifier.instance.init();
  DraftModeNotifier.instance.registerOnConfirmHandler(_handleConfirmAction);
  runApp(NotifierExampleApp(navigatorKey: _navigatorKey));
}

Future<BuildContext?> _waitForRootContext() async {
  BuildContext? ctx = _navigatorKey.currentContext;
  if (ctx != null) {
    return ctx;
  }
  final end = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    ctx = _navigatorKey.currentContext;
    if (ctx != null) {
      return ctx;
    }
  }
  return ctx;
}

Future<void> _handleConfirmAction() async {
  debugPrint('start:handleConfirmAction.');
  final ctx = await _waitForRootContext();
  if (ctx == null) {
    debugPrint('Unable to show confirmation dialog: no context.');
    return;
  }
  final navigatorState = _navigatorKey.currentState;
  if (navigatorState == null || !navigatorState.mounted) {
    return;
  }
  await showCupertinoDialog<void>(
    context: ctx,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('Confirmed'),
      content: const Text('Notification acknowledged.'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class NotifierExampleApp extends StatelessWidget {
  const NotifierExampleApp({
    super.key,
    required this.navigatorKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const NotifierDemo(),
    );
  }
}

class NotifierDemo extends StatefulWidget {
  const NotifierDemo({super.key});

  @override
  State<NotifierDemo> createState() => _NotifierDemoState();
}

class _NotifierDemoState extends State<NotifierDemo> {
  final TextEditingController _titleController = TextEditingController(
    text: 'title',
  );
  final TextEditingController _messageController = TextEditingController(
    text: 'message',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    await Future.delayed(const Duration(seconds: 3));
    await DraftModeNotifier.instance.showActionNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text,
      body: _messageController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraftModeUIPageExample(
      title: 'Notifier Demo',
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey, width: 0.8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'Title',
                style: const TextStyle(fontSize: 20),
              ),
              CupertinoTextField(
                controller: _messageController,
                placeholder: 'Message',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _sendNotification,
              child: const Text('Show notification'),
            ),
          ),
        ),
      ],
    );
  }
}
