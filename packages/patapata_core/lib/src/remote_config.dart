// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'config.dart';

/// Abstract class for the [RemoteConfig].
///
/// Inherit this class to create the [RemoteConfig] class.
abstract class RemoteConfig extends Config with ReadableConfig {
  /// Fetches configuration data from a remote server.
  ///
  /// [expiration] is the cache expiration time. Default is 5 hours.
  /// If [force] is true, it ignores the cache and fetches directly from the server.
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  });
}

/// Class for managing all [RemoteConfig] used by the app.
///
/// Access to [RemoteConfig] is usually done through this class.
/// example
/// ```dart
/// getApp().remoteConfig.getBool('key');
/// ```
class ProxyRemoteConfig extends RemoteConfig {
  /// A list of [RemoteConfig] instances managed by this class.
  /// These instances are used to fetch and store configuration data from a remote server.
  final List<RemoteConfig> _remoteConfigs = [];

  /// A map of default configuration values.
  /// These values are used when no other values are specified for the corresponding keys.
  final Map<String, Object> _defaults = {};

  ProxyRemoteConfig();

  /// Adds [RemoteConfig] passed as an argument to the list of managed configs.
  ///
  /// When initializing [Plugin], associated remote configs are added through this function.
  /// Please make sure not to add [ProxyRemoteConfig].
  Future<void> addRemoteConfig(RemoteConfig remoteConfig) async {
    await remoteConfig.init();
    await remoteConfig.setDefaults(Map<String, Object>.of(_defaults));
    remoteConfig.addListener(onChange);
    _remoteConfigs.add(remoteConfig);

    if (initialized) {
      await remoteConfig.fetch();
    }
  }

  /// Removes [RemoteConfig] passed as an argument from the list of managed configs.
  ///
  /// When dispose the [Plugin], associated remote configs are removed through this function.
  void removeRemoteConfig(RemoteConfig remoteConfig) {
    if (_remoteConfigs.remove(remoteConfig)) {
      remoteConfig.dispose();
    }
  }

  /// Disposes all the [RemoteConfig] instances managed by this class.
  @override
  void dispose() {
    for (var v in _remoteConfigs) {
      v.dispose();
    }
    _remoteConfigs.clear();

    super.dispose();
  }

  /// Fetch data from all RemoteConfig's managed by the app.
  @override
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  }) async {
    await Future.wait([
      for (var tConfig in _remoteConfigs)
        tConfig.fetch(expiration: expiration, force: force),
    ]).catchError((e) => const <void>[]);
  }

  /// Checks if the given [key] exists in any of the [RemoteConfig] instances.
  @override
  bool hasKey(String key) => _remoteConfigs.any((v) => v.hasKey(key));

  /// Retrieve a bool value from [RemoteConfig]
  ///
  /// Gets a bool value from RemoteConfig's managed by [App].
  /// If multiple classes have the same [key],
  /// it returns the value from [RemoteConfig] that was added first to [_remoteConfigs].
  /// If the [key] does not exist in any RemoteConfig's, it returns the value in [_defaults].
  /// If that also doesn't exist, it returns the [defaultValue].
  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    for (var tConfig in _remoteConfigs) {
      if (tConfig.hasKey(key)) {
        return tConfig.getBool(key, defaultValue: defaultValue);
      }
    }

    if (_defaults.containsKey(key) && _defaults[key] is bool) {
      return _defaults[key] as bool;
    }

    return defaultValue;
  }

  /// Retrieve a double value from [RemoteConfig]
  ///
  /// Gets a double value from RemoteConfig's managed by [App].
  /// If multiple classes have the same [key],
  /// it returns the value from [RemoteConfig] that was added first to [_remoteConfigs].
  /// If the [key] does not exist in any RemoteConfig's, it returns the value in [_defaults].
  /// If that also doesn't exist, it returns the [defaultValue].
  @override
  double getDouble(
    String key, {
    double defaultValue = Config.defaultValueForDouble,
  }) {
    for (var tConfig in _remoteConfigs) {
      if (tConfig.hasKey(key)) {
        return tConfig.getDouble(key, defaultValue: defaultValue);
      }
    }

    if (_defaults.containsKey(key) && _defaults[key] is double) {
      return _defaults[key] as double;
    }

    return defaultValue;
  }

  /// Retrieve a int value from [RemoteConfig]
  ///
  /// Gets a int value from RemoteConfig's managed by [App].
  /// If multiple classes have the same [key],
  /// it returns the value from [RemoteConfig] that was added first to [_remoteConfigs].
  /// If the [key] does not exist in any RemoteConfig's, it returns the value in [_defaults].
  /// If that also doesn't exist, it returns the [defaultValue].
  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    for (var tConfig in _remoteConfigs) {
      if (tConfig.hasKey(key)) {
        return tConfig.getInt(key, defaultValue: defaultValue);
      }
    }

    if (_defaults.containsKey(key) && _defaults[key] is int) {
      return _defaults[key] as int;
    }

    return defaultValue;
  }

  /// Retrieve a String value from [RemoteConfig]
  ///
  /// Gets a String value from RemoteConfig's managed by [App].
  /// If multiple classes have the same [key],
  /// it returns the value from [RemoteConfig] that was added first to [_remoteConfigs].
  /// If the [key] does not exist in any RemoteConfig's, it returns the value in [_defaults].
  /// If that also doesn't exist, it returns the [defaultValue].
  @override
  String getString(
    String key, {
    String defaultValue = Config.defaultValueForString,
  }) {
    for (var tConfig in _remoteConfigs) {
      if (tConfig.hasKey(key)) {
        return tConfig.getString(key, defaultValue: defaultValue);
      }
    }

    if (_defaults.containsKey(key) && _defaults[key] is String) {
      return _defaults[key] as String;
    }

    return defaultValue;
  }

  /// Sets the default values for the [RemoteConfig] instances managed by this class.
  ///
  /// The [defaults] parameter is a map containing the default key-value pairs.
  /// These values are used when no other values are specified for the corresponding keys.
  ///
  /// This method is asynchronous and applies the default values to all [RemoteConfig] instances.
  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    _defaults
      ..clear()
      ..addAll(defaults);

    // After we add, we hint to the actual
    // RemoteConfig's about the defaults as well.
    // They are expected to only return true for hasKey
    // when not using default values.
    for (var tConfig in _remoteConfigs) {
      await tConfig.setDefaults(defaults);
    }
  }
}

/// A [RemoteConfig] that can be used for testing.
/// This class is not intended to be used in production.
/// This [RemoteConfig] also implements [WritableConfig] and therefore
/// can be used to set values for testing.
class MockRemoteConfig extends RemoteConfig implements WritableConfig {
  final Map<String, Object> _store;
  final Map<String, Object> _defaults = {};
  bool _firstFetch = true;

  /// Creates a [MockRemoteConfig] that can be used for testing.
  MockRemoteConfig(Map<String, Object> store) : _store = store;

  @override
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  }) async {
    if (force || _firstFetch) {
      _firstFetch = false;
      _store.addAll(_mockfetchValues);
      notifyListeners();
    }
  }

  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    return _store.containsKey(key) && _store[key] is bool
        ? _store[key] as bool
        : _defaults.containsKey(key) && _defaults[key] is bool
        ? _defaults[key] as bool
        : defaultValue;
  }

  @override
  double getDouble(
    String key, {
    double defaultValue = Config.defaultValueForDouble,
  }) {
    return _store.containsKey(key) && _store[key] is double
        ? _store[key] as double
        : _defaults.containsKey(key) && _defaults[key] is double
        ? _defaults[key] as double
        : defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    return _store.containsKey(key) && _store[key] is int
        ? _store[key] as int
        : _defaults.containsKey(key) && _defaults[key] is int
        ? _defaults[key] as int
        : defaultValue;
  }

  @override
  String getString(
    String key, {
    String defaultValue = Config.defaultValueForString,
  }) {
    return _store.containsKey(key) && _store[key] is String
        ? _store[key] as String
        : _defaults.containsKey(key) && _defaults[key] is String
        ? _defaults[key] as String
        : defaultValue;
  }

  @override
  bool hasKey(String key) {
    return _store.containsKey(key);
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    _defaults
      ..clear()
      ..addAll(defaults);
  }

  @override
  Future<void> reset(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> resetAll() async {
    _store.clear();
  }

  @override
  Future<void> resetMany(List<String> keys) async {
    for (var tKey in keys) {
      _store.remove(tKey);
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    if (_store[key] != value) {
      _store[key] = value;
      notifyListeners();
    }
  }

  @override
  Future<void> setDouble(String key, double value) async {
    if (_store[key] != value) {
      _store[key] = value;
      notifyListeners();
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    if (_store[key] != value) {
      _store[key] = value;
      notifyListeners();
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    if (_store[key] != value) {
      _store[key] = value;
      notifyListeners();
    }
  }

  @override
  Future<void> setMany(Map<String, Object> objects) async {
    _store.addAll(objects);
    notifyListeners();
  }

  void testSetMockFetchValues(Map<String, Object> values) {
    _mockfetchValues = values;
  }

  Map<String, Object> _mockfetchValues = {};
}
