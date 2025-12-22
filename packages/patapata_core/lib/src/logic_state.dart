// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'exception.dart';

/// Provides the functionality of a Finite State Machine.
///
/// The state machine holds multiple [LogicStateFactory] in a list.
/// At the creation of the machine, a [LogicState] is generated from the leading factory,
/// and the process starts.
///
/// When a [LogicState] completes, the machine fetches the list of [LogicStateTransition] from the
/// [LogicStateFactory] of that state and finds the factory of the next [LogicState] to
/// execute from the top of the list.
/// If the list is empty, [LogicStateMachine.complete] becomes true,
/// and [LogicStateMachine.current] becomes [LogicStateComplete].
///
/// example:
/// ```dart
/// LogicStateMachine(
///   [
///     LogicStateFactory<StateA>(
///       () => StateA(this),
///       [
///         LogicStateTransition<StateB>(),
///         LogicStateTransition<StateC>(),
///       ],
///     ),
///     LogicStateFactory<StateB>(
//       () => StateB(this),
///       [
///         LogicStateTransition<StateC>(),
///       ],
///     ),
///     LogicStateFactory<StateC>(
///       () => StateC(this),
///       [],
///     ),
///   ],
/// );
/// ```
class LogicStateMachine with ChangeNotifier {
  final List<LogicStateFactory> _factories;
  final List<({Type stateType, bool backAllowed})> _stateHistories = [];
  LogicState __currentState;
  LogicState get _currentState => __currentState;
  set _currentState(LogicState value) {
    _stateHistories.add((
      stateType: value.runtimeType,
      backAllowed: value.backAllowed,
    ));
    __currentState = value;
  }

  LogicStateFactory _currentFactory;

  /// Creates a new [LogicStateMachine].
  /// Starts processing immediately from the top of [factories] upon creation.
  LogicStateMachine(List<LogicStateFactory> factories, [Object? initialData])
    : assert(factories.isNotEmpty),
      _factories = factories,
      _currentFactory = factories.first,
      __currentState = factories.first.create() {
    _stateHistories.add((
      stateType: __currentState.runtimeType,
      backAllowed: __currentState.backAllowed,
    ));
    _initState(initialData);
  }

  /// The current state.
  ///
  /// If all states complete successfully, [LogicStateComplete] is set.
  ///
  /// If terminated due to a state error, [LogicStateError] is set.
  /// This is the same as what is retrieved by [error].
  LogicState get current => _currentState;

  bool _complete = false;

  /// Returns true if the machine's processing is complete.
  bool get complete => _complete;

  /// The error details when the machine terminates due to an error.
  LogicStateError? get error => (complete && _currentState is LogicStateError)
      ? _currentState as LogicStateError
      : null;

  void _initState([Object? initialData]) {
    final tState = _currentState;
    tState._machine = this;
    tState.init(initialData);
    assert(tState._initialized);
  }

  void _completeFinished() {
    _complete = true;
    _currentState = LogicStateComplete();
    _initState();
  }

  void _completeError(Object error, [StackTrace? stackTrace]) {
    _complete = true;
    _currentState = LogicStateError(error, stackTrace);
    _initState();
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  String toString() =>
      'LogicStateMachine: complete=$_complete, error=$error, current=$current';
}

/// Thrown when LogicStateTransition is not found.
class LogicStateTransitionNotFound extends PatapataCoreException {
  LogicStateTransitionNotFound()
    : super(code: PatapataCoreExceptionCode.PPE101);
}

/// Thrown when [current] is not allowed to transition to [next].
class LogicStateTransitionNotAllowed extends PatapataCoreException {
  final LogicState current;
  final LogicState next;

  LogicStateTransitionNotAllowed(this.current, this.next)
    : super(code: PatapataCoreExceptionCode.PPE102);

  @override
  String toString() =>
      'LogicStateTransitionNotAllowed: $current is not allowed to transition to $next.';
}

/// Thrown when [current] is not allowed to transition to anything.
class LogicStateAllTransitionsNotAllowed extends PatapataCoreException {
  final LogicState current;

  LogicStateAllTransitionsNotAllowed(this.current)
    : super(code: PatapataCoreExceptionCode.PPE103);

  @override
  String toString() =>
      'LogicStateAllTransitionsNotAllowed: $current is not allowed to transition to anything.';
}

/// Thrown when [current] is not current in [LogicStateMachine].
class LogicStateNotCurrent extends PatapataCoreException {
  final LogicState current;

  LogicStateNotCurrent(this.current)
    : super(code: PatapataCoreExceptionCode.PPE104);

  @override
  String toString() => 'LogicStateNotCurrent: $current is not current.';
}

typedef LogicStateCompleter = void Function();

/// The state to be executed in [LogicStateMachine].
abstract class LogicState {
  bool _initialized = false;
  late final LogicStateMachine _machine;
  late final _completer = Completer<void>();

  /// If true, allows going back via [backByType]. (default is false)
  bool backAllowed = false;

  /// Returns a Future that waits until the state is complete.
  Future<void> get onComplete => _completer.future;

  /// Completes the state and transitions to the next [LogicState].
  ///
  /// The next [LogicState] to transition to is found from the [LogicStateTransition] of the
  /// [LogicStateFactory] from which it was created.
  /// If the [LogicStateTransition] list is empty, the processing of [LogicStateMachine]
  /// will be completed.
  ///
  /// If [LogicStateTransition] exists but all are in a non-transitionable state
  /// (for example, if `predicate` returns false for all),
  /// [LogicStateAllTransitionsNotAllowed] will be thrown.
  ///
  /// [complete] and [completeError] can only be called once.
  void complete() {
    assert(_initialized);

    if (!this()) {
      throw LogicStateNotCurrent(this);
    }

    final tTransitions = _machine._currentFactory._transitions;
    LogicStateFactory? tNextFactory;
    LogicState? tNextState;

    for (var tTransition in tTransitions) {
      final tNextFactoryCandidate = _machine._factories.firstWhere(
        (v) => v.type == tTransition.nextType,
        orElse: () => throw LogicStateTransitionNotFound(),
      );
      final tNextStateCandidate = tNextFactoryCandidate.create();

      if (tTransition._predicate(this, tNextStateCandidate)) {
        tNextFactory = tNextFactoryCandidate;
        tNextState = tNextStateCandidate;

        break;
      }
    }

    if (tTransitions.isEmpty) {
      _complete();
      _machine._completeFinished();
    } else if (tNextFactory == null || tNextState == null) {
      throw LogicStateAllTransitionsNotAllowed(this);
    } else {
      _complete();
      _machine._currentFactory = tNextFactory;
      _machine._currentState = tNextState;
      _machine._initState();
    }
  }

  /// Completes the state with an error.
  /// It will not transition to the next [LogicState], and the
  /// [LogicStateMachine] will terminate as an error.
  ///
  /// [complete] and [completeError] can only be called once.
  void completeError(Object error, [StackTrace? stackTrace]) {
    assert(_initialized);

    if (!this()) {
      throw LogicStateNotCurrent(this);
    }

    _complete(error, stackTrace);
  }

  /// Goes back to a state that has already been executed,
  /// regardless of the value of its own [LogicStateTransition].
  ///
  /// If the target state's [backAllowed] is false, or if there's no history,
  /// it throws [LogicStateTransitionNotFound].
  void backByType(Type stateType, [Object? data]) {
    assert(_initialized);

    if (!this()) {
      throw LogicStateNotCurrent(this);
    }

    final tHistoryIndex = _machine._stateHistories.lastIndexWhere(
      (v) => v.stateType == stateType && v.backAllowed,
    );

    if (tHistoryIndex < 0) {
      _complete(LogicStateTransitionNotFound());
    } else {
      final tNextFactory = _machine._factories.firstWhereOrNull(
        (v) => v.type == stateType,
      );

      if (tNextFactory == null) {
        // This process will not be executed if the value of _machine._stateHistories is normal.
        _complete(LogicStateTransitionNotFound()); // coverage:ignore-line
      } else {
        final tNextState = tNextFactory.create();

        _complete();
        _machine._stateHistories.removeRange(
          tHistoryIndex,
          _machine._stateHistories.length,
        );
        _machine._currentFactory = tNextFactory;
        _machine._currentState = tNextState;
        _machine._initState(data);
      }
    }
  }

  /// Transitions to the state of [stateType].
  ///
  /// If the type of [stateType] does not exist in its own [LogicStateTransition],
  /// it throws [LogicStateTransitionNotFound].
  /// If it exists but cannot transition (for instance, if `predicate` returns false),
  /// it throws [LogicStateTransitionNotAllowed].
  ///
  /// [toByType] can only be called once. Also, [complete] will be executed automatically.
  void toByType(Type stateType, [Object? data]) {
    assert(_initialized);

    if (!this()) {
      throw LogicStateNotCurrent(this);
    }

    final tTransition = _machine._currentFactory._transitions.firstWhereOrNull(
      (v) => v.nextType == stateType,
    );

    if (tTransition == null) {
      _complete(LogicStateTransitionNotFound());
    } else {
      final tNextFactory = _machine._factories.firstWhereOrNull(
        (v) => v.type == stateType,
      );

      if (tNextFactory == null) {
        _complete(LogicStateTransitionNotFound());
      } else {
        final tNextState = tNextFactory.create();

        if (!tTransition._predicate(this, tNextState)) {
          _complete(
            LogicStateTransitionNotAllowed(
              this,
              tNextState.._machine = _machine,
            ),
          );
        } else {
          _complete();
          _machine._currentFactory = tNextFactory;
          _machine._currentState = tNextState;
          _machine._initState(data);
        }
      }
    }
  }

  /// Transitions to the state of type [T].
  ///
  /// If the type [T] does not exist in its own [LogicStateTransition],
  /// it throws [LogicStateTransitionNotFound].
  /// If it exists but cannot transition (for instance, if `predicate` returns false),
  /// it throws [LogicStateTransitionNotAllowed].
  ///
  /// [to] can only be called once. Also, [complete] will be executed automatically.
  void to<T extends LogicState>([Object? data]) {
    toByType(T, data);
  }

  void _complete([Object? error, StackTrace? stackTrace]) {
    try {
      dispose();
      final tHistoryIndex = _machine._stateHistories.lastIndexWhere(
        (e) => e.stateType == runtimeType,
      );
      if (tHistoryIndex >= 0) {
        _machine._stateHistories[tHistoryIndex] = (
          stateType: runtimeType,
          backAllowed: backAllowed,
        );
      }
    } finally {
      if (error != null) {
        _completer.completeError(error, stackTrace);
        _machine._completeError(error, stackTrace);
      } else {
        _completer.complete();
      }
    }
  }

  /// Returns true if [LogicStateMachine.current] is itself.
  @nonVirtual
  bool call() =>
      !_machine.complete &&
      !_completer.isCompleted &&
      _machine._currentState == this;

  /// Executed first when the state is created.
  @mustCallSuper
  void init(Object? data) {
    _initialized = true;
    _machine._notifyListeners();
  }

  /// Called when the state processing is completed.
  @mustCallSuper
  void dispose() {}

  @override
  String toString() =>
      '$runtimeType: initialized=$_initialized, active=${this()}';
}

/// Factory for [LogicState].
class LogicStateFactory<T extends LogicState> {
  /// Creates a new [LogicState].
  final T Function() create;
  final List<LogicStateTransition<LogicState>> _transitions;

  /// Returns the [Type] of [LogicState].
  Type get type => T;

  /// Creates a new [LogicStateFactory].
  ///
  /// Please specify all possible [LogicState]s that can transition from that
  /// [LogicState] in [transitions].
  /// When a [LogicState] is completed, it will find the next state to execute
  /// from the top of [transitions].
  /// At that time, the method (`predicate`) passed to the constructor of
  /// [LogicStateTransition] is executed, and it transitions to the first [LogicState] that returns true.
  ///
  /// If you leave [transitions] empty, the processing of [LogicStateMachine]
  /// will be completed as soon as that state is completed.
  const LogicStateFactory(
    this.create,
    List<LogicStateTransition<LogicState>> transitions,
  ) : _transitions = transitions;
}

/// A class that specifies the types of other [LogicState]s that can transition from a given [LogicState].
class LogicStateTransition<R extends LogicState> {
  final TransitionPredicate _predicate;

  Type get nextType => R;

  /// Creates a new [LogicStateTransition].
  ///
  /// If [predicate] returns false, it does not allow transitioning to that [LogicState].
  /// When a [LogicState] is completed, the next state to execute will be the
  /// first state for which [predicate] returns true.
  LogicStateTransition([TransitionPredicate? predicate])
    : _predicate = predicate ?? ((c, n) => true);
}

typedef TransitionPredicate =
    bool Function(LogicState current, LogicState next);

/// The state in which [LogicStateMachine] terminated with an error.
class LogicStateError extends LogicState {
  /// Error details.
  final Object error;

  /// StackTrace
  final StackTrace? stackTrace;

  LogicStateError(this.error, this.stackTrace);
}

/// The state in which [LogicStateMachine] successfully completed.
class LogicStateComplete extends LogicState {}
