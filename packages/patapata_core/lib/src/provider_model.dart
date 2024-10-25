// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:patapata_core/patapata_core_libs.dart';

import 'exception.dart';
import 'sequential_work_queue.dart';

typedef ProviderModelProcess = FutureOr<void> Function(
    ProviderModelBatch batch);

class _DebugDynamicType<T> {
  const _DebugDynamicType();

  Type get type => T;
}

/// A variable that can be used in batches and automatically
/// detect changes as to notify listeners when it's
/// value changes.
/// The variable can be 'set' or 'unset' depending on whether
/// it's value has been set or not.
/// If it's value has not been set and it is accessed, an
/// assertion will be thrown.
class ProviderModelVariable<T> with ChangeNotifier {
  T? _value;
  final ProviderModel _parent;
  bool _set;
  final bool _nullable;

  /// Whether this variable has been set or not.
  bool get set => _set;

  ProviderModelVariable._internalCreate(
    this._parent,
    this._value,
    this._set,
  ) : _nullable = null is T;

  @override
  String toString() {
    return '$T:${set ? unsafeValue : 'NOT SET'}';
  }

  /// The type of this variable. Runtime access to [T].
  Type get type => T;

  /// The value of this variable. If [set] is false, an assertion will be thrown.
  /// Usually you should use [getValue] instead of this.
  ///
  /// Access to this variable via this function may not provide the newest value if it is accessed while a batch is ongoing.
  /// This is why it is named 'unsafe' as a reminder to use [getValue] instead or provide getters to access this in safe situations.
  T get unsafeValue {
    assert(set, 'ProviderModelVariable of type $T was used before it was set.');

    final tSubscription = Zone.current[#providerModelUseSubscription];

    if (tSubscription != null) {
      (tSubscription as ProviderModelUseSubscription)._variables.add(this);
    }

    if (_nullable) {
      return _value as T;
    } else {
      return _value!;
    }
  }

  bool _setValue(T newValue, [bool notify = true]) {
    final tPreviousSet = _set;
    _set = true;

    if (_value == newValue) {
      if (notify && _set != tPreviousSet) {
        notifyListeners();

        return true;
      }

      return false;
    }

    _value = newValue;

    if (notify) {
      notifyListeners();
    }

    return true;
  }

  /// Get the current value of this variable.
  /// This will wait until all currently queued batches
  /// have completed before returning the value.
  ///
  /// You cannot call this from inside a [ProviderModel.lock] callback.
  Future<T> getValue() async {
    if (_parent._lockQueues == null) {
      return unsafeValue;
    }

    assert(
      _parent._lockQueues?.values.every((e) => e.insideSequentialWorkQueue) !=
          true,
      'getValue() cannot be called inside a lock() callback',
    );

    while (true) {
      if (_parent.disposed) {
        return unsafeValue;
      }

      final tQueuesToWaitFor =
          _parent._lockQueues!.values.where((e) => e.isNotEmpty);

      if (tQueuesToWaitFor.isEmpty) {
        return unsafeValue;
      }

      // Wait until all queues have been finished.
      await Future.wait([
        for (var i in tQueuesToWaitFor) i.add(() => null),
      ]);

      // But now, after waiting once, there might still be
      // more things added to the queues again.
      // So we loop back and check all over again.
    }
  }
}

/// A batch of changes to a [ProviderModel].
/// Changes made to [ProviderModelVariable]s will not be reflected until [commit] is called.
///
/// If [cancel] is called, all changes made to [ProviderModelVariable]s will be discarded.
///
/// If [commit] is called, all changes made to [ProviderModelVariable]s will be applied,
/// and [notifyListeners] will be called for anyone listening to
/// the [ProviderModel] or any [ProviderModelVariable]s.
///
/// A batch can be created by calling [ProviderModel.begin] or [ProviderModel.lock].
class ProviderModelBatch {
  ProviderModelBatch._internalCreate(this._model);

  final ProviderModel _model;
  final _reserves = <ProviderModelVariable, dynamic>{};

  var _valid = true;
  var _completed = false;
  var _disabled = false;

  /// Whether this batch is valid or not.
  /// A batch is valid from the time it is created forever unless [cancel] is called
  /// or the batch was disabled by overridding or other means.
  bool get valid => _valid && !_model.disposed;

  /// Whether this batch is complete or not.
  /// A batch is completed once [commit] or [cancel] is called.
  bool get completed => _completed;

  /// Set the value of a [ProviderModelVariable] in this batch.
  /// All subsequent calls to [get] will return [value] instead
  /// of the [ProviderModelVariable.unsafeValue] of the variable.
  void set<T>(ProviderModelVariable<T> container, T value) {
    _reserves[container] = value;
  }

  /// Whether a [ProviderModelVariable] has been set itself or in this batch.
  bool isSet<T>(ProviderModelVariable<T> container) =>
      _reserves.containsKey(container) || container.set;

  /// Get the value of a [ProviderModelVariable] in this batch.
  /// If the value has not been set in this batch, the actual value of the variable
  /// will be returned via [ProviderModelVariable.unsafeValue].
  T get<T>(ProviderModelVariable<T> container) =>
      _reserves.containsKey(container)
          ? _reserves[container]
          : container.unsafeValue;

  /// Disable this batch.
  /// This is only called externally by [ProviderModel.lock].
  void _disable() {
    _valid = false;
    _disabled = true;
  }

  /// Cancel this batch.
  /// Once cancelled, all changes made to [ProviderModelVariable]s will be discarded.
  ///
  /// Any further calls to [commit], or [cancel] will be ignored.
  void cancel() {
    if (_completed) {
      return;
    }

    _valid = false;
    _completed = true;
    _reserves.clear();
    _model._onBatchComplete(false, false, false);
  }

  /// Commit this batch.
  /// Once committed, all changes made to [ProviderModelVariable]s will be applied.
  ///
  /// Any further calls to [commit], or [cancel] will be ignored.
  ///
  /// If [notify] is null (the default), [notifyListeners] will be called on the [ProviderModel]
  /// as well as any [ProviderModelVariable]s whose value changed in this batch.
  ///
  /// If [notify] is true, [notifyListeners] will be called on the [ProviderModel]
  /// as well as all [ProviderModelVariable]s in this batch.
  ///
  /// If [notify] is false, [notifyListeners] will not be called on the [ProviderModel] nor any [ProviderModelVariable]s.
  void commit({
    bool? notify,
  }) {
    if (_completed) {
      return;
    }

    _completed = true;

    var tChanged = false;

    if (!_disabled && !_model.disposed) {
      for (var i in _reserves.entries) {
        tChanged = i.key._setValue(i.value, notify != false) || tChanged;
      }
    }

    _reserves.clear();
    _model._onBatchComplete(!_disabled, tChanged, !_disabled ? notify : false);
  }

  /// Prevent execution of [f] to be overridden and cancelled by a [ProviderModel.lock] call.
  ///
  /// This is useful when you want to execute a function that executes an
  /// external API that doesn't support it's Zone's code all of the sudden being stopped.
  ///
  /// In general, you should use this when calling network-based or database-based APIs.
  Future<R> blockOverride<R>(FutureOr<R> Function() f) async {
    final tResult = await runZoned(f);

    // When the lock is overridden, this scheduled microtask will stop execution in our custom Zone.
    await Future.microtask(() => null);

    return tResult;
  }
}

/// Use an instance of this class to pass in to [ProviderModel.lock] and [ProviderModel.begin].
class ProviderLockKey {
  ProviderLockKey(this.name, {this.conflictReason});

  final String name;
  final String? conflictReason;
}

/// Thrown when [ProviderModel.begin] is called while a lock is already in place.
class ConflictException extends PatapataCoreException {
  ConflictException(this.key, this.from)
      : super(code: PatapataCoreExceptionCode.PPE201);

  /// The [ProviderLockKey] that was being used when this exception was thrown.
  final ProviderLockKey key;

  /// The [ProviderModel] that threw this exception.
  final ProviderModel from;

  @override
  String toString() {
    final tReason = key.conflictReason;

    if (tReason == null) {
      return 'ConflictException: ${from.runtimeType}(${key.name}#${key.hashCode}), Reason: Another batch was attempted to be created but lock() was called and commit() or cancel() have not been yet.';
    }

    return 'ConflictException: ${from.runtimeType}(${key.name}#${key.hashCode}), Reason: $tReason';
  }
}

/// [ProviderModel] is an abstract class that can be extended to create a model for state management
/// and safe logic flow for your application.
/// It uses the [ChangeNotifier] mixin to notify its listeners when changes occur, and therefore
/// can be used with [Provider] via [ChangeNotifierProvider], and anything that can work with [ChangeNotifier] or [Listenable].
///
/// It provides methods for creating and managing variables ([ProviderModelVariable]),
/// [lock]ing the model for safe modifications, and subscribing to changes via [addListener] or [use].
///
/// The generic parameter [T] should be the type of the class that extends [ProviderModel].
///
/// Example usage:
/// ```dart
/// class MyClass extends ProviderModel<MyClass> {
///   late final _myVariable = createVariable<int>(0);
///
///   int get myVariable => _myVariable.unsafeValue;
///
///   void increment() {
///     // This will increment _myVariable by 1.
///     // If this function is called multiple times at the same time,
///     // the value will be incremented 1 by 1 sequentially.
///     lock((batch) async {
///       // Do some long running API call.
///       await longApiCall();
///       batch.set(_myVariable, batch.get(_myVariable) + 1);
///       batch.commit();
///     });
///   }
/// }
///
/// // Some build function of some widget with MyClass being provided
/// // via ChangeNotifierProvider.
/// Widget build(BuildContext context) {
///   final tValue = context.watch<MyClass>().myVariable;
///
///   return TextButton(
///     onPressed: () {
///       context.read<MyClass>().increment();
///     },
///     child: Text('$tValue'),
///   );
/// }
/// ```
abstract class ProviderModel<T> with ChangeNotifier {
  final ProviderLockKey _defaultLockKey = ProviderLockKey('BatchLockKey');

  Map<ProviderLockKey, SequentialWorkQueue>? _lockQueues;
  final _variables = <ProviderModelVariable>[];
  List<ProviderModelUseSubscription<T>>? _useSubscriptions;

  bool _disposed = false;

  /// Whether this [ProviderModel] has been disposed or not.
  bool get disposed => _disposed;

  bool? _debugValidType;

  /// Dipose this [ProviderModel].
  /// This will call [dispose] on all [ProviderModelVariable]s created by this [ProviderModel].
  /// This will also cancel all [ProviderModelUseSubscription]s created by this [ProviderModel].
  ///
  /// This will also cancel all locks created by this [ProviderModel] asynchronously but as fast as possible.
  /// If someone tries to use this model after this point inside a batch, it will throw an exception for new operations
  /// and cleanly fail for existing operations by returning false from things like [lock].
  @override
  @mustCallSuper
  void dispose() {
    assert(!_disposed, 'ProviderModel was already disposed.');

    _disposed = true;

    for (var i in _variables) {
      i.dispose();
    }

    final tUseSubscriptions = _useSubscriptions;

    if (tUseSubscriptions != null) {
      for (var i in tUseSubscriptions.toList(growable: false)) {
        i.cancel();
      }

      _useSubscriptions = null;
    }

    super.dispose();

    // This has no guaruntee to synchronously cancel all locks.
    // Therefore we execute this at the end.
    // If someone tries to use this model after this point inside a batch, it will throw an exception.
    if (_lockQueues != null) {
      for (var i in _lockQueues!.values) {
        i.clear();
      }

      _lockQueues = null;
    }
  }

  /// Whether this [ProviderModel] is locked with [lockKey] or not.
  bool locked(ProviderLockKey lockKey) {
    if (_lockQueues == null) {
      return false;
    }

    return _lockQueues![lockKey]?.isNotEmpty == true;
  }

  /// Create a [ProviderModelVariable] belonging to this [ProviderModel]
  /// that can be used in batches and automatically
  /// detect changes to notify listeners when it's
  /// value changes.
  ///
  /// [initial] is the initial value that this variable will be set to.
  ///
  /// Use this function as the value of a late final variable
  /// in your class.
  ///
  /// ```dart
  /// class MyClass extends ProviderModel<MyClass> {
  ///   late final myVariable = createVariable<int>(0);
  /// }
  /// ```
  @nonVirtual
  @protected
  ProviderModelVariable<U> createVariable<U>(U initial) {
    assert(
      _debugValidType ??= T != const _DebugDynamicType<dynamic>().type,
      'ProviderModel\'s T type parameter must be the same as the class that extends it. Currrently it is dynamic or unset.',
    );

    final tContainer = ProviderModelVariable<U>._internalCreate(
      this,
      initial,
      true,
    );

    _variables.add(tContainer);

    return tContainer;
  }

  /// Creates an unset [ProviderModelVariable] belonging to this [ProviderModel]
  /// that can be used in batches and automatically
  /// detect changes to notify listeners when it's
  /// value changes.
  ///
  /// When a variable is 'unset', it's value cannot be accessed
  /// until it is set via a [ProviderModelBatch.set] and [ProviderModelBatch.commit]
  /// or an assertion with be thrown.
  ///
  /// Example:
  /// ```dart
  /// class MyClass extends ProviderModel<MyClass> {
  ///   late final myVariable = createUnsetVariable<int>();
  /// }
  ///
  /// final model = MyClass();
  ///
  /// model.myVariable.unsafeValue; // assertion error
  ///
  /// model.begin()
  ///   ..set(model.myVariable, 3)
  ///   ..commit();
  ///
  /// model.myVariable.unsafeValue; // 3
  /// ```
  @nonVirtual
  @protected
  ProviderModelVariable<U> createUnsetVariable<U>() {
    assert(
      _debugValidType ??= T != const _DebugDynamicType<dynamic>().type,
      'ProviderModel\'s T type parameter must be the same as the class that extends it. Currrently it is dynamic or unset.',
    );

    final tContainer = ProviderModelVariable<U>._internalCreate(
      this,
      null,
      false,
    );

    _variables.add(tContainer);

    return tContainer;
  }

  void _onBatchComplete(bool committed, bool variablesChanged, bool? notify) {
    if (disposed) {
      return;
    }

    if (committed && notify != false) {
      if (variablesChanged || notify == true) {
        notifyListeners();
      }
    }
  }

  /// Create a batch to safely modify this [ProviderModel]'s [ProviderModelVariable] members.
  ///
  /// A [lockKey] can be passed to prevent multiple batches from being created at the same time
  /// with the same [lockKey].
  /// If a batch is already in progress with the same [lockKey], a [ConflictException] will be thrown.
  /// Every [ProviderModel] has a default [ProviderLockKey] that this function will default to
  /// if [lockKey] is not set.
  @nonVirtual
  ProviderModelBatch begin([ProviderLockKey? lockKey]) {
    assert(!_disposed, 'ProviderModel was already disposed.');
    assert(
      Zone.current[#providerModelUseSubscription] == null,
      'begin() cannot be called while a use callback is being executed.',
    );

    lockKey ??= _defaultLockKey;

    if (locked(lockKey)) {
      throw ConflictException(lockKey, this);
    }

    return ProviderModelBatch._internalCreate(this);
  }

  /// Queue up to lock this [ProviderModel] to safely modify it's [ProviderModelVariable] members.
  /// The [process] passed here is guarunteed to be executed sequentially and non-parallel to other proccesses passed to [lock].
  ///
  /// If [override] is true, all previously queued [lock] calls with [overridable] or [onOverride] set will be cancelled.
  /// If not started yet, it will be skipped, if started, it will stop execution on the next asynchronous tick.
  /// When cancelled, no notifications will be sent even if [ProviderModelBatch.commit] is executed.
  /// if [override] is false, process won't be called until all previous [lock]s have been completed.
  ///
  /// Returns a bool signifying whether execution of [process] completed without erroring, overriding, or cancelling.
  ///
  /// A [lockKey] can be passed to prevent multiple batches from being created at the same time
  /// with the same [lockKey].
  /// Every [ProviderModel] has a default [ProviderLockKey] that this function will default to
  /// if [lockKey] is not set.
  ///
  /// For details on what [waitForMicrotasks], [waitForTimers], and [waitForPeriodicTimers] do,
  /// see [SequentialWorkQueue.add].
  @nonVirtual
  Future<bool> lock(
    ProviderModelProcess process, {
    ProviderLockKey? lockKey,
    bool override = false,
    bool overridable = false,
    FutureOr<void> Function()? onOverride,
    bool waitForMicrotasks = true,
    bool waitForTimers = false,
    bool waitForPeriodicTimers = false,
  }) async {
    assert(!_disposed, 'ProviderModel was already disposed.');
    assert(
      Zone.current[#providerModelUseSubscription] == null,
      'lock() cannot be called while a use callback is being executed.',
    );

    lockKey ??= _defaultLockKey;
    _lockQueues ??= <ProviderLockKey, SequentialWorkQueue>{};

    final tQueue =
        _lockQueues!.putIfAbsent(lockKey, () => SequentialWorkQueue());

    if (override) {
      tQueue.clear();
    }

    final tBatch = ProviderModelBatch._internalCreate(this);

    return await tQueue.add<bool>(
          () async {
            await process(tBatch);

            return tBatch.valid && !disposed;
          },
          onCancel: () async {
            if (onOverride != null) {
              tBatch._disable();
              await onOverride();

              return true;
            } else if (overridable) {
              tBatch._disable();

              return true;
            }

            return false;
          },
          waitForMicrotasks: waitForMicrotasks,
          waitForTimers: waitForTimers,
          waitForPeriodicTimers: waitForPeriodicTimers,
        ) ==
        true;
  }

  /// Subscribe to changes to this [ProviderModel].
  /// The [callback] passed here will be called whenever a [ProviderModelVariable] belonging to this [ProviderModel]
  /// that was accessed inside the [callback] changes.
  /// The [callback] will be called immediately once during execution of this function synchronously.
  ///
  /// Do not call [use] inside of [callback].
  /// Do not do any sort of asynchronous work inside of [callback].
  /// Do not start any [ProviderModelBatch]es inside of [callback] via [begin] or [lock].
  /// It should be used only to access data and not modify it.
  ProviderModelUseSubscription<T> use(void Function(T model) callback) {
    assert(!_disposed, 'ProviderModel was already disposed.');
    assert(
      Zone.current[#providerModelUseSubscription] == null,
      'use() cannot be called while a use callback is being executed.',
    );

    final tSubscription = ProviderModelUseSubscription<T>._(this, callback);

    (_useSubscriptions ??= <ProviderModelUseSubscription<T>>[])
        .add(tSubscription);

    _executeUseSubscription(tSubscription);

    return tSubscription;
  }

  void _executeUseSubscription(ProviderModelUseSubscription<T> subscription) {
    subscription._clearVariables();

    runZoned<void>(
      () {
        subscription.callback(this as T);
      },
      zoneValues: {
        #providerModelUseSubscription: subscription,
      },
    );

    subscription._listenToVariables();
  }

  void _cancelUseSubscription(ProviderModelUseSubscription<T> subscription) {
    subscription._clearVariables();
    _useSubscriptions?.remove(subscription);
  }
}

/// [ProviderModelUseSubscription] is a class that represents a subscription to a [ProviderModel]'s [ProviderModelVariable]s.
///
/// It keeps track of the variables that the subscription is interested in and calls a callback function whenever any of these variables change.
///
/// This class is not meant to be instantiated directly. Instead, use [ProviderModel.use].
///
/// Example usage:
/// ```dart
/// final subscription = myModel.use((model) {
///   print(model.myVariable.unsafeValue);
/// });
/// ```
final class ProviderModelUseSubscription<T> {
  final ProviderModel _model;
  final _variables = <ProviderModelVariable>{};

  /// The callback function to be called whenever any of the variables change.
  final void Function(T model) callback;

  bool _scheduled = false;

  /// Private constructor. Use [ProviderModel.use] to create an instance.
  ProviderModelUseSubscription._(this._model, this.callback);

  void _clearVariables() {
    for (var i in _variables) {
      i.removeListener(_onVariablesChanged);
    }

    _variables.clear();
  }

  void _listenToVariables() {
    for (var i in _variables) {
      i.addListener(_onVariablesChanged);
    }
  }

  void _onVariablesChanged() {
    if (!_scheduled) {
      _scheduled = true;

      scheduleMicrotask(() {
        _scheduled = false;
        _model._executeUseSubscription(this);
      });
    }
  }

  /// Cancels the subscription.
  /// Stops listening to all variables and removes the subscription from the [ProviderModel].
  void cancel() {
    _model._cancelUseSubscription(this);
  }
}
