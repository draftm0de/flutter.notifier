import 'package:draftmode_notifier/src/response.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromPlugin carries normalized payload and metadata', () {
    const pluginResponse = NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      id: 7,
      payload: 'raw_payload',
      actionId: 'YES',
      input: 'notes',
    );

    final wrapped = DraftModeNotificationResponse.fromPlugin(
      normalizedPayload: 'confirm',
      response: pluginResponse,
    );

    expect(wrapped.payload, 'confirm');
    expect(
      wrapped.notificationResponseType,
      DraftModeNotificationResponseType.selectedNotification,
    );
    expect(wrapped.actionId, 'YES');
    expect(wrapped.input, 'notes');
    expect(wrapped.notificationId, 7);
  });

  test('fromPlugin maps action response types', () {
    const pluginResponse = NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: 'NO',
    );

    final wrapped = DraftModeNotificationResponse.fromPlugin(
      normalizedPayload: 'confirm',
      response: pluginResponse,
    );

    expect(
      wrapped.notificationResponseType,
      DraftModeNotificationResponseType.selectedNotificationAction,
    );
    expect(wrapped.actionId, 'NO');
  });
}
