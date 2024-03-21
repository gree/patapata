// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_apps_flyer;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

/// Configuration for [AppsflyerSdk].
mixin AppsFlyerPluginEnvironment {
  /// AppsFlyer's devKey.
  String get appsFlyerDevKey;

  /// AppsFlyer's iOS `appId`.
  String get appsFlyerAppIdIOS;

  /// AppsFlyer's Android `appId`.
  String get appsFlyerAppIdAndroid;
}

/// A plugin that provides functionality for AppsFlyer in Patapata.
class AppsFlyerPlugin extends Plugin {
  late AppsflyerSdk _sdk;

  /// A reference to the [AppsflyerSdk] instance.
  AppsflyerSdk get sdk => _sdk;

  /// Initializes the [AppsFlyerPlugin].
  @override
  FutureOr<bool> init(App app) async {
    if (app.environment is! AppsFlyerPluginEnvironment) {
      return false;
    }

    final tDevKey = _environment.appsFlyerDevKey;
    final tAppId = defaultTargetPlatform == TargetPlatform.iOS
        ? _environment.appsFlyerAppIdIOS
        : _environment.appsFlyerAppIdAndroid;

    if (tDevKey.isEmpty || tAppId.isEmpty) {
      return false;
    }

    await super.init(app);

    var tIsDebug = false;

    assert(() {
      tIsDebug = true;
      return true;
    }());

    _sdk = AppsflyerSdk(AppsFlyerOptions(
      afDevKey: tDevKey,
      appId: tAppId,
      showDebug: tIsDebug,
      timeToWaitForATTUserAuthorization: 60.0,
    ));

    app.user.addSynchronousChangeListener(_onUserChanged);
    if (app.permissions.trackingRequested) {
      await initSdk();
    } else {
      app.permissions.trackingStream.first.then<void>((_) => initSdk);
    }

    return true;
  }

  AppsFlyerPluginEnvironment get _environment =>
      app.environment as AppsFlyerPluginEnvironment;

  @override
  FutureOr<void> dispose() {
    app.user.removeSynchronousChangeListener(_onUserChanged);

    return super.dispose();
  }

  /// Initializes the [AppsflyerSdk].
  Future<void> initSdk() async {
    await _sdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: false,
      registerOnDeepLinkingCallback: false,
    );
  }

  FutureOr<void> _onUserChanged(User user, UserChangeData changes) {
    _sdk.setCustomerUserId(changes.id ?? '');
  }
}
