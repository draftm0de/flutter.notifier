import 'package:draftmode_notifier/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDraftModeNotifier extends Mock implements DraftModeNotifier {}

class _MockDraftModeNotifierForegroundDialog extends Mock
    implements DraftModeNotifierForegroundDialog {}

Future<void> _noopHandler(DraftModeNotificationResponse _) async {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDraftModeNotifier notifier;
  late _MockDraftModeNotifierForegroundDialog dialogPresenter;
  setUp(() {
    DraftModeNotifier.debugResetInstance(null);
    DraftModeGeofenceNotification.debugResetInstance();
    notifier = _MockDraftModeNotifier();
    dialogPresenter = _MockDraftModeNotifierForegroundDialog();
    when(() => notifier.init()).thenAnswer((_) async {});
  });

  test('exposes singleton instance', () {
    final geofence = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
      dialogPresenter: dialogPresenter,
    );
    expect(DraftModeGeofenceNotification.instance, same(geofence));
  });

  test('instance getter throws when init not yet called', () {
    expect(
      () => DraftModeGeofenceNotification.instance,
      throwsStateError,
    );
  });

  test('init wires enter/exit handlers once', () async {
    final geofence = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
      dialogPresenter: dialogPresenter,
    );
    await geofence.init(onEnter: _noopHandler, onExit: _noopHandler);
    await geofence.init(onEnter: _noopHandler, onExit: _noopHandler);

    verify(() => notifier.init()).called(1);
    verify(() => notifier.registerNotificationConsumer(
          payload: DraftModeGeofenceNotificationMode.enter.name,
          handler: _noopHandler,
          triggerFilter: null,
        )).called(1);
    verify(() => notifier.registerNotificationConsumer(
          payload: DraftModeGeofenceNotificationMode.exit.name,
          handler: _noopHandler,
          triggerFilter: null,
        )).called(1);
  });

  test('init ignores calls without handlers but accepts later ones', () async {
    final geofence = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
      dialogPresenter: dialogPresenter,
    );
    await geofence.init();
    verifyNever(() => notifier.init());

    await geofence.init(onEnter: _noopHandler);
    verify(() => notifier.init()).called(1);
  });

  test('showDialog delegates to dialog presenter', () async {
    final geofence = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
      dialogPresenter: dialogPresenter,
    );
    when(() => dialogPresenter.showSimpleDialog(
          title: any(named: 'title'),
          content: any(named: 'content'),
        )).thenAnswer((_) async {});

    await geofence.init(onEnter: _noopHandler);
    await geofence.showDialog(title: 't', content: 'c');

    verify(() => dialogPresenter.showSimpleDialog(title: 't', content: 'c'))
        .called(1);
  });

  test('showDialog throws before initialization when no presenter exists', () {
    final uninitialized = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
    );

    expect(
      () => uninitialized.showDialog(title: 't', content: 'c'),
      throwsStateError,
    );
  });

  test('constructor falls back to singleton notifier when omitted', () async {
    DraftModeNotifier.debugResetInstance(notifier);
    final geofence = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      dialogPresenter: dialogPresenter,
    );

    await geofence.init(onEnter: _noopHandler);
    verify(() => notifier.init()).called(1);
  });

  test('init builds a dialog presenter when none provided', () async {
    final geofence = DraftModeGeofenceNotification(
      navigatorKey: GlobalKey<NavigatorState>(),
      notifier: notifier,
    );

    await geofence.init(onEnter: _noopHandler);
  });
}
