// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:ffi' if (dart.library.js_interop) 'fake_ffi.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

final String _nativeLibDirectory = kIsWeb
    ? ''
    : defaultTargetPlatform == TargetPlatform.android
        ? (() {
            // TODO: This path is hardcoding. so cannot use App
            final tNativeLibDirTempFile =
                File('${Directory.systemTemp.path}/patapataNativeLib');

            if (tNativeLibDirTempFile.existsSync()) {
              try {
                return tNativeLibDirTempFile.readAsStringSync();
              } catch (_) {
                // ignore
                return '';
              }
            } else {
              return '';
            }
          })()
        : '';

DynamicLibrary safeLoadDynamicLibrary(String library) {
  if (_nativeLibDirectory.isNotEmpty) {
    try {
      return DynamicLibrary.open("$_nativeLibDirectory/lib$library.so");
    } catch (_) {
      try {
        final tLib = DynamicLibrary.open("lib$library.so");

        return tLib;
      } catch (_) {
        // On some (especially old) Android devices, we somehow can't dlopen
        // libraries shipped with the apk. We need to find the full path of the
        // library and open that one.
        // For details, see https://github.com/simolus3/moor/issues/420
        final tAppIdAsBytes = File('/proc/self/cmdline').readAsBytesSync();

        // app id ends with the first \0 character in here.
        final tEndOfAppId = max(tAppIdAsBytes.indexOf(0), 0);
        final tAppId =
            String.fromCharCodes(tAppIdAsBytes.sublist(0, tEndOfAppId));

        return DynamicLibrary.open('/data/data/$tAppId/lib/lib$library.so');
      }
    }
  } else {
    return DynamicLibrary.open("lib$library.so");
  }
}
