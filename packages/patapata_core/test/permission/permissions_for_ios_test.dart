// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import '../utils/patapata_core_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

  test('trackingRequested for iOS', () async {
    late App app;

    app = createApp();
    app.permissions.testSetRequested(
      trackingRequested: true,
    );

    expect(
      app.permissions.trackingRequested,
      true,
    );

    app.permissions.testSetRequested(trackingRequested: false);

    expect(
      app.permissions.trackingRequested,
      false,
    );

    app.dispose();
  });

  test('notificationsRequested for iOS', () async {
    late App app;

    app = createApp();
    app.permissions.testSetRequested(
      notificationsRequested: true,
    );

    expect(
      app.permissions.notificationsRequested,
      true,
    );

    app.permissions.testSetRequested(notificationsRequested: false);

    expect(
      app.permissions.notificationsRequested,
      false,
    );

    app.dispose();
  });

  test('requestTracking for iOS (notSupported)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetPermissionTrackingResult(
      PermissionTrackingResult.notSupported,
    );

    final tResult = await app.permissions.requestTracking();

    expect(tResult, PermissionTrackingResult.notSupported);

    app.dispose();
  });

  test('requestTracking for iOS (authorized)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetPermissionTrackingResult(
      PermissionTrackingResult.authorized,
    );

    final tResult = await app.permissions.requestTracking();

    expect(tResult, PermissionTrackingResult.authorized);

    app.dispose();
  });

  test('requestTracking for iOS (denied)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetPermissionTrackingResult(
      PermissionTrackingResult.denied,
    );

    final tResult = await app.permissions.requestTracking();

    expect(tResult, PermissionTrackingResult.denied);

    app.dispose();
  });

  test('requestTracking for iOS (notDetermined)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetPermissionTrackingResult(
      PermissionTrackingResult.notDetermined,
    );

    final tResult = await app.permissions.requestTracking();

    expect(tResult, PermissionTrackingResult.notDetermined);

    app.dispose();
  });

  test('requestTracking for iOS (restricted)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetPermissionTrackingResult(
      PermissionTrackingResult.restricted,
    );

    final tResult = await app.permissions.requestTracking();

    expect(tResult, PermissionTrackingResult.restricted);

    app.dispose();
  });

  test('trackingStream for iOS', () async {
    late App app;

    app = createApp();

    final tFuture = expectLater(
      app.permissions.trackingStream.asyncMap((event) => event),
      emitsInOrder(PermissionTrackingResult.values),
    );

    for (PermissionTrackingResult tResult in PermissionTrackingResult.values) {
      app.permissions.testSetPermissionTrackingResult(
        tResult,
      );

      await app.permissions.requestTracking();
    }

    await tFuture;

    app.dispose();
  });

  test('requestNotifications for iOS (true)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetLocalNotificationsPermission(true);
    final tResult = await app.permissions.requestNotifications();

    expect(tResult, PermissionNotificationResult.authorized);

    app.dispose();
  });

  test('requestNotifications for iOS (false)', () async {
    late App app;

    app = createApp();

    app.permissions.testSetLocalNotificationsPermission(false);
    final tResult = await app.permissions.requestNotifications();

    expect(tResult, PermissionNotificationResult.denied);

    app.dispose();
  });

  test('notificationsStream for iOS', () async {
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
