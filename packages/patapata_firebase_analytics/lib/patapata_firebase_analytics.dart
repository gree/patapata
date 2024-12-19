// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_firebase_analytics;

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_firebase_core/patapata_firebase_core.dart';

/// A plugin that provides functionality for Firebase Analytics.
/// This plugin requires adding the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) package to your application.
class FirebaseAnalyticsPlugin extends Plugin {
  /// A reference to the [FirebaseAnalytics] instance.
  late final FirebaseAnalytics backend;
  late final StreamSubscription<AnalyticsEvent> _eventsSubscription;

  @override
  List<Type> get dependencies => [FirebaseCorePlugin];

  /// Initializes the [FirebaseAnalyticsPlugin].
  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    backend = FirebaseAnalytics.instance;
    _eventsSubscription =
        app.analytics.eventsFor<FirebaseAnalyticsPlugin>().listen(_onEvent);
    app.user.addSynchronousChangeListener(_onUserChanged);

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    await super.dispose();

    app.user.removeSynchronousChangeListener(_onUserChanged);
    _eventsSubscription.cancel();
    backend.setAnalyticsCollectionEnabled(false);
  }

  @override
  List<NavigatorObserver> get navigatorObservers =>
      [FirebaseAnalyticsObserver(analytics: backend)];

  void _onEvent(AnalyticsEvent event) {
    // Firebase only allows int, double, and String as parameter types.
    // And no null. However Analytics needs the same keys, so we pass '' in that case.
    // For any other types, try to turn it in to JSON. If that fails, return the toString() of it.
    final tFlatData = event.flatData;
    final tParameters = tFlatData != null
        ? {
            for (var i in tFlatData.entries)
              i.key: Analytics.defaultMakeLoggableToNative(i.value),
          }
        : null;

    backend.logEvent(
      name: event.name,
      parameters: <String, Object>{
        if (event.navigationInteractionContextData != null)
          for (var i in event.navigationInteractionContextData!.entries)
            'nic_${i.key}': Analytics.defaultMakeLoggableToNative(i.value),
      }..addAll(tParameters ?? {}),
    );
  }

  String? _lastId;

  FutureOr<void> _onUserChanged(User user, UserChangeData changes) async {
    final tId = changes.getIdFor<FirebaseAnalyticsPlugin>();
    final tProperties = changes.getPropertiesFor<FirebaseAnalyticsPlugin>();

    if (tId != _lastId) {
      _lastId = tId;
      await backend.setUserId(
        id: tId,
      );
    }

    await Future.wait([
      for (var i in tProperties.entries)
        backend.setUserProperty(name: i.key, value: i.value?.toString()),
    ]);
  }
}
