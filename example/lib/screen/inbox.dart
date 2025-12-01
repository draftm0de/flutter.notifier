import 'dart:async';

import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/components.dart';
import 'package:draftmode_ui/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final ValueListenable<List<DraftModeNotificationItem>>
      _pendingListenable;
  late final VoidCallback _pendingListener;
  List<DraftModeNotificationItem> _items = const [];
  late final DateFormat _timeFormatter;

  @override
  void initState() {
    super.initState();
    _pendingListenable =
        DraftModeNotifier.instance.pendingNotificationsListenable;
    _items = _pendingListenable.value;
    _timeFormatter = DateFormat('dd.MM.yyyy HH:mm');
    _pendingListener = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = _pendingListenable.value;
      });
    };
    _pendingListenable.addListener(_pendingListener);
  }

  @override
  void dispose() {
    _pendingListenable.removeListener(_pendingListener);
    super.dispose();
  }

  Widget _buildItem(DraftModeNotificationItem item, bool selected) {
    final subtitle = item.subtitle;
    final timeLabel = _timeFormatter.format(item.createdAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              timeLabel,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.body,
            style: const TextStyle(
                fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraftModeUIPageExample(
      title: 'Inbox',
      children: [
        DraftModeUISection(
          children: [
            DraftModeUIList<DraftModeNotificationItem>(
              isPending: false,
              items: _items,
              itemBuilder: _buildItem,
              onTap: (item) {
                unawaited(
                  DraftModeNotifier.instance
                      .triggerPendingNotification(item.id),
                );
              },
              emptyPlaceholder:
                  const Text('No notifications have been received.'),
            ),
          ],
        ),
      ],
    );
  }
}
