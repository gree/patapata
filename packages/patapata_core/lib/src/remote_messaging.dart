// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'app.dart';

final _logger = Logger('patapata.RemoteMessaging');

/// Class that represents remote messages that were displayed in the notification area of the device.
class RemoteMessageNotification {
  /// Title of the notification message.
  final String? title;

  /// Body of the notification message.
  final String? body;

  /// Create a [RemoteMessageNotification]
  /// [title] represents the title of the notification,
  /// and [body] is the content of the message was shown in the notification.
  const RemoteMessageNotification({
    this.title,
    this.body,
  });

  @override
  String toString() {
    return 'RemoteMessageNotification:{title:$title, body:$body}';
  }
}

/// A class for handling remote messages such as Patapata notifications.
class RemoteMessage {
  /// The default channel name used for remote messages.
  static const String kRemoteMessageDefaultChannel = 'patapata_default_channel';

  /// A unique ID to identify the message.
  final String? messageId;

  /// The name of the notification channel.
  final String channel;

  /// A map of received data in the remote message.
  final Map<String, dynamic>? data;

  /// The remote message for the notification.
  final RemoteMessageNotification? notification;

  /// Create a [RemoteMessage]
  /// [messageId] is the ID to identify the message, [channel] is the name of the notification channel with the default being [kRemoteMessageDefaultChannel],
  /// [data] is the received data, and [notification] is passed for the remote message of the notification.
  const RemoteMessage({
    this.messageId,
    this.channel = kRemoteMessageDefaultChannel,
    this.data,
    this.notification,
  });

  /// Strings for the [messageId], [channel], and [data] of the remote message.
  @override
  String toString() {
    return 'RemoteMessage:{messageId:$messageId, channel:$channel, data:$data}';
  }
}

/// An abstract class that provides the ability to monitor state changes of [RemoteMessage].
/// For each feature that provides remote messages, create a [RemoteMessaging] that inherits from this class.
abstract class RemoteMessaging extends ChangeNotifier {
  static const _kLocalConfigKeyPrefix = 'patapata.RemoteMessaging.listeningTo:';

  late final App _app;

  /// The [App] referenced by the plugin.
  App get app => _app;

  /// Initializes the [RemoteMessaging].
  @mustCallSuper
  Future<void> init(App app) async {
    _app = app;
  }

  /// Disposes of the [RemoteMessaging] object. See [ChangeNotifier.dispose] for details.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
  }

  /// Future for the message when the app is opened via Remote Message.
  Future<RemoteMessage?> getInitialMessage();

  /// A Stream for observing the results of notified messages [messages].
  Stream<RemoteMessage> get messages;

  /// A Stream for observing the results of the notified tokens.
  Stream<String?> get tokens;

  /// Obtains a token to identify the app's installation.
  /// This token can be used when you want to send notifications from other services to your own app.
  Future<String?> getToken();

  /// Whether the channel name [channel] is registered to for receiving messages.
  @mustCallSuper
  FutureOr<bool> listenChannel(String channel) async {
    if (listeningToChannel(channel)) {
      return false;
    }

    await _app.localConfig.setBool('$_kLocalConfigKeyPrefix$channel', true);

    return true;
  }

  /// Ignore the channel name [channel] to stop receiving messages from this channel.
  @mustCallSuper
  FutureOr<bool> ignoreChannel(String channel) async {
    if (!listeningToChannel(channel)) {
      return false;
    }

    await _app.localConfig.reset('$_kLocalConfigKeyPrefix$channel');

    return true;
  }

  /// Determine whether the channel name [channel] is registered to for receiving messages.
  bool listeningToChannel(String channel) =>
      _app.localConfig.getBool('$_kLocalConfigKeyPrefix$channel');
}

/// Class for managing all [RemoteMessaging] used by the app.
///
/// Access to [RemoteMessaging] is usually done through this class.
/// example
/// ```dart
/// getApp().remoteMessaging.getInitialMessage();
/// ```
class ProxyRemoteMessaging extends RemoteMessaging {
  final Map<RemoteMessaging, StreamSubscription<RemoteMessage>> _subscriptions =
      {};
  final Map<RemoteMessaging, StreamSubscription<String?>> _tokenSubscriptions =
      {};
  final List<RemoteMessaging> _remoteMessagings = [];

  final _messagesController = StreamController<RemoteMessage>.broadcast();
  final _tokenController = StreamController<String?>.broadcast();

  /// Create a [ProxyRemoteMessaging]
  ProxyRemoteMessaging();

  /// Add [remoteMessaging] to the [RemoteMessaging]s managed by [ProxyRemoteMessaging].
  Future<void> addRemoteMessaging(RemoteMessaging remoteMessaging) async {
    await remoteMessaging.init(_app);
    _subscriptions[remoteMessaging] =
        remoteMessaging.messages.listen(_onMessage);
    _tokenSubscriptions[remoteMessaging] =
        remoteMessaging.tokens.listen(_onToken);
    _remoteMessagings.add(remoteMessaging);
  }

  /// Remove [remoteMessaging] from the [RemoteMessaging]s managed by [ProxyRemoteMessaging].
  void removeRemoteMessaging(RemoteMessaging remoteMessaging) {
    if (_remoteMessagings.remove(remoteMessaging)) {
      _subscriptions.remove(remoteMessaging)?.cancel();
      _tokenSubscriptions.remove(remoteMessaging)?.cancel();
      remoteMessaging.dispose();
    }
  }

  void _onMessage(RemoteMessage message) {
    _messagesController.add(message);
  }

  void _onToken(String? token) {
    _tokenController.add(token);
  }

  @override
  void dispose() {
    for (var v in _remoteMessagings) {
      v.dispose();
    }
    _remoteMessagings.clear();
    super.dispose();
  }

  /// This function returns the first initial message that can be obtained from the list of managed [RemoteMessage]s.
  /// If there were none, this returns null.
  @override
  Future<RemoteMessage?> getInitialMessage() {
    // Only get the first message.
    return Future.wait<RemoteMessage?>(
        _remoteMessagings.map<Future<RemoteMessage?>>(
      (v) => v.getInitialMessage(),
    )).then(
      (v) => v.firstWhere(
        (b) => b != null,
        orElse: () => null,
      ),
    );
  }

  /// The stream of all [RemoteMessage]s managed by this class.
  @override
  Stream<RemoteMessage> get messages => _messagesController.stream;

  /// The stream of all tokens from all [RemoteMessage]s managed by this class.
  @override
  Stream<String?> get tokens => _tokenController.stream;

  /// Obtains the first token from all [RemoteMessage]s managed by this class.
  @override
  Future<String?> getToken() async {
    assert(() {
      if (_remoteMessagings.length > 1) {
        _logger.fine(
            'Multiple RemoteMessaging registered in ProxyRemoteMessaging. Only returning first one found.');
      }

      return true;
    }());

    if (_remoteMessagings.isNotEmpty) {
      try {
        return _remoteMessagings.first.getToken();
        // coverage:ignore-start
      } catch (e, stackTrace) {
        _logger.info('Failed to get token from plugin', e, stackTrace);
      }
      // coverage:ignore-end
    }

    return null;
  }

  /// This function registers the [RemoteMessaging] with the specified channel name [channel] in the list of [RemoteMessaging] managed by this class.
  /// If there are multiple [RemoteMessaging], it returns true if the first one that matches the channel name [channel] is found.
  @override
  FutureOr<bool> listenChannel(String channel) {
    return Future.wait<bool>(
      _remoteMessagings
          .map<Future<bool>>((v) async => v.listenChannel(channel)),
    )
        .then(
      (v) => v.firstWhere(
        (b) => b,
        orElse: () => false,
      ),
    )
        .then((v) async {
      await super.listenChannel(channel);
      return v;
    });
  }

  /// This function ignores messages with the specified channel name [channel] from the list managed by this class.
  /// If there are multiple [RemoteMessaging], it executes the ignore operation on the first one that matches the channel name [channel]. If the ignore operation is successful, it returns true.
  @override
  FutureOr<bool> ignoreChannel(String channel) {
    return Future.wait<bool>(
      _remoteMessagings
          .map<Future<bool>>((v) async => v.ignoreChannel(channel)),
    )
        .then(
      (v) => v.firstWhere(
        (b) => b,
        orElse: () => false,
      ),
    )
        .then((v) async {
      await super.ignoreChannel(channel);
      return v;
    });
  }
}

/// This is a mock class for RemoteMessaging, used for testing purposes.
class MockRemoteMessaging extends RemoteMessaging {
  final Future<RemoteMessage?> Function()? _getInitialMessage;
  final Stream<RemoteMessage> Function()? _messages;
  final Stream<String?> Function()? _tokens;
  final Future<String?> Function()? _getToken;

  /// Constructor for the MockRemoteMessaging class.
  /// The arguments are functions that return the values you want to
  /// return when you call the corresponding functions.
  MockRemoteMessaging({
    Future<RemoteMessage?> Function()? getInitialMessage,
    Stream<RemoteMessage> Function()? messages,
    Stream<String?> Function()? tokenStream,
    Future<String?> Function()? getToken,
  })  : _getInitialMessage = getInitialMessage,
        _messages = messages,
        _tokens = tokenStream,
        _getToken = getToken;

  @override
  Future<RemoteMessage?> getInitialMessage() {
    if (_getInitialMessage != null) {
      return _getInitialMessage!();
    }

    return Future.value(null);
  }

  @override
  Stream<RemoteMessage> get messages {
    if (_messages != null) {
      return _messages!();
    }

    return const Stream.empty();
  }

  @override
  Stream<String?> get tokens {
    if (_tokens != null) {
      return _tokens!();
    }

    return const Stream.empty();
  }

  @override
  Future<String?> getToken() {
    if (_getToken != null) {
      return _getToken!();
    }

    return Future.value(null);
  }
}
