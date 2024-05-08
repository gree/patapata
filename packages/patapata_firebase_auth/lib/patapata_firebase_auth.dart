// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
library patapata_firebase_auth;

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';

/// A plugin that provides functionality for Firebase Authentication.
/// This plugin requires adding the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) package to your application.
class FirebaseAuthPlugin extends Plugin {
  /// A reference to the [firebase.FirebaseAuth] instance.
  late final firebase.FirebaseAuth instance;

  /// A StreamSubscription for [firebase.User?] type.
  /// This can be used to listen to changes in the user's authentication status.
  StreamSubscription<firebase.User?>? userSubscription;

  /// Initializes the [FirebaseAuthPlugin].
  @override
  FutureOr<bool> init(App app) async {
    await super.init(app);

    instance = firebase.FirebaseAuth.instance;

    enableUserChangesSubscription();

    return true;
  }

  /// Synchronize User.id in App and User.uid logged in Firebase.
  ///
  /// To enable this functionality, you need to call this function
  /// after creating the [App] instance.
  /// For example:
  /// ```dart
  /// void main() async {
  ///   final App tApp = App(
  ///     environment: ...,
  ///     plugins: [
  ///       ...,
  ///       FirebaseAuthPlugin(),
  ///       ...,
  ///     ],
  ///     createAppWidget: ...,
  ///  );
  ///
  ///   tApp.run();
  /// }
  /// ```
  void enableUserChangesSubscription() async {
    userSubscription = instance.userChanges().listen(
      (user) {
        if (user != null && user.uid != app.user.id) {
          app.user.changeId(user.uid);
        }
      },
    );
  }

  /// Dispose the [FirebaseAuthPlugin].
  @override
  FutureOr<void> dispose() async {
    await super.dispose();

    userSubscription?.cancel();
    userSubscription = null;
  }
}
