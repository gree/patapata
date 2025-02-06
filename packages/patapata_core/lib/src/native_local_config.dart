// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'local_config.dart';
import 'plugin.dart';

import '../finder/local_config_finder.dart'
    if (dart.library.io) '../src/native_local_config_finder.dart'
    if (dart.library.js_interop) '../web/web_local_config_finder.dart';

/// This is an abstract class that utilizes conditional import functionality
/// to handle [LocalConfigFinder] in both the app environment and web environment
/// using a common source code.
/// In the app environment, it functions as [NativeLocalConfigFinder],
/// while in the web environment, it functions as [WebLocalConfigFinder].
///
/// Please refer to the reference below for information on conditional imports.
/// https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files
abstract class LocalConfigFinder {
  factory LocalConfigFinder() => getLocalConfigFinder();
  LocalConfig? getLocalConfig() => null; // coverage:ignore-line
}

final LocalConfigFinder _finder = LocalConfigFinder();

class NativeLocalConfigPlugin extends Plugin {
  @override
  String get name => 'dev.patapata.native_local_config';

  @override
  LocalConfig? createLocalConfig() => _finder.getLocalConfig();
}
