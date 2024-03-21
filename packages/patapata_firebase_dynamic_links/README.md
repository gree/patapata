<div align="center">
  <h1>Patapata - Firebase Dynamic Links</h1>
  <p>
    <strong>Add support for <a href="https://firebase.google.com/docs/dynamic-links/">Firebase Dynamic Links</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Firebase Dynamic Links](https://firebase.google.com/docs/dynamic-links/) to your Patapata app.

It will automatically handle dynamic links from Firebase and send them to Patapata's Link system.

This plugin requires the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) plugin to be installed and activated.

---

***Firebase Dynamic Links is deprecated by Google***

Patapata and StandardApp supports features like Apple's Universal Links and Android's App Links, which also provide the ability to open your app from a link.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_firebase_dynamic_links
```

2. Import the package

```dart
import 'package:patapata_firebase_dynamic_links/patapata_firebase_dynamic_links.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      FirebaseCorePlugin(),
      FirebaseDynamicLinksPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_firebase_dynamic_links/LICENSE)
