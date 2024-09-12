// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'dart:ffi' if (dart.library.html) 'fake_ffi.dart';

import 'app.dart';
import 'util.dart';
import 'error.dart';

typedef ReportRecordFilter = ReportRecord? Function(ReportRecord record);

const int _kLineLimit = 1023;

void _debugLogMuter(String? message, {int? wrapWidth}) {}

/// Settings for [Log] system
mixin LogEnvironment {
  /// The log level ([Level.value]) that patapata processes.
  int get logLevel;

  /// If true, outputs the contents of the log to the debug console.
  bool get printLog => kDebugMode;
}

/// Provides an implementation for [Logger.onRecord].
///
/// When a message is added to [Logger], [report] is automatically called and
/// [ReportRecord] filtered by [filter] is added to [reports].
///
/// Filters can be added with [addFilter] or [ignoreType].
/// If a filter returns null, that record is ignored.
///
/// You can add a filter that changes the log level of records that match regular
/// expressions in the remote config (`patapataLogLevelFilters`).
///
/// Example: Firebase Remote Config
/// ```json
/// {
///   'foo': 800,
///   'bar': 1000
/// }
/// ```
///
/// Each filter is processed from the top.
///
/// The log level to be processed can be set in [LogEnvironment.logLevel] or
/// in the remote config (`patapata_log_level`).
/// (default is [Level.INFO])
///
/// If settings are made in both [LogEnvironment.logLevel] and the remote config,
/// the remote config setting takes precedence.
///
/// This class is automatically initialized during the initialization of
/// patapata [App] and can be accessed from [App.log].
class Log {
  static const String kReportMechanism = 'patapataReport';
  static const String kRootLogMechanism = 'patapataRootLog';
  static const String kUnhandledErrorMechanism = 'patapataUnhandledError';
  static const String kFlutterErrorMechanism = 'patapataFlutterError';
  static const String kNativeMechanism = 'patapataNativeThrowable';

  static const String kRemoteConfigLevelFilters = 'patapataLogLevelFilters';

  final App app;
  StreamSubscription<LogRecord>? _rootLogPrintSubscription;
  DebugPrintCallback? _originalDebugPrint;
  StreamSubscription<LogRecord>? _rootLogDelegateSubscription;
  FlutterExceptionHandler? _originalOnFlutterError;
  final _filters = <ReportRecordFilter>[];
  final _typeFilters = <Type>{};

  final _duplicateTracker = Expando('patapata.Log');

  final _reportStreamController = StreamController<ReportRecord>.broadcast();

  /// Returns the stream of [ReportRecord] processed by [report].
  Stream<ReportRecord> get reports => _reportStreamController.stream;

  Log(this.app) {
    final tEnvironment = app.environment;
    logPrinting = switch (tEnvironment) {
      LogEnvironment() => tEnvironment.printLog,
      // debugPrint's implementation is actually quite heavy even in release mode.
      // So we disable it in release mode.
      _ => kDebugMode
    };
    setLevelByValue(-kPataInHex);

    _rootLogDelegateSubscription =
        Logger.root.onRecord.listen(_onRootLogRecordDelegate);

    _originalOnFlutterError = FlutterError.onError;
    FlutterError.onError = _onFlutterError;

    App.appStageChangeStream
        .firstWhere((e) =>
            e == app && e.stage == AppStage.initializingPluginsWithRemoteConfig)
        .then((_) {
      // When RemoteConfig is ready in our app, start listening
      // for RemoteConfig changes and grab and parse our configuration.
      _onRemoteConfigChange();
      app.remoteConfig.addListener(_onRemoteConfigChange);
    });
  }

  Map<RegExp, Level?>? _levelFilters;
  String? _remoteConfigLevelFiltersString;

  void _onRemoteConfigChange() {
    final tLevelFiltersString =
        app.remoteConfig.getString(Log.kRemoteConfigLevelFilters);

    if (_remoteConfigLevelFiltersString == tLevelFiltersString) {
      return;
    }

    _remoteConfigLevelFiltersString = tLevelFiltersString;

    if (tLevelFiltersString.isEmpty) {
      _levelFilters = null;
    } else {
      try {
        final tDecodedLevelFilters =
            (jsonDecode(tLevelFiltersString) as Map).cast<String, int?>();
        _levelFilters = {
          for (var e in tDecodedLevelFilters.entries)
            RegExp(e.key): e.value == null
                ? null
                : Level.LEVELS.firstWhere((v) => v.value == e.value!,
                    orElse: () => Level('REMOTE', e.value!)),
        };
      } catch (e) {
        // Print directly, if this was a bad error that happens
        // many many times, the report system won't have a way to
        // filter out this message and cause account limit over issues
        // all over the place.
        _print(
            'Log: RemoteConfig ${Log.kRemoteConfigLevelFilters} parsing failed: $e');
      }
    }
  }

  /// Releases each resource.
  void dispose() {
    app.remoteConfig.removeListener(_onRemoteConfigChange);

    _rootLogPrintSubscription?.cancel();
    _rootLogPrintSubscription = null;

    if (_originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }

    _rootLogDelegateSubscription?.cancel();
    _rootLogDelegateSubscription = null;

    if (_originalOnFlutterError != null) {
      FlutterError.onError = _originalOnFlutterError;
      _originalOnFlutterError = null;
    }

    _reportStreamController.close();
  }

  Level _level = Level.INFO;

  set level(Level value) {
    _level = value;
    Logger.root.level = _level;
  }

  /// The level of the log to be processed.
  Level get level => _level;

  /// Specifies the level of the log to be processed using [Level.value].
  ///
  /// If `-[kPataInHex]` is specified,
  /// [LogEnvironment.logLevel] is used. (If not set, it defaults to [Level.INFO])
  void setLevelByValue(int value) {
    final tDefaultLogLevel = app.environment is LogEnvironment
        ? (app.environment as LogEnvironment).logLevel
        : Level.INFO.value;

    if (value == -kPataInHex) {
      value = tDefaultLogLevel;
    }

    level = Level.LEVELS.firstWhere((v) => v.value == value,
        orElse: () => Level('REMOTE', value));
  }

  bool _seenBefore(Object error) {
    // From Expando's documentation...
    // The object must not be a number, a string, a boolean, `null`, a
    // `dart:ffi` pointer, a `dart:ffi` struct, or a `dart:ffi` union.
    if (error is num || error is String || error is bool) {
      return false;
    }

    if (!kIsWeb) {
      if (error is Pointer || error is Struct || error is Union) {
        return false;
      }
    }

    if (_duplicateTracker[error] == true) {
      return true;
    }

    _duplicateTracker[error] = true;
    return false;
  }

  /// If true, the log contents will be output on the debug console and system log.
  bool get logPrinting => _rootLogPrintSubscription != null;
  set logPrinting(bool value) {
    if (value) {
      _rootLogPrintSubscription ??=
          Logger.root.onRecord.listen(_onRootLogRecordPrint);

      if (debugPrint == _debugLogMuter) {
        debugPrint = _originalDebugPrint!;
      }
    } else {
      _rootLogPrintSubscription?.cancel();
      _rootLogPrintSubscription = null;

      if (debugPrint != _debugLogMuter) {
        _originalDebugPrint = debugPrint;
        debugPrint = _debugLogMuter;
      }
    }
  }

  void _print(String message) {
    if (message.isEmpty == true) {
      return;
    }

    message.split('\n').forEach((message) {
      if (utf8.encode(message).length < 1024) {
        debugPrint(message);
        return;
      }
      final tLines = _splitStringByUtf8ByteLength(message);
      for (var i = 0; i < tLines.length; i++) {
        debugPrint(tLines[i]);
      }
    });
  }

  List<String> _splitStringByUtf8ByteLength(String message) {
    return [
      ...(() sync* {
        final tRunes = message.runes.toList(growable: false);
        final tRunesLength = tRunes.length;
        int tByteLength = 0;
        int tStart = 0;

        for (var i = 0; i < tRunesLength; i++) {
          final tRune = tRunes[i];

          if (tRune <= 0xFF) {
            if (tByteLength + 1 > _kLineLimit) {
              yield message.substring(tStart, i);
              tStart = i;
              tByteLength = 0;
            }

            tByteLength++;
          } else {
            final tRuneBytesLength =
                utf8.encode(String.fromCharCode(tRune)).length;

            if (tByteLength + tRuneBytesLength > _kLineLimit) {
              yield message.substring(tStart, i);
              tStart = i;
              tByteLength = 0;
            }

            tByteLength += tRuneBytesLength;
          }
        }

        if (tStart < tRunesLength) {
          yield message.substring(tStart, tRunesLength);
        }
      })(),
    ];
  }

  void _onRootLogRecordPrint(LogRecord record) {
    _print(record.toString());

    final tError = record.error;

    if (tError is FlutterErrorDetails) {
      // Flutter errors print stack traces and everything
      // needed in the toString() method. So we are already done.
      return;
    }

    final tErrorString = tError?.toString();

    if (tErrorString != null && record.message != tErrorString) {
      _print(tErrorString);
    }

    if (record.stackTrace != null) {
      _print(record.stackTrace.toString());
    }
  }

  void _onRootLogRecordDelegate(LogRecord record) {
    if (record.object is ReportRecord) {
      report(record.object as ReportRecord);
    } else {
      report(ReportRecord.fromLogRecord(record));
    }
  }

  void _onFlutterError(FlutterErrorDetails details) {
    final Level tLevel;
    final List<String>? tFingerprint;
    if (details.exception is PatapataException) {
      final tException = details.exception as PatapataException;
      tLevel = tException.logLevel ?? Level.SEVERE;
      tFingerprint = tException.fingerprint;
    } else {
      tLevel = Level.SEVERE;
      tFingerprint = null;
    }

    report(
      ReportRecord(
        level: tLevel,
        object: details,
        error: details.exception,
        stackTrace: details.stack,
        fingerprint: tFingerprint,
        mechanism: Log.kFlutterErrorMechanism,
      ),
    );

    if (_originalOnFlutterError != null) {
      _originalOnFlutterError!(details);
    }
  }

  /// Filters [record] and adds the result to [reports].
  /// If the filter returns null, that record is ignored.
  ///
  /// This method is automatically called when a message is added to [Logger].
  void report(ReportRecord record) {
    if (record.level < level) {
      return;
    }

    if (record.object != null && _seenBefore(record.object!)) {
      return;
    }

    if (record.error != null && _seenBefore(record.error!)) {
      return;
    }

    final tRecord = filter(record);

    if (tRecord == null) {
      return;
    }

    final tError = tRecord.error;

    if (tError is PatapataException) {
      scheduleMicrotask(() {
        try {
          tError.onReported(tRecord);
        } catch (e) {
          _print(e.toString());
        }
      });
    }

    _reportStreamController.add(tRecord);
  }

  ReportRecord? _shouldIgnoreByType(ReportRecord record) =>
      record.error != null && _typeFilters.contains(record.error.runtimeType)
          ? null
          : record;

  /// Adds a filter.
  ///
  /// If the filter returns null, that record is ignored.
  void addFilter(ReportRecordFilter test) {
    _filters.add(test);
  }

  /// Removes the filter added with [addFilter].
  void removeFilter(ReportRecordFilter test) {
    _filters.remove(test);
  }

  /// Adds a filter to ignore if [ReportRecord.error] matches [type].
  void ignoreType(Type type) {
    _typeFilters.add(type);

    if (_typeFilters.length == 1) {
      _filters.add(_shouldIgnoreByType);
    }
  }

  /// Removes the filter added with [ignoreType].
  void unignoreType(Type type) {
    _typeFilters.remove(type);

    if (_typeFilters.isEmpty) {
      _filters.remove(_shouldIgnoreByType);
    }
  }

  /// Filters [object] and returns the result.
  ReportRecord? filter(ReportRecord object) {
    ReportRecord? tObject = object;

    // First check local filters
    for (var tFilter in _filters) {
      tObject = tFilter(tObject!);

      if (tObject == null) {
        return null;
      }
    }

    // Then check remote filters
    tObject = _filterFromRemote(tObject!);

    return tObject;
  }

  ReportRecord? _filterFromRemote(ReportRecord record) {
    if (_levelFilters == null) {
      return record;
    }

    for (var i in _levelFilters!.entries) {
      if (record.level == i.value) {
        continue;
      }

      if (record.message.isNotEmpty && i.key.hasMatch(record.message)) {
        if (i.value == null) {
          return null;
        }

        record = record.copyWith(level: i.value);
      }

      if (record.error != null) {
        final tToCheck = record.error!.toString();

        if (tToCheck.isNotEmpty && i.key.hasMatch(tToCheck)) {
          if (i.value == null) {
            return null;
          }

          record = record.copyWith(level: i.value);
        }
      }

      if (record.object != null) {
        final tToCheck = record.object!.toString();

        if (tToCheck.isNotEmpty && i.key.hasMatch(tToCheck)) {
          if (i.value == null) {
            return null;
          }

          record = record.copyWith(level: i.value);
        }
      }
    }

    return record;
  }
}

/// A log entry representation used to propagate information from [Logger] to
/// individual handlers.
///
/// This class is used by the [Log] system.
/// You can also use this class to send your own reports.
class ReportRecord implements LogRecord {
  @override
  final Level level;
  @override
  final String message;

  /// Non-string message passed to Logger.
  @override
  final Object? object;

  /// Logger where this record is stored.
  @override
  final String loggerName;

  /// Time when this record was created.
  @override
  final DateTime time;

  /// Unique sequence number greater than all log records created before it.
  @override
  final int sequenceNumber;

  /// Associated error (if any) when recording errors messages.
  @override
  final Object? error;

  /// Associated stackTrace (if any) when recording errors messages.
  @override
  final StackTrace? stackTrace;

  /// Zone of the calling code which resulted in this LogRecord.
  @override
  final Zone? zone;

  /// In what way this record was created/collected.
  final String mechanism;

  /// Any extra details to send with the report.
  final Map<String, Object?>? extra;

  /// Used to deduplicate events by grouping ones with the same fingerprint together.
  final List<String>? fingerprint;

  /// Creates a new instance of [ReportRecord].
  ///
  /// [message] or [object] or [error] must be specified.
  /// If [stackTrace] is not specified, it is automatically set to the stack
  /// trace of [error].
  /// If [time] is not specified, it is automatically set to the current time.
  /// If [sequenceNumber] is not specified, it is automatically set to the
  /// sequence number of the [LogRecord] with [Level.INFO] and empty [message].
  /// If [mechanism] is not specified, it is automatically set to
  /// [Log.kReportMechanism].
  ReportRecord({
    required this.level,
    String? message,
    this.object,
    this.loggerName = 'report',
    DateTime? time,
    int? sequenceNumber,
    this.error,
    StackTrace? stackTrace,
    this.zone,
    this.mechanism = Log.kReportMechanism,
    this.extra,
    this.fingerprint,
  })  : assert(message != null || object != null || error != null),
        time = time ?? DateTime.now(),
        sequenceNumber =
            sequenceNumber ?? LogRecord(Level.INFO, '', '').sequenceNumber,
        message =
            message ?? object?.toString() ?? error?.toString() ?? '<NoMessage>',
        stackTrace = (stackTrace != null && stackTrace != StackTrace.empty
                ? stackTrace
                : null) ??
            (error is Error &&
                    error.stackTrace != null &&
                    error.stackTrace != StackTrace.empty
                ? error.stackTrace
                : null);

  /// Creates a new instance of [ReportRecord] from [LogRecord].
  factory ReportRecord.fromLogRecord(LogRecord record) => ReportRecord(
        level: record.level,
        message: record.message,
        object: record.object,
        loggerName: record.loggerName,
        time: record.time,
        sequenceNumber: record.sequenceNumber,
        error: record.error,
        fingerprint: (record.error is PatapataException)
            ? (record.error as PatapataException).fingerprint
            : null,
        stackTrace: record.stackTrace,
        zone: record.zone,
        mechanism: Log.kRootLogMechanism,
      );

  @override
  String toString() => '[${level.name}] $loggerName: $message';

  /// Returns a new instance of [ReportRecord] with the specified attributes
  /// replaced.
  ReportRecord copyWith({
    Level? level,
    String? message,
    Object? object,
    String? loggerName,
    DateTime? time,
    int? sequenceNumber,
    Object? error,
    StackTrace? stackTrace,
    Zone? zone,
    String? mechanism,
    Map<String, Object?>? extra,
    List<String>? fingerprint,
  }) {
    return ReportRecord(
      level: level ?? this.level,
      message: message ?? this.message,
      object: object ?? this.object,
      loggerName: loggerName ?? this.loggerName,
      time: time ?? this.time,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      zone: zone ?? this.zone,
      mechanism: mechanism ?? this.mechanism,
      extra: extra ?? this.extra,
      fingerprint: fingerprint ?? this.fingerprint,
    );
  }
}

final Map<String, MethodChannel> _nativeLoggingMethodChannels = {};

final _nativeLogger = Logger('patapata.native');

final _nativeLoggerLevelMap = {
  0: Level('EMERGENCY', Level.SHOUT.value),
  1: Level('ALERT', Level.SHOUT.value - 10),
  2: Level('CRITICAL', Level.SHOUT.value - 20),
  3: Level('ERROR', Level.SEVERE.value),
  4: Level.WARNING,
  5: Level('NOTICE', Level.INFO.value + 10),
  6: Level.INFO,
  7: Level('DEBUG', Level.FINE.value),
};

Future<dynamic> _nativeLoggingMethodHandler(MethodCall call) async {
  if (call.method != 'logging') {
    return null;
  }

  if (call.arguments is! Map) {
    return null;
  }

  final tLoggingPackage = (call.arguments as Map).cast<String, dynamic>();

  Level tLevel = Level.INFO;

  if (tLoggingPackage['level'] is int &&
      _nativeLoggerLevelMap.containsKey(tLoggingPackage['level'] as int)) {
    tLevel = _nativeLoggerLevelMap[tLoggingPackage['level'] as int]!;
  }

  String? tMessage;

  if (tLoggingPackage['message'] is String) {
    tMessage = tLoggingPackage['message'] as String?;
  }

  DateTime tTimestamp;

  if (tLoggingPackage['timestamp'] is int) {
    tTimestamp = DateTime.fromMillisecondsSinceEpoch(
      tLoggingPackage['timestamp'] as int,
      isUtc: true,
    );
  } else {
    tTimestamp = DateTime.now();
  }

  Map<String, Object?>? tExtra;

  if (tLoggingPackage['metadata'] is String) {
    final tMetadata = tLoggingPackage['metadata'] as String?;

    if (tMetadata != null) {
      try {
        tExtra = (jsonDecode(tMetadata) as Map).cast<String, Object?>();
      } catch (e) {
        // ignore
      }
    }
  }

  NativeThrowable? tThrowable;

  if (tLoggingPackage['throwable'] is Map) {
    tThrowable = NativeThrowable.fromMap(
        (tLoggingPackage['throwable'] as Map).cast<String, dynamic>());
  }

  _nativeLogger.log(
    tLevel,
    ReportRecord(
      level: tLevel,
      message: tMessage,
      error: tThrowable,
      stackTrace: tThrowable?.chain,
      time: tTimestamp,
      extra: tExtra,
      mechanism: Log.kNativeMechanism,
    ),
  );

  return null;
}

///
/// This is a regular expression to parse and separate a single frame (line) of a
/// Java StackTrace.
///
/// `(.+?[\.].+?(?=\.))?` Capture if there is a Java package name at the beginning.
/// `([^\.]+?\.[^\.(]+?)` Capture the Java class name and method.
/// `(?:\((.+?)(?::([\d]+?))?\))?` Capture the filename if present, followed by the line number if available.
///
final RegExp _nativeAndroidFrameParser = RegExp(
    r'^(.+?[\.].+?(?=\.))?\.?([^\.]+?\.[^\.(]+?)(?:\((.+?)(?::([\d]+?))?\))?$');

///
/// This is a regular expression to parse and separate a single frame (line) of an
/// iOS StackTrace.
///
/// `.+?\s+` Drop the leading index.
/// `(.+?)` Capture the iOS Framework part.
/// `\s+.+?\s+` Ignore the memory address.
/// `(.+?)` Capture the function name.
/// `(?:\s+\+\s+(\d+)?)?` If present, capture the line number.
///
final RegExp _nativeIosFrameParser =
    RegExp(r'^.+?\s+(.+?)\s+.+?\s+(.+?)(?:\s+\+\s+(\d+)?)?$');

/// Class for exceptions that occurred natively.
///
/// By registering the MethodChannel with [registerNativeThrowableMethodChannel],
/// you can notify the patapata's [Log] system of exceptions that occurred natively.
///
/// Currently, this feature only supports Android and iOS.
///
/// example: Android (Kotlin)
///
/// dart
/// ```dart
/// NativeThrowable.registerNativeThrowableMethodChannel('patapata/logging')
/// ```
/// Android
/// ```kotlin
/// val methodChannel = MethodChannel(binding.binaryMessenger, "patapata/logging")
///
/// methodChannel.invokeMethod(
///   "logging",
///   mapOf(
///     "level" to 3,
///
///     "message" to "Log message",
///
///     "metadata" to "{\"foo\": \"bar\"}",
///
///     "timestamp" to System.currentTimeMillis(),
///
///     // throwable is Throwable class.
///     // For Android, instead of the below mapOf, toPatapataMap from a Throwable type can be used.
///     "throwable" to mapOf(
///       "type" to throwable.javaClass.name,
///       "message" to throwable.message,
///       "stackTrace" to throwable.stackTrace.map { it.toString() },
///       "cause" to throwable.cause?.run { throwableToMap(this) }
///     )
///   )
/// )
/// ```
class NativeThrowable {
  /// For Android, it's the javaClassName; for iOS, it's things like the error domain.
  final String? type;

  /// Error details.
  final String? message;

  /// A chain of stack traces.
  ///
  /// This property is represented as `stackTrace` in the Map.
  final Chain? chain;

  /// Cause of the exception.
  final NativeThrowable? cause;

  const NativeThrowable({
    this.type,
    this.message,
    this.chain,
    this.cause,
  });

  /// Registers the MethodChannel with the [name].
  ///
  /// In Native, by creating a MethodChannel with the [name] and invoking the
  /// `logging` method, you can notify the app's [Log] system.
  ///
  /// arguments: Type is Map
  /// ```json
  /// {
  ///   // Log level
  ///   // Conforms to syslog severity level.
  ///   //
  ///   // This value corresponds to the value of the Level class defined on the dart side.
  ///   // 0: Level('EMERGENCY', Level.SHOUT.value),
  ///   // 1: Level('ALERT', Level.SHOUT.value - 10),
  ///   // 2: Level('CRITICAL', Level.SHOUT.value - 20),
  ///   // 3: Level('ERROR', Level.SEVERE.value),
  ///   // 4: Level.WARNING,
  ///   // 5: Level('NOTICE', Level.INFO.value + 10),
  ///   // 6: Level.INFO,
  ///   // 7: Level('DEBUG', Level.FINE.value),
  ///   //
  ///   // If omitted, it is treated as 6.
  ///   "level": 3,
  ///
  ///
  ///   // required: Log message
  ///   "message": "Log message",
  ///
  ///   // json string of extra data
  ///   // This value is passed to [ReportRecord.extra] on the dart side.
  ///   "metadata": "{\"foo\": \"bar\"}",
  ///
  ///   // timestamp(Unix time)
  ///   "timestamp": 1234567890,
  ///
  ///   // Map of Native exception classes converted to this [NativeThrowable] class.
  ///   // For Android, by calling the `toPatapataMap` that extends the Java's `Throwable` class,
  ///   // you can convert it to the map of this class.
  ///   "throwable": Throwable.toPatapataMap()
  /// }
  /// ```
  ///
  static void registerNativeThrowableMethodChannel(String name) {
    if (!_nativeLoggingMethodChannels.containsKey(name)) {
      _nativeLoggingMethodChannels[name] = MethodChannel(name)
        ..setMethodCallHandler(_nativeLoggingMethodHandler);
    }
  }

  /// Unregisters the MethodChannel.
  static void unregisterNativeThrowableMethodChannel(String name) {
    if (_nativeLoggingMethodChannels.containsKey(name)) {
      _nativeLoggingMethodChannels[name]?.setMethodCallHandler(null);
      _nativeLoggingMethodChannels.remove(name);
    }
  }

  /// Creates a new instance of [NativeThrowable] from the Map.
  factory NativeThrowable.fromMap(Map<String, dynamic> map) {
    final tStackTrace = (map['stackTrace'] as List?)?.cast<String>();
    final tCause = map['cause'] is Map
        ? NativeThrowable.fromMap((map['cause'] as Map).cast<String, dynamic>())
        : null;

    late RegExp tMatcher;
    late int tPackageGroup;
    int? tFileGroup;
    late int tMethodGroup;
    late int tLineGroup;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        tMatcher = _nativeAndroidFrameParser;
        tPackageGroup = 1;
        tFileGroup = 3;
        tMethodGroup = 2;
        tLineGroup = 4;
        break;
      case TargetPlatform.iOS:
        tMatcher = _nativeIosFrameParser;
        tPackageGroup = 1;
        tFileGroup = null;
        tMethodGroup = 2;
        tLineGroup = 3;
        break;
      default:
        // ignore: avoid_print
        print('$defaultTargetPlatform not supported for NativeThrowable yet.');
        break;
    }

    final tChain = Chain([
      if (tStackTrace != null)
        Trace(
          tStackTrace.map(
            (v) {
              try {
                final tMatch = tMatcher.firstMatch(v);

                if (tMatch != null) {
                  final tLine = tMatch.group(tLineGroup);
                  return Frame(
                    Uri.file(
                        '${tMatch.group(tPackageGroup) ?? '<NoPackage>'}${(tFileGroup != null ? '/${tMatch.group(tFileGroup)}' : null) ?? '/<NoFileName>'}'
                            .replaceAll(' ', '<space>'),
                        windows: false),
                    tLine != null ? int.tryParse(tLine) : null,
                    null,
                    tMatch.group(tMethodGroup),
                  );
                } else {
                  return Frame.parseFriendly(v);
                }
              } catch (e) {
                return Frame.parseFriendly(v);
              }
            },
          ),
          original: tStackTrace.join('\n'),
        ),
      ...((NativeThrowable? cause) sync* {
        while (cause != null) {
          final tTraces = cause.chain?.traces;

          if (tTraces != null) {
            for (var tTrace in tTraces) {
              yield tTrace;
            }
          }

          cause = cause.cause;
        }
      })(tCause),
    ]);

    return NativeThrowable(
      type: map['type'] as String?,
      message: map['message'] as String?,
      chain: tChain.traces.isNotEmpty ? tChain : null,
      cause: tCause,
    );
  }

  /// Converts this class to a Map.
  Map<String, dynamic> toMap() {
    final tCause = cause?.toMap();
    final tFrames =
        chain?.traces.isNotEmpty == true ? chain?.traces.first.frames : null;

    final tPratformStackTrace = List.generate(tFrames?.length ?? 0, (index) {
      final tFrame = tFrames![index];
      try {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final tLibrary = tFrame.library.split('/');
            final tLine = tFrame.line != null ? ':${tFrame.line}' : '';
            final tPackageGroup = tLibrary[0].replaceAll('<NoPackage>', '');
            final tFileGroup = tLibrary[1].replaceAll('<NoFileName>', '');
            final tMethodGroup = tFrame.member ?? '';

            return ('$tPackageGroup${tPackageGroup.isNotEmpty ? '.' : ''}$tMethodGroup($tFileGroup$tLine)')
                .replaceAll('<space>', ' ');
          case TargetPlatform.iOS:
            final tLibrary = tFrame.library.split('/');
            final tLine = tFrame.line != null ? ' + ${tFrame.line}' : '';
            final tPackageGroup = tLibrary[0].replaceAll('<NoPackage>', '');
            final tMethodGroup = tFrame.member ?? '';

            // Dummy since memory address information is lost.
            return ('${index + 1} $tPackageGroup 0x0000000000000000 $tMethodGroup$tLine')
                .replaceAll('<space>', ' ');
          default:
            // ignore: avoid_print
            print(
                '$defaultTargetPlatform not supported for NativeThrowable yet.');
            return tFrame.toString();
        }
      } catch (e) {
        return tFrame.toString();
      }
    });

    return {
      'type': type,
      'message': message,
      'stackTrace': tPratformStackTrace.isNotEmpty ? tPratformStackTrace : null,
      'cause': tCause,
    };
  }
}
