// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_firebase_messaging;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:crypto/crypto.dart';

import 'package:firebase_messaging/firebase_messaging.dart' as firebase;
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_firebase_core/patapata_firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _logger = Logger('patapata.FirebaseMessagingPlugin');

const int _kLocalNotificationIdBase = kPataInHex;

/// Generate a random notification ID number to avoid conflicting with any other Intent on the system (hopefully)
/// This has to be less than a 32 bit signed int.
int _generateLocalNotificationId() {
  return _kLocalNotificationIdBase +
      Random().nextInt(_kLocalNotificationIdBase >> 8);
}

/// A plugin that provides Firebase Cloud Messaging functionality to Patapata.
/// This plugin requires adding the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) package to your application.
class FirebaseMessagingPlugin extends Plugin with StandardAppRoutePluginMixin {
  /// A reference to the [firebase.FirebaseMessaging] instance.
  late final firebase.FirebaseMessaging instance;

  final _selectedMessagesController =
      StreamController<RemoteMessage>.broadcast();

  @override
  List<Type> get dependencies => [
        FirebaseCorePlugin,
        NotificationsPlugin,
      ];

  /// Initializes the [FirebaseMessagingPlugin].
  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    instance = firebase.FirebaseMessaging.instance;

    if (!await instance.isSupported()) {
      _logger.info('Firebase Messaging not supported. Disabling.');

      return false;
    }

    firebase.FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    await super.dispose();

    // Can't disable a background message handler it seems.

    instance.setAutoInitEnabled(false);
  }

  @override
  RemoteMessaging createRemoteMessaging() =>
      FirebaseMessagingRemoteMessaging(this);

  /// Retrieve the Future of the first Firebase remote message.
  Future<RemoteMessage?> getInitialMessage() async {
    final tFirebaseInitialMessage = await instance.getInitialMessage();

    return tFirebaseInitialMessage != null
        ? FirebaseMessagingRemoteMessagingRemoteMessage.fromFirebase(
            tFirebaseInitialMessage)
        : null;
  }

  @override
  Future<StandardRouteData?> getInitialRouteData() async {
    try {
      final tRemoteMessage = await getInitialMessage();

      if (tRemoteMessage == null) {
        return null;
      }

      final tLocation = tRemoteMessage
              .data?[app.getPlugin<NotificationsPlugin>()?.payloadLocationKey]
          as String?;

      if (tLocation?.isNotEmpty == true) {
        final tParser = app.getPlugin<StandardAppPlugin>()?.parser;

        if (tParser == null) {
          return null;
        }

        final tLocationUri = Uri.parse(tLocation!);

        return tParser.parseRouteInformation(
          RouteInformation(
            uri: tLocationUri,
          ),
        );
      }
    } catch (e) {
      // ignore
    }

    return null;
  }

  Stream<RemoteMessage> get _selectedMessages =>
      _selectedMessagesController.stream;
}

/// The actual [RemoteMessage] that [FirebaseMessagingRemoteMessaging] uses to exchange messages with Firebase.
class FirebaseMessagingRemoteMessagingRemoteMessage extends RemoteMessage {
  /// A reference to the [firebase.RemoteMessage] instance.
  final firebase.RemoteMessage firebaseRemoteMessage;

  /// Creates a Firebase remote message for the provided argument [firebaseRemoteMessage].
  /// Optionally, provide [messageId] as a unique ID assigned to each message, [channel] for each message's channel,
  /// [data] as a Map for received data, and [notification] of [RemoteMessageNotification] with title and body information when receiving the notification.
  const FirebaseMessagingRemoteMessagingRemoteMessage({
    required this.firebaseRemoteMessage,
    String? messageId,
    String? channel,
    Map<String, dynamic>? data,
    RemoteMessageNotification? notification,
  }) : super(
          messageId: messageId,
          data: data,
          notification: notification,
        );

  /// A factory class that creates an instance of RemoteMessage from a Firebase remote message [message].
  factory FirebaseMessagingRemoteMessagingRemoteMessage.fromFirebase(
    firebase.RemoteMessage message,
  ) {
    final tNotification = message.notification;

    return FirebaseMessagingRemoteMessagingRemoteMessage(
      firebaseRemoteMessage: message,
      messageId: message.messageId,
      channel: message.from ?? RemoteMessage.kRemoteMessageDefaultChannel,
      data: message.data,
      notification: tNotification != null
          ? RemoteMessageNotification(
              title: tNotification.title,
              body: tNotification.body,
            )
          : null,
    );
  }
}

/// A class for monitoring the remote messages of [FirebaseMessagingRemoteMessagingRemoteMessage].
class FirebaseMessagingRemoteMessaging extends RemoteMessaging {
  final FirebaseMessagingPlugin _instance;

  StreamSubscription<firebase.RemoteMessage>? _onMessageSubscription;
  StreamSubscription<firebase.RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<RemoteMessage>? _onSelectMessageSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;

  final _messagesController = StreamController<RemoteMessage>.broadcast();
  final _tokensController = StreamController<String?>.broadcast();

  /// Constructor for [FirebaseMessagingRemoteMessaging].
  FirebaseMessagingRemoteMessaging(this._instance);

  /// Initializes the [FirebaseMessagingRemoteMessaging].
  @override
  Future<void> init(App app) async {
    await super.init(app);

    _onMessageSubscription =
        firebase.FirebaseMessaging.onMessage.listen(_onMessage);
    _onMessageOpenedAppSubscription = firebase
        .FirebaseMessaging.onMessageOpenedApp
        .listen(_onMessageOpenedApp);
    _onSelectMessageSubscription =
        _instance._selectedMessages.listen(_onSelectMessage);
    _onTokenRefreshSubscription =
        firebase.FirebaseMessaging.instance.onTokenRefresh.listen(_onToken);
  }

  @override
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription = null;
    _onSelectMessageSubscription?.cancel();
    _onSelectMessageSubscription = null;
    _onTokenRefreshSubscription?.cancel();
    _onTokenRefreshSubscription = null;
    super.dispose();
  }

  void _onSelectMessage(RemoteMessage message) {
    _messagesController.add(message);
  }

  void _onMessage(firebase.RemoteMessage message) async {
    _logger.info(
        '_onMessage:{messageId:${message.messageId} from:${message.from}, data:${message.data}}');

    await _showNotificationFromFirebaseRemoteMessage(message);
  }

  void _onMessageOpenedApp(firebase.RemoteMessage message) async {
    _logger.info(
        '_onMessageOpenedApp:{messageId:${message.messageId} from:${message.from}, data:${message.data}}');

    final tRemoteMessage =
        FirebaseMessagingRemoteMessagingRemoteMessage.fromFirebase(message);

    if (app.hasPlugin(StandardAppPlugin)) {
      try {
        final tLocation = tRemoteMessage
                .data?[app.getPlugin<NotificationsPlugin>()?.payloadLocationKey]
            as String?;

        if (tLocation?.isNotEmpty == true) {
          app.getPlugin<StandardAppPlugin>()!.route(tLocation!);
        }
      } catch (e) {
        // ignore
      }
    }

    _messagesController.add(tRemoteMessage);
  }

  void _onToken(String token) {
    _logger.info('_onToken:$token');

    _tokensController.add(token);
  }

  @override
  Future<RemoteMessage?> getInitialMessage() {
    return _instance.getInitialMessage();
  }

  @override
  Stream<RemoteMessage> get messages => _messagesController.stream;

  @override
  Stream<String?> get tokens => _tokensController.stream;

  @override
  Future<String?> getToken() async {
    try {
      return _instance.instance.getToken();
    } catch (e, stackTrace) {
      _logger.info('Failed get token for Firebase Messaginging', e, stackTrace);
      return null;
    }
  }

  @override
  FutureOr<bool> listenChannel(String channel) async {
    if (!await super.listenChannel(channel)) {
      return false;
    }

    try {
      await _instance.instance.subscribeToTopic(channel);
    } catch (e, stackTrace) {
      _logger.warning(
          'Could not subscribe to Firebase Messaging topic: $channel',
          e,
          stackTrace);

      await super.ignoreChannel(channel);

      return false;
    }

    return true;
  }

  @override
  FutureOr<bool> ignoreChannel(String channel) async {
    if (!await super.ignoreChannel(channel)) {
      return false;
    }

    try {
      await _instance.instance.unsubscribeFromTopic(channel);
    } catch (e, stackTrace) {
      _logger.warning(
          'Could not unsubscribe Firebase Messaging topic: $channel',
          e,
          stackTrace);

      return false;
    }

    return true;
  }
}

Future<AndroidBitmap<String>?> _getAndroidBitmapFromUrl(String url) async {
  HttpClient? tClient;
  IOSink? tSync;

  try {
    final tDirectory = await getApplicationDocumentsDirectory();
    final tUri = Uri.tryParse(url);

    if (tUri != null && await tDirectory.exists()) {
      tClient = HttpClient();
      final tRequest = await tClient.getUrl(tUri);
      final tResponse = await tRequest.close();

      if (tResponse.statusCode == HttpStatus.ok) {
        final tFile = File(
            '${tDirectory.path}${Platform.pathSeparator}${md5.convert(utf8.encode(url)).toString()}');
        tSync = tFile.openWrite();

        await tSync.addStream(tResponse);

        return FilePathAndroidBitmap(tFile.path);
      }
    }
  } catch (e, stackTrace) {
    _logger.info('Failed to download bitmap for notification.', e, stackTrace);
  } finally {
    try {
      tSync?.close();
    } catch (e) {
      // ignore
    }

    try {
      tClient?.close();
    } catch (e) {
      // ignore
    }
  }

  return null;
}

Future<void> _showNotificationFromFirebaseRemoteMessage(
  firebase.RemoteMessage message, {
  bool fromBackground = false,
}) async {
  if (fromBackground && defaultTargetPlatform != TargetPlatform.android) {
    // Only Android needs to manually make a notification...
    return;
  }

  final tNotification = message.notification;
  final String tPayload;

  if (tNotification != null && fromBackground) {
    // Firebase will show it for us.
    return;
  }

  try {
    tPayload = jsonEncode(message.data);
  } catch (e, stackTrace) {
    _logger.fine('Bad payload', e, stackTrace);
    return;
  }

  if (tNotification != null) {
    final tImageUrl = tNotification.android?.imageUrl;
    AndroidBitmap<String>? tImage;

    if (tImageUrl?.isNotEmpty == true) {
      tImage = await _getAndroidBitmapFromUrl(tImageUrl!);
    }

    await FlutterLocalNotificationsPlugin().show(
      _generateLocalNotificationId(),
      tNotification.title,
      tNotification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          tNotification.android?.channelId ??
              NotificationsPlugin.kDefaultAndroidChannel.id,
          tNotification.android?.channelId ??
              NotificationsPlugin.kDefaultAndroidChannel.name,
          styleInformation: tImage != null
              ? BigPictureStyleInformation(tImage)
              : BigTextStyleInformation(tNotification.body ?? ''),
          largeIcon: tImage,
        ),
      ),
      payload: tPayload,
    );

    if (tImage != null) {
      try {
        await File(tImage.data).delete();
      } catch (e, stackTrace) {
        _logger.info('Failed to delete just created image.', e, stackTrace);
      }
    }
  } else {
    // handle an internal project's style...
    // ignore: todo
    // TODO: Temp... make this generic
    final tData = message.data;

    if ((tData['notifyType'] as String?) != 'URL') {
      return;
    }

    final tImageUrl = tData['mainImageUri'] as String?;
    AndroidBitmap<String>? tImage;

    if (tImageUrl?.isNotEmpty == true) {
      tImage = await _getAndroidBitmapFromUrl(tImageUrl!);
    }

    await FlutterLocalNotificationsPlugin().show(
      _generateLocalNotificationId(),
      tData['title'] as String?,
      tData['text'] as String?,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationsPlugin.kDefaultAndroidChannel.id,
          NotificationsPlugin.kDefaultAndroidChannel.name,
          styleInformation: tImage != null
              ? BigPictureStyleInformation(tImage)
              : BigTextStyleInformation((tData['text'] as String?) ?? ''),
          largeIcon: tImage,
          ticker: tData['tickerText'] as String?,
        ),
      ),
      payload: tPayload,
    );

    if (tImage != null) {
      try {
        await File(tImage.data).delete();
      } catch (e, stackTrace) {
        _logger.info('Failed to delete just created image.', e, stackTrace);
      }
    }
  }
}

/// This function will be executed in a background isolate
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(firebase.RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationsPlugin.initializeNotificationsForBackgroundIsolate();
  await _showNotificationFromFirebaseRemoteMessage(message,
      fromBackground: true);
}
