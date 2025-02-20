// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/foundation.dart';

// TODO: Handle onError. Overall organization needs to be cleaned up.
class SynchronousErrorableFuture<T> extends SynchronousFuture<T> {
  final T _value;

  SynchronousErrorableFuture(this._value) : super(_value);

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    final dynamic tResult = onValue(_value);

    if (tResult is Future<R>) {
      return tResult;
    }

    return SynchronousErrorableFuture<R>(tResult as R);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) =>
      then(
        (value) => SynchronousErrorableFuture(value),
      );

  static Future<List<T>> wait<T>(Iterable<Future<T>> futures,
      {bool eagerError = false, void Function(T successValue)? cleanUp}) {
    final List<Future<T>> tOtherFutures = [];
    final List<SynchronousFuture<T>> tSyncFutures = [];
    final tFutureTracker = <bool>[];

    for (final tFuture in futures) {
      if (tFuture is SynchronousFuture<T>) {
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

    for (final tFuture in tSyncFutures) {
      tFuture.then((value) {
        tSyncValues.add(value);
      });
    }

    if (tOtherFutures.isEmpty) {
      // Only sync futures. Just return the list synchronously.
      return SynchronousErrorableFuture<List<T>>(tSyncValues);
    }

    // Mixed...
    final tCompleter = Completer<List<T>>();

    tAsyncFutures!.then((asyncValues) {
      // We have both value lists now. Assemble in the right order and return.
      var tSyncIndex = 0;
      var tAsyncIndex = 0;

      tCompleter.complete([
        for (var sync in tFutureTracker)
          if (sync) ...[
            tSyncValues[tSyncIndex++],
          ] else if (!sync)
            tSyncValues[tAsyncIndex++],
      ]);
    }).catchError((e, stackTrace) {
      tCompleter.completeError(e, stackTrace);
    });

    return tCompleter.future;
  }
}
