// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

#import "PatapataApplePushNotificationsPlugin.h"
#if __has_include(<patapata_apple_push_notifications/patapata_apple_push_notifications-Swift.h>)
#import <patapata_apple_push_notifications/patapata_apple_push_notifications-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "patapata_apple_push_notifications-Swift.h"
#endif

@implementation PatapataApplePushNotificationsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPatapataApplePushNotificationsPlugin registerWithRegistrar:registrar];
}
@end
