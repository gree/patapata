// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';

import 'config.dart';

/// Abstract class for the [LocalConfig].
///
/// [Config] for saving data locally.
/// Also, please check the mixin for implementing basic functionality in [MemoryLocalConfig].
abstract class LocalConfig extends Config with ReadableConfig, WritableConfig {}

/// Class for managing all [LocalConfig] used by the app.
/// If multiple local configurations are added, the most recently added local configuration is used as the current [LocalConfig].
///
/// Access to [LocalConfig] is usually done through this class.
///
/// example:
/// ```dart
/// tApp.getPlugin<ProxyLocalConfig>()?.getBool('key');
/// ```
class ProxyLocalConfig extends LocalConfig {
  final List<LocalConfig> _localConfigs = [
    // Make sure _something_ exists.
    MockLocalConfig({}),
  ];
  final Map<String, Object> _defaults = {};

  /// Create a [ProxyLocalConfig]
  ProxyLocalConfig();

  /// This adds the [localConfig] to the [LocalConfig]s managed by this class.
  Future<void> addLocalConfig(LocalConfig localConfig) async {
    await localConfig.init();
    await localConfig.setDefaults(Map<String, Object>.of(_defaults));
    localConfig.addListener(onChange);
    _localConfigs.add(localConfig);

    notifyListeners();
  }

  /// This removes [localConfig] from the [LocalConfig]s managed by this class.
  void removeLocalConfig(LocalConfig localConfig) {
    if (_localConfigs.remove(localConfig)) {
      localConfig.dispose();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (var v in _localConfigs) {
      v.dispose();
    }
    _localConfigs.clear();
  }

  LocalConfig get _current => _localConfigs.last;

  /// This class checks whether the current [LocalConfig] managed by it contains a key with the name [key].
  @override
  bool hasKey(String key) => _current.hasKey(key);

  /// Retrieves the bool value with the name [key] from the current [LocalConfig].
  /// If it cannot be retrieved, [defaultValue] is returned.
  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    if (_current.hasKey(key)) {
      return _current.getBool(key, defaultValue: defaultValue);
    }

    if (_defaults.containsKey(key) && _defaults[key] is bool) {
      return _defaults[key] as bool;
    }

    return defaultValue;
  }

  /// Retrieves the double value with the name [key] from the current [LocalConfig].
  /// If it cannot be retrieved, [defaultValue] is returned.
  @override
  double getDouble(String key,
      {double defaultValue = Config.defaultValueForDouble}) {
    if (_current.hasKey(key)) {
      return _current.getDouble(key, defaultValue: defaultValue);
    }

    if (_defaults.containsKey(key) && _defaults[key] is double) {
      return _defaults[key] as double;
    }

    return defaultValue;
  }

  /// Retrieves the int value with the name [key] from the current [LocalConfig].
  /// If it cannot be retrieved, [defaultValue] is returned.
  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    if (_current.hasKey(key)) {
      return _current.getInt(key, defaultValue: defaultValue);
    }

    if (_defaults.containsKey(key) && _defaults[key] is int) {
      return _defaults[key] as int;
    }

    return defaultValue;
  }

  /// Retrieves the String value with the name [key] from the current [LocalConfig].
  /// If it cannot be retrieved, [defaultValue] is returned.
  @override
  String getString(String key,
      {String defaultValue = Config.defaultValueForString}) {
    if (_current.hasKey(key)) {
      return _current.getString(key, defaultValue: defaultValue);
    }

    if (_defaults.containsKey(key) && _defaults[key] is String) {
      return _defaults[key] as String;
    }

    return defaultValue;
  }

  /// This sets the default values for all [LocalConfig] managed by this class to the values specified in [defaults].
  /// If values are already set, it overwrites them with the default values.
  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    _defaults
      ..clear()
      ..addAll(defaults);

    // After we add, we hint to the actual
    // LocalConfig's about the defaults as well.
    // They are expected to only return true for hasKey
    // when not using default values.
    for (var tConfig in _localConfigs) {
      await tConfig.setDefaults(defaults);
    }
  }

  /// This removes the value with the name [key] from the current [LocalConfig].
  @override
  Future<void> reset(String key) async {
    await _current.reset(key);
  }

  /// This removes all values from the current [LocalConfig].
  @override
  Future<void> resetAll() async {
    await _current.resetAll();
  }

  /// This removes the values with the names specified in [keys] from the current [LocalConfig].
  @override
  Future<void> resetMany(List<String> keys) async {
    await _current.resetMany(keys);
  }

  /// This sets the bool value [value] with the name [key] to the current [LocalConfig].
  @override
  Future<void> setBool(String key, bool value) async {
    await _current.setBool(key, value);
  }

  /// This sets the double value [value] with the name [key] to the current [LocalConfig].
  @override
  Future<void> setDouble(String key, double value) async {
    await _current.setDouble(key, value);
  }

  /// This sets the int value [value] with the name [key] to the current [LocalConfig].
  @override
  Future<void> setInt(String key, int value) async {
    await _current.setInt(key, value);
  }

  /// This sets the String value [value] with the name [key] to the current [LocalConfig].
  @override
  Future<void> setString(String key, String value) async {
    await _current.setString(key, value);
  }

  /// This sets the key-value pairs specified in the [objects] map of type `Map<String, Object>` to the current [LocalConfig].
  @override
  Future<void> setMany(Map<String, Object> objects) async {
    await _current.setMany(objects);
  }
}

/// A mixin that implements default functionality in [LocalConfig].
/// If you don't need to implement special features, you can use this mixin to create a `LocalConfig`
///
/// example:
/// ```dart
/// class HogehogeLocalConfig extends LocalConfig with MemoryLocalConfig {
///   // Processes you want to add, override, etc...
///   @override
///   bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
///     return super.getBool(key, defaultValue: false);
///   }
/// ...
/// }
/// ```
mixin MemoryLocalConfig on LocalConfig {
  /// The data managed by this class, in the form of a Map with keys and values.
  @protected
  final Map<String, Object> store = {};

  /// The default data for the data managed by this class, in the form of a Map with keys and values.
  @protected
  final Map<String, Object> defaults = {};

  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    return store.containsKey(key) && store[key] is bool
        ? store[key] as bool
        : defaults.containsKey(key) && defaults[key] is bool
            ? defaults[key] as bool
            : defaultValue;
  }

  @override
  double getDouble(String key,
      {double defaultValue = Config.defaultValueForDouble}) {
    return store.containsKey(key) && store[key] is double
        ? store[key] as double
        : defaults.containsKey(key) && defaults[key] is double
            ? defaults[key] as double
            : defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    return store.containsKey(key) && store[key] is int
        ? store[key] as int
        : defaults.containsKey(key) && defaults[key] is int
            ? defaults[key] as int
            : defaultValue;
  }

  @override
  String getString(String key,
      {String defaultValue = Config.defaultValueForString}) {
    return store.containsKey(key) && store[key] is String
        ? store[key] as String
        : defaults.containsKey(key) && defaults[key] is String
            ? defaults[key] as String
            : defaultValue;
  }

  @override
  bool hasKey(String key) {
    return store.containsKey(key);
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    this.defaults
      ..clear()
      ..addAll(defaults);
  }

  @override
  Future<void> reset(String key) async {
    store.remove(key);
    notifyListeners();
  }

  @override
  Future<void> resetAll() async {
    store.clear();
    notifyListeners();
  }

  @override
  Future<void> resetMany(List<String> keys) async {
    bool tChanged = false;

    for (final k in keys) {
      if (store.remove(k) != null) {
        tChanged = true;
      }
    }

    if (tChanged) {
      notifyListeners();
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    store[key] = value;
    notifyListeners();
  }

  @override
  Future<void> setDouble(String key, double value) async {
    store[key] = value;
    notifyListeners();
  }

  @override
  Future<void> setInt(String key, int value) async {
    store[key] = value;
    notifyListeners();
  }

  @override
  Future<void> setString(String key, String value) async {
    store[key] = value;
    notifyListeners();
  }

  @override
  Future<void> setMany(Map<String, Object> objects) async {
    for (final i in objects.entries) {
      store[i.key] = i.value;
    }

    notifyListeners();
  }
}

/// A [LocalConfig] class for mock purposes, used in tests and similar scenarios.
/// It is not intended for use by the application.
/// @nodoc
class MockLocalConfig extends LocalConfig with MemoryLocalConfig {
  /// Create a [MockLocalConfig]
  /// @nodoc
  MockLocalConfig(Map<String, Object> store) {
    this.store.addAll(store);
  }
}
