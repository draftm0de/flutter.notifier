import 'package:draftmode_notifier/notifier.dart';
import 'package:draftmode_ui/components.dart';

class Notifier {
  static String notifierKeyEnter = "enter";
  static String notifierKeyExit = "exit";

  Future<void> handleEnter(DraftModeNotificationResponse response) async {
    await DraftModeUIDialog.show(
      title: 'handleEnter',
      message: "You've tapped on the notification (${response.payload})",
    );
  }

  Future<void> handleExit(DraftModeNotificationResponse response) async {
    await DraftModeUIDialog.show(
      title: 'handleExit',
      message: "You've tapped on the notification (${response.payload})",
    );
  }
}
