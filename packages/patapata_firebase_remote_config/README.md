<div align="center">
  <h1>Patapata - Firebase Remote Config</h1>
  <p>
    <strong>Add support for <a href="https://firebase.google.com/docs/remote-config/">Firebase Remote Config</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Firebase Remote Config](https://firebase.google.com/docs/remote-config/) to your Patapata app.
It will automatically fetch remote config values from Firebase and send them to Patapata's RemoteConfig system.

This plugin requires the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) plugin to be installed and activated.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_firebase_remote_config
```

2. Import the package

```dart
import 'package:patapata_firebase_remote_config/patapata_firebase_remote_config.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      FirebaseCorePlugin(),
      FirebaseRemoteConfigPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_firebase_remote_config/LICENSE)
