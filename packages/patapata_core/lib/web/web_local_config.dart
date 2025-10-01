// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:patapata_core/web/patapata_web_plugin.dart';

import 'package:web/web.dart' as web;

class WebLocalConfig extends PatapataPlugin {
  WebLocalConfig(this.registrar);
  final Registrar registrar;

  @override
  String patapataName = "dev.patapata.native_local_config";

  @override
  void patapataDisable() {
    channel?.setMethodCallHandler(null);
  }

  MethodChannel? channel;

  @override
  void patapataEnable() {
    channel = MethodChannel(
      patapataName,
      const StandardMethodCodec(),
      registrar,
    );

    channel?.setMethodCallHandler(handleMethodCall);

    _sync();
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'reset':
        web.window.localStorage.removeItem(call.arguments as String);
        break;
      case 'resetMany':
        var tArgs = call.arguments as List<String>;
        for (var arg in tArgs) {
          web.window.localStorage.removeItem(arg);
        }
        break;
      case 'resetAll':
        web.window.localStorage.clear();
        break;
      case 'setBool':
        var tArgs = call.arguments as List<Object?>;
        web.window.localStorage
            .setItem(tArgs[0] as String, 'b${(tArgs[1] as bool) ? '1' : '0'}');
        break;
      case 'setInt':
        var tArgs = call.arguments as List<Object?>;
        web.window.localStorage.setItem(tArgs[0] as String, 'i${tArgs[1]}');
        break;
      case 'setDouble':
        var tArgs = call.arguments as List<Object?>;
        web.window.localStorage.setItem(tArgs[0] as String, 'd${tArgs[1]}');
        break;
      case 'setString':
        var tArgs = call.arguments as List<Object?>;
        web.window.localStorage.setItem(tArgs[0] as String, 's${tArgs[1]}');
        break;
      case 'setMany':
        var tArgs = (call.arguments as Map).cast<String, Object>();
        tArgs.forEach((key, value) {
          if (value is String) {
            web.window.localStorage.setItem(key, 's$value');
          } else if (value is int) {
            web.window.localStorage.setItem(key, 'i$value');
          } else if (value is double) {
            web.window.localStorage.setItem(key, 'd$value');
          } else if (value is bool) {
            web.window.localStorage.setItem(key, 'b${(value) ? '1' : '0'}');
          }
        });
        break;
      default:
        break;
    }

    _sync();
  }

  void _sync() {
    final Map<String, Object> tData = {};
    final tLength = web.window.localStorage.length;
    for (int i = 0; i < tLength; i++) {
      final tKey = web.window.localStorage.key(i);
      if (tKey != null) {
        final tValue = web.window.localStorage.getItem(tKey) ?? '';
        tData[tKey] = switch (tValue[0]) {
          'b' => tValue.substring(1) == '1',
          'i' => int.tryParse(tValue.substring(1)) ?? 0,
          'd' => double.tryParse(tValue.substring(1)) ?? 0.0,
          's' => tValue.substring(1),
          _ => '',
        };
      }
    }

    channel?.invokeMethod('syncAll', tData);
  }
}
