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
///
/// If [overridableLocalization] is true, the localization keys [localizedTitle],
/// [localizedMessage], and [localizedFix] can be overridden by [StandardPageWithResult.localizationKey].
/// The default is true.
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
    bool overridableLocalization = true,
    Level? userLogLevel,
  }) : _app = app ?? (Zone.current[#patapataApp] as App?),
       _userLogLevel = userLogLevel {
    final tPageLocalizationKey = (overridableLocalization)
        ? _app
              ?.getPlugin<StandardAppPlugin>()
              ?.delegate
              ?.pageInstances
              .lastOrNull
              ?.standardPageKey
              .currentState
              ?.localizationKey
        : null;

    _overrideLocalizeKeyBase = tPageLocalizationKey?.isNotEmpty == true
        ? '$tPageLocalizationKey.$_localizeKeyBase'
        : '';
  }

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
  ///
  /// If [StandardPageWithResult.localizationKey] is set on the currently displayed page when this class is created,
  /// you can override the default keys and display page-specific `title` by creating the following YAML file.
  /// However, if `overridableLocalization` was set to false when created, the keys will not be overridden.
  ///
  /// Example: If [StandardPageWithResult.localizationKey] is `pages.home`, then
  /// ```yaml
  /// pages:
  ///   home:
  ///     errors:
  ///       patapata:
  ///         '000':
  ///           title: Will be displayed
  /// errors:
  ///   patapata:
  ///     '000':
  ///       title: Will not be displayed
  /// ```
  String get localizedTitle => hasLocalizedTitle
      ? _localize(_localizeTitleKey, localeTitleData)
      : _defaultTitle;

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
  ///
  /// If [StandardPageWithResult.localizationKey] is set on the currently displayed page when this class is created,
  /// you can override the default keys and display page-specific `message` by creating the following YAML file.
  /// However, if `overridableLocalization` was set to false when created, the keys will not be overridden.
  ///
  /// Example: If [StandardPageWithResult.localizationKey] is `pages.home`, then
  /// ```yaml
  /// pages:
  ///   home:
  ///     errors:
  ///       patapata:
  ///         '000':
  ///           message: Will be displayed
  /// errors:
  ///   patapata:
  ///     '000':
  ///       message: Will not be displayed
  /// ```
  String get localizedMessage => hasLocalizedMessage
      ? _localize(_localizeMessageKey, localeMessageData)
      : _defaultMessage;

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
  ///
  /// If [StandardPageWithResult.localizationKey] is set on the currently displayed page when this class is created,
  /// you can override the default keys and display page-specific `fix` by creating the following YAML file.
  /// However, if `overridableLocalization` was set to false when created, the keys will not be overridden.
  ///
  /// Example: If [StandardPageWithResult.localizationKey] is `pages.home`, then
  /// ```yaml
  /// pages:
  ///   home:
  ///     errors:
  ///       patapata:
  ///         '000':
  ///           fix: Will be displayed
  /// errors:
  ///   patapata:
  ///     '000':
  ///       fix: Will not be displayed
  /// ```
  String get localizedFix =>
      hasLocalizedFix ? _localize(_localizeFixKey, localeFixData) : _defaultFix;

  /// true if the localization key for [localizedTitle] is defined.
  bool get hasLocalizedTitle =>
      hasOverrideLocalizedTitle ||
      (_l10n?.containsMessageKey('$_localizeKeyBase.$_titleKey') ?? false);

  /// true if the localization key for [localizedMessage] is defined.
  bool get hasLocalizedMessage =>
      hasOverrideLocalizedMessage ||
      (_l10n?.containsMessageKey('$_localizeKeyBase.$_messageKey') ?? false);

  /// true if the localization key for [localizedFix] is defined.
  bool get hasLocalizedFix =>
      hasOverrideLocalizedFix ||
      (_l10n?.containsMessageKey('$_localizeKeyBase.$_fixKey') ?? false);

  /// true if the localization key for [localizedTitle] is overridden.
  ///
  /// For example, when this class is created and the currently displayed page has [StandardPageWithResult.localizationKey] set.
  bool get hasOverrideLocalizedTitle =>
      _overrideLocalizeKeyBase.isNotEmpty &&
      (_l10n?.containsMessageKey('$_overrideLocalizeKeyBase.$_titleKey') ??
          false);

  /// true if the localization key for [localizedMessage] is overridden.
  ///
  /// For example, when this class is created and the currently displayed page has [StandardPageWithResult.localizationKey] set.
  bool get hasOverrideLocalizedMessage =>
      _overrideLocalizeKeyBase.isNotEmpty &&
      (_l10n?.containsMessageKey('$_overrideLocalizeKeyBase.$_messageKey') ??
          false);

  /// true if the localization key for [localizedFix] is overridden.
  ///
  /// For example, when this class is created and the currently displayed page has [StandardPageWithResult.localizationKey] set.
  bool get hasOverrideLocalizedFix =>
      _overrideLocalizeKeyBase.isNotEmpty &&
      (_l10n?.containsMessageKey('$_overrideLocalizeKeyBase.$_fixKey') ??
          false);

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
        actions: [PlatformDialogAction(result: () => true, text: 'OK')],
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

  late final String _overrideLocalizeKeyBase;

  String get _localizeKeyBase => 'errors.$namespace.$internalCode';

  String get _localizeTitleKey =>
      '${hasOverrideLocalizedTitle ? _overrideLocalizeKeyBase : _localizeKeyBase}.$_titleKey';
  String get _localizeMessageKey =>
      '${hasOverrideLocalizedMessage ? _overrideLocalizeKeyBase : _localizeKeyBase}.$_messageKey';
  String get _localizeFixKey =>
      '${hasOverrideLocalizedFix ? _overrideLocalizeKeyBase : _localizeKeyBase}.$_fixKey';

  String get _titleKey => 'title';
  String get _messageKey => 'message';
  String get _fixKey => 'fix';

  String get _defaultTitle => 'Error: $code';
  String get _defaultMessage => '$runtimeType: code=$code';
  String get _defaultFix => 'OK';

  L10n? get _l10n => _app?.getPlugin<I18nPlugin>()?.i18n.delegate.l10n;

  /// The current environment.
  /// If the current environment is of type [ErrorEnvironment], it is returned, otherwise null is returned.
  ErrorEnvironment? get _environment => _app?.environment is ErrorEnvironment
      ? _app!.environment as ErrorEnvironment
      : null;

  String _localize(String key, Map<String, String>? namedParameters) {
    return _l10n!.lookup(
      key,
      namedParameters: {'prefix': prefix, ...(namedParameters ?? {})},
    );
  }

  @override
  String toString() {
    return '$runtimeType: code=$code, message=$message${original != null ? ', original=$original' : ''}';
  }
}
