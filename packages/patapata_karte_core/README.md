<div align="center">
  <h1>Patapata - Karte Core</h1>
  <p>
    <strong>Add support for <a href="https://karte.io/">Karte</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Karte](https://karte.io/) to your Patapata app.
It will automatically send events to Karte from Patapata's Analytics system.
It will also integrate with Patapata's User system and automatically send user information to Karte.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```yaml
dependencies:
  patapata_karte_core:
    git:
      url: git://github.com/gree/patapata.git
      path: packages/patapata_karte_core
```

2. Add settings to Android
Add a string resource to `android/app/src/main/res/values/strings.xml` with name `patapata_karte_app_key` and value your Karte app key.

```xml
<string name="patapata_karte_app_key">YOUR_APP_KEY</string>
```

3. Add settings to iOS
Add a string resource to `ios/Runner/Info.plist` with name `patapata_karte_app_key` and value your Karte app key.

```xml
<key>patapata_karte_app_key</key>
<string>YOUR_APP_KEY</string>
```

4. Import the package

```dart
import 'package:patapata_karte_core/patapata_karte_core.dart';
```

5. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      KarteCorePlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_karte_core/LICENSE)