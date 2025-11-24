import 'dart:async';
import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_notifier_example/notifier.dart';
import 'package:draftmode_ui/components.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController(
    text: 'title',
  );
  final TextEditingController _subtitleController = TextEditingController(
    text: '',
  );
  final TextEditingController _messageController = TextEditingController(
    text: 'message',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> sendNotification() async {
    await DraftModeNotifier.instance.pushNotification(
      title: _titleController.text,
      subtitle: _subtitleController.text,
      body: _messageController.text,
      payload: Notifier.notifierKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraftModeUIPageExample(
      title: 'Notifier Demo',
      children: [
        DraftModeUISection(header: "Notification", children: [
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
        ]),
        const SizedBox(height: 20),
        DraftModeUISection(
          children: [
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () => sendNotification(),
                child: const Text('Send Notification'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
