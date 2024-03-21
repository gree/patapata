<div align="center">
  <h1>Patapata - AppsFlyer</h1>
  <p>
    <strong>Add support for <a href="https://www.appsflyer.com/">AppsFlyer</a> to your Patapata app.</strong>
  </p>
</div>

---

## About
This package is a plugin for [Patapata](https://pub.dev/packages/patapata_core) that adds support for [AppsFlyer](https://www.appsflyer.com/) to your Patapata app.
It currently only supports setting the user ID for AppsFlyer via the `setCustomerUserId` method, as well as registering for conversion data callbacks.

## Getting started

1. Add the dependency to your `pubspec.yaml` file

```yaml
dependencies:
  patapata_apps_flyer:
    git:
      url: git://github.com/gree/patapata.git
      path: packages/patapata_apps_flyer
```

2. Import the package

```dart
import 'package:patapata_apps_flyer/patapata_apps_flyer.dart';
```

3. Activate the plugin

```dart
/// This Environment takes AppsFlyer configuration from environment variables.
/// Pass environment variables to your app using the `--dart-define` flag.
class Environment extends AppsFlyerPluginEnvironment {
  const Environment();

    /// The AppsFlyer devKey.
    @override
    String get appsFlyerDevKey => const String.fromEnvironment('APPS_FLYER_DEV_KEY');

    /// AppsFlyer's iOS `appId`.
    @override
    String get appsFlyerAppIdIOS => const String.fromEnvironment('APPS_FLYER_APP_ID_IOS');

    /// AppsFlyer's Android `appId`.
    @override
    String get appsFlyerAppIdAndroid => const String.fromEnvironment('APPS_FLYER_APP_ID_ANDROID');
}

void main() {
  App(
    environment: const Environment(),
    plugins: [
      AppsFlyerPlugin(),
    ],
  )
  .run();
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_apps_flyer/LICENSE)