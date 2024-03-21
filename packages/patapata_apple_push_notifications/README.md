<div align="center">
  <h1>Patapata - Apple Push Notifications</h1>
  <p>
    <strong>Add support for <a href="https://developer.apple.com/documentation/usernotifications">Apple Push Notifications</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications) to your Patapata app.
It will automatically integrate with Patapata's RemoteMessaging system and register for push notifications and provide access to APNs tokens.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_apple_push_notifications
```

2. Import the package

```dart
import 'package:patapata_apple_push_notifications/patapata_apple_push_notifications.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      ApplePushNotificationsPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_apple_push_notifications/LICENSE)