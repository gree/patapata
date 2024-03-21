// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:flutter/widgets.dart';

/// The Environment class for this app.
/// Controls all static settings for the app.
/// Pass this to the [App] constructor.
/// [appType]" is a variable passed as a command-line argument with the name "APP_TYPE" when executed through 'flutter run.
class Environment with I18nEnvironment, LogEnvironment {
  @override
  final List<Locale> supportedL10ns = const [
    Locale('en'),
    Locale('ja'),
    Locale('ar'),
  ];

  @override
  final List<String> l10nPaths = const [
    'l10n',
  ];

  @override
  final int logLevel;

  @override
  final bool printLog;

  const Environment({
    this.logLevel =
        const int.fromEnvironment('LOG_LEVEL', defaultValue: -kPataInHex),
    this.printLog =
        const bool.fromEnvironment('PRINT_LOG', defaultValue: kDebugMode),
  });

  final String? appType = const String.fromEnvironment('APP_TYPE');
}
