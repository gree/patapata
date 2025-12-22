// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/src/sequential_work_queue.dart';

void main() {
  group('SequentialWorkQueue', () {
    group('basics', () {
      test('should execute work in order', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        tQueue.add(() async {
          tResults.add(1);
        });

        tQueue.add(() {
          tResults.add(2);
        });

        await tQueue.add(() async {
          tResults.add(3);
        });

        expect(tResults, [1, 2, 3]);
      });

      test('should handle work that throws an error', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        tQueue.add(() async {
          tResults.add(1);
        });

        expect(
          tQueue.add(() async {
            throw Exception('Error');
          }),
          throwsA(isA<Exception>()),
        );

        expect(
          tQueue.add(() {
            throw Exception('Error2');
          }),
          throwsA(isA<Exception>()),
        );

        await tQueue.add(() async {
          tResults.add(3);
        });

        expect(tResults, [1, 3]);
      });

      test('should support cancelling work', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        await tQueue.add(() async {
          tResults.add(1);
        });

        tQueue.add(() async {
          await Future.microtask(() => null);
          tResults.add(2);
        });

        await tQueue.clear();

        expect(tResults, [1]);
      });

      test('should execute onCancel callback when cancelling work', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        tQueue.add(
          () async {
            await Future.microtask(() => null);
            tResults.add(1);
          },
          onCancel: () {
            tResults.add(0);
            return true;
          },
        );

        tQueue.add(() async {
          await Future.microtask(() => null);
          tResults.add(2);
        });

        await tQueue.clear();

        expect(tResults, [0]);
      });

      test(
        'should not execute onCancel callback when not cancelling work',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(
            () async {
              await Future.microtask(() => null);
              tResults.add(2);
            },
            onCancel: () {
              tResults.add(0);
              return false;
            },
          );

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(3);
          });

          tQueue.add(
            () async {
              await Future.microtask(() => null);
              tResults.add(4);
            },
            onCancel: () {
              tResults.add(1);
              return false;
            },
          );

          await tQueue.clear();

          expect(tResults, [0, 1, 2, 4]);
        },
      );

      test('should execute onCancel callback that returns a future', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        tQueue.add(
          () async {
            await Future.microtask(() => null);
            tResults.add(1);
          },
          onCancel: () async {
            tResults.add(0);
            await Future.microtask(() => null);
            return true;
          },
        );

        tQueue.add(() async {
          tResults.add(2);
        });

        await tQueue.clear();

        expect(tResults, [0]);
      });

      test('should handle work that returns a value', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        int? tValue = await tQueue.add(() async {
          tResults.add(1);
          return 42;
        });

        expect(tValue, 42);

        tValue = await tQueue.add(() {
          tResults.add(2);
          return 43;
        });

        expect(tValue, 43);
        expect(tResults, [1, 2]);
      });

      test('should handle work that returns a future', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        final tValue = await tQueue.add(() async {
          tResults.add(1);
          return await Future.microtask(() => 42);
        });

        expect(tResults, [1]);
        expect(tValue, 42);
      });

      test('isEmpty should return true when empty', () async {
        final tQueue = SequentialWorkQueue();

        expect(tQueue.isEmpty, isTrue);

        tQueue.add(() async {});

        expect(tQueue.isEmpty, isFalse);

        await tQueue.add(() async {});

        expect(tQueue.isEmpty, isTrue);
      });

      test('isNotEmpty should return false when empty', () async {
        final tQueue = SequentialWorkQueue();

        expect(tQueue.isNotEmpty, isFalse);

        tQueue.add(() async {});

        expect(tQueue.isNotEmpty, isTrue);

        await tQueue.add(() async {});

        expect(tQueue.isNotEmpty, isFalse);
      });

      test(
        'insideSequentialWorkQueue should return true when inside',
        () async {
          final tQueue = SequentialWorkQueue();

          expect(tQueue.insideSequentialWorkQueue, isFalse);

          await tQueue.add(() async {
            expect(tQueue.insideSequentialWorkQueue, isTrue);
          });

          expect(tQueue.insideSequentialWorkQueue, isFalse);

          final tFuture = tQueue.add(() async {
            expect(tQueue.insideSequentialWorkQueue, isTrue);
          });

          expect(tQueue.insideSequentialWorkQueue, isFalse);

          await tFuture;
        },
      );

      test('can use custom zones inside of work', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        await tQueue.add(() async {
          tResults.add(1);

          await runZonedGuarded(
            () async {
              tResults.add(2);
              await Future.microtask(() => null);
              tResults.add(3);
            },
            (error, stackTrace) {
              tResults.add(4);
            },
          );

          tResults.add(5);
        });

        expect(tResults, [1, 2, 3, 5]);
      });

      test(
        'can use custom zones inside of work that throws an error',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          expect(
            () async => await tQueue.add(() async {
              tResults.add(1);

              final tFuture = runZoned(() async {
                tResults.add(2);
                await Future.microtask(() => null);
                throw Exception('Error');
              });
              expect(tFuture, throwsA(isA<Exception>()));

              await tFuture;
            }),
            throwsA(isA<Exception>()),
          );

          expect(tResults, [1, 2]);
        },
      );

      test(
        'can use custom zones and still cancel work. but the zone work should not be cancelled',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(() async {
            tResults.add(1);

            await runZonedGuarded(
              () async {
                tResults.add(2);
                await Future.microtask(() => null);
                tResults.add(3);
              },
              (error, stackTrace) {
                tResults.add(4);
              },
            );

            // Explanation: The dart compiler decides that it's possible
            // to run from the end of await microtask above all the way to the await tQueue.clear
            // below synchronously. Therefore it gets scheduled that way and
            // there is no way for our code to stop execution at this point
            // (even though that's what we want).
            // Therefore the final tResults.add(5) is executed.
            tResults.add(5);
          });

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(6);
          });

          await tQueue.clear();

          expect(tResults, [1, 2, 3, 5]);
        },
      );

      test('can clear inside of work', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        await tQueue.add(
          () async {
            tResults.add(1);

            tQueue.clear();

            tResults.add(2);
          },
          onCancel: () {
            return true;
          },
        );

        expect(tResults, [1, 2]);
      });
    });

    group('microtasks', () {
      test('should be able to create microtasks inside of work', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        await tQueue.add(() async {
          tResults.add(1);

          await Future.microtask(() async {
            tResults.add(2);
            await Future.microtask(() => null);
            tResults.add(3);
          });

          tResults.add(4);
        });

        expect(tResults, [1, 2, 3, 4]);
      });

      test(
        'should be able to create microtasks inside of work that throws',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          await expectLater(
            tQueue.add(() async {
              tResults.add(1);

              await Future.microtask(() async {
                tResults.add(2);
                await Future.microtask(() => null);
                throw Exception('Error');
              });
            }),
            throwsA(isA<Exception>()),
          );

          expect(tResults, [1, 2]);
        },
      );

      test(
        'should be able to create microtasks, and then cancel work',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(() async {
            tResults.add(1);

            await Future.microtask(() async {
              tResults.add(2);
              await Future.microtask(() => null);
              tResults.add(3);
            });

            tResults.add(4);
          });

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(5);
          });

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tResults, [1, 2]);
        },
      );

      test(
        'should be able to create microtasks in uncancelable work, and then attempt to cancel the work',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() async {
                tResults.add(2);
                await Future.microtask(() => null);
                tResults.add(3);
              });

              tResults.add(4);
            },
            onCancel: () {
              return false;
            },
          );

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(5);
          });

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tResults, [1, 2, 3, 4]);
        },
      );

      test(
        'should be able to create microtasks in future uncancellable work, and then attempt to cancel the work',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() async {
                tResults.add(2);
                await Future.microtask(() => null);
                tResults.add(3);
              });

              tResults.add(4);
            },
            onCancel: () async {
              return false;
            },
          );

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(5);
          });

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tResults, [1, 2, 3, 4]);
        },
      );

      test(
        'should be able to create microtasks in future cancellable work, and then cancel the work',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() async {
                tResults.add(2);
                await Future.microtask(() => null);
                tResults.add(3);
              });

              tResults.add(4);
            },
            onCancel: () async {
              return true;
            },
          );

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(5);
          });

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tResults, [1, 2]);
        },
      );

      test(
        'should be able to create microtasks in future cancellable work, and then cancel the work. Support errors',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() async {
                tResults.add(2);

                throw Exception('Error');
              });
            },
            onCancel: () async {
              return true;
            },
          );

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(5);
          });

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tResults, [1, 2]);
        },
      );

      test(
        'should be able to create microtasks in future errored cancellable work, and then attempt to cancel the work',
        () async {
          runZonedGuarded(
            () async {
              final tQueue = SequentialWorkQueue();
              final tResults = <int>[];

              tQueue.add(
                () async {
                  tResults.add(1);

                  await Future.microtask(() async {
                    tResults.add(2);
                    await Future.microtask(() => null);
                    tResults.add(3);
                  });

                  tResults.add(4);
                },
                onCancel: () async {
                  throw Exception('Error');
                },
              );

              tQueue.add(() async {
                await Future.microtask(() => null);
                tResults.add(5);
              });

              // Allow one tick to let the microtasks run.
              await Future.microtask(() => null);

              await tQueue.clear();

              expect(tResults, [1, 2, 3, 4]);
            },
            (error, stackTrace) {
              expect(error, isA<Exception>());
            },
          );
        },
      );

      test(
        'should be able to create microtasks inside microtasks and they should be cancellable',
        () async {
          final tQueue = SequentialWorkQueue();
          final tShouldCall = expectAsync0(() => null, count: 4);
          final tShouldNotCall = expectAsync0(() => null, count: 0);
          int tValue = 0;

          expectLater(
            tQueue.add(() async {
              tShouldCall();
              Future.microtask(() async {
                tShouldCall();
                // One tick
                await Future.microtask(tShouldCall);

                tValue = 1;

                // Another tick
                return Future.microtask(tShouldNotCall);
              }).then((value) {
                tShouldNotCall();
              });

              tShouldCall();
            }),
            completes,
          );

          // One tick
          await Future.microtask(() => null);

          // Two tick
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tValue, 1);
        },
      );

      test(
        'should be able to create microtasks inside a queue that is being executed inside another queue',
        () async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];

          Future<void>? tInnerQueue;

          await tQueue.add(() async {
            tResults.add(1);

            tInnerQueue = tQueue.add<void>(() async {
              tResults.add(2);

              Future.microtask(() async {
                await Future.delayed(const Duration(milliseconds: 1));
                tResults.add(3);
              });

              tQueue.clear();

              tResults.add(4);
            });

            tResults.add(5);
          });

          await tInnerQueue!;

          expect(tResults, [1, 5, 2, 4]);
        },
      );

      test('should be able to create microtasks 2', () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        void onSuccess() {
          tResults.add(1);
        }

        await tQueue.add<void>(() async {
          try {
            final tCompleter = Completer<void>();
            tCompleter.future.then((value) {
              onSuccess();
            });

            scheduleMicrotask(() async {
              await Future.delayed(const Duration(milliseconds: 1));

              tCompleter.complete();
            });

            return tCompleter.future;
          } catch (e) {
            rethrow;
          }
        });

        expect(tResults, [1]);
      });
    });
  });

  group('timers', () {
    test('should be able to create timers inside of work', () async {
      final tQueue = SequentialWorkQueue();
      final tResults = <int>[];
      final tShouldCall = expectAsync0(() => null, count: 1);

      await tQueue.add(() async {
        tResults.add(1);

        Timer.run(() async {
          await Future.microtask(() => null);
          tShouldCall();
        });

        tResults.add(2);
      }, waitForTimers: true);

      expect(tResults, [1, 2]);
    });

    test(
      'should be able to create timers inside of work that throws',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldNotCall = expectAsync0(() => null, count: 0);

        runZonedGuarded(
          () async {
            await expectLater(
              tQueue.add(() async {
                tResults.add(1);

                Timer.run(() async {
                  tResults.add(2);
                  await Future.microtask(() => null);
                  throw _TestException('SWQ Error');
                  // ignore: dead_code
                  tShouldNotCall();
                });

                return 1;
              }, waitForTimers: true),
              completion(1),
            );

            expect(tResults, [1, 2]);
          },
          (error, stack) {
            if (error is _TestException) {
              expect(error.message, 'SWQ Error');
            } else {
              Error.throwWithStackTrace(error, stack);
            }
          },
        );
      },
    );

    test('should be able to create timers, and then cancel work', () async {
      runZonedTimer(() async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldNotCall = expectAsync0(() => null, count: 0);

        tQueue.add(() async {
          tResults.add(1);

          Timer.run(() async {
            tResults.add(2);
            await Future.microtask(() => null);
            tShouldNotCall();
            tResults.add(3);
          });

          tResults.add(4);
        }, waitForTimers: true);

        tQueue.add(() async {
          await Future.microtask(() => null);
          tResults.add(5);
        }, waitForTimers: true);

        // Allow one tick to let the microtasks run.
        await Future.microtask(() => null);

        await tQueue.clear();

        expect(tResults, [1, 4, 2]);
      });
    });

    test(
      'should be able to create timers, and then cancel work with a synchronous tail run',
      () async {
        runZonedTimer(() async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];
          final tShouldNotCall = expectAsync0(() => null, count: 0);

          tQueue.add(() async {
            tResults.add(1);

            Timer(const Duration(milliseconds: 1), () async {
              tResults.add(2);
              await Future.microtask(() => null);
              tShouldNotCall();
              tResults.add(3);
            });

            tResults.add(4);
          }, waitForTimers: true);

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(5);
          }, waitForTimers: true);

          await tQueue.clear();

          expect(tResults, [1, 4]);
        });
      },
    );

    test(
      'should be able to create timers in uncancelable work, and then attempt to cancel the work',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 1);
        final tShouldNotCall = expectAsync0(() => null, count: 0);

        final tFuture = tQueue.add(
          () async {
            tResults.add(1);

            await Future.microtask(() => null);

            Timer.run(() async {
              tShouldCall();
              tResults.add(2);
              await Future.microtask(() => null);
              tResults.add(3);
            });

            await Future.microtask(() => null);

            tResults.add(4);
          },
          onCancel: () {
            return false;
          },
          waitForTimers: true,
        );

        tQueue.add(() async {
          tResults.add(5);

          Timer.run(() async {
            tShouldNotCall();
            tResults.add(6);
            await Future.microtask(() => null);
            tResults.add(7);
          });
        }, waitForTimers: true);

        // Allow one tick to let the microtasks run.
        await Future.microtask(() => null);

        // One more tick
        await Future.microtask(() => null);

        await expectLater(tFuture, completes);

        await tQueue.clear();

        expect(tResults, [1, 4, 2, 3, 5]);
      },
    );

    test('can use custom zones inside of work', () async {
      final tQueue = SequentialWorkQueue();
      final tResults = <int>[];

      await tQueue.add(() async {
        tResults.add(1);

        await runZonedGuarded(
          () async {
            tResults.add(2);
            Timer.run(() {
              tResults.add(3);
            });
          },
          (error, stackTrace) {
            tResults.add(4);
          },
        );

        tResults.add(5);
      }, waitForTimers: true);

      expect(tResults, [1, 2, 5]);
    });

    test(
      'can use custom zones inside of work but not wait for async',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];

        await tQueue.add(() async {
          tResults.add(1);

          await runZonedGuarded(
            () async {
              tResults.add(2);
              Timer.run(() {
                tResults.add(3);
              });
            },
            (error, stackTrace) {
              tResults.add(4);
            },
          );

          tResults.add(5);
        }, waitForTimers: true);

        expect(tResults, [1, 2, 5]);

        await tQueue.clear();
      },
    );

    test('can use a future to cancel work', () async {
      runZonedTimer(() async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 1);
        final tShouldNotCall = expectAsync0(() => null, count: 0);

        tQueue.add(
          () async {
            tResults.add(1);

            Timer.run(() async {
              tShouldNotCall();
              tResults.add(2);
            });

            tResults.add(3);
          },
          onCancel: () async {
            tResults.add(4);
            await Future.microtask(() => null);
            tShouldCall();
            return true;
          },
          waitForTimers: true,
        );

        final tFuture = tQueue.clear();
        // Tick once to let the microtasks run.
        await Future.microtask(() => null);

        await tFuture;

        expect(tResults, [1, 3, 4]);
      });
    });

    test('can use a future to not cancel work', () async {
      runZonedTimer(() async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 2);

        tQueue.add(
          () async {
            tResults.add(1);

            Timer.run(() async {
              tShouldCall();
              tResults.add(2);
            });

            tResults.add(3);
          },
          onCancel: () async {
            tResults.add(4);
            await Future.microtask(() => null);
            tShouldCall();
            return false;
          },
          waitForTimers: true,
        );

        final tFuture = tQueue.clear();
        // Tick once to let the microtasks run.
        await Future.microtask(() => null);

        await tFuture;

        expect(tResults, [1, 3, 4, 2]);
      });
    });

    test('can use a future to not cancel work with an error', () async {
      final tShouldCall = expectAsync0(() => null, count: 4);
      final tShouldNotCall = expectAsync0(() => null, count: 0);

      runZonedGuarded(
        () {
          runZonedTimer(() async {
            final tQueue = SequentialWorkQueue();
            final tResults = <int>[];

            tQueue.add(
              () async {
                tResults.add(1);

                Timer.run(() async {
                  tShouldCall();
                  throw _TestException('RealError');
                  // ignore: dead_code
                  tResults.add(2);
                });

                tResults.add(3);
              },
              onCancel: () async {
                tShouldCall();
                tResults.add(4);
                await Future.microtask(() => null);
                throw _TestException('CancelError');
                // ignore: dead_code
                tShouldNotCall();
                return true;
              },
              waitForTimers: true,
            );

            final tFuture = tQueue.clear();
            // Tick once to let the microtasks run.
            await Future.microtask(() => null);

            await tFuture;

            expect(tResults, [1, 3, 4]);
          });
        },
        (error, stack) {
          if (error is _TestException) {
            tShouldCall();
            expect(error.message, anyOf('CancelError', 'RealError'));
          } else {
            Error.throwWithStackTrace(error, stack);
          }
        },
      );
    });

    test(
      'can cancel a timer and that should finish a clear operation',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldNotCall = expectAsync0(() => null, count: 0);
        late Timer tTimer;

        final tAddFuture = tQueue.add(
          () async {
            tResults.add(1);

            tTimer = Timer(const Duration(milliseconds: 500), () {
              tShouldNotCall();
              tResults.add(2);
            });

            tResults.add(3);
          },
          onCancel: () async {
            return true;
          },
          waitForTimers: true,
        );

        tTimer.cancel();

        await tAddFuture;
        final tClearFuture = tQueue.clear();
        await tClearFuture;

        expect(tResults, [1, 3]);
      },
    );
  });

  group('periodic timers', () {
    test('should be able to create periodic timers inside of work', () async {
      final tQueue = SequentialWorkQueue();
      final tResults = <int>[];
      final tShouldCall = expectAsync0(() => null, count: 3);
      int tCounter = 0;

      await runZonedTimer(() async {
        await tQueue.add(() async {
          tResults.add(1);

          Timer.periodic(const Duration(milliseconds: 1), (timer) async {
            tShouldCall();
            await Future.microtask(() => null);
            expect(timer.isActive, isTrue);
            expect(timer.tick, isNonZero);
            tResults.add(2);

            tCounter++;
            if (tCounter == 3) {
              timer.cancel();
            }
          });

          tResults.add(3);
        }, waitForPeriodicTimers: true);

        expect(tResults, [1, 3, 2, 2, 2]);
      });
    });

    test(
      'should be able to create periodic timers inside of work that throws',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 3);
        final tShouldNotCall = expectAsync0(() => null, count: 0);
        int tCounter = 0;

        runZonedGuarded(
          () async {
            await runZonedTimer(() async {
              await expectLater(
                tQueue.add(() async {
                  tResults.add(1);

                  Timer.periodic(const Duration(milliseconds: 1), (
                    timer,
                  ) async {
                    tShouldCall();
                    tCounter++;
                    if (tCounter == 3) {
                      timer.cancel();
                    }
                    tResults.add(2);
                    throw _TestException('SWQ Error');
                    // ignore: dead_code
                    tShouldNotCall();
                  });

                  return 1;
                }, waitForPeriodicTimers: true),
                completion(1),
              );

              expect(tResults, [1, 2, 2, 2]);
            });
          },
          (error, stack) {
            if (error is _TestException) {
              expect(error.message, 'SWQ Error');
            } else {
              Error.throwWithStackTrace(error, stack);
            }
          },
        );
      },
    );

    test(
      'should be able to create periodic timers, and then cancel work',
      () async {
        await runZonedTimer(() async {
          final tQueue = SequentialWorkQueue();
          final tResults = <int>[];
          final tShouldCall = expectAsync0(() => null, count: 1);
          final tShouldNotCall = expectAsync0(() => null, count: 0);
          int tCounter = 0;

          tQueue.add(() async {
            tResults.add(1);

            Timer.periodic(const Duration(milliseconds: 1), (timer) async {
              tShouldCall();
              tCounter++;
              if (tCounter == 3) {
                tShouldNotCall();
                timer.cancel();
              }
              tResults.add(2);
            });

            tResults.add(3);
          }, waitForPeriodicTimers: true);

          tQueue.add(() async {
            await Future.microtask(() => null);
            tResults.add(4);
          });

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          await tQueue.clear();

          expect(tResults, [1, 3, 2]);
        });
      },
    );

    test(
      'should be able to create periodic timers in uncancelable work, and then attempt to cancel the work',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 3);
        final tShouldNotCall = expectAsync0(() => null, count: 0);
        int tCounter = 0;

        runZonedTimer(() async {
          final tFuture = tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() => null);

              Timer.periodic(const Duration(milliseconds: 1), (timer) async {
                tShouldCall();
                tCounter++;
                if (tCounter == 3) {
                  timer.cancel();
                }
                tResults.add(2);
              });

              tResults.add(3);
            },
            onCancel: () {
              return false;
            },
            waitForPeriodicTimers: true,
          );

          tQueue.add(() async {
            tResults.add(4);

            Timer.periodic(const Duration(milliseconds: 1), (timer) async {
              tShouldNotCall();
              tResults.add(5);
            });
          }, waitForPeriodicTimers: true);

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          // One more tick
          await Future.microtask(() => null);

          await expectLater(tFuture, completes);

          await tQueue.clear();

          expect(tResults, [1, 3, 2, 2, 2, 4]);
        });
      },
    );

    test(
      'should be able to create periodic timers in future uncancellable work, and then attempt to cancel the work',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 3);
        final tShouldNotCall = expectAsync0(() => null, count: 0);
        int tCounter = 0;

        runZonedTimer(() async {
          final tFuture = tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() => null);

              Timer.periodic(const Duration(milliseconds: 1), (timer) async {
                tShouldCall();
                tCounter++;
                if (tCounter == 3) {
                  timer.cancel();
                }
                tResults.add(2);
              });

              tResults.add(3);
            },
            onCancel: () async {
              return false;
            },
            waitForPeriodicTimers: true,
          );

          tQueue.add(() async {
            tResults.add(4);

            Timer.periodic(const Duration(milliseconds: 1), (timer) async {
              tShouldNotCall();
              tResults.add(5);
            });
          }, waitForPeriodicTimers: true);

          // Allow one tick to let the microtasks run.
          await Future.microtask(() => null);

          // One more tick
          await Future.microtask(() => null);

          await expectLater(tFuture, completes);

          await tQueue.clear();

          expect(tResults, [1, 3, 2, 2, 2, 4]);
        });
      },
    );

    test(
      'should be able to create periodic timers in future cancellable work, and then cancel the work',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 1);
        final tShouldNotCall = expectAsync0(() => null, count: 0);
        int tCounter = 0;

        await runZonedTimer(() async {
          final tFuture = tQueue.add(
            () async {
              tResults.add(1);

              await Future.microtask(() => null);

              Timer.periodic(const Duration(milliseconds: 1), (timer) async {
                tShouldCall();
                tCounter++;
                if (tCounter == 3) {
                  timer.cancel();
                }
                tResults.add(2);
              });

              tResults.add(3);
            },
            onCancel: () async {
              return true;
            },
            waitForPeriodicTimers: true,
          );

          tQueue.add(() async {
            tResults.add(4);

            Timer.periodic(const Duration(milliseconds: 1), (timer) async {
              tShouldNotCall();
              tResults.add(5);
            });
          }, waitForPeriodicTimers: true);

          // Allow two ticks to let the microtasks run.
          await Future.microtask(() => null);
          await Future.microtask(() => null);

          expectLater(tFuture, completes);

          await tQueue.clear();

          expect(tResults, [1, 3, 2]);
        });
      },
    );

    test(
      'should be able to create periodic timers in future cancellable work, and then cancel the work. Support errors',
      () async {
        final tShouldCall = expectAsync0(() => null, count: 5);
        final tShouldNotCall = expectAsync0(() => null, count: 0);

        runZonedGuarded(
          () async {
            await runZonedTimer(() async {
              final tQueue = SequentialWorkQueue();
              final tResults = <int>[];
              int tCounter = 0;

              tQueue.add(
                () async {
                  tResults.add(1);

                  Timer.periodic(const Duration(milliseconds: 1), (
                    timer,
                  ) async {
                    tShouldCall();
                    tCounter++;
                    if (tCounter == 3) {
                      timer.cancel();
                    }
                    tResults.add(2);
                  });

                  tResults.add(3);
                },
                onCancel: () async {
                  tShouldCall();
                  tResults.add(4);
                  await Future.microtask(() => null);
                  throw _TestException('CancelError');
                  // ignore: dead_code
                  tShouldNotCall();
                  return true;
                },
                waitForPeriodicTimers: true,
              );

              final tFuture = tQueue.clear();
              // Tick once to let the microtasks run.
              await Future.microtask(() => null);

              await tFuture;

              expect(tResults, [1, 3, 4, 2, 2, 2]);
            });
          },
          (error, stack) {
            if (error is _TestException) {
              tShouldCall();
              expect(error.message, 'CancelError');
            } else {
              Error.throwWithStackTrace(error, stack);
            }
          },
        );
      },
    );

    test('can use custom zones inside of work', () async {
      final tQueue = SequentialWorkQueue();
      final tResults = <int>[];
      final tShouldCall = expectAsync0(() => null, count: 3);
      int tCounter = 0;

      runZonedTimer(() async {
        await tQueue.add(() async {
          tResults.add(1);

          runZoned(() {
            tResults.add(2);
            Timer.periodic(const Duration(milliseconds: 1), (timer) async {
              tShouldCall();
              tCounter++;
              if (tCounter == 3) {
                timer.cancel();
              }
              tResults.add(3);
            });
          });

          tResults.add(5);
        }, waitForPeriodicTimers: true);

        expect(tResults, [1, 2, 5, 3, 3, 3]);
      });
    });

    test(
      'can use custom zones inside of work but not wait for async',
      () async {
        final tQueue = SequentialWorkQueue();
        final tResults = <int>[];
        final tShouldCall = expectAsync0(() => null, count: 10);
        int tCounter = 0;

        runZonedTimer(() async {
          await tQueue.add(() async {
            tResults.add(1);

            runZoned(() {
              tResults.add(2);
              Timer.periodic(const Duration(milliseconds: 1), (timer) async {
                tShouldCall();
                tCounter++;
                if (tCounter == 10) {
                  timer.cancel();
                }
                tResults.add(3);
              });
            });

            tResults.add(5);
          }, waitForPeriodicTimers: true);

          expect(tResults, [1, 2, 5, 3, 3, 3]);
        });
      },
    );
  });
}

T runZonedTimer<T>(T Function() callback) {
  return runZoned<T>(
    callback,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        // We want to execute asap.
        // We aren't going to cancel any timers either.
        Zone.root.scheduleMicrotask(f);

        return parent.createTimer(zone, duration, () {});
      },
      createPeriodicTimer: (self, parent, zone, period, f) {
        // We want to execute asap.
        final tTimer = _TestPeriodicTimer();

        void fTick() {
          tTimer._tick++;
          f(tTimer);

          if (tTimer.isActive) {
            Zone.root.scheduleMicrotask(() {
              if (tTimer.isActive) {
                fTick();
              }
            });
          }
        }

        Zone.root.scheduleMicrotask(() {
          if (tTimer.isActive) {
            fTick();
          }
        });

        return tTimer;
      },
    ),
  );
}

class _TestException implements Exception {
  final String message;

  _TestException(this.message);

  @override
  String toString() {
    return message;
  }
}

class _TestPeriodicTimer implements Timer {
  @override
  void cancel() {
    _isActive = false;
  }

  bool _isActive = true;

  @override
  bool get isActive => _isActive;

  int _tick = 0;

  @override
  int get tick => _tick;
}
