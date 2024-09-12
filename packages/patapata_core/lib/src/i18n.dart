// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_format.dart';
import 'package:logging/logging.dart';
import 'package:patapata_core/src/exception.dart';
import 'package:patapata_core/src/util.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:yaml/yaml.dart';

import 'app.dart';
import 'plugin.dart';

final _logger = Logger('patapata.I18n');

bool _reassembling = false;

/// Language settings of the application. Used in [I18nPlugin].
mixin I18nEnvironment {
  /// List of [Locale] supported by the application (default is `Locale('en')`)
  List<Locale>? get supportedL10ns;

  /// List of paths to directories storing language files (default is `l10n`)
  List<String>? get l10nPaths;
}

/// Returns a localized string using the yaml file when [L10n.lookup] is called.
///
/// Specify the key set in the yaml file for [key].
/// If the key does not exist, it will return the [key] string.
///
/// By passing parameters to [namedParameters], formatting compliant with
/// [MessageFormat] is possible.
///
/// example:
///
/// yaml
/// ```yaml
/// example:
///   title: Title
/// ```
/// dart
/// ```dart
/// l(context, 'example.title');
/// ```
String l(
  BuildContext context,
  String key, [
  Map<String, Object>? namedParameters,
]) =>
    Localizations.of<L10n>(context, L10n)?.lookup(
      key,
      namedParameters: namedParameters,
    ) ??
    key;

/// Provides functionality required to switch the language of the application.
///
/// This class is automatically created during the initialization of
/// [I18nPlugin] and can be retrieved from the Plugin.
///
/// By setting [supportedL10ns] and [l10nDelegates] to [WidgetsApp]'s
/// `supportedLocales` and `localizationsDelegates` respectively, a
/// [Localizations] Widget containing the [L10n] suitable for the
/// language in use will be added to the tree.
///
/// If using [StandardMaterialApp] or [StandardCupertinoApp],
/// it will be set automatically.
class I18n {
  final List<String> _l10nPaths = [];

  final List<Locale> _supportedL10ns = [];

  /// The `supportedLocales` to be set in [WidgetsApp].
  List<Locale> get supportedL10ns => _supportedL10ns;

  /// The [LocalizationsDelegate] provided by patapata.
  late final L10nDelegate delegate = L10nDelegate(this);

  /// The `localizationsDelegates` to be set in [WidgetsApp].
  late final List<LocalizationsDelegate> l10nDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}

/// Plugin that provides localization.
/// The [l] function becomes available.
///
/// This Plugin is required for the core of Patapata to work.
/// Automatically initialized during the initialization of patapata [App].
class I18nPlugin extends Plugin {
  final _i18n = I18n();

  /// The [I18n] class.
  I18n get i18n => _i18n;

  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    tz.initializeTimeZones();

    final tEnv = app.environment;
    if (tEnv is I18nEnvironment) {
      final tPaths = tEnv.l10nPaths;

      if (tPaths != null) {
        _i18n._l10nPaths.addAll(tPaths);
      } else {
        _i18n._l10nPaths.add('l10n');
      }

      final tSupported = tEnv.supportedL10ns;

      if (tSupported != null) {
        _i18n._supportedL10ns.addAll(tSupported);
      } else {
        return false;
      }
    } else {
      _i18n._l10nPaths.add('l10n');
      _i18n._supportedL10ns.add(const Locale('en'));
    }

    return true;
  }

  @override
  Widget createAppWidgetWrapper(Widget child) => _L10nAssetReloader(
        child: child,
      );
}

class _L10nAssetReloader extends StatefulWidget {
  final Widget child;

  const _L10nAssetReloader({
    required this.child,
  });

  @override
  State<_L10nAssetReloader> createState() => __L10nAssetReloaderState();
}

class __L10nAssetReloaderState extends State<_L10nAssetReloader> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  // coverage:ignore-start
  @override
  void reassemble() {
    super.reassemble();
    _reassembling = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _reassembling = false;
    });
  }
  // coverage:ignore-end
}

class _LoadYamlParcel {
  final String source;
  final Uri? sourceUri;

  const _LoadYamlParcel(
    this.source,
    this.sourceUri,
  );
}

Map<String, Object> _loadYaml(_LoadYamlParcel parcel) {
  Map<String, Object> cMap = {};

  late Function(YamlMap, String?) fProcessMap;

  fProcessMap = (yamlMap, keyBase) {
    final tKeys = yamlMap.keys;

    for (final String tKey in tKeys.cast<String>()) {
      Object? tValue = yamlMap[tKey];

      if (tValue is YamlMap) {
        fProcessMap(tValue, keyBase == null ? tKey : '$keyBase.$tKey');
      } else if (tValue != null) {
        cMap['${keyBase != null ? '$keyBase.' : ''}$tKey'] = tValue;
      }
    }
  };

  final tYaml = loadYaml(
    parcel.source,
    sourceUrl: parcel.sourceUri,
  );

  if (tYaml is YamlMap) {
    fProcessMap(
      tYaml,
      null,
    );
  } else {
    throw ArgumentError.value(
      parcel.source,
      'source',
      'The source is not a valid YAML map.',
    );
  }

  return cMap;
}

class _PrepareMapParcel {
  final Locale locale;
  final Map<String, Object> map;

  _PrepareMapParcel(this.locale, this.map);
}

Map<String, Object> _prepareMap(_PrepareMapParcel parcel) {
  final tMap = parcel.map;
  final tLocale = parcel.locale.toLanguageTag();

  for (final i in tMap.entries) {
    if (i.value is String) {
      // We format it to parse the blocks for faster lookup later.
      tMap[i.key] = MessageFormat(i.value as String, locale: tLocale)
        ..format({});
    }
  }

  return tMap;
}

/// Manages resources required for localization.
///
/// For each [Locale], place the yaml file in the directory specified by
/// [I18nEnvironment.l10nPaths].
/// The file name becomes the identifier returned by
/// [Locale.toLanguageTag] and is normalized by [Intl.canonicalizedLocale].
///
/// This class is automatically created during the load of
/// [L10nDelegate] and loads each resource.
class L10n {
  static Future<Map<String, Object>> _loadMapFromAssets(
    Locale locale,
    AssetBundle assetBundle,
    String fileName,
    List<String> paths,
  ) =>
      Future.wait([
        for (var i in paths)
          assetBundle
              .loadString(
                '$i/$fileName.yaml',
                cache: false,
              )
              .catchError((e, stackTrace) {
                if (!kIsTest) {
                  // coverage:ignore-start
                  _logger.warning(
                    'Failed to load l10n file: $i/$fileName.yaml\nDid you configure I18nEnvironment correctly?',
                    L10nLoadAssetsException(original: e),
                    stackTrace,
                  );
                  // coverage:ignore-end
                }

                return 'patapata_dummy_never: dummy';
              })
              .then<Map<String, Object>>(
                (v) => platformCompute(
                  _loadYaml,
                  _LoadYamlParcel(
                    v,
                    Uri.tryParse('$i/$fileName.yaml'),
                  ),
                  debugLabel: 'patapata_core:i18n:loadYaml',
                ),
              )
              .catchError((e, stackTrace) {
                _logger.warning(
                  'Failed to parse l10n file: $i/$fileName.yaml',
                  L10nLoadAssetsException(original: e),
                  stackTrace,
                );

                return <String, Object>{};
              }),
      ])
          .then<Map<String, Object>>(
              (maps) => maps.reduce((v, e) => v..addAll(e)))
          .then((v) =>
              platformCompute(_prepareMap, _PrepareMapParcel(locale, v)));

  /// Load the yaml file corresponding to [Locale] from the asset.
  ///
  /// If [assetBundle] is not passed, it will be loaded from [rootBundle].
  static Future<L10n> fromAssets({
    required Locale locale,
    required List<String> paths,
    AssetBundle? assetBundle,
  }) async {
    return L10n(
      locale,
      await _loadMapFromAssets(
        locale,
        assetBundle ??= rootBundle,
        Intl.canonicalizedLocale(locale.toLanguageTag()),
        paths,
      ),
    );
  }

  final Locale _locale;

  /// The [Locale] supported by this [L10n].
  Locale get locale => _locale;

  final Map<String, Object> _map;

  const L10n(this._locale, this._map);

  /// Returns a string specified by [key] from the loaded yaml file.
  ///
  /// By passing parameters to [namedParameters],
  /// formatting compliant with [MessageFormat] is possible.
  ///
  /// This method is called from the [l] method.
  String lookup(
    String key, {
    Map<String, Object>? namedParameters,
  }) {
    final tValue = _map[key];

    if (tValue == null) {
      return key;
    }

    if (tValue is MessageFormat) {
      return tValue.format(namedParameters ?? const {});
    } else {
      return tValue.toString();
    }
  }

  /// Returns true if [key] is defined in the yaml file.
  bool containsMessageKey(String key) => _map.containsKey(key);

  /// Returns true if [key] is defined in the yaml file.
  static bool containsKey({
    required BuildContext context,
    required String key,
  }) =>
      Localizations.of<L10n>(context, L10n)?.containsMessageKey(key) ?? false;
}

/// Factory to load resources for [L10n].
/// Called by the [Localizations] Widget.
class L10nDelegate extends LocalizationsDelegate<L10n> {
  L10nDelegate(this._i18n);

  final I18n _i18n;

  L10n? _l10n;

  /// The loaded [L10n] class.
  /// If it hasn't been loaded yet, null.
  L10n? get l10n => _l10n;

  @override
  bool isSupported(Locale locale) {
    return _i18n.supportedL10ns.contains(locale);
  }

  @override
  Future<L10n> load(Locale locale) => L10n.fromAssets(
        locale: locale,
        paths: _i18n._l10nPaths,
        assetBundle: mockL10nAssetBundle,
      ).then((value) => _l10n = value);

  // coverage:ignore-start
  @override
  bool shouldReload(LocalizationsDelegate<L10n> old) => _reassembling;
  // coverage:ignore-end
}

@visibleForTesting
AssetBundle? mockL10nAssetBundle;

/// Thrown if the loading of an asset in [L10n] fails.
class L10nLoadAssetsException extends PatapataCoreException {
  L10nLoadAssetsException({
    super.original,
  }) : super(code: PatapataCoreExceptionCode.PPE401);
}
