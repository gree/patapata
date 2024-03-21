// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import FlutterMacOS

class NativeLocalConfig : PatapataPlugin {
    fileprivate let mChannel: FlutterMethodChannel
    fileprivate var mOnChangeListener: Any?
    fileprivate var mOnSizeLimitExceededListener: Any?
    fileprivate let mStore = UserDefaults(suiteName: "\(Bundle.main.bundleIdentifier ?? "unknown").dev.patapata.native_local_config") ?? UserDefaults.standard
    
    init(registrar: FlutterPluginRegistrar) {
        mChannel = FlutterMethodChannel(name: "dev.patapata.native_local_config", binaryMessenger: registrar.messenger)
    }
    
    public var patapataName: String = "dev.patapata.native_local_config"
    
    public func patapataEnable() {
        mChannel.setMethodCallHandler(handle)
        
        mOnChangeListener = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: mStore, queue: OperationQueue.main, using: onChange)
        
        syncStore()
    }
    
    fileprivate func syncStore() {
        let tDict = mStore.dictionaryRepresentation().filter {
            switch $0.value {
            case is Bool:
                return true
            case is Int:
                return true
            case is Double:
                return true
            case is String:
                return true
            default:
                return false
            }
        }
        
        mChannel.invokeMethod("syncAll", arguments: tDict)
    }
    
    fileprivate func onChange(_: Notification) {
        syncStore()
    }
    
    fileprivate func onSizeLimitExceeded(notification: Notification) {
        // mChannel.invokeMethod("error", arguments: <#T##Any?#>)
        // Should we send this? It could happen async from a set command
        // It could also happen from something not related to patapata at all...
    }
    
    public func patapataDisable() {
        mChannel.setMethodCallHandler(nil)
        NotificationCenter.default.removeObserver(mOnChangeListener!, name: UserDefaults.didChangeNotification, object: mStore)
        mOnChangeListener = nil
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "reset":
            mStore.removeObject(forKey: call.arguments as! String)
            result(nil)
            break
        case "resetMany":
            let tArgs = call.arguments as! Array<String>
            
            for i in tArgs {
                mStore.removeObject(forKey: i)
            }
            
            result(nil)
            break
        case "resetAll":
            for i in mStore.dictionaryRepresentation() {
                mStore.removeObject(forKey: i.key)
            }
            
            result(nil)
            break
        case "setBool":
            let tArgs = call.arguments as! Array<Any>
            mStore.set(tArgs[1] as! Bool, forKey: tArgs[0] as! String)
            result(nil)
            break
        case "setInt":
            let tArgs = call.arguments as! Array<Any>
            mStore.set(tArgs[1] as! Int, forKey: tArgs[0] as! String)
            result(nil)
            break
        case "setDouble":
            let tArgs = call.arguments as! Array<Any>
            mStore.set(tArgs[1] as! Double, forKey: tArgs[0] as! String)
            result(nil)
            break
        case "setString":
            let tArgs = call.arguments as! Array<Any>
            mStore.set(tArgs[1] as! String, forKey: tArgs[0] as! String)
            result(nil)
            break
        case "setMany":
            let tArgs = call.arguments as! Dictionary<String, Any>
            
            for i in tArgs {
                mStore.set(i.value, forKey: i.key)
            }
            
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
}
