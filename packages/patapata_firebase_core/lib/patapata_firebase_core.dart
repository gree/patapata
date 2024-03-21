// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_firebase_core;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:patapata_core/patapata_core.dart';

export 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Configuration for Firebase in the application, used by [FirebaseCorePlugin].
mixin FirebaseCorePluginEnvironment {
  /// The name of Firebase to pass to [Firebase.initializeApp].
  String? get firebaseName => null;

  /// The options of Firebase to pass to [Firebase.initializeApp].
  Map<TargetPlatform, FirebaseOptions>? get firebaseOptions => null;

  /// The options for the web platform of Firebase to pass to [Firebase.initializeApp].
  FirebaseOptions? get firebaseWebOptions => null;
}

/// A plugin that provides FirebaseCore functionality.
/// This plugin is required when adding Firebase to an application that uses Patapata.
class FirebaseCorePlugin extends Plugin {
  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    final tEnvironment = app.environment is FirebaseCorePluginEnvironment
        ? app.environment as FirebaseCorePluginEnvironment
        : null;

    await Firebase.initializeApp(
      name: tEnvironment?.firebaseName,
      options: kIsWeb
          ? tEnvironment?.firebaseWebOptions
          : tEnvironment?.firebaseOptions?[defaultTargetPlatform],
    );

    return true;
  }
}
