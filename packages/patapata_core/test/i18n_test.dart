// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/src/exception.dart';

import 'pages/home_page.dart';
import 'utils/patapata_core_test_utils.dart';

class _Environment {
  const _Environment();
}

class _I18nEnvironment with I18nEnvironment {
  const _I18nEnvironment(this._l10nPaths, this._supportedL10ns);

  final List<String>? _l10nPaths;

  @override
  List<String>? get l10nPaths => _l10nPaths;

  final List<Locale>? _supportedL10ns;

  @override
  List<Locale>? get supportedL10ns => _supportedL10ns;
}

void main() {
  group('class L10n', () {
    setUp(() {
      testInitialize();
    });

    test('Create L10n class.', () async {
      const tL10n = L10n(Locale('en'), {'aaa': 'Test'});

      expect(tL10n.locale, equals(const Locale('en')));
      expect(tL10n.containsMessageKey('aaa'), isTrue);
      expect(tL10n.lookup('aaa'), equals('Test'));
      expect(tL10n.containsMessageKey('bbb'), isFalse);
      expect(tL10n.lookup('bbb'), equals('bbb'));
    });

    test(
      'The resource is loaded from assets and the lookup works correctly.',
      () async {
        final tL10nEn = await L10n.fromAssets(
          locale: const Locale('en'),
          paths: ['l10n'],
          assetBundle: mockL10nAssetBundle,
        );
        final tL10nJa = await L10n.fromAssets(
          locale: const Locale('ja'),
          paths: ['l10n'],
          assetBundle: mockL10nAssetBundle,
        );

        // en
        expect(tL10nEn.locale, equals(const Locale('en')));
        expect(tL10nEn.lookup('home.title'), equals('HomePage'));
        expect(tL10nEn.containsMessageKey('test.title'), isTrue);
        expect(
          tL10nEn.lookup('test.title', namedParameters: {'param': 'en'}),
          equals('TestMessage:en'),
        );
        expect(tL10nEn.containsMessageKey('test2.title'), isFalse);
        expect(
          tL10nEn.lookup('test2.title', namedParameters: {'param': 'en'}),
          equals('test2.title'),
        );

        // ja
        expect(tL10nJa.locale, equals(const Locale('ja')));
        expect(tL10nJa.lookup('home.title'), equals('ホーム'));
        expect(tL10nJa.containsMessageKey('test.title'), isTrue);
        expect(
          tL10nJa.lookup('test.title', namedParameters: {'param': 'ja'}),
          equals('テストメッセージ:ja'),
        );
        expect(tL10nJa.containsMessageKey('test2.title'), isFalse);
        expect(
          tL10nJa.lookup('test2.title', namedParameters: {'param': 'ja'}),
          equals('test2.title'),
        );
      },
    );

    test(
      'If multiple paths are specified, the same key will be overwritten by subsequent files.',
      () async {
        final tL10nEn = await L10n.fromAssets(
          locale: const Locale('en'),
          paths: ['l10n', 'l10n2'],
          assetBundle: mockL10nAssetBundle,
        );
        final tL10nJa = await L10n.fromAssets(
          locale: const Locale('ja'),
          paths: ['l10n', 'l10n2'],
          assetBundle: mockL10nAssetBundle,
        );

        // en
        expect(tL10nEn.lookup('home.title'), equals('HomePage2'));
        expect(tL10nEn.containsMessageKey('test.title'), isTrue);
        expect(
          tL10nEn.lookup('test.title', namedParameters: {'param': 'en'}),
          equals('TestMessage:en'),
        );
        expect(tL10nEn.containsMessageKey('test2.title'), isTrue);
        expect(
          tL10nEn.lookup('test2.title', namedParameters: {'param': 'en'}),
          equals('TestMessage2:en'),
        );

        // ja
        expect(tL10nJa.lookup('home.title'), equals('ホーム2'));
        expect(tL10nJa.containsMessageKey('test.title'), isTrue);
        expect(
          tL10nJa.lookup('test.title', namedParameters: {'param': 'ja'}),
          equals('テストメッセージ:ja'),
        );
        expect(tL10nJa.containsMessageKey('test2.title'), isTrue);
        expect(
          tL10nJa.lookup('test2.title', namedParameters: {'param': 'ja'}),
          equals('テストメッセージ2:ja'),
        );
      },
    );
    test(
      'Load error in assets. The `patapata_dummy_never` is set as dummy.',
      () async {
        // The path is invalid and will not be loaded.
        final tL10nNotFound = await L10n.fromAssets(
          locale: const Locale('en'),
          paths: ['aaa'],
          assetBundle: mockL10nAssetBundle,
        );

        // Languages not supported by the app are not loaded.
        final tL10nAr = await L10n.fromAssets(
          locale: const Locale('ar'),
          paths: ['l10n'],
          assetBundle: mockL10nAssetBundle,
        );

        // Since [assetBundle] is not specified, the assets is loaded from [rootBundle],
        // but in the test environment, the actual assets does not exist.
        final tL10nEn = await L10n.fromAssets(
          locale: const Locale('en'),
          paths: ['l10n'],
        );

        expect(tL10nNotFound.containsMessageKey('home.title'), isFalse);
        expect(tL10nNotFound.lookup('patapata_dummy_never'), 'dummy');
        expect(tL10nAr.containsMessageKey('home.title'), isFalse);
        expect(tL10nAr.lookup('patapata_dummy_never'), 'dummy');
        expect(tL10nEn.containsMessageKey('home.title'), isFalse);
        expect(tL10nEn.lookup('patapata_dummy_never'), 'dummy');
      },
    );

    test('Parse error in yaml.', () async {
      Object? tException;
      final tLogSubscription = Logger.root.onRecord.listen((LogRecord record) {
        tException = record.error;
      });

      final tL10nError = await L10n.fromAssets(
        locale: const Locale('en'),
        paths: ['parse_error'],
        assetBundle: mockL10nAssetBundle,
      );

      expect(tL10nError.containsMessageKey('home.title'), isFalse);
      expect(tL10nError.containsMessageKey('patapata_dummy_never'), isFalse);
      expect(tException, isA<L10nLoadAssetsException>());
      expect(
        (tException as L10nLoadAssetsException).code,
        equals(PatapataCoreExceptionCode.PPE401.name),
      );

      // Empty yaml file
      tException = null;
      final tL10nEmpty = await L10n.fromAssets(
        locale: const Locale('en'),
        paths: ['empty'],
        assetBundle: mockL10nAssetBundle,
      );

      expect(tL10nEmpty.containsMessageKey('home.title'), isFalse);
      expect(tL10nEmpty.containsMessageKey('patapata_dummy_never'), isFalse);
      expect(tException, isA<L10nLoadAssetsException>());
      expect(
        (tException as L10nLoadAssetsException).code,
        equals(PatapataCoreExceptionCode.PPE401.name),
      );

      tLogSubscription.cancel();
    });
  });

  group('Initialize I18nPlugin and load assets.', () {
    test(
      "If I18nEnvironment is not specified, Locale('en') is read from l10n as default.",
      () async {
        final tApp = createApp(environment: const _Environment());
        final tI18nPlugin = I18nPlugin();
        const tLocale = Locale('en');

        final bool tResult = await tI18nPlugin.init(tApp);
        expect(tResult, isTrue);
        expect(tI18nPlugin.i18n.supportedL10ns, [tLocale]);
        expect(tI18nPlugin.i18n.delegate.isSupported(tLocale), isTrue);
        expect(
          tI18nPlugin.i18n.delegate.isSupported(const Locale('ja')),
          isFalse,
        );
        expect(tI18nPlugin.i18n.delegate.l10n, isNull);
        await tI18nPlugin.i18n.delegate.load(tLocale);
        expect(tI18nPlugin.i18n.delegate.l10n, isNotNull);
        expect(
          tI18nPlugin.i18n.delegate.l10n!.containsMessageKey('test.title'),
          isTrue,
        );
      },
    );

    test(
      'If I18nEnvironment.l10nPaths is not set, `l10n` will be the default.',
      () async {
        final tApp = createApp(
          environment: const _I18nEnvironment(null, [Locale('en')]),
        );
        final tI18nPlugin = I18nPlugin();
        const tLocale = Locale('en');

        final bool tResult = await tI18nPlugin.init(tApp);
        expect(tResult, isTrue);
        await tI18nPlugin.i18n.delegate.load(tLocale);
        expect(
          tI18nPlugin.i18n.delegate.l10n!.containsMessageKey('test.title'),
          isTrue,
        );
      },
    );

    test('If I18nEnvironment.supportedL10ns is required.', () async {
      final tApp = createApp(environment: const _I18nEnvironment(null, null));
      final tI18nPlugin = I18nPlugin();

      final bool tResult = await tI18nPlugin.init(tApp);
      expect(tResult, isFalse);
    });
  });

  group('Widget tests', () {
    late App tApp;

    setUp(() async {
      tApp = createApp(
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'Test Title',
          pages: [
            StandardPageFactory<HomePage, void>(create: (data) => HomePage()),
          ],
        ),
      );
    });

    testWidgets('l function process correctly.', (WidgetTester tester) async {
      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(
          l(StandardMaterialApp.globalNavigatorContext!, 'home.title'),
          equals('HomePage'),
        );
        expect(
          l(StandardMaterialApp.globalNavigatorContext!, 'test.title', {
            'param': 'test',
          }),
          equals('TestMessage:test'),
        );
      });

      tApp.dispose();
    });

    testWidgets('L10n.containsKey process correctly.', (
      WidgetTester tester,
    ) async {
      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(
          L10n.containsKey(
            context: StandardMaterialApp.globalNavigatorContext!,
            key: 'home.title',
          ),
          isTrue,
        );
        expect(
          L10n.containsKey(
            context: StandardMaterialApp.globalNavigatorContext!,
            key: 'test2.title',
          ),
          isFalse,
        );
      });

      tApp.dispose();
    });
  });
}
