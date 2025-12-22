// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/src/exception.dart';

void main() {
  test('A new machine should be in the first state after instantiation.', () {
    expect(
      LogicStateMachine([
        LogicStateFactory<StateA>(() => StateA(), []),
      ]).current,
      isInstanceOf<StateA>(),
    );
  });

  test('LogicStateMachine.toString', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);
    tMachine.current.onComplete.ignore();

    expect(
      tMachine.toString(),
      'LogicStateMachine: complete=false, error=null, current=${tMachine.current.runtimeType}: initialized=true, active=true',
    );

    tMachine.current.complete();

    expect(
      tMachine.toString(),
      'LogicStateMachine: complete=true, error=null, current=${tMachine.current.runtimeType}: initialized=true, active=false',
    );
  });

  test('A state can transition to another instance of itself', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateA>(),
      ]),
    ]);

    final tFirstInstance = tMachine.current;
    tMachine.current.complete();

    expect(tMachine.current, isInstanceOf<StateA>());

    expect(tMachine.current, isNot(equals(tFirstInstance)));
  });

  test('A machine should be complete when the last state completes', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);

    tMachine.current.complete();

    expect(tMachine.current, isInstanceOf<LogicStateComplete>());

    expect(tMachine.complete, isTrue);
  });

  test(
    'A LogicStateTransitionNotFound should be thrown when a state class in a transition is attempted to transition to, where that state does not exist in the machine',
    () {
      final tMachine = LogicStateMachine([
        LogicStateFactory<StateA>(() => StateA(), [
          LogicStateTransition<StateB>(),
        ]),
      ]);

      expect(
        () => tMachine.current.complete(),
        throwsA(isA<LogicStateTransitionNotFound>()),
      );
    },
  );

  test('A state can transition to another state', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);

    tMachine.current.complete();

    expect(tMachine.current, isInstanceOf<StateB>());
  });

  test('A state can transition to another state, and then another', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateC>(() => StateC(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), [
        LogicStateTransition<StateC>(),
      ]),
    ]);

    tMachine.current.complete();
    tMachine.current.complete();

    expect(tMachine.current, isInstanceOf<StateC>());
  });

  test('A state can fail to transition via delegate failure', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(
          ((LogicState current, LogicState next) => false),
        ),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);

    expect(
      () => tMachine.current.complete(),
      throwsA(isA<LogicStateAllTransitionsNotAllowed>()),
    );
  });

  test('LogicStateAllTransitionsNotAllowed.toString', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(
          ((LogicState current, LogicState next) => false),
        ),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);

    late LogicStateAllTransitionsNotAllowed tError;
    try {
      tMachine.current.complete();
    } catch (e) {
      tError = e as LogicStateAllTransitionsNotAllowed;
    }

    expect(
      tError.toString(),
      equals(
        'LogicStateAllTransitionsNotAllowed: ${tError.current.toString()} is not allowed to transition to anything.',
      ),
    );
  });

  test('A new machine must have at least one state.', () {
    expect(() => LogicStateMachine([]), throwsAssertionError);
  });

  test('A state can transition itself to a specific other state', () {
    expect(
      LogicStateMachine([
        LogicStateFactory<StateXToA>(() => StateXToA(), [
          LogicStateTransition<StateB>(),
          LogicStateTransition<StateA>(),
        ]),
        LogicStateFactory<StateB>(() => StateB(), []),
        LogicStateFactory<StateA>(() => StateA(), []),
      ]).current,
      isInstanceOf<StateA>(),
    );
  });

  test('A state can not transition if it is not the current state', () {
    expect(
      () => LogicStateMachine([
        LogicStateFactory<StateXToAThenB>(() => StateXToAThenB(), [
          LogicStateTransition<StateB>(),
          LogicStateTransition<StateA>(),
        ]),
        LogicStateFactory<StateB>(() => StateB(), []),
        LogicStateFactory<StateA>(() => StateA(), []),
      ]).current,
      throwsA(isA<LogicStateNotCurrent>()),
    );
  });

  test('LogicStateNotCurrent.toString', () {
    late final LogicStateNotCurrent tError;
    try {
      LogicStateMachine([
        LogicStateFactory<StateXToAThenB>(() => StateXToAThenB(), [
          LogicStateTransition<StateB>(),
          LogicStateTransition<StateA>(),
        ]),
        LogicStateFactory<StateB>(() => StateB(), []),
        LogicStateFactory<StateA>(() => StateA(), []),
      ]).current;
    } catch (e) {
      tError = e as LogicStateNotCurrent;
    }

    expect(
      tError.toString(),
      equals(
        'LogicStateNotCurrent: ${tError.current.toString()} is not current.',
      ),
    );
  });

  testWidgets(
    'A state can asynchronously transition itself to itself',
    (tester) async {
      final tMachine = LogicStateMachine([
        LogicStateFactory<StateZToZAsync>(() => StateZToZAsync(), [
          LogicStateTransition<StateInstantComplete>(),
          LogicStateTransition<StateZToZAsync>(),
        ]),
        LogicStateFactory<StateInstantComplete>(
          () => StateInstantComplete(),
          [],
        ),
      ], 0);

      await tester.pump(const Duration(milliseconds: 5));

      expect(tMachine.complete, isTrue);
    },
    timeout: const Timeout(Duration(milliseconds: 10)),
  );

  test('A machine notifies on completion', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);

    bool cComplete = false;
    tMachine.addListener(() {
      cComplete = tMachine.complete;
    });
    tMachine.current.complete();

    expect(cComplete, isTrue);
  });

  test('complete. not current state', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);

    tMachine.current.onComplete.ignore();
    final tState = tMachine.current;
    tMachine.current.complete();

    expect(() => tState.complete(), throwsA(isA<LogicStateNotCurrent>()));
  });

  test('Transitions to the state of Type.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);

    tMachine.current.toByType(StateB);

    expect(tMachine.current, isInstanceOf<StateB>());
  });

  test('Transitions to the state of Type. not current state.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);

    final tState = tMachine.current;
    tMachine.current.toByType(StateB);

    expect(() => tState.toByType(StateA), throwsA(isA<LogicStateNotCurrent>()));
  });

  test('Transitions to the state of Type. Transition not found.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);
    tMachine.current.onComplete.ignore();
    tMachine.current.toByType(StateC);

    expect(tMachine.error?.error, isInstanceOf<LogicStateTransitionNotFound>());
  });

  test('Transitions to the state of Type. Factory not found.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateC>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);
    tMachine.current.onComplete.ignore();
    tMachine.current.toByType(StateC);

    expect(tMachine.error?.error, isInstanceOf<LogicStateTransitionNotFound>());
  });

  test('Transitions to the state of Type. not allowed.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(
          (LogicState current, LogicState next) => false,
        ),
      ]),
      LogicStateFactory<StateB>(() => StateB(), []),
    ]);
    tMachine.current.onComplete.ignore();
    tMachine.current.toByType(StateB);

    expect(
      tMachine.error?.error,
      isInstanceOf<LogicStateTransitionNotAllowed>(),
    );

    final tError = tMachine.error?.error as LogicStateTransitionNotAllowed;
    expect(
      tError.toString(),
      equals(
        'LogicStateTransitionNotAllowed: ${tError.current.toString()} is not allowed to transition to ${tError.next.toString()}.',
      ),
    );
  });

  test('A machine notifies on failed completion', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);

    Object? cError;
    tMachine.addListener(() {
      cError = tMachine.error?.error;
    });
    tMachine.current.onComplete.ignore();
    tMachine.current.completeError('FakeError');

    expect(cError, equals('FakeError'));
  });

  test('completeError. not current state', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);

    tMachine.current.onComplete.ignore();
    final tState = tMachine.current;
    tMachine.current.completeError('FakeError');

    expect(
      () => tState.completeError('FakeError'),
      throwsA(isA<LogicStateNotCurrent>()),
    );
  });

  test('A state can transition to back state if allowed.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA()..backAllowed = true, [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), [
        LogicStateTransition<StateBackA>(),
      ]),
      LogicStateFactory<StateBackA>(() => StateBackA(), []),
    ]);
    tMachine.current.complete();
    tMachine.current.complete();

    expect(tMachine.current, isInstanceOf<StateA>());
  });

  test('A state can not transition to back state', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), [
        LogicStateTransition<StateBackA>(),
      ]),
      LogicStateFactory<StateBackA>(() => StateBackA(), []),
    ]);
    tMachine.current.complete();
    tMachine.current.complete();

    expect(tMachine.error?.error, isInstanceOf<LogicStateTransitionNotFound>());
  });

  test('backByType. not current state.', () {
    final tMachine = LogicStateMachine([
      LogicStateFactory<StateA>(() => StateA(), [
        LogicStateTransition<StateB>(),
      ]),
      LogicStateFactory<StateB>(() => StateB(), [
        LogicStateTransition<StateA>(),
      ]),
      LogicStateFactory<StateA>(() => StateA(), []),
    ]);
    tMachine.current.complete();
    final tState = tMachine.current;
    tMachine.current.complete();

    expect(
      () => tState.backByType(StateA),
      throwsA(isA<LogicStateNotCurrent>()),
    );
  });

  test('LogicStateTransitionNotFound test', () {
    // If const is added, test coverage will not be 100%.
    // ignore: prefer_const_constructors
    final tError = LogicStateTransitionNotFound();

    expect(tError.code, equals(PatapataCoreExceptionCode.PPE101.name));
  });
}

class StateA extends LogicState {}

class StateB extends LogicState {}

class StateC extends LogicState {}

class StateXToA extends LogicState {
  @override
  void init(Object? data) {
    super.init(data);
    to<StateA>();
  }
}

class StateXToAThenB extends LogicState {
  @override
  void init(Object? data) {
    super.init(data);
    to<StateA>();
    to<StateB>();
  }
}

class StateZToZAsync extends LogicState {
  @override
  void init(Object? data) async {
    super.init(data);
    final tCounter = data as int;

    if (tCounter == 3) {
      complete();
    } else {
      await Future.delayed(const Duration(milliseconds: 1));
      to<StateZToZAsync>(tCounter + 1);
    }
  }
}

class StateInstantComplete extends LogicState {
  @override
  void init(Object? data) {
    super.init(data);
    complete();
  }
}

class StateBackA extends LogicState {
  @override
  void init(Object? data) {
    super.init(data);
    onComplete.ignore();
    backByType(StateA);
  }
}
