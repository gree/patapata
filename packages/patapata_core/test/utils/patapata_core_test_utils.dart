// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';

import '../pages/home_page.dart';
import '../pages/notification_page.dart';
import '../pages/error_page.dart';

class Environment with I18nEnvironment, NotificationsEnvironment {
  const Environment();

  @override
  List<String>? get l10nPaths => [
        'l10n',
      ];

  @override
  List<Locale>? get supportedL10ns => [
        const Locale('ja'),
        const Locale('en'),
      ];

  @override
  List<AndroidNotificationChannel> get notificationsAndroidChannels => [
        const AndroidNotificationChannel(
          'custom',
          'Patapata Test Channel',
          importance: Importance.max,
          enableLights: true,
        )
      ];

  @override
  String get notificationsAndroidDefaultIcon => 'ic_notification';

  @override
  bool get notificationsDarwinDefaultPresentAlert => false;

  @override
  bool get notificationsDarwinDefaultPresentBadge => false;

  @override
  bool get notificationsDarwinDefaultPresentSound => false;

  @override
  bool get notificationsDarwinDefaultPresentBanner => false;

  @override
  bool get notificationsDarwinDefaultPresentList => false;
}

class MockL10nAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    final tYamlMap = {
      'l10n/en.yaml': '''
home:
  title: HomePage
notification:
  title: NotificationPage
test:
  title: TestMessage:{param}
  pl:
    title: LocalizationTest
    message: LocalizationTestMessage:{param}
    errors:
      pl:
        '000':
          title: PlPageErrorTitle:{prefix}{data}
          message: PlPageErrorMessage:{prefix}{data}
          fix: PlPageErrorFix:{prefix}{data}
errors:
  test:
    '000':
      title: ErrorTitle:{prefix}{data}
      message: ErrorMessage:{prefix}{data}
      fix: ErrorFix:{prefix}{data}
    shout:
      '111':
        title: ErrorPageTitle
        message: ErrorPageMessage
        fix: ErrorPageFix
  pl:
    '000':
      title: PlErrorTitle:{prefix}{data}
      message: PlErrorMessage:{prefix}{data}
      fix: PlErrorFix:{prefix}{data}
    '111':
      title: PlErrorTitle2:{prefix}{data}
      message: PlErrorMessage2:{prefix}{data}
      fix: PlErrorFix2:{prefix}{data}

''',
      'l10n/ja.yaml': '''
home:
  title: ホーム
notification:
  title: 通知
test:
  title: テストメッセージ:{param}
  pl:
    title: ローカライズテスト
    message: ローカライズテストメッセージ:{param}
    errors:
      pl:
        '000':
          title: Plページエラー:{prefix}{data}
          message: Plページメッセージ:{prefix}{data}
          fix: Plページ修復:{prefix}{data}
errors:
  test:
    '000':
      title: エラー:{prefix}{data}
      message: メッセージ:{prefix}{data}
      fix: 修復:{prefix}{data}
    shout:
      '111':
        title: エラーページ:タイトル
        message: エラーページ:メッセージ
        fix: エラーページ:修復
  pl:
    '000':
      title: Plエラー:{prefix}{data}
      message: Plメッセージ:{prefix}{data}
      fix: Pl修復:{prefix}{data}
    '111':
      title: Plエラー2:{prefix}{data}
      message: Plメッセージ2:{prefix}{data}
      fix: Pl修復2:{prefix}{data}
''',
      'l10n2/en.yaml': '''
home:
  title: HomePage2
test2:
  title: TestMessage2:{param}
''',
      'l10n2/ja.yaml': '''
home:
  title: ホーム2
test2:
  title: テストメッセージ2:{param}
''',
      'parse_error/en.yaml': '''
home
  title: This message will not be displayed because it will result in a parse error.
''',
      'empty/en.yaml': '''
''',
    };

    final tCompleter = Completer<ByteData>();

    try {
      final tByteData = ByteData.view(
        Uint8List.fromList(
          utf8.encode(
            tYamlMap[key]!,
          ),
        ).buffer,
      );
      tCompleter.complete(tByteData);
    } catch (e, stackTrace) {
      tCompleter.completeError(e, stackTrace);
    }

    return tCompleter.future;
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

bool _testInitialized = false;

void testInitialize() {
  if (_testInitialized) {
    return;
  }

  _testInitialized = true;

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

  PackageInfoPlugin.setMockValues(
    appName: 'mock_patapata_core',
    packageName: 'io.flutter.plugins.mockpatapatacore',
    version: '1.0',
    buildNumber: '1',
    buildSignature: 'patapata_core_build_signature',
    installerStore: null,
  );

  mockL10nAssetBundle = MockL10nAssetBundle();
}

final _patapataCoreTestKey = GlobalKey();
App createApp({
  Object? environment,
  Widget? appWidget,
  StartupSequence? startupSequence,
  List<Plugin>? plugins,
}) {
  testInitialize();

  return App(
    plugins: plugins,
    environment: environment ?? const Environment(),
    createAppWidget: (context, app) =>
        appWidget ??
        StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<HomePage, void>(
              create: (data) => HomePage(),
            ),
            StandardPageFactory<NotificationPage, void>(
              create: (pageData) => NotificationPage(),
              links: {r'notification/': (match, uri) {}},
              linkGenerator: (pageData) => 'notification/',
            ),
            StandardErrorPageFactory<ErrorPage>(
              create: (pageData) => ErrorPage(),
            ),
          ],
          routableBuilder: (context, child) {
            return KeyedSubtree(
              key: _patapataCoreTestKey,
              child: child!,
            );
          },
        ),
    startupSequence: startupSequence,
  );
}

Future<void> setTestDeviceSize(
  WidgetTester tester,
  Size tTestDeviceSize, {
  double devicePixelRatio = 1.0,
  double textScaleFactorTestValue = 1.0,
}) async {
  // Set the device size to the test device size.
  await tester.binding.setSurfaceSize(tTestDeviceSize);
  tester.view.physicalSize = tTestDeviceSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.binding.platformDispatcher.textScaleFactorTestValue =
      textScaleFactorTestValue;
}
