// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/services.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';

const _methodChannel = MethodChannel('dev.patapata.native_local_config');

final _logger = Logger('patapata.NativeLocalConfig');

class WebLocalConfigFinder implements LocalConfigFinder {
  @override
  LocalConfig? getLocalConfig() => WebLocalConfig();
}

class WebLocalConfig extends LocalConfig with MemoryLocalConfig {
  @override
  Future<void> init() async {
    _methodChannel.setMethodCallHandler(_onMethodCall);
    await super.init();
  }

  @override
  void dispose() async {
    _methodChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'syncAll':
        _onSyncAll((call.arguments as Map).cast<String, Object>());
        break;
      case 'error':
        _onError((call.arguments as Map).cast<String, Object?>());
        break;
      default:
        break;
    }
  }

  void _onSyncAll(Map<String, Object> data) {
    store.clear();
    store.addAll(data);
    notifyListeners();
  }

  void _onError(Map<String, Object?> error) {
    final tError = NativeThrowable.fromMap(error);

    _logger.severe(tError.message, tError, tError.chain);
  }

  @override
  Future<void> reset(String key) async {
    await super.reset(key);
    await _methodChannel.invokeMethod('reset', key);
  }

  @override
  Future<void> resetAll() async {
    await super.resetAll();
    await _methodChannel.invokeMethod('resetAll');
  }

  @override
  Future<void> resetMany(List<String> keys) async {
    await super.resetMany(keys);
    await _methodChannel.invokeMethod('resetMany', keys);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _methodChannel.invokeMethod('setBool', [key, value]);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _methodChannel.invokeMethod('setDouble', [key, value]);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _methodChannel.invokeMethod('setInt', [key, value]);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _methodChannel.invokeMethod('setString', [key, value]);
  }

  @override
  Future<void> setMany(Map<String, Object> objects) async {
    await _methodChannel.invokeMethod('setMany', objects);
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    await super.setDefaults(defaults);
  }
}

LocalConfigFinder getLocalConfigFinder() => WebLocalConfigFinder();
