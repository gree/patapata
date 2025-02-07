// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';

/// This is the abstract class for exceptions that occur in the sample application.
abstract base class AppException extends PatapataException {
  AppException({
    super.app,
    super.message,
    super.original,
    super.fingerprint,
    super.localeTitleData,
    super.localeMessageData,
    super.localeFixData,
    super.fix,
    super.logLevel,
    super.userLogLevel,
    super.overridableLocalization,
  });

  @override
  String get defaultPrefix => 'APE';

  @override
  String get namespace => 'app';
}

/// An exception that is thrown when the app encounters an unknown error.
final class AppUnknownException extends AppException {
  AppUnknownException();

  @override
  String get internalCode => '000';
}

/// Thrown when an unsupported version (usually old) of the app is detected.
final class AppVersionException extends AppException {
  AppVersionException() : super(logLevel: Level.INFO);

  @override
  String get internalCode => '010';

  @override
  void onReported(ReportRecord record) {
    showDialog(getApp().navigatorContext);
  }

  @override
  Future<void> Function()? get fix => () async {
        // Launch the app store.
      };
}
