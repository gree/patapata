// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

/// This is a page demonstrating how to use DeviceInfo and PackageInfo.
class DeviceAndPackageInfoPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    // Get the device model name.
    // If the platform is Web, you can retrieve the browser name.
    String model = "";
    if (kIsWeb) {
      model = getApp().device.webInfo!.browserName.toString();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      model = getApp().device.androidDeviceInfo!.model;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      model = getApp().device.iosDeviceInfo!.model;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      model = getApp().device.windowsInfo!.computerName;
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      model = getApp().device.linuxInfo!.prettyName;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      model = getApp().device.macOsInfo!.model;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.device_and_package_info.title')),
      ),
      body: ListView(
        children: [
          Center(
            child: Text(
              l(context, 'pages.device_and_package_info.body'),
            ),
          ),
          Table(
            border: TableBorder.all(),
            children: [
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                      child: Text(
                          l(context, 'pages.device_and_package_info.model')),
                    ),
                  ),
                  TableCell(
                    child: Center(child: Text(model)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                      child: Text(
                          l(context, 'pages.device_and_package_info.app_name')),
                    ),
                  ),
                  TableCell(
                    // Get the app name from PackageInfo.
                    child: Center(child: Text(getApp().package.info.appName)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                        child: Text(l(context,
                            'pages.device_and_package_info.build_number'))),
                  ),
                  TableCell(
                    // Get the build number from PackageInfo.
                    child:
                        Center(child: Text(getApp().package.info.buildNumber)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                        child: Text(l(context,
                            'pages.device_and_package_info.build_signature'))),
                  ),
                  TableCell(
                    // Get the build signature from PackageInfo.
                    child: Center(
                        child: Text(getApp().package.info.buildSignature)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                        child: Text(l(context,
                            'pages.device_and_package_info.package_name'))),
                  ),
                  TableCell(
                    // Get the package name from PackageInfo.
                    child:
                        Center(child: Text(getApp().package.info.packageName)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                        child: Text(l(
                            context, 'pages.device_and_package_info.version'))),
                  ),
                  // Get the app version from PackageInfo.
                  TableCell(
                    child: Center(child: Text(getApp().package.info.version)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
