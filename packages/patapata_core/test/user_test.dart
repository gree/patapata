// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

class TestPluginA extends Plugin {}

class TestPluginB extends Plugin {}

class FetchExceptionRemoteConfig extends RemoteConfig {
  @override
  Future<void> fetch({
    Duration expiration = const Duration(hours: 5),
    bool force = false,
  }) {
    throw UnimplementedError();
  }

  @override
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool}) {
    throw UnimplementedError();
  }

  @override
  double getDouble(
    String key, {
    double defaultValue = Config.defaultValueForDouble,
  }) {
    throw UnimplementedError();
  }

  @override
  int getInt(String key, {int defaultValue = Config.defaultValueForInt}) {
    throw UnimplementedError();
  }

  @override
  String getString(
    String key, {
    String defaultValue = Config.defaultValueForString,
  }) {
    throw UnimplementedError();
  }

  @override
  bool hasKey(String key) {
    return false;
  }

  @override
  Future<void> setDefaults(Map<String, Object> defaults) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changeId test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    const tUserId = 'userId';
    final tProperties = {'propertyKey': 'propertyValue'};
    final tData = {'dataKey': 'dataValue'};
    const tOverrideId = 'overrideId';
    final tOverrideIdMap = {TestPluginA: tOverrideId};
    final tOverrideMap = {
      'propertyKey': 'overrideValue',
      'pluginKey': 'pluginValue',
    };
    final tOverrideProperties = {TestPluginA: tOverrideMap};

    await tUser.changeId(
      tUserId,
      properties: tProperties,
      data: tData,
      overrideId: tOverrideIdMap,
      overrideProperties: tOverrideProperties,
    );

    expect(tUser.id, equals(tUserId));
    expect(tUser.properties, equals(tProperties));
    expect(await tUser.getData('dataKey'), equals('dataValue'));
    expect(
      tUser.getPropertiesFor<TestPluginA>(),
      equals(tUser.properties..addAll(tOverrideMap)),
    );
    expect(tUser.getIdFor<TestPluginA>(), equals(tOverrideId));
    expect(tUser.getPropertiesFor<TestPluginB>(), equals(tUser.properties));
    expect(tUser.getIdFor<TestPluginB>(), equals(tUserId));
    expect(tUser.variables.map((e) => e.unsafeValue), [
      tUserId,
      tProperties,
      tData,
    ]);

    const tUserId2 = 'userId2';
    await tUser.changeId(tUserId2);

    expect(tUser.id, equals(tUserId2));
    expect(tUser.properties, equals({'propertyKey': null}));
  });

  test('set test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    final tProperties = {'propertyKey': 'propertyValue'};
    final tData = {'dataKey': 'dataValue'};
    final tOverrideMap = {
      'propertyKey': 'overrideValue',
      'pluginKey': 'pluginValue',
    };
    final tOverrideProperties = {TestPluginA: tOverrideMap};

    await tUser.set(
      properties: tProperties,
      data: tData,
      overrideProperties: tOverrideProperties,
    );

    expect(tUser.properties, equals(tProperties));
    expect(await tUser.getData('dataKey'), equals('dataValue'));
    expect(
      tUser.getPropertiesFor<TestPluginA>(),
      equals(tUser.properties..addAll(tOverrideMap)),
    );
    expect(tUser.getPropertiesFor<TestPluginB>(), equals(tUser.properties));
  });

  test('setProperties test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    const tPropertyKey = 'propertyKey';
    const tPropertyValue = 'propertyValue';
    final tProperties = {tPropertyKey: tPropertyValue};
    final tOverrideMap = {
      tPropertyKey: 'overrideValue',
      'pluginKey': 'pluginValue',
    };
    final tOverrideProperties = {TestPluginA: tOverrideMap};

    await tUser.setProperties(
      tProperties,
      overrideProperties: tOverrideProperties,
    );
    expect(tUser.properties, equals(tProperties));
    expect(
      tUser.getPropertiesFor<TestPluginA>(),
      equals(tUser.properties..addAll(tOverrideMap)),
    );
    expect(tUser.getPropertiesFor<TestPluginB>(), equals(tUser.properties));
  });

  test('getPropertie defaultValue test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    const tPropertyKey = 'propertyKey';
    const tPropertyValue = 'propertyValue';
    final tProperties = {tPropertyKey: tPropertyValue};

    await tUser.setProperties(tProperties);
    expect(tUser.properties, equals(tProperties));
    expect(tUser.getProperty(tPropertyKey), tPropertyValue);
    expect(tUser.getProperty('aaa'), isNull);
    expect(tUser.getProperty('aaa', 'default'), 'default');
  });

  test('setData test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    const tKey = 'testKey';
    const tValue = 'testValue';
    await tUser.setData(tKey, tValue);

    expect(await tUser.getData(tKey), equals(tValue));
    expect(tUser.getDataSync(tKey), equals(tValue));
    expect(await tUser.getData('aaa'), isNull);
  });

  test('removeData test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    final tData = {'dataKey': 'dataValue', 'deleteDataKey': 'deleteDataValue'};

    await tUser.set(data: tData);
    expect(await tUser.getData('dataKey'), equals('dataValue'));
    expect(await tUser.getData('deleteDataKey'), equals('deleteDataValue'));

    await tUser.removeData('deleteDataKey');
    expect(await tUser.getData('dataKey'), equals('dataValue'));
    expect(await tUser.getData('deleteDataKey'), isNull);
  });

  test('removeAllData test.', () async {
    final tApp = createApp();
    final tUser = User(app: tApp);

    final tData = {'dataKey': 'dataValue', 'deleteDataKey': 'deleteDataValue'};

    await tUser.set(data: tData);
    expect(await tUser.getData('dataKey'), equals('dataValue'));
    expect(await tUser.getData('deleteDataKey'), equals('deleteDataValue'));

    await tUser.removeAllData();
    expect(await tUser.getData('dataKey'), isNull);
    expect(await tUser.getData('deleteDataKey'), isNull);
  });

  test(
    'addSynchronousChangeListener and removeSynchronousChangeListener test.',
    () async {
      final tApp = createApp();
      final tUser = User(app: tApp);

      const tUserId = 'userId';
      final Map<String, String?> tProperties = {'propertyKey': 'propertyValue'};
      final tData = {'dataKey': 'dataValue'};
      const tOverrideId = 'overrideId';
      final tOverrideIdMap = {TestPluginA: tOverrideId};
      final tOverrideMap = {
        'propertyKey': 'overrideValue',
        'pluginKey': 'pluginValue',
      };
      final tOverrideProperties = {TestPluginA: tOverrideMap};

      bool tCallbackCalled = false;
      fCallback(User user, UserChangeData data) {
        expect(data.id, equals(tUserId));
        expect(data.properties, equals(tProperties));
        expect(data.data, tData);
        expect(data.getPropertiesFor<TestPluginA>(), tOverrideMap);
        expect(data.getIdFor<TestPluginA>(), equals(tOverrideId));
        expect(data.getPropertiesFor<TestPluginB>(), tProperties);
        expect(data.getIdFor<TestPluginB>(), equals(tUserId));

        data.id = 'updateId';
        data.removeAllProperties();
        data.data.updateAll((key, value) => 'updateDataValue');

        tCallbackCalled = true;
      }

      tUser.addSynchronousChangeListener(fCallback);
      await tUser.changeId(
        tUserId,
        properties: tProperties,
        data: tData,
        overrideId: tOverrideIdMap,
        overrideProperties: tOverrideProperties,
      );
      expect(tCallbackCalled, isTrue);
      expect(tUser.id, equals('updateId'));
      expect(tUser.properties, equals({'propertyKey': null}));
      expect(await tUser.getData('dataKey'), equals('updateDataValue'));
      expect(
        tUser.getPropertiesFor<TestPluginA>(),
        equals({'propertyKey': 'overrideValue', 'pluginKey': 'pluginValue'}),
      );
      expect(tUser.getIdFor<TestPluginA>(), equals(tOverrideId));

      tCallbackCalled = false;
      tUser.removeSynchronousChangeListener(fCallback);
      await tUser.changeId(
        tUserId,
        properties: tProperties,
        data: tData,
        overrideId: tOverrideIdMap,
        overrideProperties: tOverrideProperties,
      );
      expect(tCallbackCalled, isFalse);
    },
  );

  test('equals test.', () async {
    final tApp = createApp();
    final tUser1 = User(app: tApp);
    final tUser2 = User(app: tApp);
    final tUser3 = User(app: tApp);

    const tUserId = 'userId';

    await tUser1.changeId(tUserId);
    await tUser2.changeId(tUserId);
    await tUser3.changeId('user3');

    expect(tUser1, equals(tUser2));
    expect(tUser1, isNot(tUser3));
    expect(tUser1.hashCode, equals(tUser2.hashCode));
    expect(tUser1.hashCode, isNot(tUser3.hashCode));
    expect({tUser1, tUser2, tUser3}.length, equals(2));

    // ignore: invalid_use_of_protected_member
    expect(tUser1.key, isNot(tUser2.key));
  });

  test('set saves the value even if RemoteConfig fetch fails.', () async {
    final tApp = createApp();
    await (tApp.remoteConfig as ProxyRemoteConfig).addRemoteConfig(
      FetchExceptionRemoteConfig(),
    );
    final tUser = User(app: tApp);

    final Map<String, String?> tProperties = {'propertyKey': 'propertyValue'};

    await tUser.set(properties: tProperties);

    expect(tUser.properties, equals(tProperties));
  });
}
