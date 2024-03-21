// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_firebase_crashlytics;

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_firebase_core/patapata_firebase_core.dart';
import 'package:stack_trace/stack_trace.dart';

/// This is a plugin that provides FirebaseCrashlytics functionality to Patapata.
/// To use this plugin, you need to add the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) package to your application.
class FirebaseCrashlyticsPlugin extends Plugin {
  static const _exceptionLogPrefix = '[EXCEPTION]';
  StreamSubscription<ReportRecord>? _onReportSubscription;

  @override
  List<Type> get dependencies => [FirebaseCorePlugin];

  /// Initialize [FirebaseCrashlyticsPlugin].
  @override
  FutureOr<bool> init(App app) async {
    if (kIsWeb) {
      // It's not working right now.
      return false;
    }

    await super.init(app);

    _onReportSubscription = app.log.reports.listen(_onReport);

    app.user.addSynchronousChangeListener(_onUserChanged);

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    app.user.removeSynchronousChangeListener(_onUserChanged);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);

    await super.dispose();
    await _onReportSubscription?.cancel();

    _onReportSubscription = null;
  }

  void _onReport(ReportRecord record) async {
    if (record.level < Level.WARNING) {
      await FirebaseCrashlytics.instance.log(record.toString());

      return;
    }

    if (record.object is FlutterErrorDetails) {
      FirebaseCrashlytics.instance
          .recordFlutterError(record.object as FlutterErrorDetails);

      return;
    }

    FirebaseCrashlytics.instance.log(_exceptionLogPrefix + record.message);

    StackTrace? tStackTrace = record.stackTrace;

    if (tStackTrace is Chain) {
      tStackTrace = tStackTrace.toTrace();
    }

    if (tStackTrace is Trace) {
      tStackTrace = tStackTrace.vmTrace;
    }

    await FirebaseCrashlytics.instance.recordError(
      record.error ?? record.object ?? record.message,
      tStackTrace == null || tStackTrace == StackTrace.empty
          ? Trace.current(1)
          : tStackTrace,
      reason: record.message,
      printDetails: false,
    );
  }

  String? _lastId;

  FutureOr<void> _onUserChanged(User user, UserChangeData changes) async {
    final tId = changes.getIdFor<FirebaseCrashlyticsPlugin>();
    final tProperties = changes.getPropertiesFor<FirebaseCrashlyticsPlugin>();

    if (tId != _lastId) {
      _lastId = tId;
      await FirebaseCrashlytics.instance.setUserIdentifier(tId ?? '');
    }

    await Future.wait([
      for (var i in tProperties.entries)
        FirebaseCrashlytics.instance.setCustomKey(i.key, i.value ?? ''),
    ]);
  }

  /// Sends unsent crash reports to Firebase.
  /// For details, refer to [FirebaseCrashlytics.sendUnsentReports].
  Future<void> sendUnsentReports() async {
    await FirebaseCrashlytics.instance.sendUnsentReports();
  }
}
