// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

void main() {
  testInitialize();

  group('NetworkInformation', () {
    test('factory unknown', () async {
      final tNetworkInformation = NetworkInformation.unknown();

      expect(
        tNetworkInformation.connectivities.contains(
          NetworkConnectivity.unknown,
        ),
        isTrue,
      );
    });

    test('toString', () async {
      final tNetworkInformation = NetworkInformation.unknown();

      expect(tNetworkInformation.toString().isNotEmpty, isTrue);
    });

    test('copyWith', () async {
      NetworkInformation tNetworkInformation = NetworkInformation.unknown();
      tNetworkInformation = tNetworkInformation.copyWith();

      expect(
        tNetworkInformation.connectivities.contains(
          NetworkConnectivity.unknown,
        ),
        isTrue,
      );
    });

    test('Operator equals', () async {
      NetworkInformation tNetworkInformationMobile1 = const NetworkInformation(
        connectivities: [NetworkConnectivity.mobile],
      );

      NetworkInformation tNetworkInformationMobile2 = const NetworkInformation(
        connectivities: [NetworkConnectivity.mobile],
      );

      NetworkInformation tNetworkInformationWifi = const NetworkInformation(
        connectivities: [NetworkConnectivity.wifi],
      );

      expect(tNetworkInformationMobile1 == tNetworkInformationMobile2, isTrue);

      expect(tNetworkInformationMobile1 == tNetworkInformationWifi, isFalse);
    });

    test('getter hashCode', () async {
      expect(NetworkInformation.unknown().hashCode != 0, isTrue);
    });
  });

  group('class NetworkPlugin', () {
    test('getter information', () async {
      final NetworkPlugin tNetwork = NetworkPlugin();

      expect(tNetwork.information == NetworkInformation.unknown(), isTrue);
    });

    test('Function init', () async {
      final NetworkPlugin tNetwork = NetworkPlugin();
      final App tApp = createApp();

      final bool tResult = await tNetwork.init(tApp);
      expect(tResult, isTrue);

      tNetwork.dispose();
    });
    test('getter informationStream', () async {
      final App tApp = createApp();
      final NetworkPlugin tNetwork = NetworkPlugin();

      final List<List<NetworkConnectivity>> tValues = [
        [NetworkConnectivity.none],
        [NetworkConnectivity.other],
        [NetworkConnectivity.mobile],
        [NetworkConnectivity.wifi],
        [NetworkConnectivity.ethernet],
        [NetworkConnectivity.bluetooth],
        [NetworkConnectivity.vpn],
      ];

      tNetwork.init(tApp);

      final tFuture = expectLater(
        tNetwork.informationStream.asyncMap((event) => event.connectivities),
        emitsInOrder(tValues),
      );

      for (var i in tValues) {
        await tNetwork.testChangeConnectivity(i);
      }

      await tFuture;

      tNetwork.dispose();
    });

    test('Function _onConnectivityChanged NetworkConnectivity.none', () async {
      final NetworkPlugin tNetwork = NetworkPlugin();

      testOnConnectivityChangedValue = [NetworkConnectivity.none];
      await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(
        tNetwork.information.connectivities.contains(NetworkConnectivity.none),
        isTrue,
      );
    });

    test('Function _onConnectivityChanged NetworkConnectivity.other', () async {
      final NetworkPlugin tNetwork = NetworkPlugin();

      testOnConnectivityChangedValue = [NetworkConnectivity.other];
      await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(
        tNetwork.information.connectivities.contains(NetworkConnectivity.other),
        isTrue,
      );
    });

    test(
      'Function _onConnectivityChanged NetworkConnectivity.mobile',
      () async {
        final NetworkPlugin tNetwork = NetworkPlugin();

        testOnConnectivityChangedValue = [NetworkConnectivity.mobile];
        await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(
          tNetwork.information.connectivities.contains(
            NetworkConnectivity.mobile,
          ),
          isTrue,
        );
      },
    );

    test('Function _onConnectivityChanged NetworkConnectivity.wifi', () async {
      final NetworkPlugin tNetwork = NetworkPlugin();

      testOnConnectivityChangedValue = [NetworkConnectivity.wifi];
      await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(
        tNetwork.information.connectivities.contains(NetworkConnectivity.wifi),
        isTrue,
      );
    });

    test(
      'Function _onConnectivityChanged NetworkConnectivity.ethernet',
      () async {
        final NetworkPlugin tNetwork = NetworkPlugin();

        testOnConnectivityChangedValue = [NetworkConnectivity.ethernet];
        await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(
          tNetwork.information.connectivities.contains(
            NetworkConnectivity.ethernet,
          ),
          isTrue,
        );
      },
    );

    test(
      'Function _onConnectivityChanged NetworkConnectivity.bluetooth',
      () async {
        final NetworkPlugin tNetwork = NetworkPlugin();

        testOnConnectivityChangedValue = [NetworkConnectivity.bluetooth];
        await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(
          tNetwork.information.connectivities.contains(
            NetworkConnectivity.bluetooth,
          ),
          isTrue,
        );
      },
    );

    test('Function _onConnectivityChanged NetworkConnectivity.vpn', () async {
      final NetworkPlugin tNetwork = NetworkPlugin();

      testOnConnectivityChangedValue = [NetworkConnectivity.vpn];
      await tNetwork.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(
        tNetwork.information.connectivities.contains(NetworkConnectivity.vpn),
        isTrue,
      );
    });

    test('Function dispose', () async {
      final App tApp = createApp();
      final NetworkPlugin tNetwork = NetworkPlugin();
      await tNetwork.init(tApp);
      await tNetwork.dispose();

      expect(tNetwork.disposed, isTrue);
    });
  });
}
