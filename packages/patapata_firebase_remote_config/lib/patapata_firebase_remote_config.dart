// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_firebase_remote_config;

import 'package:firebase_remote_config/firebase_remote_config.dart'
    as firebase_remote_config;
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_firebase_core/patapata_firebase_core.dart';

final _logger = Logger('patapata.FirebaseRemoteConfigPlugin');

/// This is a plugin that provides FirebaseRemoteConfig functionality to Patapata.
/// To use this plugin, you need to add the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) package to your application.
class FirebaseRemoteConfigPlugin extends Plugin {
  @override
  List<Type> get dependencies => [FirebaseCorePlugin];

  @override
  RemoteConfig createRemoteConfig() =>
      _FirebaseRemoteConfigPluginRemoteConfig();
}

class _FirebaseRemoteConfigPluginRemoteConfig extends RemoteConfig {
  late firebase_remote_config.FirebaseRemoteConfig _remoteConfig;
  StreamSubscription<firebase_remote_config.RemoteConfigUpdate>? _subscription;

  @override
  Future<void> init() async {
    bool tIsDebug = false;

    assert(() {
      tIsDebug = true;
      return true;
    }());

    _remoteConfig = firebase_remote_config.FirebaseRemoteConfig.instance;

    if (tIsDebug) {
      await _remoteConfig.setConfigSettings(
        firebase_remote_config.RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 1),
        ),
      );
      _logger.finer('Enabled debug mode. Fetches will be more frequent!');
    }

    _subscription = _remoteConfig.onConfigUpdated.listen(_onRemoteChanged);
    await super.init();
  }

  @override
  void dispose() {
    super.dispose();

    _subscription?.cancel();
    _subscription = null;
  }

  void _onRemoteChanged(firebase_remote_config.RemoteConfigUpdate update) {
    onChange();
  }

  @override
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  }) async {
    _logger.fine('fetch:$expiration');

    try {
      if (force) {
        _logger.info('force fetch:$expiration');
        await _remoteConfig.setConfigSettings(
          firebase_remote_config.RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: Duration.zero,
          ),
        );
        await _remoteConfig.fetchAndActivate();
        await _remoteConfig.setConfigSettings(
          firebase_remote_config.RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: expiration,
          ),
        );
      } else {
        await _remoteConfig.setConfigSettings(
          firebase_remote_config.RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: expiration,
          ),
        );
        await _remoteConfig.fetchAndActivate();
      }
    } catch (e, stackTrace) {
      _logger.info('Failed to fetch', e, stackTrace);
    }
  }

  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    final tValue = _remoteConfig.getValue(key);

    if (tValue.source == firebase_remote_config.ValueSource.valueStatic) {
      return defaultValue;
    }

    return tValue.asBool();
  }

  @override
  double getDouble(String key,
      {double defaultValue = Config.defaultValueForDouble}) {
    final tValue = _remoteConfig.getValue(key);

    if (tValue.source == firebase_remote_config.ValueSource.valueStatic) {
      return defaultValue;
    }

    return tValue.asDouble();
  }

  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    final tValue = _remoteConfig.getValue(key);

    if (tValue.source == firebase_remote_config.ValueSource.valueStatic) {
      return defaultValue;
    }

    return tValue.asInt();
  }

  @override
  String getString(String key,
      {String defaultValue = Config.defaultValueForString}) {
    final tValue = _remoteConfig.getValue(key);

    if (tValue.source == firebase_remote_config.ValueSource.valueStatic) {
      return defaultValue;
    }

    return tValue.asString();
  }

  @override
  bool hasKey(String key) =>
      _remoteConfig.getValue(key).source ==
      firebase_remote_config.ValueSource.valueRemote;

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    await _remoteConfig.setDefaults(defaults);
  }
}
