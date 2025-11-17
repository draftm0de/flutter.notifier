import 'dart:async';

import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _subtitleController = TextEditingController(
    text: '',
  );
  final TextEditingController _messageController = TextEditingController(
    text: 'message',
  );
  final TextEditingController _secondsController = TextEditingController(
    text: '5',
  );
  String? _inputError;
  Duration? _remaining;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _secondsController.dispose();
    _subtitleController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _remaining = Duration(seconds: seconds);
    });
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          final current = _remaining;
          if (current == null || current.inSeconds <= 1) {
            _remaining = Duration.zero;
            timer.cancel();
          } else {
            _remaining = current - const Duration(seconds: 1);
          }
        });
      },
    );
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _remaining = Duration.zero;
    });
  }

  Future<void> _sendNotification() async {
    final seconds = int.tryParse(_secondsController.text);
    if (seconds == null || seconds <= 0) {
      setState(() {
        _inputError = 'Enter seconds greater than 0';
      });
      return;
    }

    setState(() {
      _inputError = null;
    });

    _startCountdown(seconds);

    await Future.delayed(Duration(seconds: seconds));
    _stopCountdown();
    await DraftModeNotifier.instance.showActionNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text,
      body: _messageController.text,
      subtitle:
          _subtitleController.text.isEmpty ? null : _subtitleController.text,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final remText = _formatDuration(_remaining ?? Duration.zero);
    final statusText = 'Remaining: $remText';

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
                controller: _subtitleController,
                placeholder: 'Subtitle (optional)',
                style: const TextStyle(fontSize: 20),
              ),
              CupertinoTextField(
                controller: _messageController,
                placeholder: 'Message',
                minLines: 4,
                maxLines: 7,
                style: const TextStyle(fontSize: 20),
              ),
              CupertinoTextField(
                controller: _secondsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                placeholder: 'e.g. 20',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 7),
              Text(
                statusText,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              if (_inputError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _inputError!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
              ],
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
