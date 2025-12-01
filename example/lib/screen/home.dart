import 'dart:async';

import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_notifier_example/notifier.dart';
import 'package:draftmode_notifier_example/screen/inbox.dart';
import 'package:draftmode_ui/buttons.dart';
import 'package:draftmode_ui/components.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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
  late final ValueListenable<int> _pendingCountListenable;
  late final VoidCallback _pendingListener;
  late final List<String> _types = [
    Notifier.notifierKeyEnter,
    Notifier.notifierKeyExit
  ];
  String? _selectedType;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedType = _types.first;
    _pendingCountListenable =
        DraftModeNotifier.instance.pendingNotificationCountListenable;
    _pendingCount = DraftModeNotifier.instance.pendingNotificationCount;
    _pendingListener = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingCount = _pendingCountListenable.value;
      });
    };
    _pendingCountListenable.addListener(_pendingListener);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _subtitleController.dispose();
    _pendingCountListenable.removeListener(_pendingListener);
    super.dispose();
  }

  Future<void> sendNotification() async {
    debugPrint(_selectedType);
    await DraftModeNotifier.instance.pushNotification(
      title: _titleController.text,
      subtitle: _subtitleController.text,
      body: _messageController.text,
      payload: _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraftModeUIPageExample(
      title: 'Notifier Demo',
      bottomTrailing: [
        DraftModePageNavigationBottomItem(
          icon: DraftModeUIButtons.listBullet,
          badge: DraftModeUIBadge.formatCountOrNull(_pendingCount),
          loadWidget: const InboxScreen(),
        ),
      ],
      children: [
        DraftModeUISection(header: "Type", children: [
          DraftModeUIList(
            isPending: _types.isEmpty,
            items: _types,
            selectedItem: _selectedType,
            itemBuilder: (item, selected) {
              return Text(item);
            },
            onTap: (item) => setState(() {
              _selectedType = item;
            }),
          ),
        ]),
        DraftModeUISection(header: "Message", children: [
          DraftModeUIRow(CupertinoTextField(
            controller: _titleController,
            placeholder: 'Title',
            style: const TextStyle(fontSize: 16),
          )),
          DraftModeUIRow(CupertinoTextField(
            controller: _subtitleController,
            placeholder: 'Subtitle (optional)',
            style: const TextStyle(fontSize: 16),
          )),
          DraftModeUIRow(CupertinoTextField(
            controller: _messageController,
            placeholder: 'Message',
            minLines: 4,
            maxLines: 7,
            style: const TextStyle(fontSize: 16),
          )),
        ]),
        const SizedBox(height: 20),
        DraftModeUISection(
          children: [
            DraftModeUIButton.text('Send Notification',
                onPressed: sendNotification)
          ],
        ),
      ],
    );
  }
}
