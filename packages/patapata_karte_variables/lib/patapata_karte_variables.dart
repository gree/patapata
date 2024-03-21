// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_karte_variables;

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:karte_variables/karte_variables.dart';
import 'package:patapata_karte_core/patapata_karte_core.dart';

final _logger = Logger('patapata.KarteVariablesPlugin');

/// A plugin that provides KarteVariables functionality. For information about KarteVariables, please refer to the [official documentation](https://pub.dev/packages/karte_variables).
/// To use this plugin, you need to add the [patapata_karte_core](https://pub.dev/packages/patapata_karte_core) package to your application.
class KarteVariablesPlugin extends Plugin {
  @override
  List<Type> get dependencies => [KarteCorePlugin];

  @override
  RemoteConfig createRemoteConfig() => _KarteVariablesPluginRemoteConfig();
}

class _KarteVariablesPluginRemoteConfig extends RemoteConfig {
  Map<String, Object> _defaults = {};
  final Map<String, Object> _variables = {};
  bool _updating = false;
  bool _fetching = false;

  Future<void> _updateVariablesFromDefaults() async {
    _updating = true;

    try {
      _variables.clear();

      for (var tKey in _defaults.keys) {
        final tDefaultValue = _defaults[tKey];

        switch (tDefaultValue?.runtimeType) {
          case int:
            await _updateVariable<int>(tKey, tDefaultValue as int);
            break;
          case double:
            await _updateVariable<double>(tKey, tDefaultValue as double);
            break;
          case String:
            await _updateVariable<String>(tKey, tDefaultValue as String);
            break;
          case bool:
            await _updateVariable<bool>(tKey, tDefaultValue as bool);
            break;
          default:
            break;
        }
      }

      _updating = false;

      if (_defaults.isNotEmpty) {
        onChange();
      }
    } catch (e, stackTrace) {
      _updating = false;
      _logger.warning('Failed to update Variables', e, stackTrace);
    }
  }

  Future<T> _updateVariable<T>(String key, T defaultValue) async {
    final tVariable = await Variables.get(key);
    dynamic tValue;

    switch (T) {
      case int:
        tValue = await tVariable.getInteger(defaultValue as int);
        break;
      case double:
        tValue = await tVariable.getDouble(defaultValue as double);
        break;
      case String:
        tValue = await tVariable.getString(defaultValue as String);
        break;
      case bool:
        tValue = await tVariable.getBoolean(defaultValue as bool);
        break;
      default:
        break;
    }

    _variables[key] = tValue;

    return tValue;
  }

  @override
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  }) async {
    if (_fetching) {
      return;
    }

    _fetching = true;

    try {
      await Variables.fetch();
      // ignore: todo
      // TODO: Expiration. Just make a timer.
    } catch (e, stackTrace) {
      _logger.warning('Failed to fetch Variables', e, stackTrace);
    }

    if (_updating) {
      return;
    }

    // Karte Flutter version doesn't support getting variables
    // synchronously. So we cheat and use the defaults as a hint
    // that these are going to get getted.
    // If something unexpected not in defaults comes along...
    // we get it async and use onChange to tell people
    // it updated while returning the default value before that.
    // Not a great solution but yeah...
    await _updateVariablesFromDefaults();

    _fetching = false;
  }

  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    if (_variables.containsKey(key)) {
      final tVariable = _variables[key];

      return tVariable is bool ? tVariable : defaultValue;
    } else {
      // We got an unexpected get. Update it.
      _updateVariable<bool>(key, defaultValue).then((v) {
        onChange();
      });

      // Until that's done we have to return the default value.
      return defaultValue;
    }
  }

  @override
  double getDouble(String key,
      {double defaultValue = Config.defaultValueForDouble}) {
    if (_variables.containsKey(key)) {
      final tVariable = _variables[key];

      return tVariable is double ? tVariable : defaultValue;
    } else {
      // We got an unexpected get. Update it.
      _updateVariable<double>(key, defaultValue).then((v) {
        onChange();
      });

      // Until that's done we have to return the default value.
      return defaultValue;
    }
  }

  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    if (_variables.containsKey(key)) {
      final tVariable = _variables[key];

      return tVariable is int ? tVariable : defaultValue;
    } else {
      // We got an unexpected get. Update it.
      _updateVariable<int>(key, defaultValue).then((v) {
        onChange();
      });

      // Until that's done we have to return the default value.
      return defaultValue;
    }
  }

  @override
  String getString(String key,
      {String defaultValue = Config.defaultValueForString}) {
    if (_variables.containsKey(key)) {
      final tVariable = _variables[key];

      return tVariable is String ? tVariable : defaultValue;
    } else {
      // We got an unexpected get. Update it.
      _updateVariable<String>(key, defaultValue).then((v) {
        onChange();
      });

      // Until that's done we have to return the default value.
      return defaultValue;
    }
  }

  @override
  bool hasKey(String key) {
    // This is not 100% correct.
    // This will return a false positive when
    // a _defaults value that was saved in
    // _variables exists (most of the time...)
    // However Karte doesn't provide a way to know
    // if a key exists or not so we do the best we can.
    return _variables.containsKey(key);
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    _defaults = Map<String, Object>.of(defaults);
    await _updateVariablesFromDefaults();
  }
}
