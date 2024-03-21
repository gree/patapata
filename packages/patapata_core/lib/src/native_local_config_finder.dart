// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';

final _logger = Logger('patapata.NativeLocalConfig');

const _methodChannelName = 'dev.patapata.native_local_config';
const _methodChannel = MethodChannel(_methodChannelName);

class NativeLocalConfigFinder implements LocalConfigFinder {
  @override
  LocalConfig? getLocalConfig() => NativeLocalConfig();
}

class NativeLocalConfig extends LocalConfig with MemoryLocalConfig {
  @visibleForTesting
  final Map<String, Object> mockNativeLocalConfigMap = {};

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
    super.setBool(key, value);
    await _methodChannel.invokeMethod('setBool', [key, value]);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    super.setDouble(key, value);
    await _methodChannel.invokeMethod('setDouble', [key, value]);
  }

  @override
  Future<void> setInt(String key, int value) async {
    super.setInt(key, value);
    await _methodChannel.invokeMethod('setInt', [key, value]);
  }

  @override
  Future<void> setString(String key, String value) async {
    super.setString(key, value);
    await _methodChannel.invokeMethod('setString', [key, value]);
  }

  @override
  Future<void> setMany(Map<String, Object> objects) async {
    super.setMany(objects);
    await _methodChannel.invokeMethod('setMany', objects);
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {
    await super.setDefaults(defaults);
  }

  @override
  @visibleForTesting
  void setMockMethodCallHandler() {
    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockMethodCallHandler(
      _methodChannel,
      (methodCall) async {
        methodCallLogs.add(methodCall);
        switch (methodCall.method) {
          case 'reset':
            final tKey = methodCall.arguments as String;
            mockNativeLocalConfigMap.remove(tKey);
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
          case 'resetAll':
            mockNativeLocalConfigMap.clear();
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
          case 'resetMany':
            final tKeys = List<String>.from(methodCall.arguments);

            for (final tKey in tKeys) {
              mockNativeLocalConfigMap.remove(tKey);
            }
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;

          case 'setBool':
            final tArguments = methodCall.arguments as List<dynamic>;
            mockNativeLocalConfigMap[tArguments[0] as String] =
                tArguments[1] as bool;
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
          case 'setDouble':
            final tArguments = methodCall.arguments as List<dynamic>;
            mockNativeLocalConfigMap[tArguments[0] as String] =
                tArguments[1] as double;
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
          case 'setInt':
            final tArguments = methodCall.arguments as List<dynamic>;
            mockNativeLocalConfigMap[tArguments[0] as String] =
                tArguments[1] as int;
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
          case 'setString':
            final tArguments = methodCall.arguments as List<dynamic>;
            mockNativeLocalConfigMap[tArguments[0] as String] =
                tArguments[1] as String;
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
          case 'setMany':
            final tArguments = Map<String, Object>.from(methodCall.arguments);

            for (final tKey in tArguments.keys) {
              mockNativeLocalConfigMap[tKey] = tArguments[tKey] as Object;
            }
            _onMethodCall(
              MethodCall('syncAll', mockNativeLocalConfigMap),
            );
            break;
        }
        return null;
      },
    );
  }

  @visibleForTesting
  void sendError() {
    _onMethodCall(
      MethodCall(
        'error',
        {
          "type": runtimeType.toString(),
          "message": "",
          "stackTrace": const [],
          "cause": const {},
        },
      ),
    );
  }
}

LocalConfigFinder getLocalConfigFinder() => NativeLocalConfigFinder();
