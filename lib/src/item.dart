/// Snapshot describing a notification that has been issued but not acted on.
class DraftModeNotificationItem {
  DraftModeNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.subtitle,
    required this.payload,
  }) : createdAt = DateTime.now();

  final int id;
  final String title;
  final String body;
  final String? subtitle;
  final String payload;
  final DateTime createdAt;
}
