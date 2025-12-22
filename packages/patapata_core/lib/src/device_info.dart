// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:device_info_plus/device_info_plus.dart' as plugin;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'plugin.dart';
import 'app.dart';
import 'util.dart';

/// Plugin that manages information related to the platform's device.
///
/// This plugin retrieves information from [DeviceInfoPlatform] during initialization,
/// allowing synchronous access from the application or other plugins.
///
/// This plugin is automatically created during application initialization
/// and can be accessed from [App.package].
class DeviceInfoPlugin extends Plugin {
  final plugin.DeviceInfoPlugin _deviceInfoPlugin = plugin.DeviceInfoPlugin();

  plugin.AndroidDeviceInfo? _androidDeviceInfo;

  /// device information for Android.
  plugin.AndroidDeviceInfo? get androidDeviceInfo => _androidDeviceInfo;

  plugin.IosDeviceInfo? _iosDeviceInfo;

  /// device information for iOS.
  plugin.IosDeviceInfo? get iosDeviceInfo => _iosDeviceInfo;

  plugin.LinuxDeviceInfo? _linuxInfo;

  /// device information for Linux.
  plugin.LinuxDeviceInfo? get linuxInfo => _linuxInfo;

  plugin.MacOsDeviceInfo? _macOsInfo;

  /// device information for macOS.
  plugin.MacOsDeviceInfo? get macOsInfo => _macOsInfo;

  plugin.WindowsDeviceInfo? _windowsInfo;

  /// device information for Windows.
  plugin.WindowsDeviceInfo? get windowsInfo => _windowsInfo;

  plugin.WebBrowserInfo? _webInfo;

  /// device information for WebBrowser.
  plugin.WebBrowserInfo? get webInfo => _webInfo;

  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    if (debugIsWeb || kIsWeb) {
      _webInfo = await _deviceInfoPlugin.webBrowserInfo;
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          _androidDeviceInfo = await _deviceInfoPlugin.androidInfo;
          break;
        case TargetPlatform.iOS:
          _iosDeviceInfo = await _deviceInfoPlugin.iosInfo;
          break;
        case TargetPlatform.linux:
          _linuxInfo = await _deviceInfoPlugin.linuxInfo;
          break;
        case TargetPlatform.macOS:
          _macOsInfo = await _deviceInfoPlugin.macOsInfo;
          break;
        case TargetPlatform.windows:
          _windowsInfo = await _deviceInfoPlugin.windowsInfo;
          break;
        default:
          break;
      }
    }

    return true;
  }

  @override
  Widget createAppWidgetWrapper(Widget child) {
    return Provider<DeviceInfoPlugin>.value(value: this, child: child);
  }

  /// If your test environment is [TargetPlatform.linux], [TargetPlatform.windows], Web,
  /// then it assumes that you want to override and specify [DeviceInfoPlatform.instance],
  /// so I'm not considering entering a branch.
  ///
  /// The functions used to overwrite [DeviceInfoPlatform] in each environment are:
  /// [TargetPlatform.linux] ... [DeviceInfoLinuxPlatform.registerWith]
  /// [TargetPlatform.windows] ... [DeviceInfoWindowsPlatform.registerWith]
  /// Web ... [DeviceInfoWebPlatform.registerWith]
  /// Check the lib/test/device_info_test.dart for usage examples.
  @override
  @visibleForTesting
  void setMockMethodCallHandler() {
    // ignore: invalid_use_of_visible_for_testing_member
    testSetMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/device_info'),
      (methodCall) async {
        methodCallLogs.add(methodCall);
        switch (methodCall.method) {
          case 'getDeviceInfo':
            switch (defaultTargetPlatform) {
              case TargetPlatform.android:
                return mockAndroidDeviceInfoMap;
              case TargetPlatform.iOS:
                return mockIosDeviceInfoMap;
              case TargetPlatform.macOS:
                return mockMacosDeviceInfoMap;
              default:
                break;
            }
        }
        return null;
      },
    );
  }

  // Declared in the same order as the source code
  // of [AndroidDeviceInfo.fromMap] to make it easier to compare.
  static const Map<String, dynamic> _defaultMockAndroidDeviceInfoMap =
      <String, dynamic>{
        'id': 'id',
        'host': 'host',
        'tags': 'tags',
        'type': 'type',
        'model': 'model',
        'board': 'board',
        'brand': 'Google',
        'device': 'device',
        'product': 'product',
        'display': 'display',
        'hardware': 'hardware',
        'bootloader': 'bootloader',
        'isPhysicalDevice': true,
        'fingerprint': 'fingerprint',
        'manufacturer': 'manufacturer',
        'supportedAbis': ['arm64-v8a', 'x86', 'x86_64'],
        'systemFeatures': ['FEATURE_AUDIO_PRO', 'FEATURE_AUDIO_OUTPUT'],
        'supported32BitAbis': ['x86 (IA-32)', 'MMX'],
        'supported64BitAbis': ['x86-64', 'MMX', 'SSSE3'],
        'version': <String, dynamic>{
          'sdkInt': 16,
          'baseOS': 'baseOS',
          'previewSdkInt': 30,
          'release': 'release',
          'codename': 'codename',
          'incremental': 'incremental',
          'securityPatch': 'securityPatch',
        },
        'serialNumber': 'SERIAL',
        'isLowRamDevice': false,
        'freeDiskSize': 1024,
        'totalDiskSize': 2024,
        'physicalRamSize': 8192,
        'availableRamSize': 4096,
      };

  @visibleForTesting
  static Map<String, dynamic> mockAndroidDeviceInfoMap =
      _defaultMockAndroidDeviceInfoMap;

  /// Mocks [AndroidDeviceInfo] for testing purposes.
  @visibleForTesting
  static void setMockAndroidDeviceInfo({
    String? id,
    String? host,
    String? tags,
    String? type,
    String? model,
    String? board,
    String? brand,
    String? device,
    String? product,
    String? display,
    String? hardware,
    String? bootloader,
    bool? isPhysicalDevice,
    String? fingerprint,
    String? manufacturer,
    List<String>? supportedAbis,
    List<String>? systemFeatures,
    List<String>? supported64BitAbis,
    List<String>? supported32BitAbis,
    Map<String, dynamic>? version,
    String? serialNumber,
    bool? isLowRamDevice,
    int? freeDiskSize,
    int? totalDiskSize,
    int? physicalRamSize,
    int? availableRamSize,
  }) {
    mockAndroidDeviceInfoMap = {
      'id': id ?? _defaultMockAndroidDeviceInfoMap['id'],
      'host': host ?? _defaultMockAndroidDeviceInfoMap['host'],
      'tags': tags ?? _defaultMockAndroidDeviceInfoMap['tags'],
      'type': type ?? _defaultMockAndroidDeviceInfoMap['type'],
      'model': model ?? _defaultMockAndroidDeviceInfoMap['model'],
      'board': board ?? _defaultMockAndroidDeviceInfoMap['board'],
      'brand': brand ?? _defaultMockAndroidDeviceInfoMap['brand'],
      'device': device ?? _defaultMockAndroidDeviceInfoMap['device'],
      'product': product ?? _defaultMockAndroidDeviceInfoMap['product'],
      'display': display ?? _defaultMockAndroidDeviceInfoMap['display'],
      'hardware': hardware ?? _defaultMockAndroidDeviceInfoMap['hardware'],
      'bootloader':
          bootloader ?? _defaultMockAndroidDeviceInfoMap['bootloader'],
      'isPhysicalDevice':
          isPhysicalDevice ??
          _defaultMockAndroidDeviceInfoMap['isPhysicalDevice'],
      'fingerprint':
          fingerprint ?? _defaultMockAndroidDeviceInfoMap['fingerprint'],
      'manufacturer':
          manufacturer ?? _defaultMockAndroidDeviceInfoMap['manufacturer'],
      'supportedAbis':
          supportedAbis ?? _defaultMockAndroidDeviceInfoMap['supportedAbis'],
      'systemFeatures':
          systemFeatures ?? _defaultMockAndroidDeviceInfoMap['systemFeatures'],
      'supported64BitAbis':
          supported64BitAbis ??
          _defaultMockAndroidDeviceInfoMap['supported64BitAbis'],
      'supported32BitAbis':
          supported32BitAbis ??
          _defaultMockAndroidDeviceInfoMap['supported32BitAbis'],
      'version': version ?? _defaultMockAndroidDeviceInfoMap['version'],
      'serialNumber':
          serialNumber ?? _defaultMockAndroidDeviceInfoMap['serialNumber'],
      'isLowRamDevice':
          isLowRamDevice ?? _defaultMockAndroidDeviceInfoMap['isLowRamDevice'],
      'freeDiskSize':
          freeDiskSize ?? _defaultMockAndroidDeviceInfoMap['freeDiskSize'],
      'totalDiskSize':
          totalDiskSize ?? _defaultMockAndroidDeviceInfoMap['totalDiskSize'],
      'physicalRamSize':
          physicalRamSize ??
          _defaultMockAndroidDeviceInfoMap['physicalRamSize'],
      'availableRamSize':
          availableRamSize ??
          _defaultMockAndroidDeviceInfoMap['availableRamSize'],
    };
  }

  @visibleForTesting
  static Map<String, dynamic> mockIosDeviceInfoMap = <String, dynamic>{
    'name': 'name',
    'model': 'model',
    'modelName': 'modelName',
    'utsname': <String, dynamic>{
      'release': 'release',
      'version': 'version',
      'machine': 'machine',
      'sysname': 'sysname',
      'nodename': 'nodename',
    },
    'systemName': 'systemName',
    'systemVersion': 'systemVersion',
    'isPhysicalDevice': true,
    'isiOSAppOnMac': true,
    'localizedModel': 'localizedModel',
    'identifierForVendor': 'identifierForVendor',
    'freeDiskSize': 1024,
    'totalDiskSize': 2024,
    'physicalRamSize': 8192,
    'availableRamSize': 4096,
  };

  /// Mocks [IosDeviceInfo] for testing purposes.
  @visibleForTesting
  static void setMockIosDeviceInfo({
    String? name,
    String? model,
    String? modelName,
    Map<String, dynamic>? utsname,
    String? systemName,
    String? systemVersion,
    bool? isPhysicalDevice,
    bool? isiOSAppOnMac,
    String? localizedModel,
    String? identifierForVendor,
    int? freeDiskSize,
    int? totalDiskSize,
    int? physicalRamSize,
    int? availableRamSize,
  }) {
    mockIosDeviceInfoMap = <String, dynamic>{
      'name': name ?? mockIosDeviceInfoMap['name'],
      'model': model ?? mockIosDeviceInfoMap['model'],
      'modelName': modelName ?? mockIosDeviceInfoMap['modelName'],
      'utsname': utsname ?? mockIosDeviceInfoMap['utsname'],
      'systemName': systemName ?? mockIosDeviceInfoMap['systemName'],
      'systemVersion': systemVersion ?? mockIosDeviceInfoMap['systemVersion'],
      'isPhysicalDevice':
          isPhysicalDevice ?? mockIosDeviceInfoMap['isPhysicalDevice'],
      'isiOSAppOnMac': isiOSAppOnMac ?? mockIosDeviceInfoMap['isiOSAppOnMac'],
      'localizedModel':
          localizedModel ?? mockIosDeviceInfoMap['localizedModel'],
      'identifierForVendor':
          identifierForVendor ?? mockIosDeviceInfoMap['identifierForVendor'],
      'freeDiskSize': freeDiskSize ?? mockIosDeviceInfoMap['freeDiskSize'],
      'totalDiskSize': totalDiskSize ?? mockIosDeviceInfoMap['totalDiskSize'],
      'physicalRamSize':
          physicalRamSize ?? mockIosDeviceInfoMap['physicalRamSize'],
      'availableRamSize':
          availableRamSize ?? mockIosDeviceInfoMap['availableRamSize'],
    };
  }

  @visibleForTesting
  static plugin.LinuxDeviceInfo mockLinuxDeviceInfo = plugin.LinuxDeviceInfo(
    name: 'name',
    version: 'version',
    id: 'id',
    idLike: ['idLike'],
    versionCodename: 'versionCodename',
    versionId: 'versionId',
    prettyName: 'prettyName',
    buildId: 'buildId',
    variant: 'variant',
    variantId: 'variantId',
    machineId: 'machineId',
  );

  /// Mocks [LinuxDeviceInfo] for testing purposes.
  @visibleForTesting
  static void setMockLinuxDeviceInfo({
    String? name,
    String? version,
    String? id,
    List<String>? idLike,
    String? versionCodename,
    String? versionId,
    String? prettyName,
    String? buildId,
    String? variant,
    String? variantId,
    String? machineId,
  }) {
    mockLinuxDeviceInfo = plugin.LinuxDeviceInfo(
      name: name ?? mockLinuxDeviceInfo.name,
      version: version ?? mockLinuxDeviceInfo.version,
      id: id ?? mockLinuxDeviceInfo.id,
      idLike: idLike ?? mockLinuxDeviceInfo.idLike,
      versionCodename: versionCodename ?? mockLinuxDeviceInfo.versionCodename,
      versionId: versionId ?? mockLinuxDeviceInfo.versionId,
      prettyName: prettyName ?? mockLinuxDeviceInfo.prettyName,
      buildId: buildId ?? mockLinuxDeviceInfo.buildId,
      variant: variant ?? mockLinuxDeviceInfo.variant,
      variantId: variantId ?? mockLinuxDeviceInfo.variantId,
      machineId: machineId ?? mockLinuxDeviceInfo.machineId,
    );
  }

  @visibleForTesting
  static Map<String, dynamic> mockMacosDeviceInfoMap = <String, dynamic>{
    'computerName': 'computerName',
    'hostName': 'hostName',
    'arch': 'arch',
    'model': 'model',
    'modelName': 'modelName',
    'kernelVersion': 'kernelVersion',
    'osRelease': 'osRelease',
    'majorVersion': 10,
    'minorVersion': 9,
    'patchVersion': 3,
    'activeCPUs': 4,
    'memorySize': 16,
    'cpuFrequency': 2,
    'systemGUID': 'systemGUID',
  };

  /// Mocks [MacOsDeviceInfo] for testing purposes.
  @visibleForTesting
  static void setMockMacosDeviceInfo({
    String? arch,
    String? model,
    String? modelName,
    int? activeCPUs,
    int? memorySize,
    int? cpuFrequency,
    String? hostName,
    String? osRelease,
    String? computerName,
    String? kernelVersion,
    String? systemGUID,
    int? majorVersion,
    int? minorVersion,
    int? patchVersion,
  }) {
    mockMacosDeviceInfoMap = <String, dynamic>{
      'arch': arch ?? mockMacosDeviceInfoMap['arch'],
      'model': model ?? mockMacosDeviceInfoMap['model'],
      'modelName': modelName ?? mockMacosDeviceInfoMap['modelName'],
      'activeCPUs': activeCPUs ?? mockMacosDeviceInfoMap['activeCPUs'],
      'memorySize': memorySize ?? mockMacosDeviceInfoMap['memorySize'],
      'cpuFrequency': cpuFrequency ?? mockMacosDeviceInfoMap['cpuFrequency'],
      'hostName': hostName ?? mockMacosDeviceInfoMap['hostName'],
      'osRelease': osRelease ?? mockMacosDeviceInfoMap['osRelease'],
      'computerName': computerName ?? mockMacosDeviceInfoMap['computerName'],
      'kernelVersion': kernelVersion ?? mockMacosDeviceInfoMap['kernelVersion'],
      'systemGUID': systemGUID ?? mockMacosDeviceInfoMap['systemGUID'],
      'majorVersion': majorVersion ?? mockMacosDeviceInfoMap['majorVersion'],
      'minorVersion': minorVersion ?? mockMacosDeviceInfoMap['minorVersion'],
      'patchVersion': patchVersion ?? mockMacosDeviceInfoMap['patchVersion'],
    };
  }

  @visibleForTesting
  static plugin.WindowsDeviceInfo mockWindowsDeviceInfo =
      plugin.WindowsDeviceInfo(
        computerName: 'computerName',
        numberOfCores: 4,
        systemMemoryInMegabytes: 16,
        userName: 'userName',
        majorVersion: 10,
        minorVersion: 0,
        buildNumber: 10240,
        platformId: 1,
        csdVersion: 'csdVersion',
        servicePackMajor: 1,
        servicePackMinor: 0,
        suitMask: 1,
        productType: 1,
        reserved: 1,
        buildLab: '22000.co_release.210604-1628',
        buildLabEx: '22000.1.amd64fre.co_release.210604-1628',
        digitalProductId: Uint8List.fromList([]),
        displayVersion: '21H2',
        editionId: 'Pro',
        installDate: DateTime(2022, 04, 02),
        productId: '00000-00000-0000-AAAAA',
        productName: 'Windows 10 Pro',
        registeredOwner: 'registeredOwner',
        releaseId: 'releaseId',
        deviceId: 'deviceId',
      );

  /// Mocks [WindowsDeviceInfo] for testing purposes.
  @visibleForTesting
  static void setMockWindowsDeviceInfo({
    String? computerName,
    int? numberOfCores,
    int? systemMemoryInMegabytes,
    String? userName,
    int? majorVersion,
    int? minorVersion,
    int? buildNumber,
    int? platformId,
    String? csdVersion,
    int? servicePackMajor,
    int? servicePackMinor,
    int? suitMask,
    int? productType,
    int? reserved,
    String? buildLab,
    String? buildLabEx,
    Uint8List? digitalProductId,
    String? displayVersion,
    String? editionId,
    DateTime? installDate,
    String? productId,
    String? productName,
    String? registeredOwner,
    String? releaseId,
    String? deviceId,
  }) {
    mockWindowsDeviceInfo = plugin.WindowsDeviceInfo(
      computerName: computerName ?? mockWindowsDeviceInfo.computerName,
      numberOfCores: numberOfCores ?? mockWindowsDeviceInfo.numberOfCores,
      systemMemoryInMegabytes:
          systemMemoryInMegabytes ??
          mockWindowsDeviceInfo.systemMemoryInMegabytes,
      userName: userName ?? mockWindowsDeviceInfo.userName,
      majorVersion: majorVersion ?? mockWindowsDeviceInfo.majorVersion,
      minorVersion: minorVersion ?? mockWindowsDeviceInfo.minorVersion,
      buildNumber: buildNumber ?? mockWindowsDeviceInfo.buildNumber,
      platformId: platformId ?? mockWindowsDeviceInfo.platformId,
      csdVersion: csdVersion ?? mockWindowsDeviceInfo.csdVersion,
      servicePackMajor:
          servicePackMajor ?? mockWindowsDeviceInfo.servicePackMajor,
      servicePackMinor:
          servicePackMinor ?? mockWindowsDeviceInfo.servicePackMinor,
      suitMask: suitMask ?? mockWindowsDeviceInfo.suitMask,
      productType: productType ?? mockWindowsDeviceInfo.productType,
      reserved: reserved ?? mockWindowsDeviceInfo.reserved,
      buildLab: buildLab ?? mockWindowsDeviceInfo.buildLab,
      buildLabEx: buildLabEx ?? mockWindowsDeviceInfo.buildLabEx,
      digitalProductId:
          digitalProductId ?? mockWindowsDeviceInfo.digitalProductId,
      displayVersion: displayVersion ?? mockWindowsDeviceInfo.displayVersion,
      editionId: editionId ?? mockWindowsDeviceInfo.editionId,
      installDate: installDate ?? mockWindowsDeviceInfo.installDate,
      productId: productId ?? mockWindowsDeviceInfo.productId,
      productName: productName ?? mockWindowsDeviceInfo.productName,
      registeredOwner: registeredOwner ?? mockWindowsDeviceInfo.registeredOwner,
      releaseId: releaseId ?? mockWindowsDeviceInfo.releaseId,
      deviceId: deviceId ?? mockWindowsDeviceInfo.deviceId,
    );
  }

  @visibleForTesting
  static Map<String, dynamic> mockWebBrowserInfoMap = <String, dynamic>{
    'browserName': plugin.BrowserName.safari,
    'appCodeName': 'appCodeName',
    'appName': 'appName',
    'appVersion': 'appVersion',
    'deviceMemory': 42.0,
    'language': 'language',
    'languages': ['en', 'es'],
    'platform': 'platform',
    'product': 'product',
    'productSub': 'productSub',
    'userAgent': 'Safari',
    'vendor': 'vendor',
    'vendorSub': 'vendorSub',
    'hardwareConcurrency': 2,
    'maxTouchPoints': 42,
  };

  /// Mocks [WebBrowserInfo] for testing purposes.
  @visibleForTesting
  static void setMockWebBrowserInfo({
    String? browserName,
    String? appCodeName,
    String? appName,
    String? appVersion,
    double? deviceMemory,
    String? language,
    List<String>? languages,
    String? platform,
    String? product,
    String? productSub,
    String? userAgent,
    String? vendor,
    String? vendorSub,
    int? hardwareConcurrency,
    int? maxTouchPoints,
  }) {
    mockWebBrowserInfoMap = <String, dynamic>{
      'browserName':
          browserName?.toBrowserName ?? mockWebBrowserInfoMap['browserName'],
      'appCodeName': appCodeName ?? mockWebBrowserInfoMap['appCodeName'],
      'appName': appName ?? mockWebBrowserInfoMap['appName'],
      'appVersion': appVersion ?? mockWebBrowserInfoMap['appVersion'],
      'deviceMemory': deviceMemory ?? mockWebBrowserInfoMap['deviceMemory'],
      'language': language ?? mockWebBrowserInfoMap['language'],
      'languages': languages ?? mockWebBrowserInfoMap['languages'],
      'platform': platform ?? mockWebBrowserInfoMap['platform'],
      'product': product ?? mockWebBrowserInfoMap['product'],
      'productSub': productSub ?? mockWebBrowserInfoMap['productSub'],
      'userAgent': userAgent ?? mockWebBrowserInfoMap['userAgent'],
      'vendor': vendor ?? mockWebBrowserInfoMap['vendor'],
      'vendorSub': vendorSub ?? mockWebBrowserInfoMap['vendorSub'],
      'hardwareConcurrency':
          hardwareConcurrency ?? mockWebBrowserInfoMap['hardwareConcurrency'],
      'maxTouchPoints':
          maxTouchPoints ?? mockWebBrowserInfoMap['maxTouchPoints'],
    };
  }
}

@visibleForTesting
bool debugIsWeb = false;

extension DeviceInfoStringExtension on String {
  plugin.BrowserName get toBrowserName {
    switch (toLowerCase()) {
      case 'firefox':
        return plugin.BrowserName.firefox;
      case 'samsunginternet':
        return plugin.BrowserName.samsungInternet;
      case 'opera':
        return plugin.BrowserName.opera;
      case 'msie':
        return plugin.BrowserName.msie;
      case 'edge':
        return plugin.BrowserName.edge;
      case 'chrome':
        return plugin.BrowserName.chrome;
      case 'safari':
        return plugin.BrowserName.safari;
      default:
        return plugin.BrowserName.unknown;
    }
  }
}

@visibleForTesting
class DeviceInfoLinuxPlatform extends DeviceInfoPlatform {
  static void registerWith() {
    DeviceInfoPlatform.instance = DeviceInfoLinuxPlatform();
  }

  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    return DeviceInfoPlugin.mockLinuxDeviceInfo;
  }
}

@visibleForTesting
class DeviceInfoWindowsPlatform extends DeviceInfoPlatform {
  static void registerWith() {
    DeviceInfoPlatform.instance = DeviceInfoWindowsPlatform();
  }

  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    return DeviceInfoPlugin.mockWindowsDeviceInfo;
  }
}

@visibleForTesting
class DeviceInfoWebPlatform extends DeviceInfoPlatform {
  static void registerWith() {
    DeviceInfoPlatform.instance = DeviceInfoWebPlatform();
  }

  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    return plugin.WebBrowserInfo.fromMap(
      DeviceInfoPlugin.mockWebBrowserInfoMap,
    );
  }
}
