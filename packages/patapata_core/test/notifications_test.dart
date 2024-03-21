// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/src/exception.dart';

import 'utils/patapata_core_test_utils.dart';
import 'pages/notification_page.dart';

const NotificationResponse notificationResponse = NotificationResponse(
  notificationResponseType: NotificationResponseType.selectedNotification,
  payload: "notification/",
);

class _EmptyEnvironment {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('check init success', () async {
    final NotificationsPlugin tNotificationsPlugin = NotificationsPlugin();

    final App tApp = createApp(environment: _EmptyEnvironment());
    final bool tResult = await tNotificationsPlugin.init(tApp);

    expect(
      tResult,
      isTrue,
    );
  });

  test('check init success using environment', () async {
    final NotificationsPlugin tNotificationsPlugin = NotificationsPlugin();

    final App tApp = createApp();

    final bool tResult = await tNotificationsPlugin.init(tApp);

    expect(
      tResult,
      isTrue,
    );
  });

  test(
    'check notifications',
    () async {
      final NotificationsPlugin tNotificationsPlugin = NotificationsPlugin();

      expectLater(
        tNotificationsPlugin.notifications.asyncMap((event) => event.payload),
        emitsInOrder(
          [
            "notification/",
          ],
        ),
      );

      final App tApp = createApp();

      await tNotificationsPlugin.init(tApp);

      tNotificationsPlugin.enableStandardAppIntegration();

      tNotificationsPlugin.mockRecieveNotificationResponse(
        notificationResponse,
      );
    },
  );

  test(
    'check locationFromPayload',
    () async {
      final NotificationsPlugin tNotificationsPlugin = NotificationsPlugin();
      final App tApp = createApp();
      await tNotificationsPlugin.init(tApp);

      expect(
        tNotificationsPlugin.uriFromPayload(
          null,
        ),
        isNull,
      );

      expect(
        tNotificationsPlugin.uriFromPayload(
          "notification/",
        ),
        Uri.parse("notification/"),
      );

      expect(
        tNotificationsPlugin.uriFromPayload(
          '{"location": "notification/"}',
        ),
        Uri.parse("notification/"),
      );
    },
  );

  testWidgets(
    'check getInitialRouteData',
    (WidgetTester tester) async {
      notificationAppLaunchDetailsMap = {
        "notificationLaunchedApp": true,
        'notificationResponse': {
          'notificationResponseType': 0,
          'payload': "notification/",
        }
      };

      final App tApp = createApp();
      tApp.run();

      await tApp.runProcess(() async {
        final tNotificationsPlugin = tApp.getPlugin<NotificationsPlugin>();

        tApp.getPlugin<NotificationsPlugin>()?.enableStandardAppIntegration();

        await tester.pumpAndSettle();

        final tStandardRouteData =
            await tNotificationsPlugin?.getInitialRouteData();

        expect(
          tStandardRouteData?.factory?.pageType,
          NotificationPage,
        );
      });
    },
  );

  test('check dispose', () async {
    final NotificationsPlugin tNotificationsPlugin = NotificationsPlugin();

    tNotificationsPlugin.dispose();

    expect(
      tNotificationsPlugin.disposed,
      isTrue,
    );
  });

  test('NotificationsInitializationException test', () async {
    // ignore: prefer_const_constructors
    final tException = NotificationsInitializationException();

    expect(
      tException.code,
      equals(PatapataCoreExceptionCode.PPE501.name),
    );
  });
}
