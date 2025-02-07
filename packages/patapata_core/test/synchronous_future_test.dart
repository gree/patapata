import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/src/synchronous_future.dart';

void main() {
  group('SynchronousErrorableFuture', () {
    test('should complete with value synchronously', () async {
      final tFuture = SynchronousErrorableFuture<int>(42);
      await expectLater(tFuture, completion(42));
    });

    test('should complete with error synchronously', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');
      await expectLater(tFuture, throwsA('error message'));
    });

    test('then() should transform value correctly', () async {
      final tFuture = SynchronousErrorableFuture<int>(42);
      final tResult = tFuture.then((value) => value * 2);
      await expectLater(tResult, completion(84));
    });

    test('then() should propagate error', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');
      final tResult = tFuture.then((value) => value * 2);
      await expectLater(tResult, throwsA('error message'));
    });

    test('then() should call onError if error occurs', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');
      final tResult = tFuture.then(
        (value) => value * 2,
        onError: (error) {
          expect(error, 'error message');
          return 99;
        },
      );
      await expectLater(tResult, completion(99));
    });

    test(
        'then() should call onError with error and stackTrace. StackTrace is empty.',
        () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');

      final tResult = tFuture.then(
        (value) => value * 2,
        onError: (error, stackTrace) {
          expect(error, 'error message');
          expect(stackTrace, StackTrace.empty);
          return 99;
        },
      );

      await expectLater(tResult, completion(99));
    });

    test('then() should call onError with error and stackTrace', () async {
      final tStackTrace = StackTrace.current;
      final tFuture =
          SynchronousErrorableFuture<int>.error('error message', tStackTrace);

      final tResult = tFuture.then(
        (value) => value * 2,
        onError: (error, stackTrace) {
          expect(error, 'error message');
          expect(stackTrace, tStackTrace);
          return 99;
        },
      );

      await expectLater(tResult, completion(99));
    });

    test('then() should throw error if onError type is incorrect', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');

      final tResult = tFuture.then(
        (value) => value * 2,
        onError: (int x) => 99,
      );

      expect(tResult, throwsA(isA<ArgumentError>()));
    });

    test('catchError() should handle error and recover', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message')
          .catchError((error) => 99);
      await expectLater(tFuture, completion(99));
    });

    test('catchError() should not modify value if no error', () async {
      final tFuture =
          SynchronousErrorableFuture<int>(42).catchError((error) => 99);
      await expectLater(tFuture, completion(42));
    });

    test('catchError() should handle error when test returns true', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');

      final tResult = tFuture.catchError(
        (error) => 99,
        test: (error) => true,
      );

      await expectLater(tResult, completion(99));
    });

    test('catchError() should not handle error when test returns false',
        () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message');

      final tResult = tFuture.catchError(
        (error) => 99,
        test: (error) => false,
      );

      await expectLater(tResult, throwsA('error message'));
    });

    test('asStream() should return stream with one value', () async {
      final tFuture = SynchronousErrorableFuture<int>(42);
      final tStream = tFuture.asStream();
      expect(await tStream.first, 42);
    });

    test('timeout() should return the original value immediately', () async {
      final tFuture = SynchronousErrorableFuture<int>(42)
          .timeout(Duration.zero, onTimeout: () => 99);
      await expectLater(tFuture, completion(42));
    });

    test('timeout() should not trigger onTimeout', () async {
      bool tOnTimeoutCalled = false;
      final tFuture = SynchronousErrorableFuture<int>(42).timeout(Duration.zero,
          onTimeout: () {
        tOnTimeoutCalled = true;
        return 99;
      });

      await expectLater(tFuture, completion(42));
      expect(tOnTimeoutCalled, isFalse,
          reason: 'SynchronousErrorableFuture は同期的に値を返すため onTimeout は発火しない');
    });

    test('timeout() should return the original error immediately', () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message')
          .timeout(Duration.zero, onTimeout: () => 99);
      await expectLater(tFuture, throwsA('error message'));
    });

    test('wait() should resolve multiple synchronous futures', () async {
      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        SynchronousErrorableFuture<int>(2),
        SynchronousErrorableFuture<int>(3),
      ];
      final tResult = SynchronousErrorableFuture.wait(tFutures);
      await expectLater(tResult, completion([1, 2, 3]));
    });

    test('wait() should resolve mixed synchronous and asynchronous futures',
        () async {
      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        Future<int>.delayed(Duration.zero, () => 2),
        SynchronousErrorableFuture<int>(3),
      ];
      final tResult = SynchronousErrorableFuture.wait(tFutures);
      await expectLater(tResult, completion([1, 2, 3]));
    });

    test('wait() should handle synchronous errors', () async {
      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        SynchronousErrorableFuture<int>.error('error message'),
        SynchronousErrorableFuture<int>(3),
      ];
      final tResult = SynchronousErrorableFuture.wait(tFutures);
      await expectLater(tResult, throwsA('error message'));
    });

    test('wait() should handle asynchronous errors', () async {
      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        Future<int>.delayed(Duration.zero, () => throw 'error message'),
        SynchronousErrorableFuture<int>(3),
      ];
      final tResult = SynchronousErrorableFuture.wait(tFutures);
      await expectLater(tResult, throwsA('error message'));
    });

    test(
        'wait() should handle asynchronous errors. Mixed synchronous and asynchronous futures',
        () async {
      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        Future<int>.delayed(Duration.zero, () => 2),
        Future<int>.delayed(Duration.zero, () => throw 'error message'),
        SynchronousErrorableFuture<int>.error('error message'),
        SynchronousErrorableFuture<int>(3),
      ];
      final tResult = SynchronousErrorableFuture.wait(tFutures);
      await expectLater(tResult, throwsA('error message'));
    });

    test('wait() should handle empty list', () async {
      final tResult = SynchronousErrorableFuture.wait([]);
      await expectLater(tResult, completion(isEmpty));
    });

    test('wait() should respect eagerError flag', () async {
      final tFutures = [
        Future<int>.delayed(const Duration(milliseconds: 10), () => 1),
        Future<int>.delayed(
            const Duration(milliseconds: 5), () => throw 'error'),
        Future<int>.delayed(const Duration(milliseconds: 20), () => 3),
      ];
      final tResult =
          SynchronousErrorableFuture.wait(tFutures, eagerError: true);
      await expectLater(tResult, throwsA('error'));
    });

    test('wait() should execute whenComplete after all futures resolve',
        () async {
      bool tCompleted = false;

      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        SynchronousErrorableFuture<int>(2),
        SynchronousErrorableFuture<int>(3),
      ];

      final tResult =
          SynchronousErrorableFuture.wait(tFutures).whenComplete(() {
        tCompleted = true;
      });

      await expectLater(tResult, completion([1, 2, 3]));
      expect(tCompleted, isTrue);
    });

    test('wait() should execute whenComplete even if error occurs', () async {
      bool tCompleted = false;

      final tFutures = [
        SynchronousErrorableFuture<int>(1),
        SynchronousErrorableFuture<int>.error('error message'),
        SynchronousErrorableFuture<int>(3),
      ];

      final tResult =
          SynchronousErrorableFuture.wait(tFutures).whenComplete(() {
        tCompleted = true;
      });

      await expectLater(tResult, throwsA('error message'));
      expect(tCompleted, isTrue);
    });

    test('whenComplete() should execute action and return value', () async {
      bool tCompleted = false;
      final tFuture = SynchronousErrorableFuture<int>(42).whenComplete(() {
        tCompleted = true;
      });

      await expectLater(tFuture, completion(42));
      expect(tCompleted, isTrue);
    });

    test('whenComplete() should execute action and return Future', () async {
      bool tCompleted = false;
      final tFuture =
          SynchronousErrorableFuture<int>(42).whenComplete(() async {
        tCompleted = true;
      }).then((value) {
        return value * 2;
      });

      await expectLater(tFuture, completion(84));
      expect(tCompleted, isTrue);
    });

    test('whenComplete() should execute action and propagate error', () async {
      bool tCompleted = false;
      final tFuture = SynchronousErrorableFuture<int>.error('error message')
          .whenComplete(() {
        tCompleted = true;
      });

      await expectLater(tFuture, throwsA('error message'));
      expect(tCompleted, isTrue,
          reason: 'エラーが発生しても whenComplete() のアクションは実行されるべき');
    });

    test('whenComplete() should replace future error if action throws an error',
        () async {
      final tFuture = SynchronousErrorableFuture<int>(42).whenComplete(() {
        throw 'new error';
      });

      await expectLater(tFuture, throwsA('new error'));
    });

    test(
        'whenComplete() should propagate original error if action does not throw',
        () async {
      final tFuture = SynchronousErrorableFuture<int>.error('error message')
          .whenComplete(() {
        // ここではエラーを発生させない
      });

      await expectLater(tFuture, throwsA('error message'));
    });

    test(
        'whenComplete() should propagate action error even if original was error',
        () async {
      final tFuture = SynchronousErrorableFuture<int>.error('original error')
          .whenComplete(() {
        throw 'new error';
      });

      await expectLater(tFuture, throwsA('new error'));
    });
  });

  group('SynchronousErrorableFuture. Test to verify synchronous behavior', () {
    test('should return value synchronously in then()', () {
      bool tThenCalled = false;
      final tFuture = SynchronousErrorableFuture<int>(42);

      tFuture.then((value) {
        tThenCalled = true;
      });

      expect(tThenCalled, isTrue, reason: 'then() が同期的に呼ばれるべき');
    });

    test('Future.value should not return synchronously in then()', () {
      bool tThenCalled = false;
      final tFuture = Future.value(42);

      tFuture.then((value) {
        tThenCalled = true;
      });

      expect(tThenCalled, isFalse, reason: '通常の Future は非同期的に then() を実行する');
    });

    test('should return error synchronously in catchError()', () {
      bool tErrorCaught = false;
      final tFuture = SynchronousErrorableFuture<int>.error('error');

      tFuture.catchError((error) {
        tErrorCaught = true;
        return 0;
      });

      expect(tErrorCaught, isTrue, reason: 'catchError() が同期的に実行されるべき');
    });

    test('Future.error should not return synchronously in catchError()', () {
      bool tErrorCaught = false;
      final tFuture = Future<int>.error('error');

      tFuture.catchError((error) {
        tErrorCaught = true;
        return 0;
      });

      expect(tErrorCaught, isFalse,
          reason: '通常の Future は非同期的に catchError() を実行する');
    });
  });
}
