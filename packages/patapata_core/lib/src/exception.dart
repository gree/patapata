// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// ignore_for_file: constant_identifier_names

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

/// Error codes for [PatapataCoreException].
enum PatapataCoreExceptionCode {
  /// [LogicStateTransitionNotFound]
  PPE101,

  /// [LogicStateTransitionNotAllowed]
  PPE102,

  /// [LogicStateAllTransitionsNotAllowed]
  PPE103,

  /// [LogicStateNotCurrent]
  PPE104,

  /// [ConflictException]
  PPE201,

  /// [ResetStartupSequence]
  PPE301,

  /// [L10nLoadAssetsException]
  PPE401,

  /// [NotificationsInitializationException]
  PPE501,

  /// [WebPageNotFound]
  PPE601,
}

/// Extension to split [PatapataCoreExceptionCode] into
/// [PatapataCoreException.prefix] and [PatapataCoreException.internalCode].
extension PatapataCoreExceptionCodeExtension on PatapataCoreExceptionCode {
  /// Prefix of the error code.
  String get prefix => name.substring(0, 3);

  /// Internal code of the error code.
  String get internalCode => name.substring(3);
}

/// `patapata_core` package exception.
///
/// This exception is thrown when an error occurs in the `patapata_core` package.
/// The error code is defined in [PatapataCoreExceptionCode].
///
/// [defaultPrefix] is `PPE`. ([PatapataCoreExceptionCodeExtension.prefix])
/// [namespace] is `patapata`
///
/// The value of [prefix] can be overridden by defining
/// [ErrorEnvironment.errorReplacePrefixMap] on the application side.
/// If it is not defined, the value of [defaultPrefix] will be used.
abstract class PatapataCoreException extends PatapataException {
  final PatapataCoreExceptionCode _exceptionCode;

  PatapataCoreException({
    required PatapataCoreExceptionCode code,
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
  }) : _exceptionCode = code;

  @override
  String get defaultPrefix => _exceptionCode.prefix;

  @override
  String get internalCode => _exceptionCode.internalCode;

  @override
  String get namespace => 'patapata';
}
