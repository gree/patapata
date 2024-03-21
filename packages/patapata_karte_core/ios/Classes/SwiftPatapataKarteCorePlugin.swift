// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import Flutter
import UIKit
import KarteCore

public class SwiftPatapataKarteCorePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        if let tData = Bundle.main.infoDictionary, let tKey = tData["patapata_karte_app_key"] as? String {
            // KarteApp.setLogLevel(.debug)
            let tEnvironment = ProcessInfo().environment
            // Karte fails to setup with a crash in a XCTest environment
            if (tEnvironment["XCTestConfigurationFilePath"] == nil) {
                KarteApp.setup(appKey: tKey)
                KarteApp.optOut()
            }
        }
    }
}
