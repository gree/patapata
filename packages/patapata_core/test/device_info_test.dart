// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

/// TODO: The arguments for "with arguments"
///　will be verified by checking the actual values
///　on the device during the time of going to the office and used as a reference.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceInfoPlugin.androidInfo', () {
    late App app;
    late DeviceInfoPlugin deviceInfoPlugin;
    setUp(() {
      app = createApp();
      deviceInfoPlugin = DeviceInfoPlugin();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    test('init', () async {
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.androidDeviceInfo != null, isTrue);
      expect(deviceInfoPlugin.androidDeviceInfo!.data,
          DeviceInfoPlugin.mockAndroidDeviceInfoMap);
    });

    test('setMockAndroidDeviceInfo no arguments', () async {
      DeviceInfoPlugin.setMockAndroidDeviceInfo();
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.androidDeviceInfo, isNotNull);
      expect(deviceInfoPlugin.androidDeviceInfo!.id, 'id');
      expect(deviceInfoPlugin.androidDeviceInfo!.host, 'host');
      expect(deviceInfoPlugin.androidDeviceInfo!.tags, 'tags');
      expect(deviceInfoPlugin.androidDeviceInfo!.type, 'type');
      expect(deviceInfoPlugin.androidDeviceInfo!.model, 'model');
      expect(deviceInfoPlugin.androidDeviceInfo!.board, 'board');
      expect(deviceInfoPlugin.androidDeviceInfo!.brand, 'Google');
      expect(deviceInfoPlugin.androidDeviceInfo!.device, 'device');
      expect(deviceInfoPlugin.androidDeviceInfo!.product, 'product');
      expect(deviceInfoPlugin.androidDeviceInfo!.display, 'display');
      expect(deviceInfoPlugin.androidDeviceInfo!.hardware, 'hardware');
      expect(deviceInfoPlugin.androidDeviceInfo!.bootloader, 'bootloader');
      expect(deviceInfoPlugin.androidDeviceInfo!.isPhysicalDevice, isTrue);
      expect(deviceInfoPlugin.androidDeviceInfo!.fingerprint, 'fingerprint');
      expect(deviceInfoPlugin.androidDeviceInfo!.manufacturer, 'manufacturer');
      expect(deviceInfoPlugin.androidDeviceInfo!.supportedAbis,
          ['arm64-v8a', 'x86', 'x86_64']);
      expect(deviceInfoPlugin.androidDeviceInfo!.systemFeatures,
          ['FEATURE_AUDIO_PRO', 'FEATURE_AUDIO_OUTPUT']);
      expect(deviceInfoPlugin.androidDeviceInfo!.supported32BitAbis,
          ['x86 (IA-32)', 'MMX']);
      expect(deviceInfoPlugin.androidDeviceInfo!.supported64BitAbis,
          ['x86-64', 'MMX', 'SSSE3']);
      expect(deviceInfoPlugin.androidDeviceInfo!.version.sdkInt, 16);
      expect(deviceInfoPlugin.androidDeviceInfo!.version.baseOS, 'baseOS');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.previewSdkInt, 30);
      expect(deviceInfoPlugin.androidDeviceInfo!.version.release, 'release');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.codename, 'codename');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.incremental,
          'incremental');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.securityPatch,
          'securityPatch');
      expect(deviceInfoPlugin.androidDeviceInfo!.serialNumber, 'SERIAL');
      expect(deviceInfoPlugin.androidDeviceInfo!.isLowRamDevice, isFalse);
    });

    test('setMockAndroidDeviceInfo with arguments', () async {
      DeviceInfoPlugin.setMockAndroidDeviceInfo(
        id: '',
        host: '',
        tags: '',
        type: '',
        model: '',
        board: '',
        brand: '',
        device: '',
        product: '',
        display: '',
        hardware: '',
        bootloader: '',
        isPhysicalDevice: false,
        fingerprint: '',
        manufacturer: '',
        supportedAbis: <String>[''],
        systemFeatures: [''],
        supported64BitAbis: [''],
        supported32BitAbis: [''],
        version: <String, dynamic>{
          'sdkInt': 0,
          'baseOS': '',
          'previewSdkInt': 0,
          'release': '',
          'codename': '',
          'incremental': '',
          'securityPatch': '',
        },
        serialNumber: '',
        isLowRamDevice: false,
      );

      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.androidDeviceInfo != null, isTrue);
      expect(deviceInfoPlugin.androidDeviceInfo!.data,
          DeviceInfoPlugin.mockAndroidDeviceInfoMap);
      expect(deviceInfoPlugin.androidDeviceInfo!.id, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.host, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.tags, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.type, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.model, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.board, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.brand, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.device, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.product, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.display, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.hardware, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.isPhysicalDevice, isFalse);
      expect(deviceInfoPlugin.androidDeviceInfo!.bootloader, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.fingerprint, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.manufacturer, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.supportedAbis, ['']);
      expect(deviceInfoPlugin.androidDeviceInfo!.systemFeatures, ['']);
      expect(deviceInfoPlugin.androidDeviceInfo!.supported32BitAbis, ['']);
      expect(deviceInfoPlugin.androidDeviceInfo!.supported64BitAbis, ['']);
      expect(deviceInfoPlugin.androidDeviceInfo!.version.sdkInt, 0);
      expect(deviceInfoPlugin.androidDeviceInfo!.version.baseOS, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.previewSdkInt, 0);
      expect(deviceInfoPlugin.androidDeviceInfo!.version.release, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.codename, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.incremental, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.version.securityPatch, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.serialNumber, '');
      expect(deviceInfoPlugin.androidDeviceInfo!.isLowRamDevice, isFalse);
    });
  });

  group('DeviceInfoPlugin.iosInfo', () {
    late App app;
    late DeviceInfoPlugin deviceInfoPlugin;
    setUp(() {
      app = createApp();
      deviceInfoPlugin = DeviceInfoPlugin();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    test('init', () async {
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.iosDeviceInfo != null, isTrue);
      expect(deviceInfoPlugin.iosDeviceInfo!.data,
          DeviceInfoPlugin.mockIosDeviceInfoMap);
    });

    test('setMockIosDeviceInfo no arguments', () async {
      DeviceInfoPlugin.setMockIosDeviceInfo();
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.iosDeviceInfo != null, isTrue);
      expect(deviceInfoPlugin.iosDeviceInfo!.data,
          DeviceInfoPlugin.mockIosDeviceInfoMap);
      expect(deviceInfoPlugin.iosDeviceInfo!.name, 'name');
      expect(deviceInfoPlugin.iosDeviceInfo!.model, 'model');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.release, 'release');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.version, 'version');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.machine, 'machine');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.sysname, 'sysname');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.nodename, 'nodename');
      expect(deviceInfoPlugin.iosDeviceInfo!.systemName, 'systemName');
      expect(deviceInfoPlugin.iosDeviceInfo!.systemVersion, 'systemVersion');
      expect(deviceInfoPlugin.iosDeviceInfo!.localizedModel, 'localizedModel');
      expect(deviceInfoPlugin.iosDeviceInfo!.isPhysicalDevice, isTrue);
      expect(deviceInfoPlugin.iosDeviceInfo!.identifierForVendor,
          'identifierForVendor');
    });

    test('setMockIosDeviceInfo with arguments', () async {
      DeviceInfoPlugin.setMockIosDeviceInfo(
        name: '',
        model: '',
        utsname: <String, dynamic>{
          'release': '',
          'version': '',
          'machine': '',
          'sysname': '',
          'nodename': '',
        },
        systemName: '',
        systemVersion: '',
        isPhysicalDevice: false,
        localizedModel: '',
        identifierForVendor: '',
      );
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.iosDeviceInfo != null, isTrue);
      expect(deviceInfoPlugin.iosDeviceInfo!.data,
          DeviceInfoPlugin.mockIosDeviceInfoMap);
      expect(deviceInfoPlugin.iosDeviceInfo!.name, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.model, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.release, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.version, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.machine, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.sysname, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.utsname.nodename, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.systemName, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.systemVersion, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.localizedModel, '');
      expect(deviceInfoPlugin.iosDeviceInfo!.isPhysicalDevice, isFalse);
      expect(deviceInfoPlugin.iosDeviceInfo!.identifierForVendor, '');
    });
  });

  group('DeviceInfoPlugin.macOsInfo', () {
    late App app;
    late DeviceInfoPlugin deviceInfoPlugin;
    setUp(() {
      app = createApp();
      deviceInfoPlugin = DeviceInfoPlugin();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    });

    test('init', () async {
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.macOsInfo != null, isTrue);
      expect(deviceInfoPlugin.macOsInfo!.data,
          DeviceInfoPlugin.mockMacosDeviceInfoMap);
    });

    test('setMockMacosDeviceInfoMap no arguments', () async {
      DeviceInfoPlugin.setMockMacosDeviceInfo();
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.macOsInfo != null, isTrue);
      expect(deviceInfoPlugin.macOsInfo!.data,
          DeviceInfoPlugin.mockMacosDeviceInfoMap);
      expect(deviceInfoPlugin.macOsInfo!.arch, 'arch');
      expect(deviceInfoPlugin.macOsInfo!.model, 'model');
      expect(deviceInfoPlugin.macOsInfo!.activeCPUs, 4);
      expect(deviceInfoPlugin.macOsInfo!.memorySize, 16);
      expect(deviceInfoPlugin.macOsInfo!.cpuFrequency, 2);
      expect(deviceInfoPlugin.macOsInfo!.hostName, 'hostName');
      expect(deviceInfoPlugin.macOsInfo!.osRelease, 'osRelease');
      expect(deviceInfoPlugin.macOsInfo!.computerName, 'computerName');
      expect(deviceInfoPlugin.macOsInfo!.kernelVersion, 'kernelVersion');
      expect(deviceInfoPlugin.macOsInfo!.systemGUID, 'systemGUID');
    });

    test('setMockMacosDeviceInfoMap with arguments', () async {
      DeviceInfoPlugin.setMockMacosDeviceInfo(
        arch: '',
        model: '',
        activeCPUs: 0,
        memorySize: 0,
        cpuFrequency: 0,
        hostName: '',
        osRelease: '',
        computerName: '',
        kernelVersion: '',
        systemGUID: '',
        majorVersion: 1,
        minorVersion: 1,
        patchVersion: 1,
      );
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.macOsInfo != null, isTrue);
      expect(deviceInfoPlugin.macOsInfo!.data,
          DeviceInfoPlugin.mockMacosDeviceInfoMap);
      expect(deviceInfoPlugin.macOsInfo!.arch, '');
      expect(deviceInfoPlugin.macOsInfo!.model, '');
      expect(deviceInfoPlugin.macOsInfo!.activeCPUs, 0);
      expect(deviceInfoPlugin.macOsInfo!.memorySize, 0);
      expect(deviceInfoPlugin.macOsInfo!.cpuFrequency, 0);
      expect(deviceInfoPlugin.macOsInfo!.hostName, '');
      expect(deviceInfoPlugin.macOsInfo!.osRelease, '');
      expect(deviceInfoPlugin.macOsInfo!.computerName, '');
      expect(deviceInfoPlugin.macOsInfo!.kernelVersion, '');
      expect(deviceInfoPlugin.macOsInfo!.systemGUID, '');
      expect(deviceInfoPlugin.macOsInfo!.majorVersion, 1);
      expect(deviceInfoPlugin.macOsInfo!.minorVersion, 1);
      expect(deviceInfoPlugin.macOsInfo!.patchVersion, 1);
    });
  });

  group('DeviceInfoPlugin.linuxInfo', () {
    late App app;
    late DeviceInfoPlugin deviceInfoPlugin;
    setUp(() {
      DeviceInfoLinuxPlatform.registerWith();
      app = createApp();
      deviceInfoPlugin = DeviceInfoPlugin();
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    });

    test('init', () async {
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.linuxInfo != null, isTrue);
    });
    test('setMockLinuxDeviceInfo no arguments', () async {
      DeviceInfoPlugin.setMockLinuxDeviceInfo();
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.linuxInfo != null, isTrue);
      expect(deviceInfoPlugin.linuxInfo!.name, 'name');
      expect(deviceInfoPlugin.linuxInfo!.version, 'version');
      expect(deviceInfoPlugin.linuxInfo!.id, 'id');
      expect(deviceInfoPlugin.linuxInfo!.idLike, ['idLike']);
      expect(deviceInfoPlugin.linuxInfo!.versionCodename, 'versionCodename');
      expect(deviceInfoPlugin.linuxInfo!.versionId, 'versionId');
      expect(deviceInfoPlugin.linuxInfo!.prettyName, 'prettyName');
      expect(deviceInfoPlugin.linuxInfo!.buildId, 'buildId');
      expect(deviceInfoPlugin.linuxInfo!.variant, 'variant');
      expect(deviceInfoPlugin.linuxInfo!.variantId, 'variantId');
      expect(deviceInfoPlugin.linuxInfo!.machineId, 'machineId');
    });

    test('setMockLinuxDeviceInfo with arguments', () async {
      DeviceInfoPlugin.setMockLinuxDeviceInfo(
        name: '',
        version: '',
        id: '',
        idLike: [''],
        versionCodename: '',
        versionId: '',
        prettyName: '',
        buildId: '',
        variant: '',
        variantId: '',
        machineId: '',
      );
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.linuxInfo != null, isTrue);
      expect(deviceInfoPlugin.linuxInfo!.name, '');
      expect(deviceInfoPlugin.linuxInfo!.version, '');
      expect(deviceInfoPlugin.linuxInfo!.id, '');
      expect(deviceInfoPlugin.linuxInfo!.idLike, ['']);
      expect(deviceInfoPlugin.linuxInfo!.versionCodename, '');
      expect(deviceInfoPlugin.linuxInfo!.versionId, '');
      expect(deviceInfoPlugin.linuxInfo!.prettyName, '');
      expect(deviceInfoPlugin.linuxInfo!.buildId, '');
      expect(deviceInfoPlugin.linuxInfo!.variant, '');
      expect(deviceInfoPlugin.linuxInfo!.variantId, '');
      expect(deviceInfoPlugin.linuxInfo!.machineId, '');
    });
  });

  group('DeviceInfoPlugin.windowsInfo', () {
    late App app;
    late DeviceInfoPlugin deviceInfoPlugin;
    setUp(() {
      DeviceInfoWindowsPlatform.registerWith();
      app = createApp();
      deviceInfoPlugin = DeviceInfoPlugin();
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });

    test('init', () async {
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.windowsInfo != null, isTrue);
    });

    test('setMockWindowsDeviceInfo no arguments', () async {
      DeviceInfoPlugin.setMockWindowsDeviceInfo();
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.windowsInfo != null, isTrue);
      expect(deviceInfoPlugin.windowsInfo!.computerName, 'computerName');
      expect(deviceInfoPlugin.windowsInfo!.numberOfCores, 4);
      expect(deviceInfoPlugin.windowsInfo!.systemMemoryInMegabytes, 16);
      expect(deviceInfoPlugin.windowsInfo!.userName, 'userName');
      expect(deviceInfoPlugin.windowsInfo!.majorVersion, 10);
      expect(deviceInfoPlugin.windowsInfo!.minorVersion, 0);
      expect(deviceInfoPlugin.windowsInfo!.buildNumber, 10240);
      expect(deviceInfoPlugin.windowsInfo!.platformId, 1);
      expect(deviceInfoPlugin.windowsInfo!.csdVersion, 'csdVersion');
      expect(deviceInfoPlugin.windowsInfo!.servicePackMajor, 1);
      expect(deviceInfoPlugin.windowsInfo!.servicePackMinor, 0);
      expect(deviceInfoPlugin.windowsInfo!.suitMask, 1);
      expect(deviceInfoPlugin.windowsInfo!.productType, 1);
      expect(deviceInfoPlugin.windowsInfo!.reserved, 1);
      expect(deviceInfoPlugin.windowsInfo!.buildLab,
          '22000.co_release.210604-1628');
      expect(deviceInfoPlugin.windowsInfo!.buildLabEx,
          '22000.1.amd64fre.co_release.210604-1628');
      expect(deviceInfoPlugin.windowsInfo!.digitalProductId,
          Uint8List.fromList([]));
      expect(deviceInfoPlugin.windowsInfo!.displayVersion, '21H2');
      expect(deviceInfoPlugin.windowsInfo!.editionId, 'Pro');
      expect(deviceInfoPlugin.windowsInfo!.installDate, DateTime(2022, 04, 02));
      expect(deviceInfoPlugin.windowsInfo!.productId, '00000-00000-0000-AAAAA');
      expect(deviceInfoPlugin.windowsInfo!.productName, 'Windows 10 Pro');
      expect(deviceInfoPlugin.windowsInfo!.registeredOwner, 'registeredOwner');
      expect(deviceInfoPlugin.windowsInfo!.releaseId, 'releaseId');
      expect(deviceInfoPlugin.windowsInfo!.deviceId, 'deviceId');
    });
    test('setMockWindowsDeviceInfo with arguments', () async {
      DeviceInfoPlugin.setMockWindowsDeviceInfo(
        computerName: '',
        numberOfCores: 0,
        systemMemoryInMegabytes: 0,
        userName: '',
        majorVersion: 0,
        minorVersion: 1,
        buildNumber: 0,
        platformId: 0,
        csdVersion: '',
        servicePackMajor: 0,
        servicePackMinor: 1,
        suitMask: 0,
        productType: 0,
        reserved: 0,
        buildLab: '',
        buildLabEx: '',
        digitalProductId: Uint8List.fromList([]),
        displayVersion: '',
        editionId: '',
        installDate: DateTime(2023, 04, 02),
        productId: '',
        productName: '',
        registeredOwner: '',
        releaseId: '',
        deviceId: '',
      );
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.windowsInfo != null, isTrue);
      expect(deviceInfoPlugin.windowsInfo!.computerName, '');
      expect(deviceInfoPlugin.windowsInfo!.numberOfCores, 0);
      expect(deviceInfoPlugin.windowsInfo!.systemMemoryInMegabytes, 0);
      expect(deviceInfoPlugin.windowsInfo!.userName, '');
      expect(deviceInfoPlugin.windowsInfo!.majorVersion, 0);
      expect(deviceInfoPlugin.windowsInfo!.minorVersion, 1);
      expect(deviceInfoPlugin.windowsInfo!.buildNumber, 0);
      expect(deviceInfoPlugin.windowsInfo!.platformId, 0);
      expect(deviceInfoPlugin.windowsInfo!.csdVersion, '');
      expect(deviceInfoPlugin.windowsInfo!.servicePackMajor, 0);
      expect(deviceInfoPlugin.windowsInfo!.servicePackMinor, 1);
      expect(deviceInfoPlugin.windowsInfo!.suitMask, 0);
      expect(deviceInfoPlugin.windowsInfo!.productType, 0);
      expect(deviceInfoPlugin.windowsInfo!.reserved, 0);
      expect(deviceInfoPlugin.windowsInfo!.buildLab, '');
      expect(deviceInfoPlugin.windowsInfo!.buildLabEx, '');
      expect(deviceInfoPlugin.windowsInfo!.digitalProductId,
          Uint8List.fromList([]));
      expect(deviceInfoPlugin.windowsInfo!.displayVersion, '');
      expect(deviceInfoPlugin.windowsInfo!.editionId, '');
      expect(deviceInfoPlugin.windowsInfo!.installDate, DateTime(2023, 04, 02));
      expect(deviceInfoPlugin.windowsInfo!.productId, '');
      expect(deviceInfoPlugin.windowsInfo!.productName, '');
      expect(deviceInfoPlugin.windowsInfo!.registeredOwner, '');
      expect(deviceInfoPlugin.windowsInfo!.releaseId, '');
      expect(deviceInfoPlugin.windowsInfo!.deviceId, '');
    });
  });

  group('DeviceInfoPlugin.webInfo', () {
    late App app;
    late DeviceInfoPlugin deviceInfoPlugin;
    setUp(() {
      DeviceInfoWebPlatform.registerWith();
      app = createApp();
      deviceInfoPlugin = DeviceInfoPlugin();
      debugIsWeb = true;
    });
    test('init', () async {
      final bool tResult = await deviceInfoPlugin.init(app);

      expect(tResult, isTrue);
      expect(deviceInfoPlugin.webInfo != null, isTrue);
      expect(deviceInfoPlugin.webInfo!.data,
          DeviceInfoPlugin.mockWebBrowserInfoMap);
    });
    test('setMockWebBrowserInfoMap no arguments', () async {
      DeviceInfoPlugin.setMockWebBrowserInfo();
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.webInfo != null, isTrue);
      expect(deviceInfoPlugin.webInfo!.data,
          DeviceInfoPlugin.mockWebBrowserInfoMap);
    });
    test('setMockWebBrowserInfoMap with arguments', () async {
      DeviceInfoPlugin.setMockWebBrowserInfo(
        browserName: 'safari',
        appCodeName: 'appCodeName',
        appName: 'appName',
        appVersion: 'appVersion',
        deviceMemory: 42.0,
        language: 'language',
        languages: ['en', 'es'],
        platform: 'platform',
        product: 'product',
        productSub: 'productSub',
        userAgent: 'Safari',
        vendor: 'vendor',
        vendorSub: 'vendorSub',
        hardwareConcurrency: 2,
        maxTouchPoints: 42,
      );
      await deviceInfoPlugin.init(app);

      expect(deviceInfoPlugin.webInfo != null, isTrue);
      expect(deviceInfoPlugin.webInfo!.data,
          DeviceInfoPlugin.mockWebBrowserInfoMap);
    });
  });
}
