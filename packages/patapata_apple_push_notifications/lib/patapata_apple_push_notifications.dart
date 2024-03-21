// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_apple_push_notifications;

import 'package:flutter/services.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';

final _logger = Logger('patapata.ApplePushNotificationsPlugin');
const _channel =
    MethodChannel('dev.patapata.patapata_apple_push_notifications');

/// A plugin that provides Apple push notification functionality to Patapata.
class ApplePushNotificationsPlugin extends Plugin {
  final _messagesController = StreamController<RemoteMessage>.broadcast();
  final _tokensController = StreamController<String?>.broadcast();

  @override
  String get name => 'dev.patapata.patapata_apple_push_notifications';

  /// Initializes the [ApplePushNotificationsPlugin].
  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    _channel.setMethodCallHandler(_handleMethodCall);

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    await super.dispose();
  }

  @override
  RemoteMessaging createRemoteMessaging() =>
      ApplePushNotificationsRemoteMessaging(this);

  RemoteMessage _createRemoteMessage(Map<String, dynamic> response) {
    final tNotification = Map.castFrom<dynamic, dynamic, String, dynamic>(
        response['notification'] as Map);
    final tRequest = Map.castFrom<dynamic, dynamic, String, dynamic>(
        tNotification['request'] as Map);
    final tContent = Map.castFrom<dynamic, dynamic, String, dynamic>(
        tRequest['content'] as Map);

    return RemoteMessage(
      messageId: tRequest['identifier'],
      data: Map.castFrom<dynamic, dynamic, String, dynamic>(
          tContent['userInfo'] as Map),
      notification: (tContent['title'] as String?)?.isNotEmpty == true ||
              (tContent['body'] as String?)?.isNotEmpty == true
          ? RemoteMessageNotification(
              title: tContent['title'] as String?,
              body: tContent['body'] as String?,
            )
          : null,
    );
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'updateAPNsToken':
        final tToken = call.arguments as String?;
        _logger.info('updateAPNsToken:$tToken');
        _tokensController.add(tToken);
        break;
      case 'didReceiveRemoteNotification':
        final tUserInfo = Map.castFrom<dynamic, dynamic, String, dynamic>(
            call.arguments as Map);
        _logger.info('didReceiveRemoteNotification:$tUserInfo');
        // _messagesController.add(RemoteMessage(
        //   messageId: '',
        //   data: tUserInfo,
        //   notification: RemoteMessageNotification(),
        // ));
        break;
      case 'didReceiveNotificationResponse':
        final tResponse = Map.castFrom<dynamic, dynamic, String, dynamic>(
            call.arguments as Map);
        _logger.info('didReceiveNotificationResponse:$tResponse');

        _messagesController.add(_createRemoteMessage(tResponse));
        break;
      default:
        break;
    }
  }

  /// A [Stream] that can be listened to for monitoring changes to [RemoteMessage].
  Stream<RemoteMessage> get messages => _messagesController.stream;

  /// A [Stream] that can be used to monitor changes to the token.
  Stream<String?> get tokenStream => _tokensController.stream;

  /// Returns a Future for the initial Apple notification RemoteMessage.
  Future<RemoteMessage?> getInitialNotification() async {
    final tNotificationResponse = await _channel
        .invokeMapMethod<String, dynamic>('getInitialNotification');

    return tNotificationResponse != null
        ? _createRemoteMessage(tNotificationResponse)
        : null;
  }

  /// Returns a Future for the token required for the application to use RemoteMessage.
  Future<String?> getToken() {
    return _channel.invokeMethod<String>('getToken');
  }
}

/// A class for monitoring remote messages of Apple push notifications.
class ApplePushNotificationsRemoteMessaging extends RemoteMessaging {
  final ApplePushNotificationsPlugin _instance;

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String?>? _onTokensSubscription;

  final _messagesController = StreamController<RemoteMessage>.broadcast();
  final _tokensController = StreamController<String?>.broadcast();

  /// Creates a [ApplePushNotificationsRemoteMessaging].
  ApplePushNotificationsRemoteMessaging(this._instance);

  /// Initializes the [ApplePushNotificationsRemoteMessaging].
  @override
  Future<void> init(App app) async {
    await super.init(app);

    _onMessageSubscription = _instance.messages.listen(_onMessage);
    _onTokensSubscription = _instance.tokenStream.listen(_onToken);
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageSubscription = null;
    _onTokensSubscription?.cancel();
    _onTokensSubscription = null;
    super.dispose();
  }

  void _onMessage(RemoteMessage message) async {
    _logger.info(
        '_onMessage:{messageId:${message.messageId} channel:${message.channel}, data:${message.data}}');

    _messagesController.add(message);
  }

  void _onToken(String? token) {
    _logger.info('_onToken:$token');

    _tokensController.add(token);
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    return _instance.getInitialNotification();
  }

  @override
  Stream<RemoteMessage> get messages => _messagesController.stream;

  @override
  Stream<String?> get tokens => _tokensController.stream;

  @override
  Future<String?> getToken() async {
    return _instance.getToken();
  }

  @override
  // ignore: must_call_super
  FutureOr<bool> listenChannel(String channel) async {
    return false;
  }

  @override
  // ignore: must_call_super
  FutureOr<bool> ignoreChannel(String channel) async {
    return false;
  }
}
