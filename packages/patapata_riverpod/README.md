<div align="center">
  <h1>Patapata - Riverpod</h1>
  <p>
    <strong>Add support for <a href="https://pub.dev/packages/riverpod">Riverpod</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Riverpod](https://pub.dev/packages/riverpod) to your Patapata app.

It will automatically inject your app's environment into your Riverpod providers.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_riverpod
```

2. Import the package

```dart
import 'package:patapata_riverpod/patapata_riverpod.dart';
```

3. Activate the plugin

```dart
void main() {
  App(
    environment: const Environment(),
    plugins: [
      RiverpodPlugin(),
    ],
  )
  .run();
}
```

4. See the providers you can use by reading the [API documentation](https://pub.dev/documentation/patapata_riverpod/latest/patapata_riverpod/patapata_riverpod-library.html).

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_riverpod/LICENSE)