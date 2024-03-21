// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import Flutter
import UIKit
import AppTrackingTransparency

fileprivate var sPlugins = Set<PatapataPluginContainer>()

public class PatapataCorePlugin: NSObject, FlutterPlugin {
    let mRegistrar: FlutterPluginRegistrar
    let mChannel: FlutterMethodChannel
    
    init(registrar: FlutterPluginRegistrar) {
        mRegistrar = registrar
        mChannel = FlutterMethodChannel(name: "dev.patapata.patapata_core", binaryMessenger: registrar.messenger())
        
        super.init()
        
        registrar.addMethodCallDelegate(self, channel: mChannel)
        
        // Register default plugins.
        registrar.registerPatapata(plugin: NativeLocalConfig(registrar: registrar))
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let _ = PatapataCorePlugin(registrar: registrar)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enablePlugin":
            guard let tName = call.arguments as? String else {
                result(FlutterError(code: "PPE000", message: "Invalid plugin name passed to enablePlugin", details: nil))
                
                return
            }
            
            enablePlugin(with: tName)
            result(nil)
        case "disablePlugin":
            guard let tName = call.arguments as? String else {
                result(FlutterError(code: "PPE000", message: "Invalid plugin name passed to disablePlugin", details: nil))
                
                return
            }
            
            disablePlugin(with: tName)
            result(nil)
        case "Permissions:requestTracking":
            requestTrackingPermission(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func enablePlugin(with pluginName: String) {
        for i in sPlugins {
            guard i.plugin.patapataName == pluginName && i.registrar.messenger().hash == mRegistrar.messenger().hash else {
                continue
            }
            
            i.plugin.patapataEnable();
        }
    }
    
    public func disablePlugin(with pluginName: String) {
        for i in sPlugins {
            guard i.plugin.patapataName == pluginName && i.registrar.messenger().hash == mRegistrar.messenger().hash else {
                continue
            }
            
            i.plugin.patapataDisable()
        }
    }
    
    func requestTrackingPermission(_ result: @escaping FlutterResult) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { (status) in
                switch status {
                case .authorized:
                    result("authorized")
                    break
                case .denied:
                    result("denied")
                    break
                case .notDetermined:
                    result("notDetermined")
                    break
                case .restricted:
                    result("restricted")
                    break
                default:
                    result(nil)
                }
            }
        } else {
            result(nil)
        }
    }
}

fileprivate struct PatapataPluginContainer : Hashable {
    let plugin: PatapataPlugin
    let registrar: FlutterPluginRegistrar
    
    static func == (lhs: PatapataPluginContainer, rhs: PatapataPluginContainer) -> Bool {
        return lhs.plugin.patapataName == rhs.plugin.patapataName && lhs.registrar.messenger().hash == rhs.registrar.messenger().hash
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(plugin.patapataName)
        hasher.combine(registrar.messenger().hash)
    }
}


extension FlutterPluginRegistrar {
    public func registerPatapata(plugin: PatapataPlugin) {
        sPlugins.insert(PatapataPluginContainer(plugin: plugin, registrar: self))
    }
    
    public func unregisterPatapata(plugin: PatapataPlugin) {
        sPlugins.remove(PatapataPluginContainer(plugin: plugin, registrar: self))
    }
}
