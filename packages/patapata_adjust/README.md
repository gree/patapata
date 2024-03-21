<div align="center">
  <h1>Patapata - Adjust</h1>
  <p>
    <strong>Add support for <a href="https://www.adjust.com/">Adjust</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [Adjust](https://www.adjust.com/) to your Patapata app.
It will automatically send events to Adjust from Patapata's Analytics system.
It will also integrate with Patapata's User system and automatically send user information to Adjust by setting the Adjust SDK's `user_id` session callback parameter.

This plugin will only start sending events to Adjust once Patapata's tracking permission has been processed at least once via `getApp().permissions.requestTracking()`.

This plugin does not support any of the other features of Adjust, such as attribution or push notifications.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```yaml
dependencies:
  patapata_adjust:
    git:
      url: git://github.com/gree/patapata.git
      path: packages/patapata_adjust
```

2. Import the package

```dart
import 'package:patapata_adjust/patapata_adjust.dart';
```

3. Activate the plugin

```dart
/// This Environment takes adjust configuration from environment variables.
/// Pass environment variables to your app using the `--dart-define` flag.
class Environment extends AdjustPluginEnvironment {
  const Environment();

  /// The app token issued when adding the app on Adjust's dashboard.
  @override
  String get adjustAppToken => const String.fromEnvironment('ADJUST_APP_TOKEN');

  /// The environment for Adjust. Refer to the values in [AdjustEnvironment].
  @override
  String get adjustEnvironment => const String.fromEnvironment('ADJUST_ENVIRONMENT');

  /// The log level for Adjust. Refer to the values in [AdjustLogLevel].
  @override
  String? get adjustLogLevel => const String.fromEnvironment('ADJUST_LOG_LEVEL');
}

void main() {
  App(
    environment: const Environment(),
    plugins: [
      AdjustPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_adjust/LICENSE)