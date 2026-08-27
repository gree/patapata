<div align="center">
  <h1>Patapata</h1>

  <div align="center">
      <img src="https://github.com/gree/patapata/raw/main/assets/logo_pata2_horizontal.png" width="500"/>
  </div>

  <p>
    <strong>A collection of best-practices and tools for building applications quickly and reliably.</strong>
  </p>

  <h4>
    <a href="https://github.com/gree/patapata">Project Homepage</a>
  </h4>

  <p align="center">
    <a href="https://github.com/gree/patapata/actions">
      <img alt="GitHub Workflow Status (branch)" src="https://img.shields.io/github/actions/workflow/status/gree/patapata/check.yml?branch=main"/>
    </a>
    <a href="https://pub.dev/packages/patapata_core">
      <img alt="Pub Popularity" src="https://img.shields.io/pub/popularity/patapata_core?"/>
    </a>
    <a href="https://github.com/invertase/melos">
      <img src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg" alt="Maintained with Melos" />
    </a>
    <a href="LICENSE">
      <img alt="License" src="https://img.shields.io/github/license/gree/patapata"/>
    </a>
    <a href="https://codecov.io/gh/gree/patapata">
      <img src="https://codecov.io/gh/gree/patapata/branch/main/graph/badge.svg"/>
    </a>
  </p>

</div>

---

[[Changelog]](https://github.com/gree/patapata/blob/main/CHANGELOG.md) • [[Packages]](https://pub.dev/publishers/gree.co.jp/packages)

---

Patapata is a framework built on Flutter for creating applications of production quality quickly and reliably.
It provides a collection of best-practices built directly in to the various APIs so you can build apps that are consistent, stable, and performant.

[Flutter](https://flutter.dev) is Google’s UI toolkit for building beautiful, natively compiled applications for mobile,
web, and desktop from a single codebase. Flutter is used by developers and organizations around the world, and is free
and open source.

---

## Documentation

**If you just want to jump in and get Patapata working without any plugins or reading the documentation, check out [![patapata_core pub.dev badge](https://img.shields.io/pub/v/patapata_core.svg?label=patapata_core)](https://pub.dev/packages/patapata_core).**

Most of our documentation is within the [patapata_core](https://github.com/gree/patapata/blob/main/packages/patapata_core/README.md) package, so start there.

If you want documentation on the various plugins we provide, check out the plugin sections below.

## Stable Plugins

| Name                   | pub.dev                                                                                                                                             | Related Product                                                                                                                                                             | Documentation                                                     | View Source                                                                                                                     | Android | iOS | Web | MacOS | Windows | Linux
|------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------------------------:|:---------:|:-----:|:-----:|:-------:|:-------:|:-------:|
| Apple Push Notifications | [![patapata_apple_push_notifications pub.dev badge](https://img.shields.io/pub/v/patapata_apple_push_notifications.svg)](https://pub.dev/packages/patapata_apple_push_notifications) | [🔗](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns) | [📖](https://pub.dev/documentation/patapata_apple_push_notifications/latest/) | [`patapata_apple_push_notifications`](https://github.com/gree/patapata/tree/main/packages/patapata_apple_push_notifications) | ✖︎ | ✔ | ✖︎ | ✔ | ✖︎ | ✖︎ |
| Firebase Analytics | [![patapata_firebase_analytics pub.dev badge](https://img.shields.io/pub/v/patapata_firebase_analytics.svg)](https://pub.dev/packages/patapata_firebase_analytics) | [🔗](https://firebase.google.com/docs/flutter/setup) | [📖](https://pub.dev/documentation/patapata_firebase_analytics/latest/) | [`patapata_firebase_analytics`](https://github.com/gree/patapata/tree/main/packages/patapata_firebase_analytics) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Firebase Auth | [![patapata_firebase_auth pub.dev badge](https://img.shields.io/pub/v/patapata_firebase_auth.svg)](https://pub.dev/packages/patapata_firebase_auth) | [🔗](https://firebase.google.com/docs/flutter/setup) | [📖](https://pub.dev/documentation/patapata_firebase_auth/latest/) | [`patapata_firebase_auth`](https://github.com/gree/patapata/tree/main/packages/patapata_firebase_auth) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Firebase Core | [![patapata_firebase_core pub.dev badge](https://img.shields.io/pub/v/patapata_firebase_core.svg)](https://pub.dev/packages/patapata_firebase_core) | [🔗](https://firebase.google.com/docs/flutter/setup) | [📖](https://pub.dev/documentation/patapata_firebase_core/latest/) | [`patapata_firebase_core`](https://github.com/gree/patapata/tree/main/packages/patapata_firebase_core) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Firebase Crashlytics | [![patapata_firebase_crashlytics pub.dev badge](https://img.shields.io/pub/v/patapata_firebase_crashlytics.svg)](https://pub.dev/packages/patapata_firebase_crashlytics) | [🔗](https://firebase.google.com/docs/flutter/setup) | [📖](https://pub.dev/documentation/patapata_firebase_crashlytics/latest/) | [`patapata_firebase_crashlytics`](https://github.com/gree/patapata/tree/main/packages/patapata_firebase_crashlytics) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Firebase Messaging | [![patapata_firebase_messaging pub.dev badge](https://img.shields.io/pub/v/patapata_firebase_messaging.svg)](https://pub.dev/packages/patapata_firebase_messaging) | [🔗](https://firebase.google.com/docs/flutter/setup) | [📖](https://pub.dev/documentation/patapata_firebase_messaging/latest/) | [`patapata_firebase_messaging`](https://github.com/gree/patapata/tree/main/packages/patapata_firebase_messaging) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Firebase Remote Config | [![patapata_firebase_remote_config pub.dev badge](https://img.shields.io/pub/v/patapata_firebase_remote_config.svg)](https://pub.dev/packages/patapata_firebase_remote_config) | [🔗](https://firebase.google.com/docs/flutter/setup) | [📖](https://pub.dev/documentation/patapata_firebase_remote_config/latest/) | [`patapata_firebase_remote_config`](https://github.com/gree/patapata/tree/main/packages/patapata_firebase_remote_config) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Sentry | [![patapata_sentry pub.dev badge](https://img.shields.io/pub/v/patapata_sentry.svg)](https://pub.dev/packages/patapata_sentry) | [🔗](https://sentry.io/welcome/) | [📖](https://pub.dev/documentation/patapata_sentry/latest/) | [`patapata_sentry`](https://github.com/gree/patapata/tree/main/packages/patapata_sentry) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Riverpod | [![patapata_riverpod pub.dev badge](https://img.shields.io/pub/v/patapata_riverpod.svg)](https://pub.dev/packages/patapata_riverpod) | [🔗](https://riverpod.dev/) | [📖](https://pub.dev/documentation/patapata_riverpod/latest/) | [`patapata_riverpod`](https://github.com/gree/patapata/tree/main/packages/patapata_riverpod) | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |

## Unreleased But Useable Plugins
| Name                   | Related Product                                                                                                                                                             | Documentation                                                     | View Source                                                                                                                     | Android | iOS | Web | MacOS | Windows | Linux
|------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------------------------:|:---------:|:-----:|:-----:|:-------:|:-------:|:-------:|
| Adjust | [🔗](https://www.adjust.com/) | [📖](https://pub.dev/documentation/patapata_adjust/latest/) | [`patapata_adjust`](https://github.com/gree/patapata/tree/main/packages/patapata_adjust) | ✔ | ✔ | ✔ | ✖︎ | ✖︎ | ✖︎ |
| AppsFlyer | [🔗](https://www.appsflyer.com/) | [📖](https://pub.dev/documentation/patapata_apps_flyer/latest/) | [`patapata_apps_flyer`](https://github.com/gree/patapata/tree/main/packages/patapata_apps_flyer) | ✔ | ✔ | ✖︎ | ✖︎ | ✖︎ | ✖︎ |
| Karte Core | [🔗](https://karte.io/) | [📖](https://pub.dev/documentation/patapata_karte_core/latest/) | [`patapata_karte_core`](https://github.com/gree/patapata/tree/main/packages/patapata_karte_core) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |
| Karte Variables | [🔗](https://karte.io/) | [📖](https://pub.dev/documentation/patapata_karte_variables/latest/) | [`patapata_karte_variables`](https://github.com/gree/patapata/tree/main/packages/patapata_karte_variables) | ✔ | ✔ | ✔ | β | ✖︎ | ✖︎ |

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/LICENSE)
