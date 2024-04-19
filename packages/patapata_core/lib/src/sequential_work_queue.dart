// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:collection';

final class _SequentialWorkQueueItem
    extends LinkedListEntry<_SequentialWorkQueueItem> {
  final Completer<void> completer;
  final FutureOr Function() work;
  final FutureOr<bool> Function()? onCancel;
  Completer<bool>? cancellingCompleter;
  bool cancelled = false;
  final asyncQueue = Queue<Future<void>>();

  _SequentialWorkQueueItem(this.completer, this.work, this.onCancel);
}

/// A utility class that will process work giving to it
/// in order, without failure.
///
/// It is guaranteed under a standard Zone that all work
/// will be processed, whether previous works fails or not.
class SequentialWorkQueue {
  final _queue = LinkedList<_SequentialWorkQueueItem>();

  /// Checks whether the current code is running inside this [SequentialWorkQueue] work callback via [add].
  bool get insideSequentialWorkQueue =>
      Zone.current[#sequentialWorkQueue] == hashCode;

  /// Add [work] to this [SequentialWorkQueue].
  /// It will be executed when all previous [work]
  /// registered to the [SequentialWorkQueue] as completed.
  ///
  /// If the [work] added here throws, the Future returned by
  /// this function will error. However future [work] will
  /// continue to be processed correctly.
  ///
  /// [work] is considered complete when the function itself returns, if the returned value
  /// is a [Future], when that [Future] completes, if [waitForMicrotasks] is true, when all
  /// scheduled microtasks with [Future.microtask], [scheduleMicrotask], [Future], etc complete,
  /// if [waitForTimers] is true, any [Timer] inside [work] has completed,
  /// and finally if [waitForPeriodicTimers] is true, any [Timer.periodic] inside [work] has completed.
  /// Similar to how a main function is considered complete when all asynchronous work.
  /// scheduled within it has completed.
  ///
  /// You can optionally pass [onCancel] that will be called
  /// if something attempts to clear this [SequentialWorkQueue] with methods like [clear].
  /// If [onCancel] returns true, this [work] with either stop executing or not execute all together, and [add] will return null.
  /// If [onCancel] returns false, this [work] does not support cancelling, and will continue to execute until completion.
  /// If [onCancel] is not passed, the default is the same as if onCancel returned true.
  ///
  /// When [onCancel] returns true, work that is current running in a separate [Zone]
  /// will be allowed to complete. Code directly after the [Zone] execution will not be executed.
  ///
  /// Example:
  /// ```dart
  /// final tQueue = SequentialWorkQueue();
  ///
  /// await tQueue.add(() async {
  ///   print('1');
  ///   await Future.delayed(Duration(seconds: 1));
  ///   print('2');
  /// });
  ///
  /// tQueue.add(() async {
  ///   print('3');
  ///   await Future.delayed(Duration(seconds: 1));
  ///   print('4');
  /// });
  ///
  /// // Just for demo purposees, wait for one tick to allow the print('3') line to execute.
  /// // But then it will wait at the next await.
  /// await Future.microtask(() => null);
  ///
  /// // Executing this here means the code beyond print('3') will not execute.
  /// await tQueue.clear();
  ///
  /// // Prints: 1, 2, 3
  /// ```
  Future<T?> add<T extends Object?>(
    FutureOr<T> Function() work, {
    FutureOr<bool> Function()? onCancel,
    bool waitForMicrotasks = true,
    bool waitForTimers = false,
    bool waitForPeriodicTimers = false,
  }) {
    return _runInSafeZone(() async {
      final tCompleter = Completer<void>();
      final tQueueItem = _SequentialWorkQueueItem(tCompleter, work, onCancel);
      _queue.add(tQueueItem);

      final tValueCompleter = Completer<T?>();

      Future<void> fFinish(
        bool cancel,
        T? value, [
        Object? error,
        StackTrace? stackTrace,
      ]) async {
        return _runInSafeZone(() async {
          if (!cancel) {
            // This should only be called once.

            // Wait for all async work to complete.
            while (tQueueItem.asyncQueue.isNotEmpty) {
              await tQueueItem.asyncQueue.removeFirst();

              if (tQueueItem.cancelled) {
                // We got cancelled while waiting.
                // Clean up a bit and just return.
                // If we are cancelled, that means the cancel condition
                // of the above code has already been met and we don't need
                // to do anything else.
                tQueueItem.asyncQueue.clear();

                return;
              }
            }
          }

          if (!tCompleter.isCompleted) {
            tQueueItem.unlink();
            tCompleter.complete();
          }

          if (!tValueCompleter.isCompleted) {
            if (error != null) {
              tValueCompleter.completeError(error, stackTrace);
            } else {
              tValueCompleter.complete(value);
            }
          }
        });
      }

      try {
        if (tQueueItem.previous != null) {
          await tQueueItem.previous!.completer.future;

          if (tQueueItem.cancelled) {
            fFinish(true, null);
            return tValueCompleter.future;
          }
        }

        runZoned<void>(
          () {
            try {
              final tResult = work();

              if (tResult != null) {
                if (tResult is Future<T>) {
                  _runInSafeZone(() {
                    final tSafeZone = Zone.current;
                    final fOnResult = tSafeZone.bindUnaryCallback<void, T>(
                      (value) {
                        fFinish(false, value);
                      },
                    );
                    final tOnError = tSafeZone
                        .bindBinaryCallback<void, Object?, StackTrace>(
                            (error, stackTrace) {
                      fFinish(false, null, error, stackTrace);
                    });

                    tResult.then<void>(
                      fOnResult,
                      onError: tOnError,
                    );
                  });
                } else {
                  fFinish(false, tResult);
                }
              } else {
                fFinish(false, null);
              }
            } catch (error, stackTrace) {
              fFinish(false, null, error, stackTrace);
            }
          },
          zoneValues: {
            #sequentialWorkQueue: hashCode,
            #sequentialWorkQueueItem: tQueueItem.hashCode,
          },
          zoneSpecification: ZoneSpecification(
            fork: (self, parent, zone, specification, zoneValues) {
              return parent.fork(
                zone,
                specification,
                {
                  ...?zoneValues,
                  // Keep this so we know if we are inside this queue.
                  #sequentialWorkQueue: hashCode,
                  // Reset this so we don't cancel code in this new Zone.
                  #sequentialWorkQueueItem: 0,
                },
              );
            },
            scheduleMicrotask: (self, parent, zone, f) {
              if (!waitForMicrotasks ||
                  zone[#sequentialWorkQueueItem] != tQueueItem.hashCode) {
                return parent.scheduleMicrotask(zone, f);
              }

              late Completer<void> tAsyncCompleter;

              void fCompleteAsync() {
                _runInSafeZone(() {
                  // When the compiler optimizes the tail end of an await
                  // call to execute code synchronously across multiple tail ends
                  // of other awaits and in particular, across the Zone exit
                  // boundary we care about, the cancellation code will not
                  // have been run yet.
                  // Run it here otherwise we get in to a state where
                  // the value completer never completes.
                  if (tQueueItem.cancelled &&
                      tQueueItem.asyncQueue.length == 1) {
                    fFinish(true, null);
                  }

                  tAsyncCompleter.complete();
                });
              }

              final tUnsafeZone = Zone.current;

              _runInSafeZone(() {
                tAsyncCompleter = Completer<void>();
                tQueueItem.asyncQueue.add(tAsyncCompleter.future);

                Zone.current.scheduleMicrotask(() {
                  if (!tQueueItem.cancelled) {
                    if (tQueueItem.cancellingCompleter != null) {
                      _runInSafeZone(() {
                        tQueueItem.cancellingCompleter!.future
                            .then((cancelled) {
                          fCompleteAsync();

                          if (!cancelled) {
                            tUnsafeZone.run(f);
                          } else {
                            fFinish(true, null);
                          }
                        });
                      });
                    } else {
                      fCompleteAsync();
                      f();
                    }
                  } else {
                    fCompleteAsync();
                    fFinish(true, null);
                  }
                });
              });
            },
            createTimer: (self, parent, zone, duration, f) {
              if (!waitForTimers ||
                  zone[#sequentialWorkQueueItem] != tQueueItem.hashCode) {
                return parent.createTimer(zone, duration, f);
              }

              late Completer<void> tAsyncCompleter;

              void fCompleteAsync() {
                _runInSafeZone(() {
                  tAsyncCompleter.complete();
                });
              }

              final tUnsafeZone = Zone.current;

              return _runInSafeZone(() {
                tAsyncCompleter = Completer<void>();
                tQueueItem.asyncQueue.add(tAsyncCompleter.future);

                final tBackingTimer = Zone.current.createTimer(duration, () {
                  if (!tQueueItem.cancelled) {
                    if (tQueueItem.cancellingCompleter != null) {
                      _runInSafeZone(() {
                        tQueueItem.cancellingCompleter!.future
                            .then((cancelled) {
                          fCompleteAsync();

                          if (!cancelled) {
                            tUnsafeZone.run(f);
                          } else {
                            fFinish(true, null);
                          }
                        });
                      });
                    } else {
                      fCompleteAsync();
                      f();
                    }
                  } else {
                    fCompleteAsync();
                    fFinish(true, null);
                  }
                });

                final tTimer = _TimerWithCancelCallback(
                  tBackingTimer,
                  // This callback happens when the timer is cancelled.
                  () {
                    if (!tAsyncCompleter.isCompleted) {
                      // Notify that this timer has been cancelled.
                      // This will let the future for [add] to complete.
                      fCompleteAsync();
                    }
                  },
                );

                return tTimer;
              });
            },
            createPeriodicTimer: (self, parent, zone, period, f) {
              if (!waitForPeriodicTimers ||
                  zone[#sequentialWorkQueueItem] != tQueueItem.hashCode) {
                return parent.createPeriodicTimer(zone, period, f);
              }

              late Completer<void> tAsyncCompleter;

              void fCompleteAsync() {
                _runInSafeZone(() {
                  if (!tAsyncCompleter.isCompleted) {
                    tAsyncCompleter.complete();
                  }
                });
              }

              final tUnsafeZone = Zone.current;

              return _runInSafeZone(() {
                tAsyncCompleter = Completer<void>();
                tQueueItem.asyncQueue.add(tAsyncCompleter.future);

                late final _TimerWithCancelCallback tTimer;

                final tBackingTimer =
                    Zone.current.createPeriodicTimer(period, (timer) {
                  if (!tQueueItem.cancelled) {
                    if (tQueueItem.cancellingCompleter != null) {
                      _runInSafeZone(() {
                        tQueueItem.cancellingCompleter!.future
                            .then((cancelled) {
                          if (!cancelled) {
                            tUnsafeZone.runUnary(f, tTimer);
                          } else {
                            tTimer.cancelWithoutCallback();
                            fCompleteAsync();
                            fFinish(true, null);
                          }
                        });
                      });
                    } else {
                      f(tTimer);
                    }
                  } else {
                    tTimer.cancelWithoutCallback();
                    fCompleteAsync();
                    fFinish(true, null);
                  }
                });

                tTimer = _TimerWithCancelCallback(
                  tBackingTimer,
                  // This callback happens when the timer is cancelled.
                  () {
                    if (!tAsyncCompleter.isCompleted) {
                      // Notify that this timer has been cancelled.
                      // This will let the future for [add] to complete.
                      fCompleteAsync();
                    }
                  },
                );

                return tTimer;
              });
            },
          ),
        );
      } catch (error, stackTrace) {
        // If we get here, something went wrong.
        // Can't think of a possible realistic code path
        // that would cause this to happen, so we will ignore
        // this line for coverage.
        // coverage:ignore-start
        fFinish(false, null, error, stackTrace);
        // coverage:ignore-end
      }

      return tValueCompleter.future;
    });
  }

  /// Clear the queue.
  /// This will attempt to cancel all work pending and running.
  /// It will return when all work has truly completed or cancelled.
  ///
  /// If a work callback is current executing and is cancelable,
  /// the work itself will cancel however any async work scheduled
  /// inside a child [Zone] via [runZone] and friends will not be cancelled.
  /// Ie, microtasks, timers, and futures will not be cancelled.
  ///
  /// This function will always execute in the closest parent [Zone] that
  /// isn't a special [Zone] created by [add].
  /// This means that if you call this function inside a [work] function
  /// added to this [SequentialWorkQueue], due to the [Zone] changing, awaiting
  /// for this function will not actually wait for it to finish.
  /// In general, you should probably not use await with this function
  /// if you are inside a [work] function.
  Future<void> clear() {
    return _runInSafeZone(() async {
      final tQueue = _queue
          .where((element) => element.cancellingCompleter == null)
          .toList(growable: false);

      for (var i in tQueue) {
        i.cancellingCompleter = Completer<bool>();
      }

      final tWorkToWaitFor = <Future<void>>[];

      for (var i in tQueue) {
        final tCompleter = i.cancellingCompleter!;
        tWorkToWaitFor.add(i.completer.future);

        if (i.onCancel != null) {
          try {
            final tCancelResult = i.onCancel!();

            if (tCancelResult == true) {
              i.cancelled = true;
              tCompleter.complete(true);
            } else if (tCancelResult == false) {
              i.cancellingCompleter = null;
              tCompleter.complete(false);
            } else {
              final tCancelFinalResult = await tCancelResult;

              if (tCancelFinalResult) {
                i.cancelled = true;
                tCompleter.complete(true);
              } else {
                i.cancellingCompleter = null;
                tCompleter.complete(false);
              }
            }
          } catch (error, stackTrace) {
            // Continue processing the queue.
            // We will send this off to the zone unhandled callback.
            i.cancellingCompleter = null;
            tCompleter.complete(false);
            Zone.current.handleUncaughtError(error, stackTrace);
          }
        } else {
          i.cancelled = true;
          tCompleter.complete(true);
        }
      }

      await Future.wait(tWorkToWaitFor);
    });
  }

  /// Whether this queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Whether this queue is not empty
  bool get isNotEmpty => _queue.isNotEmpty;

  T _runInSafeZone<T>(T Function() f) {
    var tZoneToExecuteIn = Zone.current;

    if (tZoneToExecuteIn[#sequentialWorkQueueItem] != null) {
      // We are inside the queue.
      // We will need to run this in the parent zone.
      do {
        tZoneToExecuteIn = tZoneToExecuteIn.parent!;
      } while (tZoneToExecuteIn[#sequentialWorkQueueItem] != null);

      return tZoneToExecuteIn.run<T>(f);
    }

    return f();
  }
}

class _TimerWithCancelCallback implements Timer {
  final Timer backingTimer;
  final void Function() onCancel;

  _TimerWithCancelCallback(this.backingTimer, this.onCancel);

  @override
  void cancel() {
    backingTimer.cancel();
    onCancel();
  }

  void cancelWithoutCallback() {
    backingTimer.cancel();
  }

  @override
  bool get isActive => backingTimer.isActive;

  @override
  int get tick => backingTimer.tick;
}
