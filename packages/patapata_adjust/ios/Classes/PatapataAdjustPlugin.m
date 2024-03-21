// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

#import "PatapataAdjustPlugin.h"
#if __has_include(<patapata_adjust/patapata_adjust-Swift.h>)
#import <patapata_adjust/patapata_adjust-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "patapata_adjust-Swift.h"
#endif

@implementation PatapataAdjustPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPatapataAdjustPlugin registerWithRegistrar:registrar];
}
@end
