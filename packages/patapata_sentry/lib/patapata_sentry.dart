// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_sentry;

import 'package:flutter/widgets.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Configuration for [SentryPlugin].
mixin SentryPluginEnvironment {
  /// Destination for sending events to Sentry.
  String get sentryDSN;

  /// Options to set for Sentry SDK.
  FutureOr<void> Function(SentryFlutterOptions)? get sentryOptions;
}

/// This plugin provides functionality for Sentry, which monitors application errors.
class SentryPlugin extends Plugin {
  StreamSubscription<ReportRecord>? _onReportSubscription;

  @override
  bool get requireRemoteConfig => true;

  SentryPluginEnvironment get _environment =>
      app.environment as SentryPluginEnvironment;

  /// Initializes the [SentryPlugin].
  @override
  FutureOr<bool> init(App app) async {
    if (app.environment is! SentryPluginEnvironment) {
      return false;
    }

    await super.init(app);

    if (_environment.sentryDSN.isEmpty) {
      return false;
    }

    await SentryFlutter.init(
      (options) {
        options
          ..dsn = _environment.sentryDSN
          ..debug = false
          ..enableBreadcrumbTrackingForCurrentPlatform()
          ..tracesSampleRate = app.remoteConfig.getDouble(
            'patapata_sentry_plugin_tracessamplerate',
            defaultValue: 1.0,
          )
          ..sampleRate = app.remoteConfig.getDouble(
            'patapata_sentry_plugin_samplerate',
            defaultValue: 1.0,
          )
          ..beforeSend = _beforeSend
          ..beforeBreadcrumb = _beforeBreadcrumb
          ..enablePrintBreadcrumbs = false;

        options.sdk.addIntegration('patapata');

        if (_environment.sentryOptions != null) {
          _environment.sentryOptions!(options);
        }
      },
    );

    _onReportSubscription = app.log.reports.listen(_onReport);

    app.user.addSynchronousChangeListener(_onUserChanged);

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    app.user.removeSynchronousChangeListener(_onUserChanged);

    await super.dispose();
    await _onReportSubscription!.cancel();

    _onReportSubscription = null;
  }

  SentryEvent? _beforeSend(SentryEvent event, {dynamic hint}) {
    if (disposed) {
      // Don't send if we are disabled.
      return null;
    }

    // Align the Sentry logging level to the app logging level.
    if (_sentryLevelToLoggingLevel(event.level!) < app.log.level) {
      return null;
    }

    return event;
  }

  Breadcrumb? _beforeBreadcrumb(Breadcrumb? breadcrumb, {dynamic hint}) {
    if (breadcrumb == null || disposed) {
      // Don't send if we are disabled.
      return null;
    }

    // Align the Sentry logging level to the app logging level.
    if (_sentryLevelToLoggingLevel(breadcrumb.level!) < app.log.level) {
      return null;
    }

    return breadcrumb;
  }

  @override
  List<NavigatorObserver> get navigatorObservers => [SentryNavigatorObserver()];

  FutureOr<void> _onUserChanged(User user, UserChangeData changes) {
    final tId = changes.getIdFor<SentryPlugin>();
    final tProperties = changes.getPropertiesFor<SentryPlugin>();

    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: tId ?? '<anonymous>',
        username: scope.user?.username,
        email: scope.user?.email,
        ipAddress: scope.user?.ipAddress,
        data: tProperties,
      ));
    });
  }

  Level _sentryLevelToLoggingLevel(SentryLevel sentryLevel) {
    switch (sentryLevel) {
      case SentryLevel.fatal:
        return Level.SHOUT;
      case SentryLevel.error:
        return Level.SEVERE;
      case SentryLevel.warning:
        return Level.WARNING;
      case SentryLevel.info:
        return Level.INFO;
      case SentryLevel.debug:
      default:
        return Level.FINE;
    }
  }

  SentryLevel _loggingLevelToSentryLevel(Level level) {
    if (level >= Level.SHOUT) {
      return SentryLevel.fatal;
    } else if (level >= Level.SEVERE) {
      return SentryLevel.error;
    } else if (level >= Level.WARNING) {
      return SentryLevel.warning;
    } else if (level >= Level.INFO) {
      return SentryLevel.info;
    } else {
      return SentryLevel.debug;
    }
  }

  void _onReport(ReportRecord record) async {
    if (record.mechanism == Log.kFlutterErrorMechanism) {
      // Sentry does it by itself, automatically.
      return;
    }

    final tSentryLevel = _loggingLevelToSentryLevel(record.level);
    final Map<String, Object> tExtra = record.extra != null
        ? Map<String, Object>.from(
            record.extra!.map((key, value) => MapEntry(key, value ?? '<null>')))
        : {};
    SentryException? tException;
    final tMechanism = Mechanism(type: record.mechanism, handled: true);
    final tError = record.error;

    tExtra['patapataReportRecord'] = record;

    if (record.mechanism == Log.kNativeMechanism && tError is NativeThrowable) {
      tException = SentryException(
        type: tError.type ?? 'patapata.NativeThrowable',
        value: tError.message ?? tError.toString(),
        mechanism: tMechanism,
        stackTrace: SentryStackTrace(
            frames: List<SentryStackFrame>.of(
                ((NativeThrowable? nativeThrowable) sync* {
          while (nativeThrowable != null) {
            bool tProcessedFirst = false;

            if (nativeThrowable.chain != null) {
              for (var tTrace in nativeThrowable.chain!.traces) {
                for (var tFrame in tTrace.frames) {
                  yield SentryStackFrame(
                    package: tFrame.library,
                    lineNo: tFrame.line,
                    colNo: tFrame.column,
                    native: true,
                    function: tFrame.member,
                    absPath: tFrame.uri.toString(),
                  );
                }

                if (!tProcessedFirst) {
                  tProcessedFirst = true;
                  yield SentryStackFrame(absPath: '<asynchronous suspension>');
                }
              }
            }

            nativeThrowable = nativeThrowable.cause;

            if (nativeThrowable != null) {
              yield SentryStackFrame(absPath: '<caused by>');
            }
          }
        })(tError))),
      );
    }

    tExtra.addAll(<String, Object>{
      if (record.object != null) 'LogRecord.object': record.object!.toString(),
      'LogRecord.sequenceNumber': record.sequenceNumber,
    });

    if (record.level >= Level.WARNING) {
      final tEvent = SentryEvent(
        level: tSentryLevel,
        timestamp: record.time.toUtc(),
        fingerprint: record.fingerprint != null
            ? [SentryEvent.defaultFingerprint, ...record.fingerprint!]
            : null,
        logger: record.loggerName,
        message: SentryMessage(record.message),
        throwable: tError,
        exceptions: tException != null ? [tException] : null,
      );

      await Sentry.captureEvent(
        tEvent,
        stackTrace: record.stackTrace,
        hint: Hint.withMap(tExtra),
      );
    } else {
      tExtra.addAll(<String, Object>{
        if (tError != null) 'LogRecord.error': tError.toString(),
        if (record.stackTrace != null)
          'LogRecord.stackTrace': record.stackTrace!,
        'LogRecord.loggerName': record.loggerName,
      });

      Sentry.addBreadcrumb(
        Breadcrumb(
          level: tSentryLevel,
          timestamp: record.time.toUtc(),
          message: record.message,
          data: tExtra,
          category: record.loggerName,
          type: tError != null ? 'error' : null,
        ),
        hint: Hint.withMap(tExtra),
      );
    }
  }
}
