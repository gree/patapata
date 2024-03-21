<div align="center">
  <h1>Patapata - Firebase Core</h1>
  <p>
    <strong>Add support for <a href="https://firebase.google.com/">Firebase</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Firebase](https://firebase.google.com/) to your Patapata app.

This plugin itself just initializes Firebase. It does not do anything else itself. You will need to add other plugins to your app to use Firebase features.

## Getting started

1. Follow the instructions for your platform to set up Firebase at https://firebase.google.com/docs/flutter/setup, up until just after executing `flutterfire configure`.

2. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_firebase_core
```

3. Import the package and the settings from your `firebase_options.dart` file

```dart
import 'package:patapata_firebase_core/patapata_firebase_core.dart';
import 'firebase_options.dart';
```

4. Activate the plugin

```dart
/// This Environment takes Firebase configuration from environment variables.
/// Pass environment variables to your app using the `--dart-define` flag.
class Environment with FirebaseCorePluginEnvironment {
  const Environment();

  /// The options of Firebase to pass to [Firebase.initializeApp].
  /// You can keep this null if you use the old google_services.json method.
  /// If you want to support a web project as well, the [FirebaseCorePluginEnvironment.firebaseWebOptions]
  /// getter is also available.
  @override
  Map<TargetPlatform, FirebaseOptions>? get firebaseOptions => {
        TargetPlatform.android: DefaultFirebaseOptions.android,
        /// etc...
      };
}

void main() {
  App(
    environment: const Environment(),
    plugins: [
      FirebaseCorePlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_firebase_core/LICENSE)