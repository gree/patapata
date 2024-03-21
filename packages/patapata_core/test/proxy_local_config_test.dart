// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/src/native_local_config_finder.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  testSetMockMethodCallHandler = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger.setMockMethodCallHandler;

  const kBoolValueKey = 'kBoolValueKey';
  const kDoubleValueKey = 'kDoubleValueKey';
  const kIntValueKey = 'kIntValueKey';
  const kStringValueKey = 'kStringValueKey';

  test('initialized | disposed', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    await tProxyLocalConfig.init();
    expect(tProxyLocalConfig.initialized, isTrue);

    tProxyLocalConfig.dispose();
    expect(tProxyLocalConfig.disposed, isTrue);
  });

  test('hasKey', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    const String kDefaultValueKey = 'defaultValue';
    const String kSetValueKey = 'setValue';

    expect(tProxyLocalConfig.hasKey(kDefaultValueKey), isFalse);
    expect(tProxyLocalConfig.hasKey(kSetValueKey), isFalse);

    await tProxyLocalConfig.setDefaults({kDefaultValueKey: 1});

    expect(tProxyLocalConfig.hasKey(kDefaultValueKey), isFalse);
    expect(tProxyLocalConfig.hasKey(kSetValueKey), isFalse);

    await tProxyLocalConfig.setInt(kSetValueKey, 1);

    expect(tProxyLocalConfig.hasKey(kDefaultValueKey), isFalse);
    expect(tProxyLocalConfig.hasKey(kSetValueKey), isTrue);
  });

  test('addLocalConfig | removeLocalConfig', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    await tProxyLocalConfig.setString(kStringValueKey, 'ProxyLocalConfig');
    expect(tProxyLocalConfig.getString(kStringValueKey), 'ProxyLocalConfig');

    await tProxyLocalConfig.addLocalConfig(tNativeLocalConfig);
    await tNativeLocalConfig.setString(kStringValueKey, 'NativeLocalConfig');

    expect(tProxyLocalConfig.getString(kStringValueKey), 'NativeLocalConfig');

    tProxyLocalConfig.removeLocalConfig(tNativeLocalConfig);
    expect(tProxyLocalConfig.getString(kStringValueKey), 'ProxyLocalConfig');
  });

  test('check bool value', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    expect(
        tProxyLocalConfig.getBool(kBoolValueKey), Config.defaultValueForBool);

    await tProxyLocalConfig.setDefaults({kBoolValueKey: true});
    expect(tProxyLocalConfig.getBool(kBoolValueKey), true);

    await tProxyLocalConfig.setBool(kBoolValueKey, false);
    expect(tProxyLocalConfig.getBool(kBoolValueKey), false);

    await tProxyLocalConfig.reset(kBoolValueKey);
    expect(tProxyLocalConfig.getBool(kBoolValueKey), true);
  });

  test('check double value', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    expect(tProxyLocalConfig.getDouble(kDoubleValueKey),
        Config.defaultValueForDouble);

    await tProxyLocalConfig.setDefaults({kDoubleValueKey: 1.0});
    expect(tProxyLocalConfig.getDouble(kDoubleValueKey), 1.0);

    await tProxyLocalConfig.setDouble(kDoubleValueKey, 2.0);
    expect(tProxyLocalConfig.getDouble(kDoubleValueKey), 2.0);

    await tProxyLocalConfig.reset(kDoubleValueKey);
    expect(tProxyLocalConfig.getDouble(kDoubleValueKey), 1.0);
  });

  test('check int value', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    expect(tProxyLocalConfig.getInt(kIntValueKey), Config.defaultValueForInt);

    await tProxyLocalConfig.setDefaults({kIntValueKey: 1});
    expect(tProxyLocalConfig.getInt(kIntValueKey), 1);

    await tProxyLocalConfig.setInt(kIntValueKey, 2);
    expect(tProxyLocalConfig.getInt(kIntValueKey), 2);

    await tProxyLocalConfig.reset(kIntValueKey);
    expect(tProxyLocalConfig.getInt(kIntValueKey), 1);
  });

  test('check String value', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    expect(tProxyLocalConfig.getString(kStringValueKey),
        Config.defaultValueForString);

    await tProxyLocalConfig.setDefaults({kStringValueKey: '1'});
    expect(tProxyLocalConfig.getString(kStringValueKey), '1');

    await tProxyLocalConfig.setString(kStringValueKey, '2');
    expect(tProxyLocalConfig.getString(kStringValueKey), '2');

    await tProxyLocalConfig.reset(kStringValueKey);
    expect(tProxyLocalConfig.getString(kStringValueKey), '1');
  });

  test('resetAll', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    await tProxyLocalConfig.setBool(kBoolValueKey, false);
    await tProxyLocalConfig.setDouble(kDoubleValueKey, 2.0);
    await tProxyLocalConfig.setInt(kIntValueKey, 2);
    await tProxyLocalConfig.setString(kStringValueKey, '2');

    expect(tProxyLocalConfig.getBool(kBoolValueKey), false);
    expect(tProxyLocalConfig.getDouble(kDoubleValueKey), 2.0);
    expect(tProxyLocalConfig.getInt(kIntValueKey), 2);
    expect(tProxyLocalConfig.getString(kStringValueKey), '2');

    await tProxyLocalConfig.resetAll();

    expect(
        tProxyLocalConfig.getBool(kBoolValueKey), Config.defaultValueForBool);
    expect(tProxyLocalConfig.getDouble(kDoubleValueKey),
        Config.defaultValueForDouble);
    expect(tProxyLocalConfig.getInt(kIntValueKey), Config.defaultValueForInt);
    expect(tProxyLocalConfig.getString(kStringValueKey),
        Config.defaultValueForString);
  });

  test('resetMany', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    const kIsSetKey1 = 'isSet1';
    const kIsSetKey2 = 'isSet2';
    const kIsNotSetKey1 = 'isNotSet1';
    const kIsNotSetKey2 = 'isNotSet2';

    await tProxyLocalConfig.setDefaults({
      kIsSetKey1: 1,
      kIsSetKey2: 1,
    });

    await tProxyLocalConfig.setInt(kIsSetKey1, 2);
    await tProxyLocalConfig.setInt(kIsNotSetKey1, 2);

    await tProxyLocalConfig.resetMany([
      kIsSetKey1,
      kIsSetKey2,
      kIsNotSetKey1,
      kIsNotSetKey2,
    ]);

    expect(tProxyLocalConfig.getInt(kIsSetKey1), 1);
    expect(tProxyLocalConfig.getInt(kIsSetKey2), 1);
    expect(tProxyLocalConfig.getInt(kIsNotSetKey1), Config.defaultValueForInt);
    expect(tProxyLocalConfig.getInt(kIsNotSetKey2), Config.defaultValueForInt);
  });

  test('setMany', () async {
    ProxyLocalConfig tProxyLocalConfig = ProxyLocalConfig();

    final Map<String, Object> tObjects = {
      'name': 'GREE, Inc.',
    };

    await tProxyLocalConfig.setMany(tObjects);

    expect(tProxyLocalConfig.getString('name'), 'GREE, Inc.');
  });
}
