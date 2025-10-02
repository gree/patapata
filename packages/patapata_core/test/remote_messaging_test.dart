// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteMessageNotification class.', () {
    const tTitle = 'title';
    const tBody = 'body';

    test('Instance (no arguments).', () async {
      // Purposely not using `const` because the current version of flutter is flagging const constructors as not being executed in coverage tests.
      // ignore: prefer_const_constructors
      final tRemoteMessageNotification = RemoteMessageNotification();

      expect(tRemoteMessageNotification, isA<RemoteMessageNotification>());
      expect(tRemoteMessageNotification.title, isNull);
      expect(tRemoteMessageNotification.body, isNull);
    });

    test('Instance (with arguments).', () async {
      const tRemoteMessageNotification = RemoteMessageNotification(
        title: tTitle,
        body: tBody,
      );

      expect(tRemoteMessageNotification, isA<RemoteMessageNotification>());
      expect(tRemoteMessageNotification.title, tTitle);
      expect(tRemoteMessageNotification.body, tBody);
      expect(
        tRemoteMessageNotification.toString(),
        'RemoteMessageNotification:{title:$tTitle, body:$tBody}',
      );
    });
  });

  group('RemoteMessage class.', () {
    const tMessageId = 'messageId';
    const tChannel = 'channel';
    const tData = {
      'key': 'value',
    };
    const tRemoteMessageNotification = RemoteMessageNotification();

    test('Instance (no arguments).', () async {
      // Purposely not using `const` because the current version of flutter is flagging const constructors as not being executed in coverage tests.
      // ignore: prefer_const_constructors
      final tRemoteMessage = RemoteMessage();

      expect(tRemoteMessage, isA<RemoteMessage>());
      expect(tRemoteMessage.messageId, isNull);
      expect(
        tRemoteMessage.channel,
        RemoteMessage.kRemoteMessageDefaultChannel,
      );
      expect(tRemoteMessage.data, isNull);
      expect(tRemoteMessage.notification, isNull);
    });

    test('Instance (with arguments).', () async {
      const tRemoteMessage = RemoteMessage(
        messageId: tMessageId,
        channel: tChannel,
        data: tData,
        notification: tRemoteMessageNotification,
      );

      expect(tRemoteMessage, isA<RemoteMessage>());
      expect(tRemoteMessage.messageId, tMessageId);
      expect(tRemoteMessage.channel, tChannel);
      expect(tRemoteMessage.data, tData);
      expect(tRemoteMessage.notification, tRemoteMessageNotification);
      expect(
        tRemoteMessage.toString(),
        'RemoteMessage:{messageId:$tMessageId, channel:$tChannel, data:$tData}',
      );
    });
  });

  group('ProxyRemoteMessaging class.', () {
    test('Getter app.', () async {
      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);

      expect(tProxyRemoteMessaging.app, tApp);
    });

    test('Function getInitialMessage (no arguments).', () async {
      final tMockRemoteMessaging = MockRemoteMessaging();

      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      final tInitialMessage = await tProxyRemoteMessaging.getInitialMessage();

      expect(tInitialMessage, isNull);
    });

    test('Function getInitialMessage (with arguments).', () async {
      const tRemoteMessage = RemoteMessage();

      final tMockRemoteMessaging = MockRemoteMessaging(
        getInitialMessage: () async => tRemoteMessage,
      );

      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      final tInitialMessage = await tProxyRemoteMessaging.getInitialMessage();

      expect(tInitialMessage, tRemoteMessage);
    });

    test('Function getToken no RemoteConfigs.', () async {
      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tResult = await tProxyRemoteMessaging.getToken();

      expect(tResult, isNull);
    });

    test('Function getToken with RemoteConfig(no token).', () async {
      final tMockRemoteMessaging = MockRemoteMessaging();

      final tProxyRemoteMessaging = ProxyRemoteMessaging();
      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      final tResult = await tProxyRemoteMessaging.getToken();

      expect(tResult, null);
    });

    test('Function getToken with RemoteConfig(with token).', () async {
      const tToken = 'token';

      final tMockRemoteMessaging = MockRemoteMessaging(
        getToken: () async => tToken,
      );

      final tProxyRemoteMessaging = ProxyRemoteMessaging();
      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      final tResult = await tProxyRemoteMessaging.getToken();

      expect(tResult, tToken);
    });

    test("Function getToken with RemoteConfig's.", () async {
      const tToken1 = 'token';
      const tToken2 = 'token';

      final tMockRemoteMessaging1 = MockRemoteMessaging(
        getToken: () async => tToken1,
      );
      final tMockRemoteMessaging2 = MockRemoteMessaging(
        getToken: () async => tToken2,
      );

      final tProxyRemoteMessaging = ProxyRemoteMessaging();
      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging1);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging2);

      final tResult = await tProxyRemoteMessaging.getToken();

      expect(tResult, tToken1);
    });

    test('Stream messageStream.', () async {
      final tMockMessagesController = StreamController<RemoteMessage>();

      final tMockRemoteMessaging = MockRemoteMessaging(
        messages: () => tMockMessagesController.stream,
      );

      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      const tRemoteMessage = RemoteMessage();

      final tMessageValues = [
        tRemoteMessage,
      ];

      final tProxyMessageFuture = expectLater(
        tProxyRemoteMessaging.messages,
        emitsInOrder(tMessageValues),
      );

      tMockMessagesController.add(tRemoteMessage);

      await tProxyMessageFuture;
    });

    test('Stream messageStream.', () async {
      final tMockMessagesController = StreamController<RemoteMessage>();

      final tMockRemoteMessaging = MockRemoteMessaging(
        messages: () => tMockMessagesController.stream,
      );

      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      const tRemoteMessage = RemoteMessage();

      final tMessageValues = [
        tRemoteMessage,
      ];

      final tProxyMessageFuture = expectLater(
        tProxyRemoteMessaging.messages,
        emitsInOrder(tMessageValues),
      );

      tMockMessagesController.add(tRemoteMessage);

      await tProxyMessageFuture;
    });

    test('Test for tokenStream.', () async {
      final tMockTokensController = StreamController<String>();

      final tMockRemoteMessaging = MockRemoteMessaging(
        tokenStream: () => tMockTokensController.stream,
      );

      final tProxyRemoteMessaging = ProxyRemoteMessaging();

      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      const tToken = 'token';

      final tTokenValues = [
        tToken,
      ];

      final tProxyTokenFuture = expectLater(
        tProxyRemoteMessaging.tokens,
        emitsInOrder(tTokenValues),
      );

      tMockTokensController.add(tToken);

      await tProxyTokenFuture;
    });

    test('Function listenChannel.', () async {
      final tMockRemoteMessaging = MockRemoteMessaging();

      final tProxyRemoteMessaging = ProxyRemoteMessaging();
      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      const tChannel = 'channel';

      expect(await tProxyRemoteMessaging.listenChannel(tChannel), true);
      expect(await tProxyRemoteMessaging.listenChannel(tChannel), false);
    });

    test('Function ignoreChannel.', () async {
      final tMockRemoteMessaging = MockRemoteMessaging();

      final tProxyRemoteMessaging = ProxyRemoteMessaging();
      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      const tChannel = 'channel';
      await tProxyRemoteMessaging.listenChannel(tChannel);

      expect(await tProxyRemoteMessaging.ignoreChannel(tChannel), true);
      expect(await tProxyRemoteMessaging.ignoreChannel(tChannel), false);
    });

    test('Function  dispose.', () async {
      final tMockRemoteMessaging = MockRemoteMessaging();

      final tProxyRemoteMessaging = ProxyRemoteMessaging();
      final tApp = createApp();
      await tProxyRemoteMessaging.init(tApp);
      await tProxyRemoteMessaging.addRemoteMessaging(tMockRemoteMessaging);

      tProxyRemoteMessaging.dispose();

      // ignore: invalid_use_of_protected_member
      expect(tMockRemoteMessaging.hasListeners, false);
    });
  });
}
