// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:patapata_core/web/patapata_web_plugin.dart';

import 'dart:html' as html;

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
        html.window.localStorage.remove(call.arguments as String);
        break;
      case 'resetMany':
        var tArgs = call.arguments as List<String>;
        for (var arg in tArgs) {
          html.window.localStorage.remove(arg);
        }
        break;
      case 'resetAll':
        html.window.localStorage.clear();
        break;
      case 'setBool':
        var tArgs = call.arguments as List<Object?>;
        html.window.localStorage[tArgs[0] as String] =
            'b${(tArgs[1] as bool) ? '1' : '0'}';
        break;
      case 'setInt':
        var tArgs = call.arguments as List<Object?>;
        html.window.localStorage[tArgs[0] as String] = 'i${tArgs[1]}';
        break;
      case 'setDouble':
        var tArgs = call.arguments as List<Object?>;
        html.window.localStorage[tArgs[0] as String] = 'd${tArgs[1]}';
        break;
      case 'setString':
        var tArgs = call.arguments as List<Object?>;
        html.window.localStorage[tArgs[0] as String] = 's${tArgs[1]}';
        break;
      case 'setMany':
        var tArgs = (call.arguments as List<dynamic>).cast<List<String>>();
        for (var arg in tArgs) {
          html.window.localStorage[arg[0]] = arg[1];
        }
        break;
      default:
        break;
    }

    _sync();
  }

  void _sync() {
    channel?.invokeMethod('syncAll', html.window.localStorage.map((key, value) {
      Object tValue;

      switch (value[0]) {
        case 'b':
          tValue = value.substring(1) == '1';

          break;
        case 'i':
          tValue = int.tryParse(value.substring(1)) ?? 0;

          break;
        case 'd':
          tValue = double.tryParse(value.substring(1)) ?? 0.0;

          break;
        case 's':
          tValue = value.substring(1);

          break;
        default:
          tValue = '';
      }

      return MapEntry(key, tValue);
    }));
  }
}
