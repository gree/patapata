// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import 'utils/patapata_core_test_utils.dart';

class _EnvironmentBase {}

class _Environment extends _EnvironmentBase {}

class ClassA {}

class TestPluginBase extends Plugin {}

class TestPluginA extends TestPluginBase {}

class TestPluginB extends TestPluginBase {
  @override
  final bool requireRemoteConfig = true;
}

class TestPluginC extends TestPluginBase {}

class MyCustomUser extends User {
  MyCustomUser(App app) : super(app: app);
}

class FetchFailsRemoteConfig extends MockRemoteConfig {
  FetchFailsRemoteConfig(super.store);

  @override
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  }) async {
    throw Exception();
  }
}

class _TestException extends PatapataException {
  _TestException(this._level);

  final Level? _level;

  @override
  Level? get logLevel => _level;

  @override
  String get defaultPrefix => 'TST';

  @override
  String get internalCode => '000';

  @override
  String get namespace => 'test';
}

void main() {
  late App<_Environment> tApp;
  final tWidgetKey = GlobalKey();

  group('App initialization test.', () {
    setUp(() {
      testInitialize();

      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
      );
    });

    testWidgets('App run test.', (tester) async {
      final tAppStageChangeStream =
          App.appStageChangeStream.asyncMap((event) => event.stage);
      expectLater(
        tAppStageChangeStream,
        emitsInOrder([
          AppStage.setup,
          AppStage.bootstrap,
          AppStage.initializingPlugins,
          AppStage.setupRemoteConfig,
          AppStage.initializingPluginsWithRemoteConfig,
          AppStage.running,
          AppStage.disposed,
        ]),
      );

      expect(tApp.stage, equals(AppStage.setup));

      final tResult = await tApp.run();

      expect(tResult, isTrue);
      expect(tApp.stage, equals(AppStage.running));

      tApp.dispose();

      expect(tApp.stage, equals(AppStage.disposed));
    });

    testWidgets('App runProcess and appWidget test.', (tester) async {
      await tApp.run();

      final tResult = await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.stage, equals(AppStage.running));
        expect(tApp.environment, isA<_Environment>());
        expect(tApp.environmentAs<_EnvironmentBase>(), isA<_EnvironmentBase>());
        expect(tApp.environmentAs<String>(), isNull);
        expect(find.byKey(tWidgetKey), findsOneWidget);

        return true;
      });

      expect(tResult, isTrue);
      expect(tApp.stage, equals(AppStage.running));

      tApp.dispose();
    });

    testWidgets('App run bootstrapCallback test.', (tester) async {
      late final AppStage tBootstrapCallbackAppStage;
      await tApp.run(() {
        tBootstrapCallbackAppStage = tApp.stage;
      });

      expect(tBootstrapCallbackAppStage, equals(AppStage.bootstrap));
      expect(tApp.stage, equals(AppStage.running));

      tApp.dispose();
    });

    testWidgets('Each required plugins and models is correctly initialized.',
        (tester) async {
      await tApp.run();

      // plugins
      expect(tApp.network, isA<NetworkPlugin>());
      expect(tApp.package, isA<PackageInfoPlugin>());
      expect(tApp.device, isA<DeviceInfoPlugin>());
      expect(tApp.getPlugin<I18nPlugin>(), isA<I18nPlugin>());
      expect(tApp.getPlugin<NativeLocalConfigPlugin>(),
          isA<NativeLocalConfigPlugin>());
      expect(tApp.getPlugin<NotificationsPlugin>(), isA<NotificationsPlugin>());
      expect(tApp.getPlugin<StandardAppPlugin>(), isA<StandardAppPlugin>());

      // models
      expect(tApp.log, isA<Log>());
      expect(tApp.user, isA<User>());
      expect(tApp.analytics, isA<Analytics>());
      expect(tApp.permissions, isA<Permissions>());
      expect(tApp.remoteConfig, isA<RemoteConfig>());
      expect(tApp.localConfig, isA<LocalConfig>());
      expect(tApp.remoteMessaging, isA<RemoteMessaging>());
      expect(tApp.navigatorObservers.length, equals(1));
      expect(tApp.navigatorObservers.first, isA<AnalyticsNavigatorObserver>());
      expect(tApp.startupSequence, isNull);

      tApp.dispose();
    });

    testWidgets('Each Provider can be obtained with getProvider.',
        (tester) async {
      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.getProvider<App>(), isA<App>());
        expect(tApp.getProvider<App<_Environment>>(), isA<App<_Environment>>());
        expect(tApp.getProvider<_Environment>(), isA<_Environment>());
        expect(tApp.getProvider<User>(), isA<User>());
        expect(tApp.getProvider<RemoteConfig>(), isA<RemoteConfig>());
        expect(tApp.getProvider<LocalConfig>(), isA<LocalConfig>());
        expect(tApp.getProvider<RemoteMessaging>(), isA<RemoteMessaging>());
        expect(tApp.getProvider<Analytics>(), isA<Analytics>());
        expect(tApp.getProvider<AnalyticsContext>(), isA<AnalyticsContext>());
        expect(
            tApp.getProvider<NetworkInformation>(), isA<NetworkInformation>());
        expect(tApp.getProvider<PackageInfoPlugin>(), isA<PackageInfoPlugin>());
        expect(tApp.getProvider<DeviceInfoPlugin>(), isA<DeviceInfoPlugin>());

        // Can also be obtained from [context.read].
        final tContext = tWidgetKey.currentContext!;
        expect(tContext.read<App>(), isA<App>());
        expect(tContext.read<App<_Environment>>(), isA<App<_Environment>>());
        expect(tContext.read<_Environment>(), isA<_Environment>());
        expect(tContext.read<User>(), isA<User>());
        expect(tContext.read<RemoteConfig>(), isA<RemoteConfig>());
        expect(tContext.read<LocalConfig>(), isA<LocalConfig>());
        expect(tContext.read<RemoteMessaging>(), isA<RemoteMessaging>());
        expect(tContext.read<Analytics>(), isA<Analytics>());
        expect(tContext.read<AnalyticsContext>(), isA<AnalyticsContext>());
        expect(tContext.read<NetworkInformation>(), isA<NetworkInformation>());
        expect(tContext.read<PackageInfoPlugin>(), isA<PackageInfoPlugin>());
        expect(tContext.read<DeviceInfoPlugin>(), isA<DeviceInfoPlugin>());
      });

      tApp.dispose();
    });

    testWidgets('getApp test.', (tester) async {
      await tApp.run();

      // Cannot be obtained outside the Zone of App.
      expect(getApp, throwsA(isA<TypeError>()));

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(getApp(), equals(tApp));
      });

      tApp.dispose();
    });

    testWidgets('addPlugin and removePlugin test.', (tester) async {
      final tPluginA = TestPluginA();
      final tPluginB = TestPluginB();
      final tPluginC = TestPluginC();

      await tApp.addPlugin(tPluginC);

      expect(tApp.hasPlugin(TestPluginC), isTrue);
      expect(tApp.getPlugin<TestPluginC>(), equals(tPluginC));
      expect(tApp.getPluginsOfType<TestPluginBase>(), equals([tPluginC]));

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.hasPlugin(TestPluginC), isTrue);
        expect(tApp.getPlugin<TestPluginC>(), equals(tPluginC));
        expect(tApp.getPluginsOfType<TestPluginBase>(), equals([tPluginC]));

        await tApp.addPlugin(tPluginA);
        expect(tApp.hasPlugin(TestPluginA), isTrue);
        expect(tApp.getPlugin<TestPluginA>(), equals(tPluginA));
        expect(
          tApp.getPluginsOfType<TestPluginBase>(),
          equals([tPluginC, tPluginA]),
        );

        await tApp.addPlugin(tPluginB);
        expect(tApp.hasPlugin(TestPluginB), isTrue);
        expect(tApp.getPlugin<TestPluginB>(), equals(tPluginB));
        expect(
          tApp.getPluginsOfType<TestPluginBase>(),
          equals([tPluginC, tPluginA, tPluginB]),
        );

        await tApp.removePlugin(tPluginA);
        expect(tApp.hasPlugin(TestPluginA), isFalse);
        expect(tApp.getPlugin<TestPluginA>(), isNull);
        expect(
          tApp.getPluginsOfType<TestPluginBase>(),
          equals([tPluginC, tPluginB]),
        );

        await tApp.removePlugin(tPluginB);
        expect(tApp.hasPlugin(TestPluginB), isFalse);
        expect(tApp.getPlugin<TestPluginB>(), isNull);
        expect(tApp.getPluginsOfType<TestPluginBase>(), equals([tPluginC]));

        await tApp.removePlugin(tPluginC);
        expect(tApp.hasPlugin(TestPluginC), isFalse);
        expect(tApp.getPlugin<TestPluginC>(), isNull);
        expect(tApp.getPluginsOfType<TestPluginBase>(), isEmpty);
      });

      tApp.dispose();
    });

    testWidgets(
        'An Exception raised by runProcess is handled as an unknown error in the App zone and rethrown to the caller.',
        (tester) async {
      await tApp.run();
      await tApp.runProcess(() async {
        await tester.pumpAndSettle();
      });

      // Check log levels processed within the App zone.
      final tStream = tApp.log.reports.asyncMap((event) => event.level);
      expectLater(
        tStream,
        emitsInOrder([
          Level.SHOUT,
          Level.SEVERE,
          Level.SEVERE,
        ]),
      );

      Object? tException;
      try {
        await tApp.runProcess(() async {
          throw _TestException(Level.SHOUT);
        });
      } catch (e) {
        tException = e;
      }
      expect((tException as _TestException).logLevel, equals(Level.SHOUT));

      // Even if the log level is less than SEVERE, an unknown error in the App zone is handled as Level.SEVERE.
      tException = null;
      try {
        await tApp.runProcess(() async {
          throw _TestException(Level.INFO);
        });
      } catch (e) {
        tException = e;
      }
      expect(tException, isA<_TestException>());
      expect((tException as _TestException).logLevel, equals(Level.INFO));

      // If logLevel is null, it is processed as Level.SEVERE in App zone.
      tException = null;
      try {
        await tApp.runProcess(() async {
          throw _TestException(null);
        });
      } catch (e) {
        tException = e;
      }
      expect((tException as _TestException).logLevel, isNull);

      tApp.dispose();
    });
  });

  group('App initialization test. options', () {
    testWidgets('Use providerKey when initializing App.', (tester) async {
      testInitialize();

      final tProviderKey = GlobalKey();
      tApp = App(
        environment: _Environment(),
        providerKey: tProviderKey,
        createAppWidget: (context, app) {
          return MultiProvider(
            providers: [
              Provider<ClassA>(
                create: (context) => ClassA(),
              ),
            ],
            child: KeyedSubtree(
              key: tProviderKey,
              child: MaterialApp(
                home: SizedBox.shrink(
                  key: tWidgetKey,
                ),
              ),
            ),
          );
        },
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.getProvider<ClassA>(), isA<ClassA>());
        expect(tWidgetKey.currentContext!.read<ClassA>(), isA<ClassA>());

        // Default providers can also be obtained.
        expect(tApp.getProvider<App>(), isA<App>());
        expect(tApp.getProvider<App<_Environment>>(), isA<App<_Environment>>());
        expect(tApp.getProvider<_Environment>(), isA<_Environment>());
        expect(tApp.getProvider<User>(), isA<User>());
        expect(tApp.getProvider<RemoteConfig>(), isA<RemoteConfig>());
        expect(tApp.getProvider<LocalConfig>(), isA<LocalConfig>());
        expect(tApp.getProvider<RemoteMessaging>(), isA<RemoteMessaging>());
        expect(tApp.getProvider<Analytics>(), isA<Analytics>());
        expect(tApp.getProvider<AnalyticsContext>(), isA<AnalyticsContext>());
        expect(
            tApp.getProvider<NetworkInformation>(), isA<NetworkInformation>());
        expect(tApp.getProvider<PackageInfoPlugin>(), isA<PackageInfoPlugin>());
        expect(tApp.getProvider<DeviceInfoPlugin>(), isA<DeviceInfoPlugin>());
      });

      tApp.dispose();
    });

    testWidgets('Use userFactory when initializing App.', (tester) async {
      testInitialize();

      tApp = App(
        environment: _Environment(),
        userFactory: ((app) => MyCustomUser(app)),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.user, isA<MyCustomUser>());
      });

      tApp.dispose();
    });

    testWidgets('Initialization of App using plugins.', (tester) async {
      testInitialize();

      late final AppStage tInitPluginAAppStage;
      final tPluginA = Plugin.inline(
        name: 'testPluginA',
        init: (app) async {
          tInitPluginAAppStage = app.stage;
          return true;
        },
      );
      late final AppStage tInitPluginBAppStage;
      final tPluginB = Plugin.inline(
        name: 'testPluginB',
        init: (app) async {
          tInitPluginBAppStage = app.stage;
          return true;
        },
      );

      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
        plugins: [
          tPluginA,
        ],
      );

      await tApp.run();
      expect(tApp.stage, equals(AppStage.running));
      expect(tInitPluginAAppStage, equals(AppStage.initializingPlugins));

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.getPlugin<InlinePlugin>(), equals(tPluginA));

        await tApp.addPlugin(tPluginB);
        expect(tInitPluginBAppStage, equals(AppStage.running));

        expect(
          tApp.getPluginsOfType<InlinePlugin>(),
          equals([tPluginA, tPluginB]),
        );

        await tApp.removePlugin(tPluginA);
        expect(tApp.getPlugin<InlinePlugin>(), equals(tPluginB));
        expect(tApp.getPluginsOfType<InlinePlugin>(), equals([tPluginB]));
      });

      tApp.dispose();
    });

    testWidgets('Initialization of App using plugins. RemoteConfig required.',
        (tester) async {
      testInitialize();

      late final AppStage tInitPluginAAppStage;
      final tPluginA = Plugin.inline(
        name: 'testPluginA',
        init: (app) async {
          tInitPluginAAppStage = app.stage;
          return true;
        },
      );
      late final AppStage tInitPluginBAppStage;
      final tPluginB = Plugin.inline(
        name: 'testPluginB',
        requireRemoteConfig: true,
        init: (app) async {
          tInitPluginBAppStage = app.stage;
          return true;
        },
      );

      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
        plugins: [
          tPluginA,
          tPluginB,
        ],
      );

      await tApp.run();
      expect(tApp.stage, equals(AppStage.running));
      expect(tInitPluginAAppStage, equals(AppStage.initializingPlugins));
      expect(tInitPluginBAppStage,
          equals(AppStage.initializingPluginsWithRemoteConfig));

      tApp.dispose();
    });

    testWidgets(
        'If the plugin init returns false during initialization, the plugin is removed.',
        (tester) async {
      testInitialize();

      fCreateApp(List<Plugin> plugins) {
        return App(
          environment: _Environment(),
          createAppWidget: (context, app) {
            return MaterialApp(
              home: SizedBox.shrink(
                key: tWidgetKey,
              ),
            );
          },
          plugins: plugins,
        );
      }

      final tPluginA = Plugin.inline(
        name: 'testPluginA',
        init: (app) async {
          return true;
        },
      );
      final tPluginFA = Plugin.inline(
        name: 'testPluginFA',
        init: (app) async {
          return false;
        },
      );
      final tPluginB = Plugin.inline(
        name: 'testPluginB',
        requireRemoteConfig: true,
        init: (app) async {
          return true;
        },
      );
      final tPluginFB = Plugin.inline(
        name: 'testPluginFB',
        requireRemoteConfig: true,
        init: (app) async {
          return false;
        },
      );

      tApp = fCreateApp([
        tPluginA,
        tPluginFA,
      ]);
      await tApp.run();
      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.getPlugin<InlinePlugin>(), equals(tPluginA));
        expect(tApp.getPluginsOfType<InlinePlugin>(), equals([tPluginA]));
      });
      tApp.dispose();

      tApp = fCreateApp([
        tPluginB,
        tPluginFB,
      ]);
      await tApp.run();
      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.getPlugin<InlinePlugin>(), equals(tPluginB));
        expect(tApp.getPluginsOfType<InlinePlugin>(), equals([tPluginB]));
      });
      tApp.dispose();
    });

    testWidgets(
        'If plugin init throws an exception during initialization, the application will fail to start.',
        (tester) async {
      testInitialize();

      fCreateApp(List<Plugin> plugins) {
        return App(
          environment: _Environment(),
          createAppWidget: (context, app) {
            return MaterialApp(
              home: SizedBox.shrink(
                key: tWidgetKey,
              ),
            );
          },
          plugins: plugins,
        );
      }

      final tPluginFA = Plugin.inline(
        name: 'testPluginFA',
        init: (app) async {
          throw Exception();
        },
      );
      final tPluginFB = Plugin.inline(
        name: 'testPluginFB',
        requireRemoteConfig: true,
        init: (app) async {
          throw Exception();
        },
      );

      tApp = fCreateApp([
        tPluginFA,
      ]);
      expect(await tApp.run(), isFalse);
      expect(tApp.stage, AppStage.initializingPlugins);
      tApp.dispose();

      tApp = fCreateApp([
        tPluginFB,
      ]);
      expect(await tApp.run(), isFalse);
      expect(tApp.stage, AppStage.initializingPluginsWithRemoteConfig);
      tApp.dispose();
    });

    testWidgets('If App.run fails, onInitFailure is called.', (tester) async {
      testInitialize();

      testInitialize();

      final tPluginA = Plugin.inline(
        name: 'testPluginA',
        init: (app) async {
          throw _TestException(Level.SEVERE);
        },
      );

      Object? tException;
      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
        plugins: [
          tPluginA,
        ],
        onInitFailure: (env, e, stackTrace) {
          tException = e;
        },
      );

      expect(await tApp.run(), isFalse);
      expect(tException, isA<_TestException>());

      tApp.dispose();
    });

    testWidgets('Use RemoteMessages.', (tester) async {
      testInitialize();

      const tRemoteMessage = RemoteMessage();
      final tMockRemoteMessaging = MockRemoteMessaging(
        getInitialMessage: () async => tRemoteMessage,
      );
      final tPluginA = Plugin.inline(
        name: 'testPluginA',
        createRemoteMessaging: () => tMockRemoteMessaging,
      );

      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
        plugins: [
          tPluginA,
        ],
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        final tMessage = await tApp.remoteMessaging.getInitialMessage();
        expect(tMessage, equals(tRemoteMessage));
      });

      tApp.dispose();
    });

    testWidgets(
        'Use RemoteConfig. If fetch fails during initialization, the application will still start.',
        (tester) async {
      testInitialize();

      final tStoreA = {
        'a': 1,
        'patapata_log_level': Level.INFO.value,
      };
      final tStoreB = {
        'b': 2,
      };
      final tRemoteConfigA = MockRemoteConfig({})
        ..testSetMockFetchValues(tStoreA);
      final tRemoteConfigB = FetchFailsRemoteConfig({})
        ..testSetMockFetchValues(tStoreB);

      final tPluginA = Plugin.inline(
        name: 'testPluginA',
        createRemoteConfig: () => tRemoteConfigA,
      );
      final tPluginB = Plugin.inline(
        name: 'testPluginB',
        createRemoteConfig: () => tRemoteConfigB,
      );

      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
        plugins: [
          tPluginA,
          tPluginB,
        ],
      );

      expect(await tApp.run(), isTrue);

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.remoteConfig.getInt('a'), equals(1));
        expect(tApp.remoteConfig.getInt('b'), equals(0));
        expect(tApp.log.level, equals(Level.INFO));

        tStoreA['a'] = 10;
        tStoreA['patapata_log_level'] = Level.SEVERE.value;
        tRemoteConfigA.testSetMockFetchValues(tStoreA);
        await tApp.remoteConfig.fetch(force: true);
        expect(tApp.log.level, equals(Level.SEVERE));
        expect(tApp.remoteConfig.getInt('a'), equals(10));
        expect(tApp.remoteConfig.getInt('b'), equals(0));
      });

      tApp.dispose();
    });

    testWidgets('Plugin can be disabled in RemoteConfig.', (tester) async {
      testInitialize();

      final tPluginA = TestPluginA();
      final tPluginB = TestPluginB();
      final tPluginC = TestPluginC();

      final tRemoteConfigA = MockRemoteConfig({})
        ..testSetMockFetchValues({
          tPluginA.remoteConfigEnabledKey: false,
          tPluginB.remoteConfigEnabledKey: false,
          tPluginC.remoteConfigEnabledKey: true,
        });

      final tRemoteConfigPlugin = Plugin.inline(
        name: 'remoteConfigPlugin',
        createRemoteConfig: () => tRemoteConfigA,
      );

      tApp = App(
        environment: _Environment(),
        createAppWidget: (context, app) {
          return MaterialApp(
            home: SizedBox.shrink(
              key: tWidgetKey,
            ),
          );
        },
        plugins: [
          tPluginA,
          tPluginB,
          tPluginC,
          tRemoteConfigPlugin,
        ],
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(tApp.hasPlugin(TestPluginA), isFalse);
        expect(tApp.hasPlugin(TestPluginB), isFalse);
        expect(tApp.hasPlugin(TestPluginC), isTrue);
      });

      tApp.dispose();
    });
  });
}
