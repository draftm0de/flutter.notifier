
import 'package:draftmode_notifier/flutter/notification.dart';

/// Provides payload and action context for a tapped local notification.
class DraftModeNotificationResponse {
  DraftModeNotificationResponse._({
    required this.payload,
    required this.notificationResponseType,
    this.actionId,
    this.input,
    this.notificationId,
  });

  /// Creates a response wrapper from the plugin callback.
  factory DraftModeNotificationResponse.fromPlugin({
    required String normalizedPayload,
    required NotificationResponse response,
  }) {
    return DraftModeNotificationResponse._(
      payload: normalizedPayload,
      notificationResponseType:
          _mapResponseType(response.notificationResponseType),
      actionId: response.actionId,
      input: response.input,
      notificationId: response.id,
    );
  }

  /// Normalized payload string DraftModeNotifier uses for routing.
  final String payload;

  /// Translated response type describing how the notification was engaged.
  final DraftModeNotificationResponseType notificationResponseType;

  /// Native identifier for the action button, when present.
  final String? actionId;

  /// Freeform input text returned by text input actions.
  final String? input;

  /// Notification id provided when the alert was shown, if included.
  final int? notificationId;
}

/// Normalized set of response types surfaced by [DraftModeNotifier].
enum DraftModeNotificationResponseType {
  selectedNotification,
  selectedNotificationAction,
}

DraftModeNotificationResponseType _mapResponseType(
    NotificationResponseType type) {
  switch (type) {
    case NotificationResponseType.selectedNotification:
      return DraftModeNotificationResponseType.selectedNotification;
    case NotificationResponseType.selectedNotificationAction:
      return DraftModeNotificationResponseType.selectedNotificationAction;
  }
}
