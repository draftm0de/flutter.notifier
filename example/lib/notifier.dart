import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/components.dart';

class Notifier {
  static String notifierKey = "custom";
  Future<void> handleEnterTap(DraftModeNotificationResponse response) async {
    await DraftModeUIDialog.show(
      title: 'Notification',
      message: "You've tapped on the notification (${response.payload})",
    );
  }
}
