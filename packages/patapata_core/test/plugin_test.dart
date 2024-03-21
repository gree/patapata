// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

void main() {
  testInitialize();

  group('Plugin', () {
    void doDefaultTests(Plugin Function() createPlugin, String name) {
      test('name should return the runtime type as a string', () {
        final tPlugin = createPlugin();
        expect(tPlugin.name, equals(name));
      });

      test('dependencies should return an empty list by default', () {
        final tPlugin = createPlugin();
        expect(tPlugin.dependencies, isEmpty);
      });

      test('requireRemoteConfig should return false by default', () {
        final tPlugin = createPlugin();
        expect(tPlugin.requireRemoteConfig, isFalse);
      });

      test('remoteConfigEnabledKey should return the correct value', () {
        final tPlugin = createPlugin();
        expect(tPlugin.remoteConfigEnabledKey,
            equals('patapata_plugin_${name}_enabled'));
      });

      test('app should return the initialized App instance', () async {
        final tPlugin = createPlugin();
        final tApp = createApp();
        await tPlugin.init(tApp);
        expect(tPlugin.app, equals(tApp));
      });

      test('initialized should return true after initialization', () async {
        final tPlugin = createPlugin();
        final tApp = createApp();
        await tPlugin.init(tApp);
        expect(tPlugin.initialized, isTrue);
      });

      test('disposed should return true after disposal', () async {
        final tPlugin = createPlugin();
        final tApp = createApp();
        await tPlugin.init(tApp);
        await tPlugin.dispose();
        expect(tPlugin.disposed, isTrue);
      });

      test('createAppWidgetWrapper should return the child widget by default',
          () {
        final tPlugin = createPlugin();
        final tChild = Container();
        final wrapper = tPlugin.createAppWidgetWrapper(tChild);
        expect(wrapper, equals(tChild));
      });

      test('createRemoteConfig should return null by default', () {
        final tPlugin = createPlugin();
        final remoteConfig = tPlugin.createRemoteConfig();
        expect(remoteConfig, isNull);
      });

      test('createLocalConfig should return null by default', () {
        final tPlugin = createPlugin();
        final localConfig = tPlugin.createLocalConfig();
        expect(localConfig, isNull);
      });

      test('createRemoteMessaging should return null by default', () {
        final tPlugin = createPlugin();
        final remoteMessaging = tPlugin.createRemoteMessaging();
        expect(remoteMessaging, isNull);
      });

      test('navigatorObservers should return an empty list by default', () {
        final tPlugin = createPlugin();
        final observers = tPlugin.navigatorObservers;
        expect(observers, isEmpty);
      });
    }

    group('Extended defaults',
        () => doDefaultTests(() => _BasePlugin(), '_BasePlugin'));

    group('Inline defaults',
        () => doDefaultTests(() => Plugin.inline(), 'inline'));

    group('Extended others', () {
      test('init can not be executed multiple times', () async {
        final tPlugin = _BasePlugin();
        final tApp = createApp();
        await tPlugin.init(tApp);

        expect(
            () async => await tPlugin.init(tApp), throwsA(isA<StateError>()));
      });

      test('dispose can not be executed multiple times', () async {
        final tPlugin = _BasePlugin();
        final tApp = createApp();
        await tPlugin.init(tApp);
        await tPlugin.dispose();

        expect(() async => await tPlugin.dispose(), throwsA(isA<StateError>()));
      });

      testWidgets('native mock enable/disable calls should be called',
          (tester) async {
        final tPlugin = _BasePlugin(shouldCall: expectAsync0(() {}, count: 2));
        final tApp = createApp(
          plugins: [tPlugin],
        );

        await tApp.run();

        await tApp.runProcess(() async {
          await tester.pumpAndSettle();

          await tApp.removePlugin(tPlugin);
        });

        tApp.dispose();
      });

      test('An error should be thrown if dependencies are not satisfied',
          () async {
        final tPlugin = _DependencyPlugin();
        final tApp = createApp();

        expect(
            () async => await tPlugin.init(tApp), throwsA(isA<StateError>()));
      });
    });

    group('Inline others', () {
      testWidgets('You can make a complete custom inline plugin',
          (tester) async {
        final tWidgetKey = GlobalKey();
        final tPlugin = Plugin.inline(
          name: 'test',
          dependencies: [_BasePlugin],
          requireRemoteConfig: true,
          init: expectAsync1((App app) async => true, count: 1),
          dispose: expectAsync0(() {}, count: 1),
          createAppWidgetWrapper: (child) => KeyedSubtree(
            key: tWidgetKey,
            child: child,
          ),
          createRemoteConfig: () => MockRemoteConfig({
            'r': 'r',
          }),
          createLocalConfig: () => MockLocalConfig({
            'l': 'l',
          }),
          createRemoteMessaging: () => MockRemoteMessaging(
            getToken: () => Future.value('token'),
          ),
          navigatorObservers: () => [NavigatorObserver()],
        );

        final tApp = createApp(
          plugins: [
            _BasePlugin(),
            tPlugin,
          ],
        );

        await tApp.run();

        await tApp.runProcess(() async {
          await tester.pumpAndSettle();

          expect(tPlugin.name, equals('test'));
          expect(tPlugin.dependencies, equals([_BasePlugin]));
          expect(tPlugin.requireRemoteConfig, isTrue);
          expect(tPlugin.remoteConfigEnabledKey,
              equals('patapata_plugin_test_enabled'));
          expect(tPlugin.app, equals(tApp));
          expect(tPlugin.initialized, isTrue);
          expect(tPlugin.disposed, isFalse);
          expect(tPlugin.navigatorObservers, isNotEmpty);

          expect(find.byKey(tWidgetKey), findsOneWidget);
          expect(tApp.remoteConfig.getString('r'), equals('r'));
          expect(tApp.localConfig.getString('l'), equals('l'));
          expect(tApp.remoteMessaging.getToken(), completion('token'));
        });

        tApp.dispose();
      });
    });
  });
}

class _BasePlugin extends Plugin {
  final void Function()? shouldCall;

  _BasePlugin({
    this.shouldCall,
  });

  @override
  void mockPatapataEnable() {
    shouldCall?.call();
  }

  @override
  void mockPatapataDisable() {
    shouldCall?.call();
  }
}

class _DependencyPlugin extends Plugin {
  @override
  final List<Type> dependencies = [_BasePlugin];
}
