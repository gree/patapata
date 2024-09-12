// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/widgets.dart';

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';

/// Settings for [PatapataException]
mixin ErrorEnvironment {
  /// Overrides the value of [PatapataException.prefix] by [PatapataException.namespace].
  ///
  /// example:
  /// When the [PatapataException.namespace] is defined as `patapata`,
  /// This would override the value of [PatapataException.prefix] to `APE`.
  /// ```dart
  /// {
  ///   'patapata': 'APE'
  /// }
  /// ```
  Map<String, String>? get errorReplacePrefixMap;

  /// Defines the default [PatapataException.widget].
  Widget Function(PatapataException)? get errorDefaultWidget;

  /// Defines the default behavior of [PatapataException.showDialog].
  Future<void> Function(BuildContext, PatapataException)?
      get errorDefaultShowDialog;
}

/// Defines exceptions that occur in applications using patapata.
abstract class PatapataException {
  final App? _app;

  /// Error message.
  /// This message is for logging and debugging purposes and is not meant to be displayed to the user.
  final String? message;

  /// Original error.
  final Object? original;

  /// Used to group and deduplicate events with the same fingerprint in the [Log] system.
  final List<String>? fingerprint;

  /// Parameters passed in the localization of [localizedTitle].
  /// [prefix] is passed by default.
  ///
  /// example: [namespace] is `patapata` and [internalCode] is `000`, then
  ///
  /// dart
  /// ```dart
  /// {
  ///   'body': 'Title',
  /// }
  /// ```
  /// yaml
  /// ```yaml
  /// errors:
  ///   patapata:
  ///     '000':
  ///       title: {body}: {prefix}000
  /// ```
  final Map<String, String>? localeTitleData;

  /// Parameters passed in the localization of [localizedMessage].
  /// [prefix] is passed by default.
  ///
  /// example: [namespace] is `patapata` and [internalCode] is `000`, then
  ///
  /// dart
  /// ```dart
  /// {
  ///   'body': 'Message',
  /// }
  /// ```
  /// yaml
  /// ```yaml
  /// errors:
  ///   patapata:
  ///     '000':
  ///       message: {body}: {prefix}000
  /// ```
  final Map<String, String>? localeMessageData;

  /// Parameters passed in the localization of [localizedFix].
  /// [prefix] is passed by default.
  ///
  /// example: [namespace] is `patapata` and [internalCode] is `000`, then
  ///
  /// dart
  /// ```dart
  /// {
  ///   'body': 'Fix',
  /// }
  /// ```
  /// yaml
  /// ```yaml
  /// errors:
  ///   patapata:
  ///     '000':
  ///       fix: {body}: {prefix}000
  /// ```
  final Map<String, String>? localeFixData;

  PatapataException({
    App? app,
    this.message,
    this.original,
    this.fingerprint,
    this.localeTitleData,
    this.localeMessageData,
    this.localeFixData,
    this.fix,
    this.logLevel,
    Level? userLogLevel,
  })  : _app = app ?? (Zone.current[#patapataApp] as App?),
        _userLogLevel = userLogLevel;

  /// Prefix for [code]
  /// Can be set by [ErrorEnvironment.errorReplacePrefixMap] with [namespace].
  /// If not set, then [defaultPrefix].
  ///
  /// Used as a localization key when being localized like in [localizedMessage].
  String get prefix =>
      _environment?.errorReplacePrefixMap?[namespace] ?? defaultPrefix;

  /// Error code.
  /// Usually a string of [prefix] and [internalCode].
  String get code => '$prefix$internalCode';

  /// Default [prefix] when not set in [ErrorEnvironment.errorReplacePrefixMap].
  @protected
  String get defaultPrefix;

  /// Internal error code.
  /// Used as a localization key when being localized like in [localizedMessage].
  @protected
  String get internalCode;

  /// Defines the namespace of the error.
  /// Used in localization keys like in [localizedMessage] and settings in [ErrorEnvironment].
  String get namespace;

  /// You can define a process to recover from the error.
  final Future<void> Function()? fix;

  /// true if [fix] is defined.
  bool get hasFix => fix != null;

  /// Displays the error title localized by the [L10n] system.
  ///
  /// The localization key will be `'errors.$namespace.$internalCode.title'`.
  ///
  /// example: [namespace] is `patapata` and [internalCode] is `000`, then
  /// ```yaml
  /// errors:
  ///   patapata:
  ///     '000':
  ///       title: ErrorTitle
  /// ```
  String get localizedTitle => hasLocalizedTitle
      ? _l10n!.lookup(
          _localizeTitleKey,
          namedParameters: {
            'prefix': prefix,
            ...(localeTitleData ?? {}),
          },
        )
      : _defaultTitleLocalize;

  /// Displays the error message localized by the [L10n] system.
  ///
  /// The localization key will be `'errors.$namespace.$internalCode.message'`.
  ///
  /// example: [namespace] is `patapata` and [internalCode] is `000`, then
  /// ```yaml
  /// errors:
  ///   patapata:
  ///     '000':
  ///       message: ErrorMessage
  /// ```
  String get localizedMessage => hasLocalizedMessage
      ? _l10n!.lookup(
          _localizeMessageKey,
          namedParameters: {
            'prefix': prefix,
            ...(localeMessageData ?? {}),
          },
        )
      : _defaultMessageLocalize;

  /// Displays the error treatment message localized by the [L10n] system.
  ///
  /// The localization key will be `'errors.$namespace.$internalCode.fix'`.
  ///
  /// example: [namespace] is `patapata` and [internalCode] is `000`, then
  /// ```yaml
  /// errors:
  ///   patapata:
  ///     '000':
  ///       fix: ErrorFix
  /// ```
  String get localizedFix => hasLocalizedFix
      ? _l10n!.lookup(
          _localizeFixKey,
          namedParameters: {
            'prefix': prefix,
            ...(localeFixData ?? {}),
          },
        )
      : _defaultFixLocalize;

  /// true if the localization key for [localizedTitle] is defined.
  bool get hasLocalizedTitle =>
      _l10n?.containsMessageKey(_localizeTitleKey) ?? false;

  /// true if the localization key for [localizedMessage] is defined.
  bool get hasLocalizedMessage =>
      _l10n?.containsMessageKey(_localizeMessageKey) ?? false;

  /// true if the localization key for [localizedFix] is defined.
  bool get hasLocalizedFix =>
      _l10n?.containsMessageKey(_localizeFixKey) ?? false;

  /// Returns ErrorWidget.
  ///
  /// Return the widget set in [ErrorEnvironment.errorDefaultWidget].
  /// If not set, it returns [Text] displaying [localizedMessage].
  Widget get widget =>
      _environment?.errorDefaultWidget?.call(this) ?? Text(localizedMessage);

  /// Notification [Level] to the [Log] system.
  ///
  /// This is the [Level] notified to the [Log] system for unknown errors.
  /// If specified by the [Logger], it takes precedence.
  final Level? logLevel;

  /// Importance from the user's perspective.
  ///
  /// Even if [logLevel] is [Level.INFO], if it's a significant error that warrants displaying an error page,
  /// setting this to [Level.SHOUT] will navigate to the error page during [onReported].
  /// Note that this value is not relayed to the [Log] system, and instead, the value of [logLevel] is reported.
  Level? get userLogLevel => _userLogLevel ?? logLevel;

  final Level? _userLogLevel;

  /// Displays a dialog.
  ///
  /// By default, it calls [PlatformDialog.show] displaying [localizedTitle] and [localizedMessage].
  /// This can be customized by [ErrorEnvironment.errorDefaultShowDialog].
  Future<void> showDialog(BuildContext context) =>
      _environment?.errorDefaultShowDialog?.call(context, this) ??
      PlatformDialog.show(
        context: context,
        title: localizedTitle,
        message: localizedMessage,
        actions: [
          PlatformDialogAction(
            result: () => true,
            text: 'OK',
          ),
        ],
      );

  /// Called when this exception is reported by the [Log] system.
  ///
  /// If using the [StandardAppPlugin] system and [userLogLevel] == [Level.SHOUT],
  /// it navigates to the page defined in [StandardErrorPageFactory].
  void onReported(ReportRecord record) {
    if (userLogLevel == Level.SHOUT) {
      _app?.getPlugin<StandardAppPlugin>()?.delegate?.goErrorPage(record);
    }
  }

  String get _localizeTitleKey => 'errors.$namespace.$internalCode.title';
  String get _localizeMessageKey => 'errors.$namespace.$internalCode.message';
  String get _localizeFixKey => 'errors.$namespace.$internalCode.fix';

  String get _defaultTitleLocalize => 'Error: $code';
  String get _defaultMessageLocalize => '$runtimeType: code=$code';
  String get _defaultFixLocalize => 'OK';

  L10n? get _l10n => _app?.getPlugin<I18nPlugin>()?.i18n.delegate.l10n;

  /// The current environment.
  /// If the current environment is of type [ErrorEnvironment], it is returned, otherwise null is returned.
  ErrorEnvironment? get _environment => _app?.environment is ErrorEnvironment
      ? _app!.environment as ErrorEnvironment
      : null;

  @override
  String toString() {
    return '$runtimeType: code=$code, message=$message${original != null ? ', original=$original' : ''}';
  }
}
