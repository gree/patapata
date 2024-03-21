// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:patapata_core/web/patapata_web_plugin.dart';
import 'package:patapata_core/web/web_local_config.dart';

var _sPlugins = <PatapataPlugin>{};

class PatapataCoreWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'dev.patapata.patapata_core',
      const StandardMethodCodec(),
      registrar,
    );

    final tPluginInstance = PatapataCoreWeb();
    channel.setMethodCallHandler(tPluginInstance.handleMethodCall);

    _sPlugins.add(WebLocalConfig(registrar));
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'enablePlugin':
        var tName = call.arguments as String?;
        if (tName == null) {
          return;
        }
        return enablePlugin(tName);
      case 'disablePlugin':
        var tName = call.arguments as String?;
        if (tName == null) {
          return;
        }
        return disablePlugin(tName);
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'patapata_core for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  void enablePlugin(String pluginName) {
    for (var plugin in _sPlugins) {
      if (plugin.patapataName == pluginName) {
        plugin.patapataEnable();
        return;
      }
    }
  }

  void disablePlugin(String pluginName) {
    for (var plugin in _sPlugins) {
      if (plugin.patapataName == pluginName) {
        plugin.patapataDisable();
        return;
      }
    }
  }
}
