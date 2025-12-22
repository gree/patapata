// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/src/exception.dart';

import 'utils/patapata_core_test_utils.dart';

class _ErrorTestEnvironment extends Environment with ErrorEnvironment {
  @override
  Future<void> Function(BuildContext context, PatapataException error)?
  get errorDefaultShowDialog => (context, error) {
    return PlatformDialog.show<void>(
      context: context,
      title: 'custom:${error.localizedTitle}',
      message: 'custom:${error.localizedMessage}',
      actions: [
        PlatformDialogAction<void>(
          result: () {},
          isDefault: true,
          text: 'custom:${error.localizedFix}',
        ),
      ],
    );
  };

  @override
  Widget Function(PatapataException p1)? get errorDefaultWidget => (error) {
    return Text('custom:${error.localizedMessage}');
  };

  @override
  Map<String, String>? get errorReplacePrefixMap => {'test': 'CST'};
}

class _TestException extends PatapataException {
  _TestException({
    super.app,
    super.message,
    super.original,
    super.fingerprint,
    super.localeTitleData,
    super.localeMessageData,
    super.localeFixData,
    super.logLevel,
    super.userLogLevel,
    super.fix,
    this.internalCode = '000',
    this.namespace = 'test',
  });

  @override
  String get defaultPrefix => 'TST';

  @override
  final String internalCode;

  @override
  final String namespace;
}

class _TestExceptionWithFix extends _TestException {
  _TestExceptionWithFix({
    required super.fix,
    super.localeTitleData,
    super.localeMessageData,
    super.localeFixData,
  });
}

class _TestInfoException extends _TestException {
  _TestInfoException()
    : super(
        app: null,
        message: null,
        original: null,
        fingerprint: null,
        localeTitleData: null,
        localeMessageData: null,
        localeFixData: null,
        logLevel: Level.INFO,
      );
}

class _TestShoutException extends _TestException {
  _TestShoutException()
    : super(
        app: null,
        message: null,
        original: null,
        fingerprint: null,
        localeTitleData: null,
        localeMessageData: null,
        localeFixData: null,
        logLevel: Level.INFO,
        userLogLevel: Level.SHOUT,
      );

  @override
  String get defaultPrefix => 'TSS';

  @override
  String get internalCode => '111';

  @override
  String get namespace => 'test.shout';
}

class TestPageLocalizationKey extends StandardPage<void> {
  @override
  String get localizationKey => 'test.pl';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('title')),
      body: const Center(child: Text('message')),
    );
  }
}

class _TestPatapataCoreException extends PatapataCoreException {
  _TestPatapataCoreException({required super.code});
}

void main() {
  testWidgets('Error test.', (WidgetTester tTester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final App tApp = createApp();
    tApp.run();

    await tApp.runProcess(() async {
      await tTester.pumpAndSettle();

      final tException = _TestException(
        message: 'TestError',
        original: 'OriginalError',
        localeTitleData: {'data': '111'},
        localeMessageData: {'data': '222'},
        localeFixData: {'data': '333'},
        fingerprint: ['A', 'B', 'C'],
      );
      expect(tException.code, 'TST000');
      expect(tException.message, 'TestError');
      expect(tException.original, 'OriginalError');
      expect(tException.logLevel, null);
      expect(tException.userLogLevel, null);
      expect(
        tException.localizedTitle,
        l(
          StandardMaterialApp.globalNavigatorContext!,
          'errors.test.000.title',
          {'prefix': 'TST', 'data': '111'},
        ),
      );
      expect(
        tException.localizedMessage,
        l(
          StandardMaterialApp.globalNavigatorContext!,
          'errors.test.000.message',
          {'prefix': 'TST', 'data': '222'},
        ),
      );
      expect(
        tException.localizedFix,
        l(StandardMaterialApp.globalNavigatorContext!, 'errors.test.000.fix', {
          'prefix': 'TST',
          'data': '333',
        }),
      );
      expect(tException.hasFix, false);
      expect(tException.fingerprint, ['A', 'B', 'C']);

      tException.showDialog(StandardMaterialApp.globalNavigatorContext!);
      await tTester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(tException.localizedTitle), findsOneWidget);
      expect(find.text(tException.localizedMessage), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      await tTester.tap(find.text('OK'));

      await tTester.pumpWidget(MaterialApp(home: tException.widget));
      expect(find.text(tException.localizedMessage), findsOneWidget);

      expect(
        tException.toString(),
        '_TestException: code=TST000, message=TestError, original=OriginalError',
      );

      final tExceptionNoMessage = _TestException();
      expect(
        tExceptionNoMessage.toString(),
        '_TestException: code=TST000, message=null',
      );
    });

    tApp.dispose();

    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'Tests log level. if userLogLevel is null, then logLevel is the value of logLevel.',
    () async {
      final tExceptionA = _TestException();
      expect(tExceptionA.logLevel, null);
      expect(tExceptionA.userLogLevel, null);

      final tExceptionB = _TestException(
        logLevel: Level.FINE,
        userLogLevel: Level.SHOUT,
      );
      expect(tExceptionB.logLevel, Level.FINE);
      expect(tExceptionB.userLogLevel, Level.SHOUT);

      final tExceptionC = _TestException(userLogLevel: Level.INFO);
      expect(tExceptionC.logLevel, null);
      expect(tExceptionC.userLogLevel, Level.INFO);

      final tExceptionD = _TestException(logLevel: Level.SEVERE);
      expect(tExceptionD.logLevel, Level.SEVERE);
      expect(tExceptionD.userLogLevel, Level.SEVERE);
    },
  );

  testWidgets('Error Fix test.', (WidgetTester tTester) async {
    final App tApp = createApp();
    tApp.run();

    bool tFixed = false;

    await tApp.runProcess(() async {
      await tTester.pumpAndSettle();

      final tException = _TestExceptionWithFix(
        localeTitleData: {'data': '111'},
        localeMessageData: {'data': '222'},
        localeFixData: {'data': '333'},
        fix: () async {
          tFixed = true;
        },
      );

      expect(
        tException.localizedFix,
        l(StandardMaterialApp.globalNavigatorContext!, 'errors.test.000.fix', {
          'prefix': 'TST',
          'data': '333',
        }),
      );
      expect(tException.hasFix, true);
      expect(tFixed, false);
      await tException.fix!();
      expect(tFixed, true);
    });

    tApp.dispose();
  });

  testWidgets('Error Environment test.', (WidgetTester tTester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final App tApp = createApp(environment: _ErrorTestEnvironment());
    tApp.run();

    await tApp.runProcess(() async {
      await tTester.pumpAndSettle();

      final tException = _TestException(
        localeTitleData: {'data': '111'},
        localeMessageData: {'data': '222'},
        localeFixData: {'data': '333'},
      );
      expect(tException.code, 'CST000');
      expect(
        tException.localizedTitle,
        l(
          StandardMaterialApp.globalNavigatorContext!,
          'errors.test.000.title',
          {'prefix': 'CST', 'data': '111'},
        ),
      );
      expect(
        tException.localizedMessage,
        l(
          StandardMaterialApp.globalNavigatorContext!,
          'errors.test.000.message',
          {'prefix': 'CST', 'data': '222'},
        ),
      );
      expect(
        tException.localizedFix,
        l(StandardMaterialApp.globalNavigatorContext!, 'errors.test.000.fix', {
          'prefix': 'CST',
          'data': '333',
        }),
      );

      tException.showDialog(StandardMaterialApp.globalNavigatorContext!);
      await tTester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('custom:${tException.localizedTitle}'), findsOneWidget);
      expect(
        find.text('custom:${tException.localizedMessage}'),
        findsOneWidget,
      );
      expect(find.text('custom:${tException.localizedFix}'), findsOneWidget);
      await tTester.tap(find.text('custom:${tException.localizedFix}'));

      await tTester.pumpWidget(MaterialApp(home: tException.widget));
      expect(
        find.text('custom:${tException.localizedMessage}'),
        findsOneWidget,
      );
    });

    tApp.dispose();

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Error log and navigate test.', (WidgetTester tTester) async {
    final tLogger = Logger('errorTest');
    final App tApp = createApp(environment: _ErrorTestEnvironment());
    tApp.run();

    await tApp.runProcess(() async {
      await tTester.pumpAndSettle();

      final tException = _TestInfoException();
      expect(tException.logLevel, Level.INFO);
      expect(tException.userLogLevel, Level.INFO);
      tLogger.info(tException.toString(), tException);
      await tTester.pumpAndSettle();
      expect(find.text(tException.localizedMessage), findsNothing);

      final tShoutException = _TestShoutException();
      expect(tShoutException.logLevel, Level.INFO);
      expect(tShoutException.userLogLevel, Level.SHOUT);
      tLogger.info(tShoutException.toString(), tShoutException);
      expect(
        tShoutException.localizedMessage,
        l(
          StandardMaterialApp.globalNavigatorContext!,
          'errors.test.shout.111.message',
          {'prefix': 'TSS'},
        ),
      );
      await tTester.pumpAndSettle();
      expect(find.text(tShoutException.localizedMessage), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('Error test.(no app zone)', (WidgetTester tTester) async {
    final App tApp = createApp();
    tApp.run();
    await tApp.runProcess(() async {
      await tTester.pumpAndSettle();
    });

    final tException = _TestException(
      localeTitleData: {'data': '111'},
      localeMessageData: {'data': '222'},
      localeFixData: {'data': '333'},
    );
    expect(tException.localizedTitle, 'Error: TST000');
    expect(tException.localizedMessage, '_TestException: code=TST000');
    expect(tException.localizedFix, 'OK');

    final tExceptionWithApp = _TestException(
      app: tApp,
      localeTitleData: {'data': '111'},
      localeMessageData: {'data': '222'},
      localeFixData: {'data': '333'},
    );
    expect(
      tExceptionWithApp.localizedTitle,
      l(StandardMaterialApp.globalNavigatorContext!, 'errors.test.000.title', {
        'prefix': 'TST',
        'data': '111',
      }),
    );
    expect(
      tExceptionWithApp.localizedMessage,
      l(
        StandardMaterialApp.globalNavigatorContext!,
        'errors.test.000.message',
        {'prefix': 'TST', 'data': '222'},
      ),
    );
    expect(
      tExceptionWithApp.localizedFix,
      l(StandardMaterialApp.globalNavigatorContext!, 'errors.test.000.fix', {
        'prefix': 'TST',
        'data': '333',
      }),
    );

    tApp.dispose();
  });

  test('TestPatapataCoreException test.', () {
    final tException = _TestPatapataCoreException(
      code: PatapataCoreExceptionCode.PPE101,
    );

    expect('patapata', tException.namespace);
    expect('PPE', tException.prefix);
    expect('PPE101', tException.code);
  });

  testWidgets('Localization test using localizationKey.', (widgetTester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageLocalizationKey, void>(
            create: (data) => TestPageLocalizationKey(),
          ),
        ],
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      final tContext = StandardMaterialApp.globalNavigatorContext!;

      final tException = _TestException(
        namespace: 'pl',
        localeTitleData: {'data': '111'},
        localeMessageData: {'data': '222'},
        localeFixData: {'data': '333'},
      );
      expect(
        tException.localizedTitle,
        l(tContext, 'test.pl.errors.pl.000.title', {
          'prefix': 'TST',
          'data': '111',
        }),
      );
      expect(
        tException.localizedMessage,
        l(tContext, 'test.pl.errors.pl.000.message', {
          'prefix': 'TST',
          'data': '222',
        }),
      );
      expect(
        tException.localizedFix,
        l(tContext, 'test.pl.errors.pl.000.fix', {
          'prefix': 'TST',
          'data': '333',
        }),
      );

      // internalCode `111` is not overridden
      final tException2 = _TestException(
        namespace: 'pl',
        internalCode: '111',
        localeTitleData: {'data': '111'},
        localeMessageData: {'data': '222'},
        localeFixData: {'data': '333'},
      );
      expect(
        tException2.localizedTitle,
        l(tContext, 'errors.pl.111.title', {'prefix': 'TST', 'data': '111'}),
      );
      expect(
        tException2.localizedMessage,
        l(tContext, 'errors.pl.111.message', {'prefix': 'TST', 'data': '222'}),
      );
      expect(
        tException2.localizedFix,
        l(tContext, 'errors.pl.111.fix', {'prefix': 'TST', 'data': '333'}),
      );

      // namespace `test` is not overridden
      final tException3 = _TestException(
        localeTitleData: {'data': '111'},
        localeMessageData: {'data': '222'},
        localeFixData: {'data': '333'},
      );
      expect(
        tException3.localizedTitle,
        l(tContext, 'errors.test.000.title', {'prefix': 'TST', 'data': '111'}),
      );
      expect(
        tException3.localizedMessage,
        l(tContext, 'errors.test.000.message', {
          'prefix': 'TST',
          'data': '222',
        }),
      );
      expect(
        tException3.localizedFix,
        l(tContext, 'errors.test.000.fix', {'prefix': 'TST', 'data': '333'}),
      );
    });

    tApp.dispose();
  });
}
