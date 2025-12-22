// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:patapata_core/src/method_channel_test_mixin.dart';
import 'package:patapata_core/src/util.dart';

import 'app.dart';

const _methodChannel = MethodChannel('dev.patapata.patapata_core');

final _logger = Logger('patapata.Permissions');

/// Result of [Permissions.requestTracking].
enum PermissionTrackingResult {
  notSupported,
  authorized,
  denied,
  notDetermined,
  restricted,
}

/// Result of [Permissions.requestNotifications].
enum PermissionNotificationResult { authorized, denied, notDetermined }

const _kLocalConfigTrackingRequested = 'patapata.Permissions:trackingRequested';
const _kLocalConfigNotificationsRequested =
    'patapata.Permissions:notificationsRequested';

/// Requests permissions from the platform (Android, iOS).
///
/// This class is automatically created at application initialization
/// and can be accessed from [App.permissions].
class Permissions with MethodChannelTestMixin {
  /// The [App] passed in the constructor.
  final App app;

  Permissions({required this.app});

  final _trackingStreamController =
      StreamController<PermissionTrackingResult>.broadcast();
  final _notificationsStreamController =
      StreamController<PermissionNotificationResult>.broadcast();

  /// Returns a Stream to observe the results of [requestTracking].
  Stream<PermissionTrackingResult> get trackingStream =>
      _trackingStreamController.stream;

  /// Returns a Stream to observe the results of [requestNotifications].
  Stream<PermissionNotificationResult> get notificationsStream =>
      _notificationsStreamController.stream;

  /// If true, tracking permissions have already been requested.
  bool get trackingRequested => defaultTargetPlatform != TargetPlatform.iOS
      ? true
      : app.localConfig.getBool(_kLocalConfigTrackingRequested);

  /// If true, notification permissions have already been requested.
  bool get notificationsRequested =>
      app.localConfig.getBool(_kLocalConfigNotificationsRequested);

  // The values ​​of Permissions:requestTracking reflected during testing
  PermissionTrackingResult? _mockPermissionTrackingResult;

  // The values ​​of requestPermission and requestPermissions reflected during testing
  bool? _mockLocalNotificationsPermission;

  /// Releases each resource.
  void dispose() {
    _trackingStreamController.close();
    _notificationsStreamController.close();
  }

  @override
  @visibleForTesting
  void setMockMethodCallHandler() {
    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockMethodCallHandler(_methodChannel, (methodCall) async {
      switch (methodCall.method) {
        case 'Permissions:requestTracking':
          return _mockPermissionTrackingResult?.name;
      }
      return null;
    });

    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (methodCall) async {
        switch (methodCall.method) {
          case 'requestNotificationsPermission':
            return _mockLocalNotificationsPermission;
          case 'requestPermissions':
            return _mockLocalNotificationsPermission;
        }
        return null;
      },
    );
  }

  /// Mocks [trackingRequested] and [notificationsRequested] for testing purposes.
  @visibleForTesting
  void testSetRequested({
    bool? trackingRequested,
    bool? notificationsRequested,
  }) {
    app.localConfig.setBool(
      _kLocalConfigTrackingRequested,
      trackingRequested ?? this.trackingRequested,
    );

    app.localConfig.setBool(
      _kLocalConfigNotificationsRequested,
      notificationsRequested ?? this.notificationsRequested,
    );
  }

  // Mocks return values ​​of Permissions:requestTracking for testing purposes.
  @visibleForTesting
  void testSetPermissionTrackingResult(PermissionTrackingResult? result) {
    _mockPermissionTrackingResult = result;
  }

  // Mocks return values ​​of requestPermission and requestPermissions for testing purposes.
  @visibleForTesting
  void testSetLocalNotificationsPermission(bool? result) {
    _mockLocalNotificationsPermission = result;
  }

  /// Requests tracking permissions.
  ///
  /// For iOS, please add `NSUserTrackingUsageDescription`
  /// to the application's `Info.plist`.
  Future<PermissionTrackingResult> requestTracking() async {
    _logger.info('requestTracking');

    PermissionTrackingResult tTrackingResult =
        PermissionTrackingResult.notSupported;

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return tTrackingResult;
    }

    await app.localConfig.setBool(_kLocalConfigTrackingRequested, true);

    try {
      final tResult = await _methodChannel.invokeMethod<String?>(
        'Permissions:requestTracking',
      );

      if (tResult == null) {
        tTrackingResult = PermissionTrackingResult.notSupported;
      } else {
        tTrackingResult = PermissionTrackingResult.values.firstWhere(
          (element) => element.name == tResult,
        );
      }
      // coverage:ignore-start
    } catch (e, stackTrace) {
      _logger.warning('requestTracking failed', e, stackTrace);
    }
    // coverage:ignore-end

    _trackingStreamController.add(tTrackingResult);

    return tTrackingResult;
  }

  /// Requests notification permissions.
  Future<PermissionNotificationResult> requestNotifications({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool critical = false,
  }) async {
    _logger.info('requestNotifications');
    PermissionNotificationResult tNotificationResult =
        PermissionNotificationResult.notDetermined;

    await app.localConfig.setBool(_kLocalConfigNotificationsRequested, true);

    try {
      if (kIsWeb) {
        return tNotificationResult;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final tPlatform = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()!;
        tNotificationResult =
            (await tPlatform.requestNotificationsPermission() ?? true)
            ? PermissionNotificationResult.authorized
            : PermissionNotificationResult.denied;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final tPlatform = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()!;
        tNotificationResult =
            (await tPlatform.requestPermissions(
                  sound: sound,
                  alert: alert,
                  badge: badge,
                  critical: critical,
                ) ??
                false)
            ? PermissionNotificationResult.authorized
            : PermissionNotificationResult.denied;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final tPlatform = FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()!;
        tNotificationResult =
            (await tPlatform.requestPermissions(
                  sound: sound,
                  alert: alert,
                  badge: badge,
                  critical: critical,
                ) ??
                false)
            ? PermissionNotificationResult.authorized
            : PermissionNotificationResult.denied;
      }
      // coverage:ignore-start
    } catch (e, stackTrace) {
      _logger.warning('requestNotifications failed', e, stackTrace);
    }
    // coverage:ignore-end

    _notificationsStreamController.add(tNotificationResult);

    return tNotificationResult;
  }
}
