// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import Flutter
import UIKit
import patapata_core

public class SwiftPatapataApplePushNotificationsPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate, PatapataPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let tInstance = SwiftPatapataApplePushNotificationsPlugin(registrar: registrar)
        registrar.registerPatapata(plugin: tInstance)
    }
    
    fileprivate let mChannel: FlutterMethodChannel
    fileprivate var mTokenData: String?
    fileprivate var mInitialNotification: [String: Any]?
    
    fileprivate var mEnabled = false
    
    init(registrar: FlutterPluginRegistrar) {
        mChannel = FlutterMethodChannel(name: "dev.patapata.patapata_apple_push_notifications", binaryMessenger: registrar.messenger())
        
        super.init()
        
        registrar.addMethodCallDelegate(self, channel: mChannel)
        registrar.addApplicationDelegate(self)
    }

    public var patapataName = "dev.patapata.patapata_apple_push_notifications"
    
    public func patapataEnable() {
        guard !mEnabled else {
            return
        }
        
        mEnabled = true
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        
        if (mTokenData != nil) {
            notifyUpdatedAPNsToken()
        }
    }
    
    public func patapataDisable() {
        guard mEnabled else {
            return
        }
        
        mEnabled = false
        mTokenData = nil
        UNUserNotificationCenter.current().delegate = nil
        UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getToken":
            result(mTokenData)
            break
        case "requestPermission":
            requestPermission(result: result)
            break
        case "getInitialNotification":
            getInitialNotification(result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    private func requestPermission(result: @escaping FlutterResult) {
        guard mEnabled else {
            result(false)
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .badge, .sound
        ]) {
            succeeded, error in
            result(succeeded)
        }
    }
    
    private func getInitialNotification(result: @escaping FlutterResult) {
        let tInitialNotification = mInitialNotification
        mInitialNotification = nil
        result(tInitialNotification)
    }
    
    private func dictionaryFromNotificationResponse(notification: UNNotificationResponse) -> [String : Any] {
        let tDateFormatter = ISO8601DateFormatter()
        let tNotification = notification.notification
        
        return [
            "actionIdentifier": notification.actionIdentifier,
            "notification": [
                "date": tDateFormatter.string(from: tNotification.date),
                "request": [
                    "identifier": tNotification.request.identifier,
                    "content": [
                        "title": tNotification.request.content.title,
                        "body": tNotification.request.content.body,
                        "userInfo": tNotification.request.content.userInfo
                    ]
                ]
            ]
        ]
    }
    
    private func getTokenString(deviceToken: Data) -> String {
        return deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    private func notifyUpdatedAPNsToken() {
        guard mEnabled else {
            return
        }
        
        mChannel.invokeMethod("updateAPNsToken", arguments: mTokenData)
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        guard mEnabled else {
            return
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        mTokenData = getTokenString(deviceToken: deviceToken)
        notifyUpdatedAPNsToken()
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard mEnabled else {
            return false
        }
        
        if UIApplication.shared.applicationState == .background {
            // No need to handle BG data
            completionHandler(.newData)
        } else {
            mChannel.invokeMethod("didReceiveRemoteNotification", arguments: userInfo)
            completionHandler(.noData)
        }
        
        return true
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                             willPresent notification: UNNotification,
                             withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        mInitialNotification = dictionaryFromNotificationResponse(notification: response)
        UIApplication.shared.applicationIconBadgeNumber = 0
        mChannel.invokeMethod("didReceiveNotificationResponse", arguments: mInitialNotification)
        completionHandler()
    }
}
