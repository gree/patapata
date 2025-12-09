// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

/// A class that extends Flutter's [SynchronousFuture] with error handling.
/// In general, the use of this class should be avoided.
///
/// If this Future is included in [Future.wait], its result will not be included in the return value.
/// Instead, use [SynchronousErrorableFuture.wait].
class SynchronousErrorableFuture<T> implements Future<T> {
  final dynamic _value;
  final StackTrace? _stackTrace;

  final bool _hasError;

  SynchronousErrorableFuture(T value)
    : _hasError = false,
      _stackTrace = null,
      _value = value;

  SynchronousErrorableFuture.error(Object error, [this._stackTrace])
    : _hasError = true,
      _value = error;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    try {
      final FutureOr<R> tResult;
      if (_hasError) {
        if (onError == null) {
          return SynchronousErrorableFuture<R>.error(
            _value,
            _stackTrace ?? StackTrace.empty,
          );
        }

        if (onError is Function(Object, StackTrace)) {
          tResult = onError(_value, _stackTrace ?? StackTrace.empty);
        } else if (onError is Function(Object)) {
          tResult = onError(_value);
        } else {
          throw ArgumentError.value(
            onError,
            "onError",
            "Error handler must accept one Object or one Object and a StackTrace"
                " as arguments, and return a value of the returned future's type",
          );
        }
      } else {
        tResult = onValue(_value);
      }

      return switch (tResult) {
        final Future<R> result => result,
        final R result => SynchronousErrorableFuture<R>(result),
      };
    } catch (e, stackTrace) {
      if (_hasError && e == _value) {
        return SynchronousErrorableFuture<R>.error(_value, _stackTrace);
      }
      return SynchronousErrorableFuture<R>.error(e, stackTrace);
    }
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    if (!_hasError) {
      return this;
    }

    if (test != null && !test(_value)) {
      return this;
    }

    return then(
      (value) => SynchronousErrorableFuture<T>(value), // coverage:ignore-line
      onError: onError,
    );
  }

  @override
  Stream<T> asStream() {
    final StreamController<T> controller = StreamController<T>();
    controller.add(_value);
    controller.close();
    return controller.stream;
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    final tFuture = (_hasError)
        ? Future<T>.error(_value, _stackTrace)
        : Future<T>.value(_value);
    return tFuture.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    try {
      final FutureOr<void> result = action();
      if (result is Future) {
        return result.then<T>((dynamic value) => _value);
      }

      return (_hasError)
          ? SynchronousErrorableFuture<T>.error(_value, _stackTrace)
          : this;
    } catch (e, stackTrace) {
      return SynchronousErrorableFuture<T>.error(e, stackTrace);
    }
  }

  /// When including [SynchronousErrorableFuture] in [Future.wait], use this method instead.
  static Future<List<T>> wait<T>(
    Iterable<Future<T>> futures, {
    bool eagerError = false,
    void Function(T successValue)? cleanUp,
  }) {
    final List<Future<T>> tOtherFutures = [];
    final List<SynchronousErrorableFuture<T>> tSyncFutures = [];
    final tFutureTracker = <bool>[];

    for (final tFuture in futures) {
      if (tFuture is SynchronousErrorableFuture<T>) {
        tSyncFutures.add(tFuture);
        tFutureTracker.add(true);
      } else {
        tOtherFutures.add(tFuture);
        tFutureTracker.add(false);
      }
    }

    if (tOtherFutures.isEmpty && tSyncFutures.isEmpty) {
      // Avoid unneeded calculations and just return now.
      return SynchronousErrorableFuture<List<T>>(<T>[]);
    }

    final tAsyncFutures = tOtherFutures.isNotEmpty
        ? Future.wait<T>(
            tOtherFutures,
            eagerError: eagerError,
            cleanUp: cleanUp,
          )
        : null;

    if (tSyncFutures.isEmpty) {
      // Only async futures. Just use the native version.
      return tAsyncFutures!;
    }

    final tSyncValues = <T>[];

    Object? tError;
    StackTrace? tStackTrace;
    for (final tFuture in tSyncFutures) {
      tFuture
          .then((value) {
            tSyncValues.add(value);
          })
          .catchError((e, stackTrace) {
            if (tError == null) {
              tError = e;
              tStackTrace = stackTrace;
            }

            throw e;
          });
    }

    if (tError != null) {
      tAsyncFutures?.ignore();
      return SynchronousErrorableFuture<List<T>>.error(tError!, tStackTrace);
    }

    if (tOtherFutures.isEmpty) {
      // Only sync futures. Just return the list synchronously.
      return SynchronousErrorableFuture<List<T>>(tSyncValues);
    }

    // Mixed...
    final tCompleter = Completer<List<T>>();

    tAsyncFutures!
        .then((asyncValues) {
          // We have both value lists now. Assemble in the right order and return.
          var tSyncIndex = 0;
          var tAsyncIndex = 0;

          tCompleter.complete([
            for (var sync in tFutureTracker)
              if (sync) ...[
                tSyncValues[tSyncIndex++],
              ] else if (!sync)
                asyncValues[tAsyncIndex++],
          ]);
        })
        .catchError((e, stackTrace) {
          tCompleter.completeError(e, stackTrace);
        });

    return tCompleter.future;
  }
}
