// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';

import 'utils/patapata_core_test_utils.dart';

final _logger = Logger('test.log');

class TestLogEnvironment with LogEnvironment {
  const TestLogEnvironment({
    int? logLevel,
    bool? printLog,
  })  : _logLevel = logLevel,
        _printLog = printLog;

  final int? _logLevel;
  final bool? _printLog;

  @override
  int get logLevel => _logLevel ?? Level.INFO.value;

  @override
  bool get printLog => _printLog ?? super.printLog;
}

class TestPatapataException extends PatapataException {
  TestPatapataException({
    required void Function(ReportRecord) onReported,
    super.logLevel,
  }) : _onReported = onReported;

  final void Function(ReportRecord) _onReported;

  @override
  void onReported(ReportRecord record) {
    _onReported(record);
  }

  @override
  String get defaultPrefix => 'LOG';

  @override
  String get internalCode => '000';

  @override
  String get namespace => 'test';
}

void main() {
  testWidgets('ReportRecord constructor.', (WidgetTester tester) async {
    ReportRecord tRecord;
    StackTrace? tStackTrace;
    try {
      throw Exception('dummy');
    } catch (e, stackTrace) {
      tStackTrace = stackTrace;
      tRecord = ReportRecord(
        level: Level.SEVERE,
        message: 'message',
        error: 'error',
        object: 'object',
        stackTrace: tStackTrace,
      );
    }
    expect(tRecord.level, equals(Level.SEVERE));
    expect(tRecord.message, equals('message'));
    expect(tRecord.error, equals('error'));
    expect(tRecord.object, equals('object'));
    expect(tRecord.stackTrace, equals(tStackTrace));

    // stackTrace from Error.
    Error? tError;
    try {
      // throw Error();
      Object? tObject;
      tObject!.toString();
    } catch (e, stackTrace) {
      expect(e, isA<Error>());
      tError = e as Error;
      tStackTrace = stackTrace;
      tRecord = ReportRecord(
        level: Level.SEVERE,
        message: 'message',
        error: e,
        object: 'object',
      );
    }
    expect(tRecord.level, equals(Level.SEVERE));
    expect(tRecord.message, equals('message'));
    expect(tRecord.error, equals(tError));
    expect(tRecord.object, equals('object'));
    expect(tRecord.stackTrace, equals(tStackTrace));
  });

  testWidgets('ReportRecord copyWith.', (WidgetTester tester) async {
    final tRecord = ReportRecord(
      level: Level.SEVERE,
      message: 'message',
      error: 'error',
      object: 'object',
    );

    final tRecordClone = tRecord.copyWith();

    final tRecordCopy = tRecord.copyWith(
      level: Level.INFO,
      message: 'message2',
      error: 'error2',
      object: 'object2',
    );

    expect(tRecord, isNot(tRecordClone));
    expect(tRecord, isNot(equals(tRecordCopy)));

    expect(tRecord.level, equals(Level.SEVERE));
    expect(tRecord.message, equals('message'));
    expect(tRecord.error, equals('error'));
    expect(tRecord.object, equals('object'));

    expect(tRecordClone.level, equals(Level.SEVERE));
    expect(tRecordClone.message, equals('message'));
    expect(tRecordClone.error, equals('error'));
    expect(tRecordClone.object, equals('object'));

    expect(tRecordCopy.level, equals(Level.INFO));
    expect(tRecordCopy.message, equals('message2'));
    expect(tRecordCopy.error, equals('error2'));
    expect(tRecordCopy.object, equals('object2'));
  });

  testWidgets('Log Environment correctly.', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
        printLog: true,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(tApp.log.level, equals(Level.SEVERE));
      expect(tApp.log.logPrinting, isTrue);
    });

    tApp.dispose();
  });

  testWidgets('level and logPrinting setter', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      tApp.log.level = Level.SEVERE;
      tApp.log.logPrinting = true;
      expect(tApp.log.level, equals(Level.SEVERE));
      expect(tApp.log.logPrinting, isTrue);

      tApp.log.level = Level.INFO;
      tApp.log.logPrinting = false;
      expect(tApp.log.level, equals(Level.INFO));
      expect(tApp.log.logPrinting, isFalse);

      tApp.log.setLevelByValue(111);
      expect(tApp.log.level.value, equals(111));
    });

    tApp.dispose();
  });

  testWidgets('report test', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tReportedRecord =
          ReportRecord(level: Level.SEVERE, message: 'test');
      final tNotReportedRecord =
          ReportRecord(level: Level.INFO, message: 'test');
      expectLater(
        tApp.log.reports,
        emits(tReportedRecord),
      );
      expectLater(
        tApp.log.reports,
        neverEmits(tNotReportedRecord),
      );

      tApp.log.report(tReportedRecord);
      tApp.log.report(tNotReportedRecord);
    });

    tApp.dispose();
  });

  testWidgets('Logger test', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tStream = tApp.log.reports.asyncMap((event) => event.message);

      expectLater(
        tStream,
        emits(equals('severe')),
      );
      expectLater(
        tStream,
        neverEmits(equals('info')),
      );

      _logger.severe('severe');
      _logger.info('info');

      _logger.severe(ReportRecord(level: Level.SEVERE, message: 'test'));
    });

    tApp.dispose();
  });

  testWidgets('Logger object test', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tObject = Object();
      final tStream = tApp.log.reports.asyncMap((event) => event.object);

      expectLater(
        tStream,
        emits(equals(tObject)),
      );

      _logger.severe(
          ReportRecord(level: Level.SEVERE, message: 'test', object: tObject));
    });

    tApp.dispose();
  });

  testWidgets('logPrinting from Logger', (WidgetTester tester) async {
    final App tApp = createApp();

    final tOriginalDebugPrint = debugPrint;
    bool tDebugPrintCalled = false;
    debugPrint = (String? message, {int? wrapWidth}) {
      tDebugPrintCalled = true;
    };

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      final tStream = tApp.log.reports.asyncMap((event) => event.message);
      expectLater(
        tStream,
        emits(equals('test')),
      );

      tApp.log.logPrinting = true;
      _logger.severe('test');
      expect(tDebugPrintCalled, isTrue);

      tDebugPrintCalled = false;
      tApp.log.logPrinting = false;
      _logger.severe('test');
      expect(tDebugPrintCalled, isFalse);

      tApp.log.logPrinting = true;
      _logger.severe('test');
      expect(tDebugPrintCalled, isTrue);
    });

    tApp.dispose();

    debugPrint = tOriginalDebugPrint;
  });

  testWidgets('duplicate error test', (WidgetTester tester) async {
    final App tApp = createApp();

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tExceptionA = Exception('duplicateObject');
      final tExceptionB = Exception('duplicateError');

      final tStream = tApp.log.reports.asyncMap((event) => event.message);
      expectLater(
        tStream,
        emitsInOrder([
          'duplicateObject',
          tExceptionB.toString(),
          emitsDone,
        ]),
      );

      try {
        try {
          throw tExceptionA;
        } catch (e, stackTrace) {
          _logger.severe('duplicateObject', e, stackTrace);
          rethrow;
        }
      } catch (e, stackTrace) {
        _logger.severe('duplicateObject', e, stackTrace);
      }

      try {
        try {
          throw tExceptionB;
        } catch (e) {
          _logger.severe(e);
          rethrow;
        }
      } catch (e) {
        _logger.severe(e);
      }
    });

    tApp.dispose();
  });

  testWidgets('filter test', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
        printLog: false,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tStream = tApp.log.reports.asyncMap((event) => event.message);
      expectLater(
        tStream,
        emitsInOrder([
          'severe',
          'removeIgnore',
        ]),
      );
      expectLater(
        tStream,
        neverEmits(equals('ignore')),
      );

      fFilter(ReportRecord record) {
        if (record.message == 'ignore' || record.message == 'removeIgnore') {
          return null;
        }
        return record;
      }

      tApp.log.addFilter(fFilter);

      final tRecord = ReportRecord(level: Level.SEVERE, message: 'severe');
      final tRecordIgnore =
          ReportRecord(level: Level.SEVERE, message: 'ignore');
      expect(tApp.log.filter(tRecord), equals(tRecord));
      expect(tApp.log.filter(tRecordIgnore), isNull);

      _logger.severe('severe');
      _logger.severe('ignore');

      tApp.log.removeFilter(fFilter);
      _logger.severe('removeIgnore');
      expect(tApp.log.filter(tRecord), equals(tRecord));
      expect(tApp.log.filter(tRecordIgnore), equals(tRecordIgnore));
    });

    tApp.dispose();
  });

  testWidgets('ignoreType test', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
        printLog: false,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tStream = tApp.log.reports.asyncMap((event) => event.message);
      expectLater(
        tStream,
        emitsInOrder([
          'severe',
          'removeIgnore',
        ]),
      );
      expectLater(
        tStream,
        neverEmits(equals('ignore')),
      );

      tApp.log.ignoreType(int);

      final tRecord =
          ReportRecord(level: Level.SEVERE, message: 'severe', error: '1');
      final tRecordIgnore =
          ReportRecord(level: Level.SEVERE, message: 'ignore', error: 1);
      expect(tApp.log.filter(tRecord), equals(tRecord));
      expect(tApp.log.filter(tRecordIgnore), isNull);

      _logger.severe('severe', '1');
      _logger.severe('ignore', 1);

      tApp.log.unignoreType(int);
      _logger.severe('removeIgnore', 1);
      expect(tApp.log.filter(tRecord), equals(tRecord));
      expect(tApp.log.filter(tRecordIgnore), equals(tRecordIgnore));
    });

    tApp.dispose();
  });

  testWidgets('Report PatapataException test', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
        printLog: false,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tStream = tApp.log.reports.asyncMap((event) => event.message);
      expectLater(
        tStream,
        emits(equals('patapataException')),
      );

      bool tOnReportedCalled = false;

      try {
        throw TestPatapataException(
          onReported: (record) {
            tOnReportedCalled = true;
            throw 'This exception must not propagate.';
          },
        );
      } catch (e, stackTrace) {
        expect(e, isA<TestPatapataException>());
        _logger.severe('patapataException', e, stackTrace);
      }

      await tester.pumpAndSettle();

      expect(tOnReportedCalled, isTrue);
    });

    tApp.dispose();
  });

  testWidgets('Log FlutterError', (WidgetTester tester) async {
    final tOriginalOnError = FlutterError.onError;
    bool tOnErrorCalled = false;
    FlutterError.onError = (details) {
      tOnErrorCalled = true;
    };

    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.INFO.value,
        printLog: false,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      final tStream = tApp.log.reports.asyncMap((event) => event.level);
      expectLater(
        tStream,
        emitsInOrder([
          Level.INFO,
          Level.SEVERE,
          Level.SEVERE,
        ]),
      );

      // throw FlutterError
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              FilledButton(
                onPressed: () {
                  throw TestPatapataException(
                    onReported: (_) {},
                    logLevel: Level.INFO,
                  );
                },
                child: const Text('ExceptionA'),
              ),
              FilledButton(
                onPressed: () {
                  throw TestPatapataException(
                    onReported: (_) {},
                    logLevel: null,
                  );
                },
                child: const Text('ExceptionB'),
              ),
              FilledButton(
                onPressed: () {
                  throw 'not PatapataException';
                },
                child: const Text('ExceptionC'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('ExceptionA'));
      await tester.takeException();

      await tester.tap(find.text('ExceptionB'));
      await tester.takeException();

      await tester.tap(find.text('ExceptionC'));
      await tester.takeException();

      expect(tOnErrorCalled, isTrue);
      FlutterError.onError = tOriginalOnError;
    });

    tApp.dispose();
  });

  testWidgets(
      'UnhandledError is handled by PlatformDispatcher. The LogLevel for UnhandledError is SEVERE or higher.',
      (WidgetTester tester) async {
    if (kIsWeb) {
      // PlatformDispatcher is not supported on the Web.
      return;
    }

    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
        printLog: true,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      // Check log levels processed within the App zone.
      final tStream = tApp.log.reports.asyncMap((event) => event.level);
      expectLater(
        tStream,
        emitsInOrder([
          Level.SHOUT,
          Level.SEVERE,
          Level.SEVERE,
          Level.SEVERE,
        ]),
      );

      // Since PlatformDispatcher is not called during tests, call it directly.

      tester.binding.platformDispatcher.onError?.call(
        TestPatapataException(
          onReported: (_) {},
          logLevel: Level.SHOUT,
        ),
        StackTrace.empty,
      );
      tester.binding.platformDispatcher.onError?.call(
        TestPatapataException(
          onReported: (_) {},
          logLevel: Level.INFO,
        ),
        StackTrace.empty,
      );
      // If logLevel is null, it is processed as Level.SEVERE in App zone.
      tester.binding.platformDispatcher.onError?.call(
        TestPatapataException(
          onReported: (_) {},
          logLevel: null,
        ),
        StackTrace.empty,
      );
      // If it is not a PatapataException, it is handled as Level.SEVERE in the App zone.
      tester.binding.platformDispatcher.onError?.call(
        'not PatapataException',
        StackTrace.empty,
      );
    });

    tApp.dispose();
  });

  testWidgets('RemoteConfig LogLevel test.', (WidgetTester tester) async {
    final Map<String, Object> tStore = {};
    final tMockRemoteConfig = MockRemoteConfig(tStore);

    final App tApp = createApp(plugins: [
      Plugin.inline(
        createRemoteConfig: () => tMockRemoteConfig,
      ),
    ]);

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tMockRemoteConfig.setInt('patapata_log_level', 111);
      await tMockRemoteConfig.fetch(force: true);

      expect(tApp.log.level.value, equals(111));
    });

    tApp.dispose();
  });

  testWidgets('RemoteConfig levelFilter test.', (WidgetTester tester) async {
    final Map<String, Object> tStore = {};
    final tMockRemoteConfig = MockRemoteConfig(tStore);

    final App tApp = createApp(plugins: [
      Plugin.inline(
        createRemoteConfig: () => tMockRemoteConfig,
      ),
    ]);

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tMockRemoteConfig.setString(Log.kRemoteConfigLevelFilters,
          '{"info":888, "severe":1111, "fine":500}');
      await tMockRemoteConfig.fetch(force: true);

      final tReportInfo = ReportRecord(level: Level.INFO, message: 'info');
      final tReportSever = ReportRecord(level: Level.INFO, message: 'severe');
      final tReportInfoToFine =
          ReportRecord(level: Level.INFO, message: 'fine');

      final tInfo = tApp.log.filter(tReportInfo);
      final tSever = tApp.log.filter(tReportSever);
      final tInfoToFine = tApp.log.filter(tReportInfoToFine);
      expect(tInfo?.level.value, equals(888));
      expect(tSever?.level.value, equals(1111));
      expect(tInfoToFine?.level, equals(Level.FINE));

      final tReportObjectInfo =
          ReportRecord(level: Level.INFO, message: 'test', error: 'info');
      final tReportErrorInfo =
          ReportRecord(level: Level.INFO, message: 'test', object: 'info');

      final tObjectInfo = tApp.log.filter(tReportObjectInfo);
      final tErrorInfo = tApp.log.filter(tReportErrorInfo);
      expect(tObjectInfo?.level.value, equals(888));
      expect(tErrorInfo?.level.value, equals(888));
    });

    tApp.dispose();
  });

  testWidgets('RemoteConfig levelFilter parsing failed.',
      (WidgetTester tester) async {
    final tOriginalDebugPrint = debugPrint;

    bool tPrintParsingError = false;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message?.contains('RemoteConfig ${Log.kRemoteConfigLevelFilters}') ==
          true) {
        tPrintParsingError = true;
      }
    };

    final Map<String, Object> tStore = {};
    final tMockRemoteConfig = MockRemoteConfig(tStore);

    final App tApp = createApp(plugins: [
      Plugin.inline(
        createRemoteConfig: () => tMockRemoteConfig,
      ),
    ]);

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      tApp.log.logPrinting = true;

      await tMockRemoteConfig.setString(
          Log.kRemoteConfigLevelFilters, '{"info":888,');
      await tMockRemoteConfig.fetch(force: true);
    });

    expect(tPrintParsingError, isTrue);

    tApp.dispose();

    debugPrint = tOriginalDebugPrint;
  });

  testWidgets('Logger large message print', (WidgetTester tester) async {
    // '[SEVERE] test.log: ' + 1007bytes = 1026bytes
    const tLargeMessageA =
        'testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttestEND';
    // '[SEVERE] test.log: ' + 1006bytes = 1025bytes
    const tLargeMessageB =
        'testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesあいう';

    final tOriginalDebugPrint = debugPrint;
    final List<String> tPrintMessage = [];
    debugPrint = (String? message, {int? wrapWidth}) {
      tPrintMessage.add(message!);
    };

    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.SEVERE.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      _logger.severe(tLargeMessageA);

      expect(tPrintMessage.length, equals(2));
      expect(tPrintMessage[0].length, equals(1023));
      expect(tPrintMessage[1], equals('END'));

      tPrintMessage.clear();

      _logger.severe(tLargeMessageB);
      expect(tPrintMessage.length, equals(2));
      expect(tPrintMessage[0].length, equals(1022));
      expect(tPrintMessage[1], equals('あいう'));
    });

    tApp.dispose();

    debugPrint = tOriginalDebugPrint;
  });

  test('NativeThrowble for Android.', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final tThrowableMap = {
      'type': 'java.lang.AAA',
      'message': 'throwbleA',
      'stackTrace': [
        'java.lang.Integer.parseInt(Integer.java:797)',
        'java.lang.Integer.parseInt(Integer.java:915)',
        'dev.patapata.patapata_core_example.MainActivity.configureFlutterEngine\$lambda-1\$lambda-0(MainActivity.kt:27)',
        'dev.patapata.patapata_core_example.MainActivity.\$r8\$lambda\$mgziiATvBKRngKgviCJADp8PLSA(Unknown Source:0)',
        'dev.patapata.patapata_core_example.MainActivity\$\$ExternalSyntheticLambda0.onMethodCall(Unknown Source:2)',
        'io.flutter.plugin.common.MethodChannel\$IncomingMethodCallHandler.onMessage(MethodChannel.java:258)',
        'io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:295)',
        'io.flutter.embedding.engine.dart.DartMessenger.lambda\$dispatchMessageToQueue\$0\$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:322)',
        'io.flutter.embedding.engine.dart.DartMessenger\$\$ExternalSyntheticLambda0.run(Unknown Source:12)',
        'android.os.Handler.handleCallback(Handler.java:942)',
        'android.os.Handler.dispatchMessage(Handler.java:99)',
        'android.os.Looper.loopOnce(Looper.java:346)',
        'android.os.Looper.loop(Looper.java:475)',
        'android.app.ActivityThread.main(ActivityThread.java:7950)',
        'java.lang.reflect.Method.invoke(Native Method)',
        'com.android.internal.os.RuntimeInit\$MethodAndArgsCaller.run(RuntimeInit.java:548)',
        'com.android.internal.os.ZygoteInit.main(ZygoteInit.java:942)',
      ],
      'cause': {
        'type': 'java.lang.BBB',
        'message': 'throwbleB',
        'stackTrace': [
          'java.lang.Integer.parseInt(Integer.java:4)',
          'java.lang.Integer.parseInt(Integer.java:5)',
          'dev.patapata.patapata_core_example.MainActivity.test(MainActivity.kt:6)',
        ],
        'cause': null,
      },
    };
    final tExpectTraces = [
      Trace(
        [
          Frame(
            Uri.file('java.lang/Integer.java'),
            797,
            null,
            'Integer.parseInt',
          ),
          Frame(
            Uri.file('java.lang/Integer.java'),
            915,
            null,
            'Integer.parseInt',
          ),
          Frame(
            Uri.file('dev.patapata.patapata_core_example/MainActivity.kt'),
            27,
            null,
            'MainActivity.configureFlutterEngine\$lambda-1\$lambda-0',
          ),
          Frame(
            Uri.file('dev.patapata.patapata_core_example/Unknown<space>Source'),
            0,
            null,
            'MainActivity.\$r8\$lambda\$mgziiATvBKRngKgviCJADp8PLSA',
          ),
          Frame(
            Uri.file('dev.patapata.patapata_core_example/Unknown<space>Source'),
            2,
            null,
            'MainActivity\$\$ExternalSyntheticLambda0.onMethodCall',
          ),
          Frame(
            Uri.file('io.flutter.plugin.common/MethodChannel.java'),
            258,
            null,
            'MethodChannel\$IncomingMethodCallHandler.onMessage',
          ),
          Frame(
            Uri.file('io.flutter.embedding.engine.dart/DartMessenger.java'),
            295,
            null,
            'DartMessenger.invokeHandler',
          ),
          Frame(
            Uri.file('io.flutter.embedding.engine.dart/DartMessenger.java'),
            322,
            null,
            'DartMessenger.lambda\$dispatchMessageToQueue\$0\$io-flutter-embedding-engine-dart-DartMessenger',
          ),
          Frame(
            Uri.file('io.flutter.embedding.engine.dart/Unknown<space>Source'),
            12,
            null,
            'DartMessenger\$\$ExternalSyntheticLambda0.run',
          ),
          Frame(
            Uri.file('android.os/Handler.java'),
            942,
            null,
            'Handler.handleCallback',
          ),
          Frame(
            Uri.file('android.os/Handler.java'),
            99,
            null,
            'Handler.dispatchMessage',
          ),
          Frame(
            Uri.file('android.os/Looper.java'),
            346,
            null,
            'Looper.loopOnce',
          ),
          Frame(
            Uri.file('android.os/Looper.java'),
            475,
            null,
            'Looper.loop',
          ),
          Frame(
            Uri.file('android.app/ActivityThread.java'),
            7950,
            null,
            'ActivityThread.main',
          ),
          Frame(
            Uri.file('java.lang.reflect/Native<space>Method'),
            null,
            null,
            'Method.invoke',
          ),
          Frame(
            Uri.file('com.android.internal.os/RuntimeInit.java'),
            548,
            null,
            'RuntimeInit\$MethodAndArgsCaller.run',
          ),
          Frame(
            Uri.file('com.android.internal.os/ZygoteInit.java'),
            942,
            null,
            'ZygoteInit.main',
          ),
        ],
      ),
      Trace(
        [
          Frame(
            Uri.file('java.lang/Integer.java'),
            4,
            null,
            'Integer.parseInt',
          ),
          Frame(
            Uri.file('java.lang/Integer.java'),
            5,
            null,
            'Integer.parseInt',
          ),
          Frame(
            Uri.file('dev.patapata.patapata_core_example/MainActivity.kt'),
            6,
            null,
            'MainActivity.test',
          ),
        ],
      ),
    ];
    final tTestNativeThrowable = NativeThrowable.fromMap(tThrowableMap);
    final tTestCause = tTestNativeThrowable.cause!;
    expect(tTestNativeThrowable.type, equals('java.lang.AAA'));
    expect(tTestNativeThrowable.message, equals('throwbleA'));
    expect(tTestCause.type, equals('java.lang.BBB'));
    expect(tTestCause.message, equals('throwbleB'));
    expect(tTestCause.cause, isNull);

    expect(tTestNativeThrowable.chain!.traces.length, equals(2));
    int tTraceIndex = 0;
    for (var traces in tTestNativeThrowable.chain!.traces) {
      int tFrameIndex = 0;
      for (var frame in traces.frames) {
        final tExpectFrame = tExpectTraces[tTraceIndex].frames[tFrameIndex];
        expect(frame.uri, equals(tExpectFrame.uri));
        expect(frame.line, equals(tExpectFrame.line));
        expect(frame.column, equals(tExpectFrame.column));
        expect(frame.member, equals(tExpectFrame.member));
        tFrameIndex++;
      }
      tTraceIndex++;
    }

    expect(tTestCause.chain!.traces.length, equals(1));
    int tFrameIndex = 0;
    for (var frame in tTestCause.chain!.traces.first.frames) {
      final tExpectFrame = tExpectTraces[1].frames[tFrameIndex];
      expect(frame.uri, equals(tExpectFrame.uri));
      expect(frame.line, equals(tExpectFrame.line));
      expect(frame.column, equals(tExpectFrame.column));
      expect(frame.member, equals(tExpectFrame.member));
      tFrameIndex++;
    }
    tTraceIndex++;

    expect(tTestNativeThrowable.toMap(), equals(tThrowableMap));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Native logging level map.', (WidgetTester tester) async {
    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.ALL.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      // Mock Native logging.
      const tChannelName = 'patapata/test/log';
      const tChannel = MethodChannel(tChannelName);
      Future<void> fNativeLogging(Map<String, Object?> arguments) async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          tChannelName,
          tChannel.codec.encodeMethodCall(
            MethodCall(
              'logging',
              arguments,
            ),
          ),
          (data) {},
        );
      }

      NativeThrowable.registerNativeThrowableMethodChannel(tChannelName);

      final tNativeLoggerLevelMap = {
        0: Level('EMERGENCY', Level.SHOUT.value),
        1: Level('ALERT', Level.SHOUT.value - 10),
        2: Level('CRITICAL', Level.SHOUT.value - 20),
        3: Level('ERROR', Level.SEVERE.value),
        4: Level.WARNING,
        5: Level('NOTICE', Level.INFO.value + 10),
        6: Level.INFO,
        7: Level('DEBUG', Level.FINE.value),
      };

      final tStream = tApp.log.reports.asyncMap((event) => event.level.value);
      expectLater(
        tStream,
        emitsInOrder([
          Level.INFO.value,
          tNativeLoggerLevelMap[0]!.value,
          tNativeLoggerLevelMap[1]!.value,
          tNativeLoggerLevelMap[2]!.value,
          tNativeLoggerLevelMap[3]!.value,
          tNativeLoggerLevelMap[4]!.value,
          tNativeLoggerLevelMap[5]!.value,
          tNativeLoggerLevelMap[6]!.value,
          tNativeLoggerLevelMap[7]!.value,
        ]),
      );

      // default level
      await fNativeLogging({
        'message': 'LogMessage',
      });

      // level map
      for (var entry in tNativeLoggerLevelMap.entries) {
        await fNativeLogging({
          'level': entry.key,
          'message': 'LogMessage',
        });
      }

      NativeThrowable.unregisterNativeThrowableMethodChannel(tChannelName);
    });

    tApp.dispose();
  });

  testWidgets('Native logging for Android.', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.ALL.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      // Mock Native logging.
      const tChannelName = 'patapata/test/log';
      const tChannel = MethodChannel(tChannelName);
      Future<void> fNativeLogging(Map<String, Object?> arguments) async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          tChannelName,
          tChannel.codec.encodeMethodCall(
            MethodCall(
              'logging',
              arguments,
            ),
          ),
          (data) {},
        );
      }

      NativeThrowable.registerNativeThrowableMethodChannel(tChannelName);

      final tThrowableMap = {
        'type': 'java.lang.AAA',
        'message': 'throwbleA',
        'stackTrace': [
          'java.lang.Integer.parseInt(Integer.java:797)',
          'java.lang.Integer.parseInt(Integer.java:915)',
          'dev.patapata.patapata_core_example.MainActivity.configureFlutterEngine\$lambda-1\$lambda-0(MainActivity.kt:27)',
          'dev.patapata.patapata_core_example.MainActivity.\$r8\$lambda\$mgziiATvBKRngKgviCJADp8PLSA(Unknown Source:0)',
          'dev.patapata.patapata_core_example.MainActivity\$\$ExternalSyntheticLambda0.onMethodCall(Unknown Source:2)',
          'io.flutter.plugin.common.MethodChannel\$IncomingMethodCallHandler.onMessage(MethodChannel.java:258)',
          'io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:295)',
          'io.flutter.embedding.engine.dart.DartMessenger.lambda\$dispatchMessageToQueue\$0\$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:322)',
          'io.flutter.embedding.engine.dart.DartMessenger\$\$ExternalSyntheticLambda0.run(Unknown Source:12)',
          'android.os.Handler.handleCallback(Handler.java:942)',
          'android.os.Handler.dispatchMessage(Handler.java:99)',
          'android.os.Looper.loopOnce(Looper.java:346)',
          'android.os.Looper.loop(Looper.java:475)',
          'android.app.ActivityThread.main(ActivityThread.java:7950)',
          'java.lang.reflect.Method.invoke(Native Method)',
          'com.android.internal.os.RuntimeInit\$MethodAndArgsCaller.run(RuntimeInit.java:548)',
          'com.android.internal.os.ZygoteInit.main(ZygoteInit.java:942)',
        ],
        'cause': {
          'type': 'java.lang.BBB',
          'message': 'throwbleB',
          'stackTrace': [
            'java.lang.Integer.parseInt(Integer.java:4)',
            'java.lang.Integer.parseInt(Integer.java:5)',
            'dev.patapata.patapata_core_example.MainActivity.test(MainActivity.kt:6)',
          ],
          'cause': null,
        },
      };

      var tStream = tApp.log.reports.first;

      await fNativeLogging({
        'level': 6,
        'message': 'LogMessage',
        'metadata': '{"foo": "bar"}',
        'timestamp': 1701930530000,
        'throwable': tThrowableMap,
      });

      var tReport = await tStream;

      expect(tReport.level, equals(Level.INFO));
      expect(tReport.message, equals('LogMessage'));
      expect(tReport.extra, equals({'foo': 'bar'}));
      expect(tReport.time.millisecondsSinceEpoch, equals(1701930530000));
      expect(tReport.object, isNull);
      expect(tReport.error, isA<NativeThrowable>());
      expect((tReport.error as NativeThrowable).toMap(), equals(tThrowableMap));
      expect(
          tReport.stackTrace, equals((tReport.error as NativeThrowable).chain));

      NativeThrowable.unregisterNativeThrowableMethodChannel(tChannelName);
    });

    tApp.dispose();

    debugDefaultTargetPlatformOverride = null;
  });

  test('NativeThrowble for iOS.', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final tThrowableMap = {
      'type': 'ErrorType',
      'message': 'throwbleA',
      'stackTrace': [
        '1 Runner 0x0000000000000000 \$s6Runner12NativeLoggerC14viewControllerACSo011FlutterViewE0C_tcfcySo0F10MethodCallC_yypSgctcACcfu_yAH_yAIctcfu0_ + 72',
        '2 Runner 0x0000000000000000 \$sSo17FlutterMethodCallCypSgIegn_Ieggg_AByXlSgIeyBy_IeyByy_TR + 136',
        '3 Flutter 0x0000000000000000 __45-[FlutterMethodChannel setMethodCallHandler:]_block_invoke + 172',
        '4 Flutter 0x0000000000000000 ___ZN7flutter25PlatformMessageHandlerIos21HandlePlatformMessageENSt21_LIBCPP_ABI_NAMESPACE10unique_ptrINS_15PlatformMessageENS1_14default_deleteIS3_EEEE_block_invoke + 116',
        '5 libdispatch.dylib 0x0000000000000000 959CD6E4-0CE7-3022-B73C-8B36F79F4745 + 7172',
        '6 libdispatch.dylib 0x0000000000000000 959CD6E4-0CE7-3022-B73C-8B36F79F4745 + 14672',
        '7 libdispatch.dylib 0x0000000000000000 _dispatch_main_queue_callback_4CF + 940',
        '8 CoreFoundation 0x0000000000000000 6174789A-E88C-3F5C-BA39-DE2E9EDC0750 + 335076',
        '9 CoreFoundation 0x0000000000000000 6174789A-E88C-3F5C-BA39-DE2E9EDC0750 + 48828',
        '10 CoreFoundation 0x0000000000000000 CFRunLoopRunSpecific + 600',
        '11 GraphicsServices 0x0000000000000000 GSEventRunModal + 164',
        '12 UIKitCore 0x0000000000000000 0E2D8679-D5F1-3C03-9010-7F6CE3662789 + 5353660',
        '13 UIKitCore 0x0000000000000000 UIApplicationMain + 2124',
        '14 Runner 0x0000000000000000 main + 64',
        '15 dyld 0x0000000000000000 start + 520',
      ],
      'cause': null,
    };
    final tExpectTrace = Trace(
      [
        Frame(
          Uri.file('Runner/<NoFileName>'),
          72,
          null,
          '\$s6Runner12NativeLoggerC14viewControllerACSo011FlutterViewE0C_tcfcySo0F10MethodCallC_yypSgctcACcfu_yAH_yAIctcfu0_',
        ),
        Frame(
          Uri.file('Runner/<NoFileName>'),
          136,
          null,
          '\$sSo17FlutterMethodCallCypSgIegn_Ieggg_AByXlSgIeyBy_IeyByy_TR',
        ),
        Frame(
          Uri.file('Flutter/<NoFileName>'),
          172,
          null,
          '__45-[FlutterMethodChannel setMethodCallHandler:]_block_invoke',
        ),
        Frame(
          Uri.file('Flutter/<NoFileName>'),
          116,
          null,
          '___ZN7flutter25PlatformMessageHandlerIos21HandlePlatformMessageENSt21_LIBCPP_ABI_NAMESPACE10unique_ptrINS_15PlatformMessageENS1_14default_deleteIS3_EEEE_block_invoke',
        ),
        Frame(
          Uri.file('libdispatch.dylib/<NoFileName>'),
          7172,
          null,
          '959CD6E4-0CE7-3022-B73C-8B36F79F4745',
        ),
        Frame(
          Uri.file('libdispatch.dylib/<NoFileName>'),
          14672,
          null,
          '959CD6E4-0CE7-3022-B73C-8B36F79F4745',
        ),
        Frame(
          Uri.file('libdispatch.dylib/<NoFileName>'),
          940,
          null,
          '_dispatch_main_queue_callback_4CF',
        ),
        Frame(
          Uri.file('CoreFoundation/<NoFileName>'),
          335076,
          null,
          '6174789A-E88C-3F5C-BA39-DE2E9EDC0750',
        ),
        Frame(
          Uri.file('CoreFoundation/<NoFileName>'),
          48828,
          null,
          '6174789A-E88C-3F5C-BA39-DE2E9EDC0750',
        ),
        Frame(
          Uri.file('CoreFoundation/<NoFileName>'),
          600,
          null,
          'CFRunLoopRunSpecific',
        ),
        Frame(
          Uri.file('GraphicsServices/<NoFileName>'),
          164,
          null,
          'GSEventRunModal',
        ),
        Frame(
          Uri.file('UIKitCore/<NoFileName>'),
          5353660,
          null,
          '0E2D8679-D5F1-3C03-9010-7F6CE3662789',
        ),
        Frame(
          Uri.file('UIKitCore/<NoFileName>'),
          2124,
          null,
          'UIApplicationMain',
        ),
        Frame(
          Uri.file('Runner/<NoFileName>'),
          64,
          null,
          'main',
        ),
        Frame(
          Uri.file('dyld/<NoFileName>'),
          520,
          null,
          'start',
        ),
      ],
    );
    final tTestNativeThrowable = NativeThrowable.fromMap(tThrowableMap);
    expect(tTestNativeThrowable.type, equals('ErrorType'));
    expect(tTestNativeThrowable.message, equals('throwbleA'));
    expect(tTestNativeThrowable.cause, isNull);

    expect(tTestNativeThrowable.chain!.traces.length, equals(1));
    int tFrameIndex = 0;
    for (var frame in tTestNativeThrowable.chain!.traces.first.frames) {
      final tExpectFrame = tExpectTrace.frames[tFrameIndex];
      expect(frame.uri, equals(tExpectFrame.uri));
      expect(frame.line, equals(tExpectFrame.line));
      expect(frame.column, equals(tExpectFrame.column));
      expect(frame.member, equals(tExpectFrame.member));
      tFrameIndex++;
    }

    expect(tTestNativeThrowable.toMap(), equals(tThrowableMap));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Native logging for iOS.', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final App tApp = createApp(
      environment: TestLogEnvironment(
        logLevel: Level.ALL.value,
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      // Mock Native logging.
      const tChannelName = 'patapata/test/log';
      const tChannel = MethodChannel(tChannelName);
      late DateTime tTimestamp;
      Future<void> fNativeLogging(Map<String, Object?> arguments) async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          tChannelName,
          tChannel.codec.encodeMethodCall(
            MethodCall(
              'logging',
              arguments,
            ),
          ),
          (data) {
            tTimestamp = DateTime.now();
          },
        );
      }

      NativeThrowable.registerNativeThrowableMethodChannel(tChannelName);

      final tThrowableMap = {
        'type': 'ErrorType',
        'message': 'throwbleA',
        'stackTrace': [
          '1 Runner 0x0000000000000000 \$s6Runner12NativeLoggerC14viewControllerACSo011FlutterViewE0C_tcfcySo0F10MethodCallC_yypSgctcACcfu_yAH_yAIctcfu0_ + 72',
          '2 Runner 0x0000000000000000 \$sSo17FlutterMethodCallCypSgIegn_Ieggg_AByXlSgIeyBy_IeyByy_TR + 136',
          '3 Flutter 0x0000000000000000 __45-[FlutterMethodChannel setMethodCallHandler:]_block_invoke + 172',
          '4 Flutter 0x0000000000000000 ___ZN7flutter25PlatformMessageHandlerIos21HandlePlatformMessageENSt21_LIBCPP_ABI_NAMESPACE10unique_ptrINS_15PlatformMessageENS1_14default_deleteIS3_EEEE_block_invoke + 116',
          '5 libdispatch.dylib 0x0000000000000000 959CD6E4-0CE7-3022-B73C-8B36F79F4745 + 7172',
          '6 libdispatch.dylib 0x0000000000000000 959CD6E4-0CE7-3022-B73C-8B36F79F4745 + 14672',
          '7 libdispatch.dylib 0x0000000000000000 _dispatch_main_queue_callback_4CF + 940',
          '8 CoreFoundation 0x0000000000000000 6174789A-E88C-3F5C-BA39-DE2E9EDC0750 + 335076',
          '9 CoreFoundation 0x0000000000000000 6174789A-E88C-3F5C-BA39-DE2E9EDC0750 + 48828',
          '10 CoreFoundation 0x0000000000000000 CFRunLoopRunSpecific + 600',
          '11 GraphicsServices 0x0000000000000000 GSEventRunModal + 164',
          '12 UIKitCore 0x0000000000000000 0E2D8679-D5F1-3C03-9010-7F6CE3662789 + 5353660',
          '13 UIKitCore 0x0000000000000000 UIApplicationMain + 2124',
          '14 Runner 0x0000000000000000 main + 64',
          '15 dyld 0x0000000000000000 start + 520',
        ],
        'cause': null,
      };

      var tStream = tApp.log.reports.first;

      await fNativeLogging({
        'level': 6,
        'message': 'LogMessage',
        'metadata': '{"foo": "bar"}',
        'throwable': tThrowableMap,
      });

      var tReport = await tStream;

      expect(tReport.level, equals(Level.INFO));
      expect(tReport.message, equals('LogMessage'));
      expect(tReport.extra, equals({'foo': 'bar'}));
      expect(DateFormat('yyyyMMdd').format(tReport.time),
          equals(DateFormat('yyyyMMdd').format(tTimestamp)));
      expect(tReport.object, isNull);
      expect(tReport.error, isA<NativeThrowable>());
      expect((tReport.error as NativeThrowable).toMap(), equals(tThrowableMap));
      expect(
          tReport.stackTrace, equals((tReport.error as NativeThrowable).chain));

      NativeThrowable.unregisterNativeThrowableMethodChannel(tChannelName);
    });

    tApp.dispose();

    debugDefaultTargetPlatformOverride = null;
  });

  test('NativeThrowble unsupported platform.', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    final tThrowableMap = {
      'type': 'java.lang.AAA',
      'message': 'throwbleA',
      'stackTrace': [
        'java.lang.Integer.parseInt(Integer.java:4)',
      ],
      'cause': null,
    };
    final tExpectFrame =
        Frame.parseFriendly('java.lang.Integer.parseInt(Integer.java:4)');

    final tTestNativeThrowable = NativeThrowable.fromMap(tThrowableMap);

    expect(tTestNativeThrowable.type, equals('java.lang.AAA'));
    expect(tTestNativeThrowable.message, equals('throwbleA'));
    expect(tTestNativeThrowable.cause, isNull);
    expect(tTestNativeThrowable.chain!.traces.length, equals(1));
    expect(tTestNativeThrowable.chain!.traces.first.frames.first.toString(),
        equals(tExpectFrame.toString()));
    expect(
      tTestNativeThrowable.toMap(),
      equals({
        'type': 'java.lang.AAA',
        'message': 'throwbleA',
        'stackTrace': [
          tExpectFrame.toString(),
        ],
        'cause': null,
      }),
    );

    debugDefaultTargetPlatformOverride = null;
  });

  test('NativeThrowble stackTrace parse error.', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final tThrowableMap = {
      'type': 'java.lang.AAA',
      'message': 'throwbleA',
      'stackTrace': [
        'aaa',
      ],
      'cause': null,
    };
    final tExpectFrame = Frame.parseFriendly('aaa');

    final tTestNativeThrowable = NativeThrowable.fromMap(tThrowableMap);

    expect(tTestNativeThrowable.type, equals('java.lang.AAA'));
    expect(tTestNativeThrowable.message, equals('throwbleA'));
    expect(tTestNativeThrowable.cause, isNull);
    expect(tTestNativeThrowable.chain!.traces.length, equals(1));
    expect(tTestNativeThrowable.chain!.traces.first.frames.first.toString(),
        equals(tExpectFrame.toString()));
    expect(
      tTestNativeThrowable.toMap(),
      equals({
        'type': 'java.lang.AAA',
        'message': 'throwbleA',
        'stackTrace': [
          tExpectFrame.toString(),
        ],
        'cause': null,
      }),
    );

    debugDefaultTargetPlatformOverride = null;
  });
}
