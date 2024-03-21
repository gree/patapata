// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'plugin.dart';
import 'util.dart';

/// This enum describes various states of network connectivity for an app or system
enum NetworkConnectivity {
  /// Status representing an unknown network state
  unknown,

  /// Status representing a state where there is no network connection
  none,

  /// Status representing a state where there is a network connection, but the type is unknown
  other,

  /// Status representing a state connected to a mobile network
  mobile,

  /// Status representing a state connected to Wi-Fi
  wifi,

  /// Status representing a state connected to Ethernet
  ethernet,

  /// Status representing a state connected to Bluetooth
  bluetooth,

  /// Status representing a state connected to a VPN network
  ///
  /// Note for iOS and macOS:
  /// There is no separate network interface type for [vpn].
  /// It returns [other] on any device (also simulator).
  vpn,
}

/// A class representing the current network status of [App].
///
/// This class, within [NetworkPlugin]
/// obtains the network status using [Connectivity].
class NetworkInformation {
  final NetworkConnectivity connectivity;

  const NetworkInformation({
    required this.connectivity,
  });

  factory NetworkInformation.unknown() => const NetworkInformation(
        connectivity: NetworkConnectivity.unknown,
      );

  @override
  String toString() => 'NetworkInformation:connectivity=${connectivity.name}';

  NetworkInformation copyWith({
    NetworkConnectivity? connectivity,
  }) =>
      NetworkInformation(
        connectivity: connectivity ?? this.connectivity,
      );

  @override
  operator ==(Object other) =>
      other is NetworkInformation && connectivity == other.connectivity;

  @override
  int get hashCode => Object.hash('NetworkInformation', connectivity);
}

/// Plugin for retrieving the network status of [App].
class NetworkPlugin extends Plugin with WidgetsBindingObserver {
  NetworkPlugin();

  final Connectivity _connectivity = Connectivity();

  NetworkInformation _currentNetworkInformation = const NetworkInformation(
    connectivity: NetworkConnectivity.unknown,
  );

  /// Return the current network status of [App].
  ///
  /// ```dart
  /// getApp().network.information
  /// ```
  NetworkInformation get information => _currentNetworkInformation;

  final _streamController = StreamController<NetworkInformation>.broadcast();

  /// Stream to get the latest network state of the app
  ///
  /// Typically accessed through the app's network.
  ///
  /// /// ```dart
  /// getApp().network.informationStream;
  /// ```
  Stream<NetworkInformation> get informationStream => _streamController.stream;

  StreamSubscription<ConnectivityResult>? _onConnectivityChangedSubscription;

  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);
    WidgetsBinding.instance.addObserver(this);
    _onConnectivityChangedSubscription =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _onConnectivityChanged(await _connectivity.checkConnectivity());

    return true;
  }

  @override
  FutureOr<void> dispose() async {
    await super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _onConnectivityChangedSubscription?.cancel();
    _onConnectivityChangedSubscription = null;
    _streamController.close();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // When we move to the foreground,
      // get the newest network information.
      _onConnectivityChanged(await _connectivity.checkConnectivity());
    }
  }

  @override
  Widget createAppWidgetWrapper(Widget child) {
    return StreamProvider<NetworkInformation>(
      create: (context) => informationStream,
      initialData: information,
      child: child,
    );
  }

  void _onConnectivityChanged(ConnectivityResult event) {
    NetworkConnectivity tConnectivity = switch (event) {
      ConnectivityResult.none => NetworkConnectivity.none,
      ConnectivityResult.other => NetworkConnectivity.other,
      ConnectivityResult.mobile => NetworkConnectivity.mobile,
      ConnectivityResult.wifi => NetworkConnectivity.wifi,
      ConnectivityResult.ethernet => NetworkConnectivity.ethernet,
      ConnectivityResult.bluetooth => NetworkConnectivity.bluetooth,
      ConnectivityResult.vpn => NetworkConnectivity.vpn,
    };

    if (_currentNetworkInformation.connectivity == tConnectivity) {
      return;
    }

    _currentNetworkInformation = _currentNetworkInformation.copyWith(
      connectivity: tConnectivity,
    );

    _streamController.add(_currentNetworkInformation);
  }

  @override
  @visibleForTesting
  void setMockMethodCallHandler() {
    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (methodCall) async {
        methodCallLogs.add(methodCall);
        switch (methodCall.method) {
          case 'check':
            return testOnConnectivityChangedValue.name;
          default:
            break;
        }
        return null;
      },
    );
  }

  StreamController<NetworkConnectivity>? _mockStreamController;
  Completer<void>? _testChangeConnectivityCompleter;

  @override
  @visibleForTesting
  void setMockStreamHandler() {
    _mockStreamController = StreamController<NetworkConnectivity>();
    StreamSubscription<NetworkConnectivity>? tMockStreamSubscription;

    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      TestMockStreamHandler.inline(
        onListen: (data, sink) {
          tMockStreamSubscription = _mockStreamController!.stream.listen((v) {
            sink.success(v.name);
            _testChangeConnectivityCompleter?.complete();
            _testChangeConnectivityCompleter = null;
          });
        },
        onCancel: (_) {
          tMockStreamSubscription?.cancel();
          _testChangeConnectivityCompleter?.complete();
          _testChangeConnectivityCompleter = null;
        },
      ),
    );
  }

  @visibleForTesting
  Future<void> testChangeConnectivity(NetworkConnectivity result) {
    final tCompleter = _testChangeConnectivityCompleter = Completer<void>();
    testOnConnectivityChangedValue = result;
    _mockStreamController?.add(result);

    return tCompleter.future;
  }
}

@visibleForTesting
NetworkConnectivity testOnConnectivityChangedValue = NetworkConnectivity.none;
