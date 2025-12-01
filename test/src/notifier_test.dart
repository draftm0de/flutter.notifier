import 'package:draftmode_notifier/notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class _MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class _MockMacFlutterLocalNotificationsPlugin extends Mock
    implements MacOSFlutterLocalNotificationsPlugin {}

class _FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

class _FakeAndroidNotificationChannel extends Fake
    implements AndroidNotificationChannel {}

void _registerConfirmConsumer(
  DraftModeNotifier notifier,
  void Function() callback,
) {
  notifier.registerConsumer(
    payload: DraftModeNotifier.confirmPayload,
    triggerFilter: DraftModeNotifier.isConfirmResponse,
    handler: (_) async => callback(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeInitializationSettings());
    registerFallbackValue(_FakeNotificationDetails());
    registerFallbackValue(_FakeAndroidNotificationChannel());
  });

  late DraftModeNotifier notifier;
  late _MockFlutterLocalNotificationsPlugin plugin;
  late _MockAndroidFlutterLocalNotificationsPlugin androidPlugin;
  late _MockIOSFlutterLocalNotificationsPlugin iosPlugin;
  late _MockMacFlutterLocalNotificationsPlugin macPlugin;
  DidReceiveNotificationResponseCallback? onForegroundResponse;
  InitializationSettings? initializationSettings;

  setUp(() {
    plugin = _MockFlutterLocalNotificationsPlugin();
    androidPlugin = _MockAndroidFlutterLocalNotificationsPlugin();
    iosPlugin = _MockIOSFlutterLocalNotificationsPlugin();
    macPlugin = _MockMacFlutterLocalNotificationsPlugin();
    notifier = DraftModeNotifier.test(plugin);
    initializationSettings = null;

    when(() => plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()).thenReturn(androidPlugin);
    when(() => plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()).thenReturn(iosPlugin);
    when(() => plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()).thenReturn(macPlugin);

    when(() => androidPlugin.createNotificationChannel(any()))
        .thenAnswer((_) async {});
    when(() =>
            iosPlugin.requestPermissions(alert: true, badge: true, sound: true))
        .thenAnswer((_) async => true);
    when(() =>
            macPlugin.requestPermissions(alert: true, badge: true, sound: true))
        .thenAnswer((_) async => true);

    when(() => plugin.initialize(
          any(),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        )).thenAnswer((invocation) async {
      initializationSettings =
          invocation.positionalArguments.first as InitializationSettings;
      onForegroundResponse =
          invocation.namedArguments[#onDidReceiveNotificationResponse]
              as DidReceiveNotificationResponseCallback?;
      return true;
    });

    when(() => plugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    when(() => plugin.cancel(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    DraftModeNotifier.debugResetInstance(null);
  });

  test('instance memoizes singleton', () {
    final first = DraftModeNotifier.instance;
    final second = DraftModeNotifier.instance;
    expect(identical(first, second), isTrue);
  });

  test('init configures platform features exactly once', () async {
    await notifier.init();
    await notifier.init();

    verify(() => plugin.initialize(
          any(),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        )).called(1);
    verify(() =>
            iosPlugin.requestPermissions(alert: true, badge: true, sound: true))
        .called(1);
    verify(() =>
            macPlugin.requestPermissions(alert: true, badge: true, sound: true))
        .called(1);
    verify(() => androidPlugin.createNotificationChannel(any())).called(1);
  });

  test('pushNotification normalizes id and forwards subtitle', () async {
    await notifier.pushNotification(
      id: 0,
      title: 'title',
      body: 'body',
      subtitle: 'subtitle',
    );

    final captured = verify(() => plugin.show(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
          payload: captureAny(named: 'payload'),
        )).captured;
    expect(captured[0], equals(1));
    final details = captured[3] as NotificationDetails;
    expect(details.android?.subText, 'subtitle');
    expect(details.iOS?.subtitle, 'subtitle');
    expect(details.android?.actions?.first.title, 'Yes');
    expect(details.android?.actions?.last.title, 'No');
    expect(captured[4], 'confirm');
  });

  test('init applies localized action labels', () async {
    await notifier.init(
      config: const DraftModeNotifierConfig(
        yesActionLabel: 'Oui',
        noActionLabel: 'Non',
      ),
    );

    final categories = initializationSettings?.iOS?.notificationCategories;
    expect(categories, isNotNull);
    final actions = categories!.single.actions;
    expect(actions.first.title, 'Oui');
    expect(actions.last.title, 'Non');
  });

  test('pushNotification reuses localized action labels', () async {
    await notifier.init(
      config: const DraftModeNotifierConfig(
        yesActionLabel: 'Si',
        noActionLabel: 'Nope',
      ),
    );

    await notifier.pushNotification(
      id: 7,
      title: 'title',
      body: 'body',
    );

    final details = verify(() => plugin.show(
          any(),
          any(),
          any(),
          captureAny(),
          payload: any(named: 'payload'),
        )).captured.single as NotificationDetails;
    final actions = details.android?.actions;
    expect(actions, isNotNull);
    expect(actions!.first.title, 'Si');
    expect(actions.last.title, 'Nope');
  });

  test('pushNotification forwards provided payload', () async {
    await notifier.pushNotification(
      id: 2,
      title: 'title',
      body: 'body',
      payload: 'open_path',
    );

    final captured = verify(() => plugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: captureAny(named: 'payload'),
        )).captured;
    expect(captured.single, 'open_path');
  });

  test('pushNotification auto-generates ids when omitted', () async {
    await notifier.pushNotification(
      title: 'title',
      body: 'body',
    );

    final captured = verify(() => plugin.show(
          captureAny(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        )).captured;
    expect(captured.first, greaterThan(0));
  });

  test('cancel normalizes ids', () async {
    await notifier.cancel(0);
    verify(() => plugin.cancel(1)).called(1);
  });

  test('normalizeNotificationId clamps to positive range', () {
    expect(normalizeNotificationId(0), 1);
    expect(normalizeNotificationId(-42) > 0, isTrue);
    expect(
        normalizeNotificationId(0x7fffffff + 5), lessThanOrEqualTo(0x7fffffff));
  });

  test('foreground tap triggers registered handler immediately', () async {
    await notifier.init();
    var called = 0;
    _registerConfirmConsumer(notifier, () {
      called++;
    });

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
    ));

    await Future<void>.delayed(Duration.zero);
    expect(called, 1);
  });

  test('tap before handler registration is replayed once', () async {
    await notifier.init();

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
    ));

    var called = 0;
    _registerConfirmConsumer(notifier, () {
      called++;
    });

    await Future<void>.delayed(Duration.zero);
    expect(called, 1);
  });

  test('multiple buffered taps replay after handler registration', () async {
    await notifier.init();

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: 'dialog',
    ));
    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: 'dialog',
    ));

    var called = 0;
    notifier.registerConsumer(
      payload: 'dialog',
      handler: (_) async {
        called++;
      },
    );

    await Future<void>.delayed(Duration.zero);
    expect(called, 2);
  });

  test('NO action tap is ignored', () async {
    await notifier.init();
    var called = 0;
    _registerConfirmConsumer(notifier, () {
      called++;
    });

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: 'NO',
    ));

    await Future<void>.delayed(Duration.zero);
    expect(called, 0);
  });

  test('custom payload tap dispatches to matching handler', () async {
    await notifier.init();
    var called = 0;
    notifier.registerConsumer(
      payload: 'open_path',
      handler: (_) async {
        called++;
      },
    );

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: 'open_path',
    ));

    await Future<void>.delayed(Duration.zero);
    expect(called, 1);
  });

  test('custom payload tap is buffered until handler is registered', () async {
    await notifier.init();

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: 'dialog',
    ));

    var called = 0;
    notifier.registerConsumer(
      payload: 'dialog',
      handler: (_) async {
        called++;
      },
    );

    await Future<void>.delayed(Duration.zero);
    expect(called, 1);
  });

  test('custom payload filter skips unmatched responses', () async {
    await notifier.init();
    var openCalled = 0;
    notifier.registerConsumer(
      payload: 'command',
      triggerFilter: (resp) => resp.actionId == 'OPEN',
      handler: (_) async {
        openCalled++;
      },
    );

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      payload: 'command',
      actionId: 'DISMISS',
    ));
    onForegroundResponse!(const NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      payload: 'command',
      actionId: 'OPEN',
    ));

    await Future<void>.delayed(Duration.zero);
    expect(openCalled, 1);
  });

  test('registerConsumer replaces the existing handler', () async {
    await notifier.init();
    var firstCalled = 0;
    var secondCalled = 0;
    _registerConfirmConsumer(notifier, () {
      firstCalled++;
    });
    notifier.registerConsumer(
      payload: DraftModeNotifier.confirmPayload,
      triggerFilter: DraftModeNotifier.isConfirmResponse,
      handler: (_) async {
        secondCalled++;
      },
    );

    onForegroundResponse!(const NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
    ));

    await Future<void>.delayed(Duration.zero);
    expect(firstCalled, 0);
    expect(secondCalled, 1);
  });

  test('pending notifications update listenables when tracked and cleared',
      () async {
    final emissions = <int>[];
    void listener() => emissions.add(notifier.pendingNotificationCount);
    notifier.pendingNotificationCountListenable.addListener(listener);

    await notifier.pushNotification(
      id: 5,
      title: 'Reminder',
      subtitle: 'Soon',
      body: 'Body',
      payload: 'payload',
    );

    expect(notifier.pendingNotificationCount, 1);
    final pending = notifier.pendingNotifications.single;
    expect(pending.title, 'Reminder');
    expect(pending.subtitle, 'Soon');
    expect(pending.payload, 'payload');

    await notifier.cancel(5);

    expect(notifier.pendingNotificationCount, 0);
    notifier.pendingNotificationCountListenable.removeListener(listener);
    expect(emissions, [1, 0]);
  });

  test('triggerPendingNotification dispatches handler and removes entry',
      () async {
    await notifier.init();
    var called = 0;
    notifier.registerConsumer(
      payload: 'payload',
      handler: (_) async {
        called++;
      },
    );

    await notifier.pushNotification(
      id: 9,
      title: 'Reminder',
      body: 'Body',
      payload: 'payload',
    );

    expect(notifier.pendingNotificationCount, 1);

    await notifier.triggerPendingNotification(9);

    expect(called, 1);
    expect(notifier.pendingNotificationCount, 0);
  });

  test('notificationTapBackground delegates to singleton instance', () async {
    DraftModeNotifier.debugResetInstance(notifier);
    await notifier.init();
    var called = 0;
    _registerConfirmConsumer(notifier, () {
      called++;
    });

    await notificationTapBackground(const NotificationResponse(
      notificationResponseType:
          NotificationResponseType.selectedNotificationAction,
      actionId: 'YES',
    ));

    expect(called, 1);
  });
}
