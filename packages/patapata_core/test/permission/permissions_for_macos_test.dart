// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import '../utils/patapata_core_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  MacOSFlutterLocalNotificationsPlugin.registerWith();

  test('trackingRequested for macOS', () async {
    late App app;

    app = createApp();

    expect(
      app.permissions.trackingRequested,
      true,
    );

    app.dispose();
  });

  test('notificationsRequested for macOS', () async {
    late App app;

    app = createApp();
    app.permissions.testSetRequested(notificationsRequested: true);

    expect(
      app.permissions.notificationsRequested,
      true,
    );

    app.permissions.testSetRequested(
      notificationsRequested: false,
    );

    expect(
      app.permissions.notificationsRequested,
      false,
    );

    app.dispose();
  });

  test('requestNotifications for macOS (true)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetLocalNotificationsPermission(true);
    final tResult = await app.permissions.requestNotifications();

    expect(tResult, PermissionNotificationResult.authorized);

    app.dispose();
  });

  test('requestNotifications for macOS (false)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetLocalNotificationsPermission(false);
    final tResult = await app.permissions.requestNotifications();

    expect(tResult, PermissionNotificationResult.denied);

    app.dispose();
  });

  test('notificationsStream for macOS', () async {
    late App app;

    app = createApp();

    final tStreamResultValues = [
      PermissionNotificationResult.authorized,
      PermissionNotificationResult.denied,
    ];

    final tFuture = expectLater(
      app.permissions.notificationsStream.asyncMap((event) => event),
      emitsInOrder(tStreamResultValues),
    );

    app.permissions.testSetLocalNotificationsPermission(true);
    await app.permissions.requestNotifications();

    app.permissions.testSetLocalNotificationsPermission(false);
    await app.permissions.requestNotifications();

    await tFuture;

    app.dispose();
  });
}
