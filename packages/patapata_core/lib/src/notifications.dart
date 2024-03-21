// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

import 'app.dart';
import 'plugin.dart';
import 'util.dart';
import 'exception.dart';
import 'widgets/standard_app.dart';

final _logger = Logger('patapata.Notifications');

const _methodChannelName = 'dexterous.com/flutter/local_notifications';
const _methodChannel = MethodChannel(_methodChannelName);

/// This is a Mixin for adding variables related to notification settings
/// to the Environment.
///
/// When initializing [FlutterLocalNotificationsPlugin] with [NotificationsPlugin.init]
/// you can override some settings with the Environment.
mixin NotificationsEnvironment {
  String get notificationsAndroidDefaultIcon;
  bool get notificationsDarwinDefaultPresentAlert;
  bool get notificationsDarwinDefaultPresentSound;
  bool get notificationsDarwinDefaultPresentBadge;
  bool get notificationsDarwinDefaultPresentBanner;
  bool get notificationsDarwinDefaultPresentList;
  List<AndroidNotificationChannel> get notificationsAndroidChannels;
  String get notificationsPayloadLocationKey => 'location';
}

/// This is a plugin for performing local notifications.
///
/// It includes the following features:
/// 1. Ability to initialize FlutterLocalNotificationsPlugin
///    separately for each operating system.
/// 2. Ability to reference the DeepLink included in the notification payload
///    and navigate to any desired screen.
class NotificationsPlugin extends Plugin with StandardAppRoutePluginMixin {
  static const AndroidNotificationChannel kDefaultAndroidChannel =
      AndroidNotificationChannel(
    'default',
    'Primary Channel',
    importance: Importance.max,
    enableLights: true,
  );

  // coverage:ignore-start
  static void initializeNotificationsForBackgroundIsolate() {
    try {
      final tPlugin = FlutterLocalNotificationsPlugin();
      tPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            requestCriticalPermission: false,
            defaultPresentAlert: true,
            defaultPresentSound: true,
            defaultPresentBadge: true,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            requestCriticalPermission: false,
            defaultPresentAlert: true,
            defaultPresentSound: true,
            defaultPresentBadge: true,
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to initialize isolate FlutterLocalNotificationsPlugin.',
        NotificationsInitializationException(original: e),
        stackTrace,
      );
    }
  }
  // coverage:ignore-end

  @override
  FutureOr<bool> init(App app) async {
    if (!await super.init(app)) {
      return false;
    }

    final tEnvironment = app.environment is NotificationsEnvironment
        ? app.environment as NotificationsEnvironment
        : null;

    try {
      final tPlugin = FlutterLocalNotificationsPlugin();
      tPlugin.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings(
              tEnvironment?.notificationsAndroidDefaultIcon ??
                  '@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            requestCriticalPermission: false,
            requestProvisionalPermission: false,
            defaultPresentAlert:
                tEnvironment?.notificationsDarwinDefaultPresentAlert ?? true,
            defaultPresentSound:
                tEnvironment?.notificationsDarwinDefaultPresentSound ?? true,
            defaultPresentBadge:
                tEnvironment?.notificationsDarwinDefaultPresentBadge ?? true,
            defaultPresentBanner:
                tEnvironment?.notificationsDarwinDefaultPresentBanner ?? true,
            defaultPresentList:
                tEnvironment?.notificationsDarwinDefaultPresentList ?? true,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            requestCriticalPermission: false,
            requestProvisionalPermission: false,
            defaultPresentAlert:
                tEnvironment?.notificationsDarwinDefaultPresentAlert ?? true,
            defaultPresentSound:
                tEnvironment?.notificationsDarwinDefaultPresentSound ?? true,
            defaultPresentBadge:
                tEnvironment?.notificationsDarwinDefaultPresentBadge ?? true,
            defaultPresentBanner:
                tEnvironment?.notificationsDarwinDefaultPresentBanner ?? true,
            defaultPresentList:
                tEnvironment?.notificationsDarwinDefaultPresentList ?? true,
          ),
        ),
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final tPlatform = tPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!;

        if (tEnvironment != null) {
          for (var i in tEnvironment.notificationsAndroidChannels) {
            await tPlatform.createNotificationChannel(i);
          }
        } else {
          await tPlatform.createNotificationChannel(kDefaultAndroidChannel);
        }
      }
    } catch (e, stackTrace) {
      // coverage:ignore-start
      _logger.warning(
        'Failed to initialize FlutterLocalNotificationsPlugin.',
        NotificationsInitializationException(original: e),
        stackTrace,
      );
      // coverage:ignore-end
    }

    return true;
  }

  @override
  FutureOr<void> dispose() {
    _streamController.close();

    return super.dispose();
  }

  final _streamController = StreamController<NotificationResponse>.broadcast();
  Stream<NotificationResponse> get notifications => _streamController.stream;

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.info('received notification: $response');
    _streamController.add(response);
  }

  String get payloadLocationKey => app.environment is NotificationsEnvironment
      ? (app.environment as NotificationsEnvironment)
          .notificationsPayloadLocationKey
      : 'location';

  Uri? uriFromPayload(String? payload) {
    if (payload?.isNotEmpty != true) {
      return null;
    }

    try {
      final tAsUrl = Uri.tryParse(payload!);

      if (tAsUrl != null) {
        return tAsUrl;
      }

      final tJsonData = jsonDecode(payload) as Map<String, dynamic>;

      if (tJsonData.containsKey(payloadLocationKey)) {
        return Uri.parse(tJsonData[payloadLocationKey] as String);
      }
    } catch (e) {
      // ignore
    }

    return null;
  }

  @override
  Future<StandardRouteData?> getInitialRouteData() async {
    final tLaunchNotification = await FlutterLocalNotificationsPlugin()
        .getNotificationAppLaunchDetails();

    if (tLaunchNotification?.notificationResponse != null) {
      if (tLaunchNotification!.didNotificationLaunchApp) {
        final tPayload =
            uriFromPayload(tLaunchNotification.notificationResponse!.payload);

        if (tPayload != null) {
          final tRouteData = await app
              .getPlugin<StandardAppPlugin>()
              ?.parser
              ?.parseRouteInformation(RouteInformation(uri: tPayload));

          if (tRouteData?.factory != null) {
            return tRouteData;
          }
        }
      }
    }

    return null;
  }

  /// This is a function to enable screen navigation via Deep Link
  /// included in the notification payload.
  ///
  /// To enable this functionality, you need to call this function
  /// after creating the [App] instance.
  /// For example:
  /// ```dart
  /// void main() async {
  ///   final App tApp = App(
  ///     environment: ...,
  ///     createAppWidget: ...,
  ///  );
  ///
  ///   tApp.getPlugin<NotificationsPlugin>()?.enableStandardAppIntegration();
  ///
  ///   tApp.run();
  /// }
  /// ```
  void enableStandardAppIntegration() {
    notifications.listen((event) {
      if (event.payload?.isNotEmpty == true) {
        app.getPlugin<StandardAppPlugin>()?.route(event.payload!);
      }
    });
  }

  @visibleForTesting
  void mockRecieveNotificationResponse(NotificationResponse response) {
    _onDidReceiveNotificationResponse(response);
  }

  @override
  @visibleForTesting
  void setMockMethodCallHandler() {
    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockMethodCallHandler(
      _methodChannel,
      (methodCall) async {
        methodCallLogs.add(methodCall);
        switch (methodCall.method) {
          case 'initialize':
            return true;
          case 'getNotificationAppLaunchDetails':
            return notificationAppLaunchDetailsMap;
        }
        return null;
      },
    );
  }
}

@visibleForTesting
Map<String, dynamic>? notificationAppLaunchDetailsMap;

/// Throw when exception if an error occurs in initializing [NotificationsPlugin].
class NotificationsInitializationException extends PatapataCoreException {
  const NotificationsInitializationException({
    super.original,
  }) : super(code: PatapataCoreExceptionCode.PPE501);
}
