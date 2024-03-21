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

  test('check bool value', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    expect(
        tNativeLocalConfig.getBool(kBoolValueKey), Config.defaultValueForBool);

    await tNativeLocalConfig.setDefaults({kBoolValueKey: true});
    expect(tNativeLocalConfig.getBool(kBoolValueKey), true);

    await tNativeLocalConfig.setBool(kBoolValueKey, false);
    expect(tNativeLocalConfig.getBool(kBoolValueKey), false);

    await tNativeLocalConfig.reset(kBoolValueKey);
    expect(tNativeLocalConfig.getBool(kBoolValueKey), true);
  });

  test('check double value', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    expect(tNativeLocalConfig.getDouble(kDoubleValueKey),
        Config.defaultValueForDouble);

    await tNativeLocalConfig.setDefaults({kDoubleValueKey: 1.0});
    expect(tNativeLocalConfig.getDouble(kDoubleValueKey), 1.0);

    await tNativeLocalConfig.setDouble(kDoubleValueKey, 2.0);
    expect(tNativeLocalConfig.getDouble(kDoubleValueKey), 2.0);

    await tNativeLocalConfig.reset(kDoubleValueKey);
    expect(tNativeLocalConfig.getDouble(kDoubleValueKey), 1.0);
  });

  test('check int value', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    expect(tNativeLocalConfig.getInt(kIntValueKey), Config.defaultValueForInt);

    await tNativeLocalConfig.setDefaults({kIntValueKey: 1});
    expect(tNativeLocalConfig.getInt(kIntValueKey), 1);

    await tNativeLocalConfig.setInt(kIntValueKey, 2);
    expect(tNativeLocalConfig.getInt(kIntValueKey), 2);

    await tNativeLocalConfig.reset(kIntValueKey);
    expect(tNativeLocalConfig.getInt(kIntValueKey), 1);
  });

  test('check String value', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    expect(tNativeLocalConfig.getString(kStringValueKey),
        Config.defaultValueForString);

    await tNativeLocalConfig.setDefaults({kStringValueKey: '1'});
    expect(tNativeLocalConfig.getString(kStringValueKey), '1');

    await tNativeLocalConfig.setString(kStringValueKey, '2');
    expect(tNativeLocalConfig.getString(kStringValueKey), '2');

    await tNativeLocalConfig.reset(kStringValueKey);
    expect(tNativeLocalConfig.getString(kStringValueKey), '1');
  });

  test('resetAll', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    await tNativeLocalConfig.setBool(kBoolValueKey, false);
    await tNativeLocalConfig.setDouble(kDoubleValueKey, 2.0);
    await tNativeLocalConfig.setInt(kIntValueKey, 2);
    await tNativeLocalConfig.setString(kStringValueKey, '2');

    expect(tNativeLocalConfig.getBool(kBoolValueKey), false);
    expect(tNativeLocalConfig.getDouble(kDoubleValueKey), 2.0);
    expect(tNativeLocalConfig.getInt(kIntValueKey), 2);
    expect(tNativeLocalConfig.getString(kStringValueKey), '2');

    await tNativeLocalConfig.resetAll();

    expect(
        tNativeLocalConfig.getBool(kBoolValueKey), Config.defaultValueForBool);
    expect(tNativeLocalConfig.getDouble(kDoubleValueKey),
        Config.defaultValueForDouble);
    expect(tNativeLocalConfig.getInt(kIntValueKey), Config.defaultValueForInt);
    expect(tNativeLocalConfig.getString(kStringValueKey),
        Config.defaultValueForString);
  });

  test('resetMany', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    const kIsSetKey1 = 'isSet1';
    const kIsSetKey2 = 'isSet2';
    const kIsNotSetKey1 = 'isNotSet1';
    const kIsNotSetKey2 = 'isNotSet2';

    await tNativeLocalConfig.setDefaults({
      kIsSetKey1: 1,
      kIsSetKey2: 1,
    });

    await tNativeLocalConfig.setInt(kIsSetKey1, 2);
    await tNativeLocalConfig.setInt(kIsNotSetKey1, 2);

    await tNativeLocalConfig.resetMany([
      kIsSetKey1,
      kIsSetKey2,
      kIsNotSetKey1,
      kIsNotSetKey2,
    ]);

    expect(tNativeLocalConfig.getInt(kIsSetKey1), 1);
    expect(tNativeLocalConfig.getInt(kIsSetKey2), 1);
    expect(tNativeLocalConfig.getInt(kIsNotSetKey1), Config.defaultValueForInt);
    expect(tNativeLocalConfig.getInt(kIsNotSetKey2), Config.defaultValueForInt);
  });

  test('setMany', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    final Map<String, Object> tObjects = {
      'name': 'GREE, Inc.',
    };

    await tNativeLocalConfig.setMany(tObjects);

    expect(tNativeLocalConfig.getString('name'), 'GREE, Inc.');
  });

  test('sendError', () async {
    NativeLocalConfig tNativeLocalConfig = NativeLocalConfig();
    await tNativeLocalConfig.init();

    tNativeLocalConfig.sendError();
  });
}
