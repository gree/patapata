// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'plugin.dart';
import 'app.dart';

class _MockValues {
  static String appName = 'mock_patapata_core';
  static String packageName = 'io.flutter.plugins.mockpatapatacore';
  static String version = '1.0';
  static String buildNumber = '1';
  static String buildSignature = 'patapata_core_build_signature';
  static String? installerStore;
}

/// Plugin that manages information related to the application's metadata.
///
/// This plugin calls [PackageInfo.fromPlatform] during initialization,
/// allowing subsequent synchronous access from the application or other plugins.
///
/// This plugin is automatically created during application initialization
/// and can be accessed from [App.package].
class PackageInfoPlugin extends Plugin {
  late final PackageInfo _info;

  /// Access to information about this application's metadata.
  PackageInfo get info => _info;

  /// Mocks [info] for testing purposes.
  @visibleForTesting
  static void setMockValues({
    required String appName,
    required String packageName,
    required String version,
    required String buildNumber,
    required String buildSignature,
    String? installerStore,
  }) {
    _MockValues.appName = appName;
    _MockValues.packageName = packageName;
    _MockValues.version = version;
    _MockValues.buildNumber = buildNumber;
    _MockValues.buildSignature = buildSignature;
    _MockValues.installerStore = installerStore;
  }

  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    _info = await PackageInfo.fromPlatform();

    return true;
  }

  @override
  Widget createAppWidgetWrapper(Widget child) {
    return Provider<PackageInfoPlugin>.value(
      value: this,
      child: child,
    );
  }

  @override
  void setMockMethodCallHandler() {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: _MockValues.appName,
      packageName: _MockValues.packageName,
      version: _MockValues.version,
      buildNumber: _MockValues.buildNumber,
      buildSignature: _MockValues.buildSignature,
      installerStore: _MockValues.installerStore,
    );
  }
}
