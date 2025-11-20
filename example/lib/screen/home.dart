import 'dart:async';
import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/components.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        DraftModeUISection(
          header: "Notification",
          children: [
            DraftModeUIRow(CupertinoTextField(
              controller: _titleController,
              placeholder: 'Title',
              style: const TextStyle(fontSize: 20),
            )),
            DraftModeUIRow(CupertinoTextField(
              controller: _subtitleController,
              placeholder: 'Subtitle (optional)',
              style: const TextStyle(fontSize: 20),
            )),
            DraftModeUIRow(CupertinoTextField(
              controller: _messageController,
              placeholder: 'Message',
              minLines: 4,
              maxLines: 7,
              style: const TextStyle(fontSize: 20),
            )),
            DraftModeUIRow(CupertinoTextField(
              controller: _secondsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              placeholder: 'e.g. 20',
              style: const TextStyle(fontSize: 20),
            ), label: "Delay",),
          ]
        ),
        const SizedBox(height: 10),
        DraftModeUISection(
          header: 'Remaining Seconds',
          children: [
            DraftModeUIRow(Text(
              statusText,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            )),
            if (_inputError != null) ...[
              const SizedBox(height: 6),
              DraftModeUIRow(Text(
                _inputError!,
                style: const TextStyle(color: CupertinoColors.systemRed),
              )),
            ]
          ]
        ),
        const SizedBox(height: 20),
        DraftModeUISection(
          children: [
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _sendNotification,
                child: const Text('Show notification'),
              ),
            )
          ],
        ),
      ],
    );
  }
}