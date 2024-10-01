// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

void main() {
  const kDefaultBoolKey = 'kDefaultBoolKey';
  const kDefaultDoubleKey = 'kDefaultDoubleKey';
  const kDefaultIntKey = 'kDefaultIntKey';
  const kDefaultStringKey = 'kDefaultStringKey';

  const kBoolValueKey = 'kBoolValueKey';
  const kDoubleValueKey = 'kDoubleValueKey';
  const kIntValueKey = 'kIntValueKey';
  const kStringValueKey = 'kStringValueKey';

  late App app;
  late MockRemoteConfig mockRemoteConfig;
  setUp(() {
    mockRemoteConfig = MockRemoteConfig({});
    mockRemoteConfig.testSetMockFetchValues({});

    final tPlugin = Plugin.inline(
      name: 'test',
      requireRemoteConfig: true,
      createRemoteConfig: () => mockRemoteConfig,
    );

    app = createApp(
      plugins: [
        tPlugin,
      ],
    );
  });

  tearDown(() {
    app.dispose();
  });

  Future<void> runApp() async {
    app.run();
    await App.appStageChangeStream.firstWhere(
      (element) {
        return element.stage == AppStage.running;
      },
    );
  }

  // test('Function hasKey.', () async {
  testWidgets('Function hasKey.', (WidgetTester tester) async {
    await runApp();

    expect(
      app.remoteConfig.hasKey(kBoolValueKey),
      false,
    );

    mockRemoteConfig.testSetMockFetchValues({
      kBoolValueKey: true,
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(
      app.remoteConfig.hasKey(kBoolValueKey),
      true,
    );
  });

  testWidgets('Function setDefaults.', (WidgetTester tester) async {
    await runApp();

    expect(app.remoteConfig.getBool(kDefaultBoolKey), false);
    expect(app.remoteConfig.getDouble(kDefaultDoubleKey), 0.0);
    expect(app.remoteConfig.getInt(kDefaultIntKey), 0);
    expect(app.remoteConfig.getString(kDefaultStringKey), '');

    await app.remoteConfig.setDefaults({
      kDefaultBoolKey: true,
      kDefaultDoubleKey: 1.0,
      kDefaultIntKey: 1,
      kDefaultStringKey: '1',
    });

    expect(mockRemoteConfig.getBool(kDefaultBoolKey), true);
    expect(mockRemoteConfig.getDouble(kDefaultDoubleKey), 1.0);
    expect(mockRemoteConfig.getInt(kDefaultIntKey), 1);
    expect(mockRemoteConfig.getString(kDefaultStringKey), '1');
  });

  testWidgets('Function reset.', (WidgetTester tester) async {
    await runApp();
    mockRemoteConfig.testSetMockFetchValues({
      kBoolValueKey: true,
      kDoubleValueKey: 1.0,
      kIntValueKey: 1,
      kStringValueKey: '1',
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kBoolValueKey), true);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), true);
    expect(app.remoteConfig.hasKey(kIntValueKey), true);
    expect(app.remoteConfig.hasKey(kStringValueKey), true);

    await mockRemoteConfig.reset(kBoolValueKey);
    await mockRemoteConfig.reset(kDoubleValueKey);
    await mockRemoteConfig.reset(kIntValueKey);
    await mockRemoteConfig.reset(kStringValueKey);

    expect(app.remoteConfig.hasKey(kBoolValueKey), false);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), false);
    expect(app.remoteConfig.hasKey(kIntValueKey), false);
    expect(app.remoteConfig.hasKey(kStringValueKey), false);
  });

  testWidgets('Function resetAll.', (WidgetTester tester) async {
    await runApp();
    mockRemoteConfig.testSetMockFetchValues({
      kBoolValueKey: true,
      kDoubleValueKey: 1.0,
      kIntValueKey: 1,
      kStringValueKey: '1',
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kBoolValueKey), true);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), true);
    expect(app.remoteConfig.hasKey(kIntValueKey), true);
    expect(app.remoteConfig.hasKey(kStringValueKey), true);

    await mockRemoteConfig.resetAll();

    expect(app.remoteConfig.hasKey(kBoolValueKey), false);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), false);
    expect(app.remoteConfig.hasKey(kIntValueKey), false);
    expect(app.remoteConfig.hasKey(kStringValueKey), false);
  });

  testWidgets('Function resetMany.', (WidgetTester tester) async {
    await runApp();
    mockRemoteConfig.testSetMockFetchValues({
      kBoolValueKey: true,
      kDoubleValueKey: 1.0,
      kIntValueKey: 1,
      kStringValueKey: '1',
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kBoolValueKey), true);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), true);
    expect(app.remoteConfig.hasKey(kIntValueKey), true);
    expect(app.remoteConfig.hasKey(kStringValueKey), true);

    await mockRemoteConfig.resetMany([
      kBoolValueKey,
      kDoubleValueKey,
      kIntValueKey,
      kStringValueKey,
    ]);

    expect(app.remoteConfig.hasKey(kBoolValueKey), false);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), false);
    expect(app.remoteConfig.hasKey(kIntValueKey), false);
    expect(app.remoteConfig.hasKey(kStringValueKey), false);
  });

  testWidgets('Function dispose.', (WidgetTester tester) async {
    await runApp();

    expect(app.remoteConfig.disposed, isFalse);

    app.remoteConfig.dispose();
    expect(app.remoteConfig.disposed, isTrue);
  });

  testWidgets('Check bool value.', (WidgetTester tester) async {
    await runApp();

    await app.remoteConfig.setDefaults({
      kDefaultBoolKey: true,
    });
    expect(app.remoteConfig.getBool(kDefaultBoolKey), true);

    expect(app.remoteConfig.hasKey(kBoolValueKey), isFalse);
    expect(
      app.remoteConfig.getBool(kBoolValueKey),
      Config.defaultValueForBool,
    );

    mockRemoteConfig.testSetMockFetchValues({
      kBoolValueKey: true,
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kBoolValueKey), isTrue);
    expect(app.remoteConfig.getBool(kBoolValueKey), true);

    mockRemoteConfig.setBool(kBoolValueKey, false);
    expect(app.remoteConfig.getBool(kBoolValueKey), false);
  });

  testWidgets('Check double value.', (WidgetTester tester) async {
    await runApp();

    await app.remoteConfig.setDefaults({
      kDefaultDoubleKey: 1.0,
    });
    expect(app.remoteConfig.getDouble(kDefaultDoubleKey), 1.0);

    expect(app.remoteConfig.hasKey(kDoubleValueKey), isFalse);
    expect(
      app.remoteConfig.getDouble(kDoubleValueKey),
      Config.defaultValueForDouble,
    );

    mockRemoteConfig.testSetMockFetchValues({
      kDoubleValueKey: 1.0,
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kDoubleValueKey), isTrue);
    expect(app.remoteConfig.getDouble(kDoubleValueKey), 1.0);

    mockRemoteConfig.setDouble(kDoubleValueKey, 2.0);
    expect(app.remoteConfig.getDouble(kDoubleValueKey), 2.0);
  });
  testWidgets('Check int value.', (WidgetTester tester) async {
    await runApp();

    await app.remoteConfig.setDefaults({
      kDefaultIntKey: 1,
    });
    expect(app.remoteConfig.getInt(kDefaultIntKey), 1);

    expect(app.remoteConfig.hasKey(kIntValueKey), isFalse);
    expect(
      app.remoteConfig.getInt(kIntValueKey),
      Config.defaultValueForInt,
    );

    mockRemoteConfig.testSetMockFetchValues({
      kIntValueKey: 1,
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kIntValueKey), isTrue);
    expect(app.remoteConfig.getInt(kIntValueKey), 1);

    mockRemoteConfig.setInt(kIntValueKey, 2);
    expect(app.remoteConfig.getInt(kIntValueKey), 2);
  });

  testWidgets('Check String value.', (WidgetTester tester) async {
    await runApp();

    await app.remoteConfig.setDefaults({
      kDefaultStringKey: '1',
    });
    expect(app.remoteConfig.getString(kDefaultStringKey), '1');

    expect(app.remoteConfig.hasKey(kStringValueKey), isFalse);
    expect(
      app.remoteConfig.getString(kStringValueKey),
      Config.defaultValueForString,
    );

    mockRemoteConfig.testSetMockFetchValues({
      kStringValueKey: '1',
    });

    await app.remoteConfig.fetch(
      force: true,
    );

    expect(app.remoteConfig.hasKey(kStringValueKey), isTrue);
    expect(app.remoteConfig.getString(kStringValueKey), '1');

    mockRemoteConfig.setString(kStringValueKey, '2');
    expect(app.remoteConfig.getString(kStringValueKey), '2');
  });

  testWidgets('Check many value.', (WidgetTester tester) async {
    await runApp();

    expect(app.remoteConfig.hasKey(kBoolValueKey), false);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), false);
    expect(app.remoteConfig.hasKey(kIntValueKey), false);
    expect(app.remoteConfig.hasKey(kStringValueKey), false);

    await mockRemoteConfig.setMany({
      kBoolValueKey: true,
      kDoubleValueKey: 1.0,
      kIntValueKey: 1,
      kStringValueKey: '1',
    });

    expect(app.remoteConfig.hasKey(kBoolValueKey), true);
    expect(app.remoteConfig.hasKey(kDoubleValueKey), true);
    expect(app.remoteConfig.hasKey(kIntValueKey), true);
    expect(app.remoteConfig.hasKey(kStringValueKey), true);

    expect(app.remoteConfig.getBool(kBoolValueKey), true);
    expect(app.remoteConfig.getDouble(kDoubleValueKey), 1.0);
    expect(app.remoteConfig.getInt(kIntValueKey), 1);
    expect(app.remoteConfig.getString(kStringValueKey), '1');
  });
}
