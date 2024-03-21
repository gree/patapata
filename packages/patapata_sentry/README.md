<div align="center">
  <h1>Patapata - Sentry</h1>
  <p>
    <strong>Add support for <a href="https://sentry.io">Sentry</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Sentry](https://sentry.io) to your Patapata app.

It will integrate with the Patapata error handling and log systems and automatically report errors to Sentry.
It will also integrate with Patapata's User system and automatically send user information to Sentry.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```sh
flutter pub add patapata_sentry
```

2. Import the package

```dart
import 'package:patapata_sentry/patapata_sentry.dart';
```

3. Activate the plugin

```dart
/// This Environment takes sentry configuration from environment variables.
/// Pass environment variables to your app using the `--dart-define` flag.
class Environment with SentryPluginEnvironment {
  const Environment();

  /// This is the DSN for the Sentry project you want to send errors to.
  @override
  String get sentryDSN => const String.fromEnvironment('SENTRY_DSN');

  /// Just as an example, we're using environment variables to configure
  /// Sentry's environment and dist. You can modify any of the options.
  @override
  FutureOr<void> Function(SentryFlutterOptions)? get sentryOptions =>
      (options) => options
        ..environment = const String.fromEnvironment('SENTRY_ENVIRONMENT')
        ..dist = const String.fromEnvironment('SENTRY_DIST');
}

void main() {
  App(
    environment: const Environment(),
    plugins: [
      SentryPlugin(),
    ],
  )
  .run();
}
```

## Extra configuration

You can change the traces sample rate and and sample rate via RemoteConfig by setting the following keys:
- `patapata_sentry_plugin_tracessamplerate`: (`SentryOptions.tracesSampleRate`)[https://pub.dev/documentation/sentry_flutter/latest/sentry_flutter/SentryOptions/tracesSampleRate.html]
- `patapata_sentry_plugin_samplerate`: (`SentryOptions.sampleRate`)[https://pub.dev/documentation/sentry_flutter/latest/sentry_flutter/SentryOptions/sampleRate.html]

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_sentry/LICENSE)