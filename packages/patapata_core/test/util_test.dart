// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'utils/patapata_core_test_utils.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'A SequentialWorkQueue can add a work item and it will execute',
    () async {
      final tQueue = SequentialWorkQueue();
      int tValue = 0;

      await tQueue.add<void>(() {
        tValue = 1;
      });

      expect(
        tValue,
        equals(1),
      );
    },
  );

  test(
      'A SequentialWorkQueue can add multiple work items and they will all execute in order',
      () async {
    final tQueue = SequentialWorkQueue();
    String tValue = '';

    tQueue.add<void>(() {
      tValue += '0';
    });

    tQueue.add<void>(() {
      tValue += '1';
    });

    await tQueue.add<void>(() {
      tValue += '2';
    });

    expect(
      tValue,
      equals('012'),
    );
  });

  test(
      'A SequentialWorkQueue completes all work\'s futures successfully, no matter the actual work\'s result',
      () async {
    final tQueue = SequentialWorkQueue();
    String tValue = '';
    List<Future<void>> tFutures = [];

    tFutures.add(tQueue.add<void>(() {
      tValue += '0';
    }));

    tFutures.add(tQueue.add<void>(() async {
      throw Error();
    }).catchError((error) => null));

    tFutures.add(tQueue.add<void>(() {
      tValue += '2';
    }));

    await Future.wait(tFutures);

    expect(
      tValue,
      equals('02'),
    );
  });

  test('A SequentialWorkQueue can have work added to it even inside other work',
      () async {
    final tQueue = SequentialWorkQueue();
    String tValue = '';
    List<Future<void>> tFutures = [];

    tFutures.add(tQueue.add<void>(() {
      tValue += '0';

      tFutures.add(tQueue.add<void>(() {
        tValue += '1';
      }));
    }));

    tFutures.add(tQueue.add<void>(() {
      tFutures.add(tQueue.add<void>(() {
        tValue += '2';
      }));

      tValue += '3';
    }));

    while (tFutures.isNotEmpty) {
      final tFuturesCopy = tFutures.toList();
      tFutures.clear();
      await Future.wait(tFuturesCopy);
    }

    expect(
      tValue,
      equals('0132'),
    );
  });

  test(
    'A SequentialWorkQueue can be cleared, cancelling all current work that can be cancelled',
    () async {
      // No async.
      var tQueue = SequentialWorkQueue();
      List<Future<void>> tFutures = [];
      String tValue = '';

      tFutures.add(tQueue.add<void>(() {
        tValue += '0';
      }, onCancel: () => true));

      tQueue.clear();

      tFutures.add(tQueue.add<void>(() {
        tValue += '1';
      }, onCancel: () => true));

      while (tFutures.isNotEmpty) {
        final tFuturesCopy = tFutures.toList();
        tFutures.clear();
        await Future.wait(tFuturesCopy);
      }

      expect(
        tValue,
        equals('01'),
        reason: 'No async',
      );

      // Async cancelled
      tQueue = SequentialWorkQueue();
      tFutures.clear();
      tValue = '';

      tFutures.add(tQueue.add<void>(() async {
        await Future.microtask(() => null);
        tValue += '0';
      }, onCancel: () async => await Future.microtask(() => true)));

      tQueue.clear();

      tFutures.add(tQueue.add<void>(() {
        tValue += '1';
      }, onCancel: () async => true));

      while (tFutures.isNotEmpty) {
        final tFuturesCopy = tFutures.toList();
        tFutures.clear();
        await Future.wait(tFuturesCopy);
      }

      expect(
        tValue,
        equals('1'),
        reason: 'Async cancelled',
      );

      // Async cancelled multiple times
      tQueue = SequentialWorkQueue();
      tFutures.clear();
      tValue = '';

      tFutures.add(tQueue.add<void>(() async {
        await Future.microtask(() => null);
        tValue += '0';
      }, onCancel: () async => await Future.microtask(() => true)));

      tFutures.add(tQueue.add<void>(() async {
        await Future.microtask(() => null);
        tValue += '0';
      }, onCancel: () async => await Future.microtask(() => true)));

      tQueue.clear();

      tFutures.add(tQueue.add<void>(() async {
        await Future.microtask(() => null);
        tValue += '0';
      }, onCancel: () async => await Future.microtask(() => true)));

      tQueue.clear();

      tFutures.add(tQueue.add<void>(() {
        tValue += '1';
      }, onCancel: () async => true));

      while (tFutures.isNotEmpty) {
        final tFuturesCopy = tFutures.toList();
        tFutures.clear();
        await Future.wait(tFuturesCopy);
      }

      expect(
        tValue,
        equals('1'),
        reason: 'Async cancelled',
      );

      // Async no cancel
      tQueue = SequentialWorkQueue();
      tFutures.clear();
      tValue = '';

      tFutures.add(tQueue.add<void>(() async {
        await Future.microtask(() => null);
        tValue += '0';
      }, onCancel: () async => await Future.microtask(() => false)));

      tQueue.clear();

      tFutures.add(tQueue.add<void>(() {
        tValue += '1';
      }, onCancel: () async => true));

      while (tFutures.isNotEmpty) {
        final tFuturesCopy = tFutures.toList();
        tFutures.clear();
        await Future.wait(tFuturesCopy);
      }

      expect(
        tValue,
        equals('01'),
        reason: 'Async no cancel',
      );
    },
  );

  test(
      'typeIs should return true if the type of List<T> is List<S> with the same type',
      () {
    expect(typeIs<int, int>(), isTrue);
    expect(typeIs<String, String>(), isTrue);
  });

  test(
      'typeIs should return false if the type of List<T> is List<S> with different types',
      () {
    expect(typeIs<int, String>(), isFalse);
    expect(typeIs<String, int>(), isFalse);
  });

  test(
    'now should return the current DateTime',
    () {
      final tNow = now.toUTCIso8601StringNoMSUS();
      final tCurrentDateTime = DateTime.now().toUTCIso8601StringNoMSUS();

      expect(
        tNow,
        equals(tCurrentDateTime),
      );
    },
    // In the case of low probability failure, perform several retries.
    retry: 5,
  );

  test(
    'platformCompute test',
    () async {
      const int tData = 5;

      final tResult = await platformCompute<int, int>(
        (input) => input * 2,
        tData,
      );

      expect(tResult, 10);
    },
  );

  test(
    'platformCompute throw exception test',
    () async {
      const int tTestData = 5;

      Future<void> testFunction() async {
        await platformCompute<int, int>(
          (input) async => throw Exception('error'),
          tTestData,
        );
      }

      // Assert check
      expect(testFunction, throwsException);
    },
  );

  testWidgets(
    'scheduleFunction should schedule the provided function to be executed after the next frame if frames are enabled',
    (WidgetTester tester) async {
      bool tExecuted = false;
      bool tPostFrameCallbackCalled = false;
      onPostFrameCallback = () {
        tPostFrameCallbackCalled = true;
      };

      scheduleFunction(() {
        tExecuted = true;
      });

      // Test that tExecuted is false before pumping.
      expect(tExecuted, false);

      await tester.pump();

      expect(tExecuted, true);
      expect(tPostFrameCallbackCalled, isTrue);
    },
  );
  group('timezone test group', () {
    late tz.Location tOriginalTimeZone;
    setUp(() {
      tz.initializeTimeZones();
      tOriginalTimeZone = tz.local;
    });
    tearDown(() {
      tz.setLocalLocation(tOriginalTimeZone);
    });
    test('toUTCIso8601StringNoMSUS should return the date in ISO8601 format',
        () {
      // I want to test changes from a time zone other than UTC, so I will test with the time zone set to Asia/Tokyo.
      final tz.Location tTimeZone = tz.getLocation('Asia/Tokyo');

      tz.TZDateTime tDateTime = tz.TZDateTime(tTimeZone, 2022, 1, 1, 12, 0, 0);
      expect("2022-01-01T03:00:00Z", tDateTime.toUTCIso8601StringNoMSUS());

      tDateTime = tz.TZDateTime(tTimeZone, 12345, 7, 9, 3, 15, 0, 0);
      expect("012345-07-08T18:15:00Z", tDateTime.toUTCIso8601StringNoMSUS());

      tDateTime = tz.TZDateTime(tTimeZone, 2022, 1, 1, 12, 0, 0);
      expect("2022-01-01T03:00:00Z", tDateTime.toUTCIso8601StringNoMSUS());
    });
  });

  testWidgets("DateTime fake time test", (WidgetTester tester) async {
    // Create an instance of the App before calling the setFakeNow function,
    // as setFakeNow internally invokes getApp().
    final App tApp = createApp(
      appWidget: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      final Stream<DateTime?> tEventStream = fakeNowStream;
      DateTime? tFakeNow;

      var tFutureFakeNow = expectLater(
        tEventStream.asyncMap(
          (dateTime) => dateTime?.toUTCIso8601StringNoMSUS(),
        ),
        emitsInOrder([null]),
      );

      setFakeNow(tFakeNow);

      // expect fake test
      await tFutureFakeNow;
      expect(fakeNowSet, false);

      tFakeNow = DateTime(2022, 1, 1, 12, 0, 0, 0, 0);

      tFutureFakeNow = expectLater(
        tEventStream.asyncMap(
          (dateTime) => dateTime?.toUTCIso8601StringNoMSUS(),
        ),
        emitsInOrder([tFakeNow.toUTCIso8601StringNoMSUS()]),
      );

      setFakeNow(tFakeNow);

      await tester.pumpAndSettle();

      // expect fake test
      await tFutureFakeNow;
      expect(fakeNowSet, true);
      expect(now, tFakeNow);

      tFakeNow = DateTime(2022, 1, 1, 14, 0, 0, 0, 0);

      tFutureFakeNow = expectLater(
        tEventStream.asyncMap(
          (dateTime) => dateTime?.toUTCIso8601StringNoMSUS(),
        ),
        emitsInOrder([tFakeNow.toUTCIso8601StringNoMSUS()]),
      );

      int tBeforeMicroseconds = !kIsWeb ? now.microsecondsSinceEpoch : 0;

      setFakeNow(tFakeNow, elapse: true);

      await tester.pumpAndSettle();

      int tAfterMicroseconds = !kIsWeb ? now.microsecondsSinceEpoch : 0;

      if (!kIsWeb) {
        expect(tAfterMicroseconds, isNot(tBeforeMicroseconds));
      }

      tApp.dispose();
    });
  });

  testWidgets("DateTime load fake now test", (WidgetTester tester) async {
    // Create an instance of the App before calling the setFakeNow function,
    // as setFakeNow internally invokes getApp().
    final tDateTimeNow =
        DateTime(2022, 1, 1, 14, 0, 0, 0, 0).toUTCIso8601StringNoMSUS();

    final App tApp = createApp(
      appWidget: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
      plugins: [
        Plugin.inline(
          createLocalConfig: () => MockLocalConfig({
            'patapataFakeNow': tDateTimeNow,
          }),
        ),
      ],
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(now.toUTCIso8601StringNoMSUS(), tDateTimeNow);
    });

    tApp.dispose();
  });
}
