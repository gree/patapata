// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_karte_core;

import 'dart:async';

import 'package:karte_core/karte_core.dart';
import 'package:patapata_core/patapata_core.dart';

/// A plugin that provides Karte functionality in Patapata.
class KarteCorePlugin extends Plugin {
  late final StreamSubscription<AnalyticsEvent> _eventsSubscription;

  /// Initializes the [KarteCorePlugin].
  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    KarteApp.optIn();
    _eventsSubscription =
        app.analytics.eventsFor<KarteCorePlugin>().listen(_onEvent);
    app.user.addSynchronousChangeListener(_onUserChanged);

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    app.user.removeSynchronousChangeListener(_onUserChanged);

    await super.dispose();

    KarteApp.optOut();
    _eventsSubscription.cancel();
  }

  void _onEvent(AnalyticsEvent event) {
    final tFlatData = event.flatData;
    final tParameters = tFlatData != null
        ? {
            for (var i in tFlatData.entries)
              i.key: Analytics.defaultMakeLoggableToNative(i.value),
          }
        : null;

    final tContextData = event.navigationInteractionContextData;
    final Map<String, Object?> tContextParameters = tContextData != null
        ? {
            for (var i in tContextData.entries)
              i.key: Analytics.defaultMakeLoggableToNative(i.value),
          }
        : {};

    if (event is AnalyticsRouteViewEvent) {
      Tracker.view(
        event.routeName ?? '<anonymous>',
        event.routeName,
        <String, Object?>{
          'navigationInteractionContext': tContextParameters,
        }..addAll(tParameters ?? {}),
      );
    } else {
      Tracker.track(
        event.name,
        <String, Object?>{
          'navigationInteractionContext': tContextParameters,
        }..addAll(tParameters ?? {}),
      );
    }
  }

  String? _lastId;

  FutureOr<void> _onUserChanged(User user, UserChangeData changes) {
    final tId = changes.getIdFor<KarteCorePlugin>();
    final tProperties = changes.getPropertiesFor<KarteCorePlugin>();

    if (tId != _lastId) {
      _lastId = tId;

      if (tId == null) {
        KarteApp.renewVisitorId();
      }

      Tracker.identify({
        'user_id': tId,
        for (var i in tProperties.entries) i.key: i.value,
      });
    } else {
      Tracker.identify({
        for (var i in tProperties.entries) i.key: i.value,
      });
    }
  }
}
