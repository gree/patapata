// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_riverpod/patapata_riverpod.dart';

class Environment {}

App createApp([void Function(WidgetRef ref)? callback, Plugin? plugin]) {
  return App(
    environment: Environment(),
    createAppWidget: (context, app) => StandardMaterialApp(
      onGenerateTitle: (context) => l(context, 'title'),
      pages: [
        StandardPageFactory<TesterPage, TesterPageData>(
          create: (data) => TesterPage(),
          pageDataWhenNull: () => TesterPageData(callback),
        ),
      ],
    ),
    plugins: [
      RiverpodPlugin(),
      if (plugin != null) plugin,
    ],
  );
}

Future<void> doRefTest(
  WidgetTester tester, {
  void Function(WidgetRef ref)? buildCallback,
  FutureOr<void> Function(WidgetTester tester, App app)? testCallback,
  Plugin? plugin,
}) async {
  final tApp = createApp(buildCallback, plugin);

  await tApp.run();

  await tApp.runProcess(() async {
    // Always pumpAndSettle to let Patapata finish initializing.
    await tester.pumpAndSettle();

    if (testCallback != null) {
      await testCallback(tester, tApp);
    }
  });

  tApp.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testSetMockMethodCallHandler = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger.setMockMethodCallHandler;
  testSetMockStreamHandler = (channel, handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      channel,
      _MockStreamHandler(handler),
    );
  };

  testWidgets('App can be accessed', (tester) async {
    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.read(appProvider), getApp());
      },
    );
  });

  testWidgets('User can be accessed', (tester) async {
    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.read(userProvider), getApp().user);
      },
    );
  });

  testWidgets('User detects changes', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    String? tId;

    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.watch(userProvider).id, tId);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tId = 'tt2';
        await app.user.changeId('tt2');
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('RemoteConfig can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    String tValue = 'value1';
    final tConfig = MockRemoteConfig({
      'string': tValue,
      'int': 1,
      'double': 1.0,
      'bool': true,
    });

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(remoteConfigProvider);
        expect(tRef, getApp().remoteConfig);
        expect(tRef.getString('string'), tConfig.getString('string'));
        expect(tRef.getString('string'), tValue);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tValue = 'value2';
        await tConfig.setString('string', tValue);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('remoteConfigString can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockRemoteConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(remoteConfigStringProvider('string'));
        expect(tRef, tMap['string']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setString('string', tMap['string'] as String);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('remoteConfigInt can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockRemoteConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(remoteConfigIntProvider('int'));
        expect(tRef, tMap['int']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setInt('int', tMap['int'] as int);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('remoteConfigDouble can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockRemoteConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(remoteConfigDoubleProvider('double'));
        expect(tRef, tMap['double']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setDouble('double', tMap['double'] as double);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('remoteConfigBool can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockRemoteConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(remoteConfigBoolProvider('bool'));
        expect(tRef, tMap['bool']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setBool('bool', tMap['bool'] as bool);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('LocalConfig can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockLocalConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createLocalConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(localConfigProvider);
        expect(tRef, getApp().localConfig);

        expect(tRef.getString('string'), tConfig.getString('string'));
        expect(tRef.getString('string'), tMap['string']);

        expect(tRef.getInt('int'), tConfig.getInt('int'));
        expect(tRef.getInt('int'), tMap['int']);

        expect(tRef.getDouble('double'), tConfig.getDouble('double'));
        expect(tRef.getDouble('double'), tMap['double']);

        expect(tRef.getBool('bool'), tConfig.getBool('bool'));
        expect(tRef.getBool('bool'), tMap['bool']);

        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setMany(tMap);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('localConfigString can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockLocalConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createLocalConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(localConfigStringProvider('string'));
        expect(tRef, tMap['string']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setString('string', tMap['string'] as String);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('localConfigInt can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockLocalConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createLocalConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(localConfigIntProvider('int'));
        expect(tRef, tMap['int']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setInt('int', tMap['int'] as int);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('localConfigDouble can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockLocalConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createLocalConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(localConfigDoubleProvider('double'));
        expect(tRef, tMap['double']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setDouble('double', tMap['double'] as double);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('localConfigBool can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    var tMap = {
      'string': 'value1',
      'int': 1,
      'double': 1.0,
      'bool': true,
    };
    final tConfig = MockLocalConfig(tMap);

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createLocalConfig: () => tConfig,
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(localConfigBoolProvider('bool'));
        expect(tRef, tMap['bool']);
        tShouldCall();
      },
      testCallback: (tester, app) async {
        tMap = {
          'string': 'value2',
          'int': 2,
          'double': 2.0,
          'bool': false,
        };
        await tConfig.setBool('bool', tMap['bool'] as bool);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('remoteMessaging can be accessed and watched', (tester) async {
    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteMessaging: () => MockRemoteMessaging(
          messages: () async* {
            yield const RemoteMessage(
              notification: RemoteMessageNotification(
                title: 'title',
                body: 'body',
              ),
            );
          },
          tokenStream: () => Stream.value('token2'),
          getToken: () => Future.value('token1'),
        ),
      ),
      buildCallback: (ref) {
        final tRef = ref.watch(remoteMessagingProvider);
        expect(tRef, getApp().remoteMessaging);
      },
    );
  });

  testWidgets('remoteMessagingMessages can be accessed and watched',
      (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    final tStreamController = StreamController<RemoteMessage>();
    RemoteMessage? tMessage;

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteMessaging: () => MockRemoteMessaging(
          messages: () => tStreamController.stream,
        ),
      ),
      buildCallback: (ref) {
        tShouldCall();
        final tRef = ref.watch(remoteMessagingMessagesProvider);

        if (tMessage == null) {
          expect(tRef.hasValue, isFalse);
          expect(tRef.isLoading, isTrue);
        } else {
          expect(tRef.hasValue, isTrue);
          expect(tRef.requireValue.notification!.title, equals('title'));
        }
      },
      testCallback: (tester, app) async {
        tMessage = const RemoteMessage(
          notification: RemoteMessageNotification(
            title: 'title',
            body: 'body',
          ),
        );
        tStreamController.add(tMessage!);
        await tester.pumpAndSettle();
      },
    );

    tStreamController.close();
  });

  testWidgets('remoteMessagingTokens can be accessed and watched',
      (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2, max: 3);
    final tStreamController = StreamController<String?>();
    String? tToken = 'token1';

    await doRefTest(
      tester,
      plugin: Plugin.inline(
        createRemoteMessaging: () => MockRemoteMessaging(
          tokenStream: () => tStreamController.stream,
          getToken: () => Future.value('token1'),
        ),
      ),
      buildCallback: (ref) {
        tShouldCall();
        final tRef = ref.watch(remoteMessagingTokensProvider);

        if (tRef.isLoading) {
          return;
        }

        expect(tRef.hasValue, isTrue);
        expect(tRef.requireValue, equals(tToken));
      },
      testCallback: (tester, app) async {
        tToken = 'token2';
        tStreamController.add(tToken);
        await tester.pumpAndSettle();
      },
    );

    tStreamController.close();
  });

  testWidgets('analytics can be accessed', (tester) async {
    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.read(analyticsProvider), getApp().analytics);
      },
    );
  });

  testWidgets('globalAnalyticsContext can be accessed', (tester) async {
    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.read(globalAnalyticsContextProvider),
            getApp().analytics.globalContext);
      },
    );
  });

  testWidgets('networkInformation can be accessed and watched', (tester) async {
    final tShouldCall = expectAsync0(() => null, count: 2);
    NetworkConnectivity tConnectivity = NetworkConnectivity.none;

    await doRefTest(
      tester,
      buildCallback: (ref) {
        tShouldCall();
        final tRef = ref.watch(networkInformationProvider);

        expect(tRef.connectivity, equals(tConnectivity));
      },
      testCallback: (tester, app) async {
        tConnectivity = NetworkConnectivity.wifi;
        await app.network.testChangeConnectivity(tConnectivity);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('packageInfo can be accessed', (tester) async {
    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.read(packageInfoProvider), getApp().package);
      },
    );
  });

  testWidgets('deviceInfo can be accessed', (tester) async {
    await doRefTest(
      tester,
      buildCallback: (ref) {
        expect(ref.read(deviceInfoProvider), getApp().device);
      },
    );
  });
}

class TesterPageData {
  final void Function(WidgetRef ref)? callback;

  TesterPageData(this.callback);
}

class TesterPage extends StandardPage<TesterPageData> {
  @override
  Widget buildPage(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      if (pageData.callback != null) {
        pageData.callback!(ref);
      }

      return const SizedBox.expand();
    });
  }
}

class _MockStreamHandler extends MockStreamHandler {
  _MockStreamHandler(this.handler);

  final TestMockStreamHandler? handler;

  @override
  void onCancel(Object? arguments) {
    handler?.onCancel(arguments);
  }

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    handler?.onListen(arguments, _MockStreamHandlerEventSink(other: events));
  }
}

class _MockStreamHandlerEventSink extends TestMockStreamHandlerEventSink {
  final MockStreamHandlerEventSink other;

  _MockStreamHandlerEventSink({
    required this.other,
  });

  @override
  void endOfStream() {
    other.endOfStream();
  }

  @override
  void error({required String code, String? message, Object? details}) {
    other.error(code: code, message: message, details: details);
  }

  @override
  void success(Object? event) {
    other.success(event);
  }
}
