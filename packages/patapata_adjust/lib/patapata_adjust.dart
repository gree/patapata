// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_adjust;

import 'dart:async';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:patapata_core/patapata_core.dart';

/// Configuration for [AdjustPlugin].
mixin AdjustPluginEnvironment {
  /// The app token issued when adding the app on Adjust's dashboard.
  String get adjustAppToken;

  /// The environment for Adjust. Refer to the values in [AdjustEnvironment].
  String get adjustEnvironment;

  /// The log level for Adjust. Refer to the values in [AdjustLogLevel].
  String? get adjustLogLevel;
}

/// This is a plugin that provides Adjust functionality.
class AdjustPlugin<T extends AdjustPluginEnvironment> extends Plugin
    with WidgetsBindingObserver {
  StreamSubscription<AnalyticsEvent>? _eventsSubscription;

  /// Initializes the [AdjustPlugin].
  @override
  FutureOr<bool> init(App app) async {
    if (kIsWeb || app.environment is! AdjustPluginEnvironment) {
      return false;
    }

    await super.init(app);

    if (app.permissions.trackingRequested) {
      _start();
    } else {
      app.permissions.trackingStream.first.then<void>((_) {
        if (!disposed) {
          _start();
        }
      });
    }

    return true;
  }

  AdjustPluginEnvironment get _environment =>
      app.environment as AdjustPluginEnvironment;

  void _start() {
    final tConfig = AdjustConfig(
      _environment.adjustAppToken,
      AdjustEnvironment.values
          .firstWhere((e) => e.name == _environment.adjustEnvironment),
    );

    if (_environment.adjustLogLevel?.isNotEmpty == true) {
      tConfig.logLevel = AdjustLogLevel.values
          .firstWhere((e) => e.name == _environment.adjustLogLevel);
    }

    Adjust.start(tConfig);

    WidgetsBinding.instance.addObserver(this);

    _eventsSubscription =
        app.analytics.eventsFor<AdjustPlugin>().listen(_onEvent);
    app.user.addSynchronousChangeListener(_onUserChanged);
  }

  @override
  FutureOr<void> dispose() async {
    app.user.removeSynchronousChangeListener(_onUserChanged);
    _eventsSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (await Adjust.isEnabled()) {
      Adjust.setEnabled(false);
    }

    return super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Adjust.onResume();
        break;
      case AppLifecycleState.paused:
        Adjust.onPause();
        break;
      default:
        break;
    }
  }

  void _onEvent(AnalyticsEvent event) {
    final tAdjustEvent = AdjustEvent(event.name);

    if (event is AnalyticsRevenueEvent) {
      tAdjustEvent.setRevenue(event.revenue, event.currency ?? 'XXX');
      tAdjustEvent.transactionId = event.orderId;
    }

    final tFlatData = event.flatData;
    final tParameters = tFlatData != null
        ? {
            for (var i in tFlatData.entries)
              i.key: Analytics.defaultMakeLoggableToNative(i.value),
          }
        : null;

    final tFinalParameters = <String, Object?>{
      if (event.navigationInteractionContextData != null)
        for (var i in event.navigationInteractionContextData!.entries)
          'nic_${i.key}': Analytics.defaultMakeLoggableToNative(i.value),
    }..addAll(tParameters ?? {});

    for (var i in tFinalParameters.entries) {
      final tValue = i.value?.toString() ?? '';

      if (tValue.isNotEmpty) {
        tAdjustEvent.addCallbackParameter(i.key, tValue);
      }
    }

    Adjust.trackEvent(tAdjustEvent);
  }

  String? _lastId;

  FutureOr<void> _onUserChanged(User user, UserChangeData changes) async {
    final tId = changes.getIdFor<AdjustPlugin<T>>();
    final tProperties = changes.getPropertiesFor<AdjustPlugin<T>>();

    if (tId != _lastId) {
      _lastId = tId;
      if (tId == null) {
        Adjust.removeSessionCallbackParameter('user_id');
      } else {
        Adjust.addSessionCallbackParameter('user_id', tId);
      }
    }

    for (var i in tProperties.entries) {
      final tValue = i.value?.toString() ?? '';

      if (tValue.isNotEmpty) {
        Adjust.addSessionCallbackParameter(i.key, tValue);
      } else {
        Adjust.removeSessionCallbackParameter(i.key);
      }
    }
  }
}
