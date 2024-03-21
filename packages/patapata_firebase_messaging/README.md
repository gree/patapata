<div align="center">
  <h1>Patapata - Firebase Cloud Messaging</h1>
  <p>
    <strong>Add support for <a href="https://firebase.google.com/docs/cloud-messaging/">Firebase Cloud Messaging</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/) to your Patapata app.
It will automatically handle push notifications from Firebase and send them to Patapata's Notification system.

This plugin requires the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) plugin to be installed and activated.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_firebase_messaging
```

2. Import the package

```dart
import 'package:patapata_firebase_messaging/patapata_firebase_messaging.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      FirebaseCorePlugin(),
      FirebaseMessagingPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_firebase_messaging/LICENSE)
