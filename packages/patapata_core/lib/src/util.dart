// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';

/// A value that can be used as a 32 bit integer.
/// It's value is just `pata` in ascii hexidecimal.
const int kPataInHex = 0x70617461;

/// Determines if [T] is a subclass of another [S]
bool typeIs<T, S>() => <T>[] is List<S>;

/// Set this to execute a callback every time [scheduleFunction]
/// is executed, after a frame has been scheduled, but before the
/// post frame callback is set.
/// Mostly used for testing purposes as a way to pump automatically.
@visibleForTesting
VoidCallback? onPostFrameCallback;

/// Sets a mock method call handler for the given [MethodChannel] for testing purposes.
///
/// The mock method call handler is a function that is called when a method call is made on the [MethodChannel].
/// By default, this function does nothing.
/// However, in testing code, this function should be set to
/// [TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler] to allow
/// integration with the testing framework.
///
/// If you use the [createApp] function defined in patapata_core_test_utils.dart this is done for you.
@visibleForTesting
void Function(MethodChannel, Future<Object?>? Function(MethodCall)?)
testSetMockMethodCallHandler = (channel, handler) {
  // Do nothing by default.
};

/// Sets a mock stream handler for the given [EventChannel] for testing purposes.
///
/// The mock stream handler is a function that is called when an event is sent on the [EventChannel].
/// By default, this function does nothing.
/// However, in testing code, this function should be set to
/// [TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler] to allow
/// integration with the testing framework.
///
/// If you use the [createApp] function defined in patapata_core_test_utils.dart, this is done for you.
// coverage:ignore-start
@visibleForTesting
void Function(EventChannel, TestMockStreamHandler?) testSetMockStreamHandler =
    (channel, handler) {
      // Do nothing by default.
    };
// coverage:ignore-end

/// [compute] doesn't work in a test environment or on the web.
/// This function runs compute on supported platforms but on
/// unsupported platforms runs a simple microtask via [scheduleMicrotask].
FutureOr<R> platformCompute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
}) {
  if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
    // coverage:ignore-start
    return compute(callback, message, debugLabel: debugLabel);
    // coverage:ignore-end
  } else {
    final Completer<R> tCompleter = Completer();

    scheduleMicrotask(() async {
      try {
        final R tResult = await callback(message);
        tCompleter.complete(tResult);
      } catch (error, stackTrace) {
        tCompleter.completeError(error, stackTrace);
      }
    });

    return tCompleter.future;
  }
}

/// Executes [func] asynchronously.
/// If this application is active and rendering, it will use
/// [SchedulerBinding.addPostFrameCallback], ensuring that it will run
/// with a call to [SchedulerBinding.scheduleFrame].
/// If the application is not active and rendering, ie, in the background,
/// it will simply add a 1ms timer and execute [func] after that time.
void scheduleFunction(VoidCallback func) {
  if (SchedulerBinding.instance.framesEnabled == true) {
    SchedulerBinding.instance.scheduleFrame();
    // This is here to allow test frameworks to call pump() correctly.
    if (onPostFrameCallback != null) {
      onPostFrameCallback!();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      func();
    });

    return;
  }
  // coverage:ignore-start
  Timer(const Duration(milliseconds: 1), func);
  // coverage:ignore-end
}

extension DateDateTimeExtension on DateTime {
  /// Dart's [DateTime.toIso8601String] function includes milliseconds and microseconds.
  /// Many backend systems don't support this, and for the most part, time information
  /// stored is fine if stored with second accuracy only.
  ///
  /// This function returns a [String] in ISO8601 format, in UTC, down to second accuracy.
  String toUTCIso8601StringNoMSUS() {
    if (!isUtc) {
      return toUtc().toUTCIso8601StringNoMSUS();
    }

    String y = (year >= -9999 && year <= 9999)
        ? '$year'.padLeft(4, '0')
        : '$year'.padLeft(6, '0');
    String m = '$month'.padLeft(2, '0');
    String d = '$day'.padLeft(2, '0');
    String h = '$hour'.padLeft(2, '0');
    String min = '$minute'.padLeft(2, '0');
    String sec = '$second'.padLeft(2, '0');

    return '$y-$m-${d}T$h:$min:${sec}Z';
  }
}

const _kFakeNowLocalConfigKey = 'patapataFakeNow';
DateTime? _now;
final _fakeTimeElapsedSince = Stopwatch();

/// Set a fake time that [now] will return.
/// Set to null to return to real time again.
///
/// If [persist] is set to true,
/// it is persisted between restarts by saving the time to [LocalConfig].
///
/// If [elapse] is set to true, the time returned from [now]
/// will be [fakeNow] plus the elapsed time since this function
/// was executed.
/// This allows for syncing time to say, a remote server.
///
/// Warning:
/// Using [elapse] set to true in combination with [persist] set to true
/// will result in only [fakeNow] being persisted, causing the value
/// loaded on app restart to be exactly [fakeNow] and not any time that
/// has elapsed after it was saved.
void setFakeNow(DateTime? fakeNow, {bool persist = true, bool elapse = false}) {
  _now = fakeNow;

  if (elapse) {
    _fakeTimeElapsedSince
      ..reset()
      ..start();
  } else {
    _fakeTimeElapsedSince.stop();
  }

  if (persist) {
    if (fakeNow == null) {
      getApp().localConfig.reset(_kFakeNowLocalConfigKey);
    } else {
      getApp().localConfig.setString(
        _kFakeNowLocalConfigKey,
        fakeNow.toUTCIso8601StringNoMSUS(),
      );
    }
  }

  _fakeNowStreamController.add(fakeNow);
}

/// Load the saved fake time from [LocalConfig], previously set by [setFakeNow].
void loadFakeNow() {
  final tFakeNowString = getApp().localConfig.getString(
    _kFakeNowLocalConfigKey,
  );

  if (tFakeNowString.isEmpty) {
    return;
  }

  final tDateTime = DateTime.tryParse(tFakeNowString);

  if (tDateTime == null) {
    return;
  }

  _now = tDateTime;
}

/// Whether is fake time is currently set or not via [setFakeNow].
bool get fakeNowSet => _now != null;

final _fakeNowStreamController = StreamController<DateTime?>.broadcast();

/// A stream to listen to when fake now changes.
Stream<DateTime?> get fakeNowStream => _fakeNowStreamController.stream;

/// Get the current [DateTime].
/// The value returned here can be overriden for
/// debug or testing purposes with [setFakeNow].
DateTime get now =>
    (_fakeTimeElapsedSince.isRunning && _now != null
        ? _now!.add(_fakeTimeElapsedSince.elapsed)
        : _now) ??
    DateTime.now();

/// Typedef for the inline onCancel callback.
@visibleForTesting
typedef TestMockStreamHandlerOnCancelCallback =
    void Function(Object? arguments);

/// Typedef for the inline onListen callback.
@visibleForTesting
typedef TestMockStreamHandlerOnListenCallback =
    void Function(Object? arguments, TestMockStreamHandlerEventSink events);

/// Test class for testing stream handlers.
/// The app does not reference this class.
@visibleForTesting
abstract class TestMockStreamHandler {
  /// Create a [TestMockStreamHandler].
  TestMockStreamHandler();

  /// Create a new inline [TestMockStreamHandler] with the given [onListen] and
  /// [onCancel] handlers.
  factory TestMockStreamHandler.inline({
    required TestMockStreamHandlerOnListenCallback onListen,
    TestMockStreamHandlerOnCancelCallback? onCancel,
  }) => _InlineMockStreamHandler(onListen: onListen, onCancel: onCancel);

  /// Handler for the listen event.
  void onListen(Object? arguments, TestMockStreamHandlerEventSink events);

  /// Handler for the cancel event.
  void onCancel(Object? arguments);
}

class _InlineMockStreamHandler extends TestMockStreamHandler {
  _InlineMockStreamHandler({
    required TestMockStreamHandlerOnListenCallback onListen,
    TestMockStreamHandlerOnCancelCallback? onCancel,
  }) : _onListenInline = onListen,
       _onCancelInline = onCancel;

  final TestMockStreamHandlerOnListenCallback _onListenInline;
  final TestMockStreamHandlerOnCancelCallback? _onCancelInline;

  @override
  void onListen(Object? arguments, TestMockStreamHandlerEventSink events) =>
      _onListenInline(arguments, events);

  @override
  void onCancel(Object? arguments) => _onCancelInline?.call(arguments);
}

/// Class for events referenced in [TestMockStreamHandler.onListen].
/// The app does not reference this class.
@visibleForTesting
abstract class TestMockStreamHandlerEventSink {
  /// Send a success event.
  void success(Object? event);

  /// Send an error event.
  void error({required String code, String? message, Object? details});

  /// Send an end of stream event.
  void endOfStream();
}
