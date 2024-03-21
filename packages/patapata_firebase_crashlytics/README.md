<div align="center">
  <h1>Patapata - Firebase Crashlytics</h1>
  <p>
    <strong>Add support for <a href="https://firebase.google.com/docs/crashlytics/">Firebase Crashlytics</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics/) to your Patapata app.
It will automatically report errors and logs to Firebase Crashlytics from Patapata's Log and Error systems.

This plugin requires the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) plugin to be installed and activated.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_firebase_crashlytics
```

2. Import the package

```dart
import 'package:patapata_firebase_crashlytics/patapata_firebase_crashlytics.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      FirebaseCorePlugin(),
      FirebaseCrashlyticsPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_firebase_crashlytics/LICENSE)
