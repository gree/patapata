<div align="center">
  <h1>Patapata - Firebase Analytics</h1>
  <p>
    <strong>Add support for <a href="https://firebase.google.com/docs/analytics/">Firebase Analytics</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Firebase Analytics](https://firebase.google.com/docs/analytics/) to your Patapata app.
It will automatically log analytics events to Firebase Analytics from Patapata's Analytics system.

This plugin requires the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) plugin to be installed and activated.

---

Due to a bug in the FlutterFire CLI, the stable version of 0.2.7 (at the time of writing this README) does not write out the required paramaters to run firebase_analytics correctly.

A temporary workaround is to use the dev version of the cli and run `flutterfire configure` again.
https://github.com/invertase/flutterfire_cli/issues/210#issuecomment-1770505141

The above still might not be enough in some cases.
If you are still having issues, try the following:
- Add `classpath 'com.google.gms:google-services:4.3.14'` to `android/build.gradle`. Make sure the version is exactly that.
- Add `apply plugin: 'com.google.gms.google-services'` to `android/app/build.gradle` at the bottom of the file.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_firebase_analytics
```

2. Import the package

```dart
import 'package:patapata_firebase_analytics/patapata_firebase_analytics.dart';
```

4. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      FirebaseCorePlugin(),
      FirebaseAnalyticsPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_firebase_analytics/LICENSE)
