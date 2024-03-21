<div align="center">
  <h1>Patapata - Karte Variables</h1>
  <p>
    <strong>Add support for <a href="https://pub.dev/packages/karte_variables">Karte Variables</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Karte Variables](https://pub.dev/packages/karte_variables) to your Patapata app.
It will automatically fetch variables from Karte and make them available in your app via Patapata's RemoteConfig system.

This plugin requires [Patapata Karte Core](https://github.com/gree/patapata/packages/patapata_karte_core) to be installed and configured.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```yaml
dependencies:
  patapata_karte_variables:
    git:
      url: git://github.com/gree/patapata.git
      path: packages/patapata_karte_variables
```

2. Import the package

```dart
import 'package:patapata_karte_variables/patapata_karte_variables.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      KarteCorePlugin(),
      KarteVariablesPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_karte_variables/LICENSE)