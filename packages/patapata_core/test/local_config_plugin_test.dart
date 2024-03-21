// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/src/native_local_config_finder.dart';

import 'utils/patapata_core_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalConfigFinder', () {
    test('factory LocalConfigFinder', () async {
      final tLocalConfigFinder = LocalConfigFinder();
      expect(tLocalConfigFinder.runtimeType, NativeLocalConfigFinder);
    });

    test('getLocalConfig', () async {
      final tLocalConfigFinder = LocalConfigFinder();
      LocalConfig? tLocalConfig = tLocalConfigFinder.getLocalConfig();

      expect(tLocalConfig, isNotNull);
      expect(tLocalConfig.runtimeType, NativeLocalConfig);
    });
  });

  group('NativeLocalConfigPlugin', () {
    test('init | dispose', () async {
      final NativeLocalConfigPlugin tNativeLocalConfigPlugin =
          NativeLocalConfigPlugin();

      final tApp = createApp();

      await tNativeLocalConfigPlugin.init(tApp);
      expect(tNativeLocalConfigPlugin.initialized, isTrue);

      tNativeLocalConfigPlugin.dispose();
      expect(tNativeLocalConfigPlugin.disposed, isTrue);
    });

    test('createLocalConfig', () async {
      final NativeLocalConfigPlugin tNativeLocalConfigPlugin =
          NativeLocalConfigPlugin();

      final tNativaLocalConfig = tNativeLocalConfigPlugin.createLocalConfig();
      expect(tNativaLocalConfig.runtimeType, NativeLocalConfig);
    });
  });
}
