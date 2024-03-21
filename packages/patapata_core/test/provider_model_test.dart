// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

void main() {
  test('You can create a ProviderModel and access all of it\'s variables', () {
    expect(
      () => _A()
        ..intVariable.unsafeValue
        ..stringVariable.unsafeValue
        ..mapVariable.unsafeValue,
      returnsNormally,
    );
  });

  test('You can access correct data from a variable', () {
    expect(
      _A().intVariable.unsafeValue,
      equals(_kIntValue),
    );
  });

  test('You can access correct data from a variable when a Map', () {
    expect(
      _A().mapVariable.unsafeValue,
      equals(_kMapValue),
    );
  });

  test('You can get the type of a ProviderModelVariable', () {
    final tA = _A();
    expect(tA.intVariable.type, equals(int));
  });

  test('You can begin a batch', () {
    final tA = _A();
    final tBatch = tA.begin(tA.keyA);
    tBatch.commit();
  });

  test('You can begin a batch when another batch is active with the same key',
      () {
    final tA = _A();
    tA.begin(tA.keyA);
    expect(() => tA.begin(tA.keyA), returnsNormally);
  });

  test(
      'You can begin a batch when another batch is active with a different key',
      () {
    final tA = _A();
    tA.begin(tA.keyA);
    expect(() => tA.begin(tA.keyB), returnsNormally);
  });

  test('You can begin a batch, and set values with it', () {
    final tA = _A();
    final tBatch = tA.begin(tA.keyA);
    tBatch.set(tA.intVariable, 2);
    expect(tBatch.get(tA.intVariable), equals(2));
    expect(tA.intVariable.unsafeValue, equals(_kIntValue));
    tBatch.commit();
    expect(tA.intVariable.unsafeValue, equals(2));
    expect(tBatch.completed, isTrue);
    expect(tBatch.valid, isTrue);
  });

  test('You can cancel a batch', () {
    final tA = _A();
    final tBatch = tA.begin(tA.keyA);
    tBatch.set(tA.intVariable, 2);
    expect(tBatch.get(tA.intVariable), equals(2));
    expect(tA.intVariable.unsafeValue, equals(_kIntValue));
    tBatch.cancel();
    expect(tA.intVariable.unsafeValue, _kIntValue);
    expect(tBatch.completed, isTrue);
    expect(tBatch.valid, isFalse);
  });

  test('When you commit a batch, listeners get notified', () {
    final tA = _A();

    tA.addListener(expectAsync0(() {}, count: 1));

    final tBatch = tA.begin(tA.keyA);
    tBatch.set(tA.intVariable, 2);
    tBatch.commit();
  });

  test('You can cancel a batch, and noone gets notified', () {
    final tA = _A();

    tA.addListener(expectAsync0(() {}, count: 0));

    final tBatch = tA.begin(tA.keyA);
    tBatch.set(tA.intVariable, 2);
    tBatch.cancel();
  });

  test('When you commit a batch with no notify, listeners do not get notified',
      () {
    final tA = _A();

    tA.addListener(expectAsync0(() {}, count: 0));

    final tBatch = tA.begin(tA.keyA);
    tBatch.set(tA.intVariable, 2);
    tBatch.commit(notify: false);
  });

  test('You can begin multiple batches and the last comitted one wins', () {
    final tA = _A();
    final tBA = tA.begin(tA.keyA);
    final tBB = tA.begin(tA.keyB);

    tBA.set(tA.intVariable, 3);
    tBB.set(tA.intVariable, 4);

    tBB.commit();
    tBA.commit();

    expect(tA.intVariable.unsafeValue, equals(3));
  });

  test('You can lock for a batch', () async {
    final tA = _A();
    expect(
      await tA.lock((batch) => batch.commit()),
      equals(true),
    );
  });

  test(
      'You can lock for a batch and the result will be true when the batch is not commited',
      () async {
    final tA = _A();
    expect(
      await tA.lock((batch) {}),
      equals(true),
    );
  });

  test('You can lock for a batch and will return false on batch cancel',
      () async {
    final tA = _A();
    expect(
      await tA.lock((batch) => batch.cancel()),
      equals(false),
    );
  });

  test('You can lock for a batch, and set values with it', () async {
    final tA = _A();

    expect(
      await tA.lock((batch) {
        batch.set(tA.intVariable, 2);
        expect(batch.get(tA.intVariable), equals(2));
        expect(tA.intVariable.unsafeValue, equals(_kIntValue));
        batch.commit();
      }),
      equals(true),
    );

    expect(tA.intVariable.unsafeValue, equals(2));
  });

  test(
      'You can not begin a batch when another locked batch is active with the same key',
      () async {
    final tA = _A();
    tA.lock((batch) async => Future.microtask(() => null));

    try {
      tA.begin();
    } catch (error) {
      expect(error, isA<ConflictException>());
      expect(
          error.toString(), startsWith('ConflictException: _A(BatchLockKey'));
    }

    tA.lock((batch) async => Future.microtask(() => null), lockKey: tA.keyA);

    try {
      tA.begin(tA.keyA);
    } catch (error) {
      expect(error, isA<ConflictException>());
      expect(error.toString(), startsWith('ConflictException: _A(keyA'));
      expect(error.toString(), endsWith('Custom Conflict Reason'));
    }
  });

  test(
      'You can begin a batch when another locked batch is active with a different key',
      () async {
    final tA = _A();
    tA.lock(
      (batch) async => Future.microtask(() => null),
      lockKey: tA.keyA,
    );
    expect(() => tA.begin(tA.keyB), returnsNormally);
  });

  test(
      'You can lock multiple times, but will wait and execute in order when using the same key',
      () async {
    final tA = _A();
    final tFA = tA.lock((batch) {
      batch.set(tA.intVariable, 4);
      batch.commit();
    });

    final tFB = tA.lock((batch) {
      batch.set(tA.intVariable, 5);
      batch.commit();
    });

    final tFC = tA.lock((batch) {
      batch.set(tA.intVariable, 6);
      batch.commit();
    });

    await Future.wait([tFA, tFB, tFC]);

    expect(tA.intVariable.unsafeValue, equals(6));
  });

  test('If a lock throws, other awaiting locks will execute normally',
      () async {
    final tA = _A();

    tA.lock((batch) {
      batch.set(tA.intVariable, 4);
      batch.commit();
    });

    tA.lock((batch) async {
      throw Error();
    }).catchError((error) => false);

    final tFC = tA.lock((batch) {
      batch.set(tA.intVariable, 6);
      batch.commit();
    });

    await tFC;

    expect(tA.intVariable.unsafeValue, equals(6));
  });

  test(
      'You can have two locks, with various override and overridable settings.',
      () async {
    const tInputs = [
      [true, true, true, true],
      [false, true, true, true],
      [true, false, true, true],
      [false, false, true, true],
      //
      [true, true, false, true],
      [false, true, false, true],
      [true, false, false, true],
      [false, false, false, true],
      //
      [true, true, true, false],
      [false, true, true, false],
      [true, false, true, false],
      [false, false, true, false],
      //
      [true, true, false, false],
      [false, true, false, false],
      [true, false, false, false],
      [false, false, false, false],
    ];
    const tExpects = [
      [1, false, true, 'null1'],
      [1, false, true, 'null1'],
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      //
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      //
      [1, false, true, 'null1'],
      [1, false, true, 'null1'],
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      //
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
      [2, true, true, 'null01'],
    ];

    for (var i = 0; i < tInputs.length; i++) {
      final tInput = tInputs[i];
      final tExpect = tExpects[i];
      final tA = _A();
      tA.addListener(expectAsync0(() {}, count: tExpect[0] as int));

      final tResultA = tA.lock((batch) async {
        batch.set(tA.stringVariable, '${batch.get(tA.stringVariable)}0');
        await Future.microtask(() => null);
        batch.commit();
      }, override: tInput[0], overridable: tInput[1]);

      final tResultB = tA.lock((batch) async {
        batch.set(tA.stringVariable, '${batch.get(tA.stringVariable)}1');
        await Future.microtask(() => null);
        await Future.microtask(() => null);
        batch.commit();
      }, override: tInput[2], overridable: tInput[3]);

      expect(await tResultA, equals(tExpect[1] as bool));
      expect(await tResultB, equals(tExpect[2] as bool));
      expect(tA.stringVariable.unsafeValue, tExpect[3] as String);
    }
  });

  test('An overriden lock has a chance to revert its changes with onOverride.',
      () async {
    final tA = _A();

    var tValue = 0;

    tA.lock(
      (batch) {
        batch.set(tA.intVariable, 4);
        tValue = 1;
        batch.commit();
      },
      onOverride: () {
        tValue = 2;
      },
    );

    final tFC = tA.lock((batch) {
      batch.set(tA.intVariable, 6);
      batch.commit();
    }, override: true);

    await tFC;

    expect(tValue, equals(2));
    expect(tA.intVariable.unsafeValue, equals(6));
  });

  test(
      'An overriden lock has a chance to revert its changes with onOverride asynchronously.',
      () async {
    final tA = _A();

    var tValue = 0;

    tA.lock(
      (batch) {
        batch.set(tA.intVariable, 4);
        tValue = 1;
        batch.commit();
      },
      onOverride: () async {
        await Future.microtask(() => null);
        tValue = 2;
      },
    );

    final tFC = tA.lock((batch) {
      batch.set(tA.intVariable, 6);
      batch.commit();
    }, override: true);

    await tFC;

    expect(tValue, equals(2));
    expect(tA.intVariable.unsafeValue, equals(6));
  });

  test('You can override multiple times without anything locking up', () async {
    final tA = _A();

    var tValue = 0;

    for (var i = 0; i < 12; i++) {
      tA.lock(
        (batch) async {
          await batch.blockOverride(() =>
              Future.delayed(const Duration(milliseconds: 45), () => null));
          batch.set(tA.intVariable, 4);
          tValue = 1;
          batch.commit();
        },
        override: true,
        overridable: true,
      );
    }

    final tFC = tA.lock((batch) async {
      await batch.blockOverride(() => Future.microtask(() => null));
      batch.set(tA.intVariable, 6);
      batch.commit();
    }, override: true);

    await tFC;

    expect(tValue, equals(0));
    expect(tA.intVariable.unsafeValue, equals(6));
  });

  test('You can have a lock in a lock with a different key', () async {
    final tA = _A();
    expect(
      await tA.lock((batch) async {
        final tAS = _A();
        expect(
          await tAS.lock((batch) async {
            await Future.microtask(() => null);
            batch.commit();
          }, lockKey: tAS.keyB),
          equals(true),
        );
      }, lockKey: tA.keyA),
      equals(true),
    );
  });

  test('Listeners are notified when variables change', () {
    final tA = _A();

    tA.intVariable.addListener(expectAsync0(() {}, count: 1));
    tA.addListener(expectAsync0(() {}, count: 1));

    tA.begin()
      ..set(tA.intVariable, 10)
      ..commit();
  });

  test(
      'Listeners are not notified even when variables change if commit\'s notify is false',
      () {
    final tA = _A();

    tA.intVariable.addListener(expectAsync0(() {}, count: 0));
    tA.addListener(expectAsync0(() {}, count: 0));

    tA.begin()
      ..set(tA.intVariable, 10)
      ..commit(notify: false);
  });

  test(
      'Listeners are always notified even when variables do not change if commit\'s notify is true',
      () {
    final tA = _A();

    tA.intVariable.addListener(expectAsync0(() {}, count: 0));
    tA.addListener(expectAsync0(() {}, count: 0));

    tA.begin()
      ..set(tA.intVariable, tA.intVariable.unsafeValue)
      ..commit(notify: true);
  });

  test('A variable can be created unset', () {
    final tA = _A();
    expect(
      () => tA.customUnsetVariable.unsafeValue,
      throwsAssertionError,
    );
    expect(
      tA.customUnsetVariable.toString(),
      equals('_CustomType:NOT SET'),
    );
  });

  test('A variable can be created unset, but set later and accessed', () {
    final tA = _A();
    tA.begin()
      ..set(tA.customUnsetVariable, _CustomType())
      ..commit();
    expect(
      tA.customUnsetVariable.unsafeValue,
      isNotNull,
    );
    expect(
      tA.customUnsetVariable.toString(),
      equals('_CustomType:CustomType'),
    );
  });

  test(
      'A variable can be created unset or set, and checked in a batch to see if it is set',
      () async {
    final tA = _A();

    await tA.lock((batch) {
      expect(tA.customUnsetVariable.set, isFalse);
      expect(batch.isSet(tA.customUnsetVariable), isFalse);
      batch.set(tA.customUnsetVariable, _CustomType());
      expect(batch.isSet(tA.customUnsetVariable), isTrue);
      expect(tA.customUnsetVariable.set, isFalse);
      batch.commit();
      expect(tA.customUnsetVariable.set, isTrue);
    });
  });

  test('You can get the value asynchronously from a variable', () async {
    final tA = _A();

    expect(await tA.intVariable.getValue(), equals(_kIntValue));

    final tFuture = tA.lock((batch) async {
      await Future.delayed(const Duration(milliseconds: 1));
      batch.set(tA.intVariable, 3);
      await Future.delayed(const Duration(milliseconds: 1));
      batch.commit();
    });

    final tValueFuture = tA.intVariable.getValue();

    await tFuture;

    expect(await tValueFuture, equals(3));
  });

  test(
      'You can get the value asynchronously from a variable when multiple batches are ongoing',
      () async {
    final tA = _A();

    final tFutures = [
      tA.lock((batch) async {
        await Future.delayed(const Duration(milliseconds: 1));
        batch.set(tA.intVariable, batch.get(tA.intVariable) + 1);
        await Future.delayed(const Duration(milliseconds: 1));
        batch.commit();
      }),
      tA.lock((batch) async {
        await Future.delayed(const Duration(milliseconds: 1));
        batch.set(tA.intVariable, batch.get(tA.intVariable) + 1);
        await Future.delayed(const Duration(milliseconds: 1));
        batch.commit();
      }),
      tA.lock((batch) async {
        await Future.delayed(const Duration(milliseconds: 1));
        batch.set(tA.intVariable, batch.get(tA.intVariable) + 1);
        await Future.delayed(const Duration(milliseconds: 1));
        batch.commit();
      }),
    ];

    final tValueFuture = tA.intVariable.getValue();

    await Future.wait(tFutures);

    expect(await tValueFuture, equals(4));
  });

  test('Listeners are notified when an unset variable is set to the same value',
      () {
    final tA = _A();

    tA.stringUnsetVariable.addListener(expectAsync0(() {}, count: 1));
    tA.addListener(expectAsync0(() {}, count: 1));

    tA.begin()
      ..set(tA.stringUnsetVariable, null)
      ..commit();
  });

  test('A model can be disposed', () {
    final tA = _A();

    final tSubscription = tA.use((model) => model.ii);

    expect(() => tA.dispose(), returnsNormally);
    expect(tA.disposed, isTrue);
    expect(() => tA.begin(), throwsAssertionError);
    expect(() => tA.lock((_) {}), throwsAssertionError);
    expect(() => tA.use((_) {}), throwsAssertionError);

    expect(() => tSubscription.cancel(), returnsNormally);
  });

  test('A model can be disposed while a batch is running', () async {
    final tA = _A();

    final tLockFuture = tA.lock((batch) async {
      await Future.delayed(const Duration(milliseconds: 1));
      batch.commit();
    });

    expect(() => tA.dispose(), returnsNormally);
    expect(tA.disposed, isTrue);
    expect(await tA.intVariable.getValue(), _kIntValue);
    expect(await tLockFuture, isFalse);
  });

  test(
      'A value of a variable will return it\'s value immediately if a model was disposed of during a batch',
      () async {
    final tA = _A();

    final tLockFuture = tA.lock((batch) async {
      await Future.delayed(const Duration(milliseconds: 1));
      batch.set(tA.intVariable, 10);
      batch.commit();
    });

    final tValueFuture = tA.intVariable.getValue();

    final tLockFuture2 = tA.lock((batch) async {
      await Future.delayed(const Duration(milliseconds: 1));
      batch.set(tA.intVariable, 20);
      batch.commit();
    });

    expect(() => tA.dispose(), returnsNormally);
    expect(tA.disposed, isTrue);

    expect(await tValueFuture, _kIntValue);
    expect(await tLockFuture, isFalse);
    expect(await tLockFuture2, isFalse);
  });

  test('A model can be used', () async {
    final tA = _A();

    final tSubscription = tA.use(
      expectAsync1(
        (_A model) => model.ii,
        count: 3,
      ),
    );

    await tA.lock((batch) {
      batch.set(tA.intVariable, 2);
      batch.commit();
    });

    await tA.lock((batch) {
      batch.set(tA.intVariable, 3);
      batch.commit();
    });

    expect(tA.ii, equals(3));

    tSubscription.cancel();

    await tA.lock((batch) {
      batch.set(tA.intVariable, 4);
      batch.commit();
    });

    expect(tA.ii, equals(4));
  });

  test('A model can be used but the callback is called asynchronously',
      () async {
    final tA = _A();

    final tSubscription = tA.use(
      expectAsync1(
        (_A model) => model.ii,
        count: 2,
      ),
    );

    tA.begin()
      ..set(tA.intVariable, 2)
      ..commit();

    await tA.lock((batch) {
      batch.set(tA.intVariable, 3);
      batch.commit();
    });

    expect(tA.ii, equals(3));

    tSubscription.cancel();
  });

  test('use can not be called inside use', () async {
    final tA = _A();

    tA.use(
      (_A model) {
        expect(() => model.use((_A model) => model.ii), throwsAssertionError);
      },
    );
  });
}

const int _kIntValue = 1;
const String? _kStringNullValue = null;
const Map<String, Object?> _kMapValue = {};

class _A extends ProviderModel<_A> {
  late final intVariable = createVariable<int>(_kIntValue);
  late final stringVariable = createVariable<String?>(_kStringNullValue);
  late final mapVariable = createVariable<Map<String, Object?>>(_kMapValue);
  late final customVariable = createVariable<_CustomType>(_CustomType());
  late final customUnsetVariable = createUnsetVariable<_CustomType>();
  late final stringUnsetVariable = createUnsetVariable<String?>();

  int get ii => intVariable.unsafeValue;

  final keyA =
      ProviderLockKey('keyA', conflictReason: 'Custom Conflict Reason');
  final keyB = ProviderLockKey('keyB');
}

class _CustomType {
  @override
  String toString() => 'CustomType';
}
