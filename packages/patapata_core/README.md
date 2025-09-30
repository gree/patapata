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

## Table of Contents
  - [About](#about)
    - [Supported Platforms](#supported-platforms)
  - [Getting started](#getting-started)
    - [Bootstrap](#bootstrap)
  - [Usage](#usage)
    - [Environment](#environment)
    - [App](#app)
      - [App startup flow](#app-startup-flow)
    - [Startup Sequence](#startup-sequence)
    - [User](#user)
    - [Standard App](#standard-app)
  - [Internationalization and localization (I18n and L10n)](#internationalization-and-localization-(i18n-and-l10n))
  - [Logging and error handling](#logging-and-error-handling)
  - [Notifications](#notifications)
  - [Utilities](#utilities)
    - [Finite State Machine](#finite-state-machine)
    - [Sequential Work Queue](#sequential-work-queue)
    - [Fake DateTime](#fake-datetime)
    - [Provider Model](#provider-model)
    - [Screen Layout](#screen-layout)
    - [Platform Dialog](#platform-dialog)
  - [Testing your application](#testing-your-application)
    - [Testing in the IDE](#testing-in-the-ide)
  - [Contributing](#contributing)
  - [License](#license)

## About

Patapata is a framework built on Flutter for creating applications of production quality quickly and reliably.
It provides a collection of best-practices built directly in to the various APIs so you can build apps that are consistent, stable, and performant.

Patapata Core is the core framework that provides the basic building blocks for your application.
You will always depend on this package in your application to use Patapata.
In addition, you can use any of the plugins that Patapata provides to add additional functionality to your application.
See the [homepage](https://github.com/gree/patapata) for details.

### Supported Platforms

We try to support the newest version of Flutter and will not purposely keep support for older versions if something is deprecated on the Flutter side.

The Patapata team believes that it is important to keep up to date with the latest version of Flutter as in our expierence with real world applications, old versions of Flutter have trouble supporting the newer versions of Android and especially iOS.

Currently, we support Flutter 3.29.0 and above, with a minimum Dart version of 3.0.0 up to 4.0.0.

We officially support Android, iOS fully, and best effort for Web and MacOS.
Windows and Linux are currently not supported.

## Getting started

To just get the standard Patapata experience and have an app up and running, execute the following in a terminal:
  
```bash
flutter create my_app
cd my_app
flutter pub add patapata_core
dart run patapata_core:bootstrap -f
```

Note that this will change the minimum Android SDK version to 24 and the minimum iOS version to 13.0.

You should be able to run your application!

### Bootstrap

As in the example above, you can use the `bootstrap` command to quickly get started with Patapata.

This command will:
- Generate an `Environment` file for you with `I18nEnvironment` and `LogEnvironment` setup by default
- Generate a `main.dart` file that will create a `Standard App` for you with default settings for almost all of Patapata's features, and a place to add your own `Provider` models to be accessable throughout your application.
- Generate a `Startup Sequence` that has a splash screen, a fake agreement page, and finally a home page.
- Generate a default error page for when your app encounters a fatal error.
- Generate an error class that supports the `PatapataException` system for your app in it's own namespace.
- Enable [Flutter's deep link system](https://docs.flutter.dev/ui/navigation/deep-linking) that `Standard App` will use for external links to your application
- Setup the `L10n` system (localization) for your application with default yaml files for English (by default) 

## Usage

Patapata has many different systems that all work together to make an application that is easy to maintain and extend.
Each system of Patapata has [documentation](https://pub.dev/documentation/patapata_core/latest/) that you can read to learn more about it.

Patapata strives to make not just development, but maintence of your application easy and as automatic as possible.

Especially if you use the `bootstrap` command setup, you have automatic logging and reporting of errors to any supported 3rd party service, automatic remote configuration of your application, and localization support ready to go (just add text to your yaml files). You have a splash screen and start up sequence with deep linking out of the box, error handling out of the box, standard features that basically all applications use ready to go (such as package information, device information, local configuration, network information, etc). You also have an analytics system that automatically is sending routing events, page data changing events, lifecycle events, and more.

Developer tools such a Finite State Machine system, a work queue system, a concept of a User, multiple screen size auto layout and more are all available to you.

Tools such as a fake DateTime system exist to make QA testing and backend testing easier as well.

Patapata provides a few must have packages that can be easily accessed without manually importing by importing `package:patapata_core/patapata_core_libs.dart`.

These packages are:
- [provider](https://pub.dev/packages/provider)
- [logging](https://pub.dev/packages/logging)
- [timezone](https://pub.dev/packages/timezone)
- [visibility_detector](https://pub.dev/packages/visibility_detector)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

### Environment

The `Environment` class is responsible for setting up the environment for your application.
This class is something you create yourself, and pass to `App` when you create it.

The concept is that your `Environment` class will mixin multiple `Environment` mixins that are provided by Patapata and plugins. Each of these mixins will setup a different part of your application's environment.

All of the `Environment` mixins following a naming convention of `NameEnvironment`, where `Name` is the name of the system that it is setting up.

In general you should try very hard to make your `Environment` class `const` so that it can be used in a `const` context.
This is important so that any tree shaking that Flutter does will remove any code that is not used in your application as well as for performance reasons.

Also, if you use one of the [String.fromEnvironment](https://api.flutter.dev/flutter/dart-core/String/String.fromEnvironment.html) methods, if you don't use a `const` certain platforms will not function correctly.
The `String.fromEnvironment` and friends can be used to pass in environment variables to your application at build time via the `--dart-define` flag.

Here is a simple example of an `Environment` class:

```dart
class Environment
    with
        I18nEnvironment,
        LogEnvironment,
        SentryEnvironment {
  /// A base URL for your API.
  final String apiBaseUrl;

  /// An API key for your API.
  final String apiKey;

  /// Set's what locales your application supports.
  @override
  final List<Locale> supportedL10ns = const [Locale('en')];

  /// Set's where your application will look for localization files.
  @override
  final List<String> l10nPaths = const [
    'l10n',
  ];

  /// The default log level.
  @override
  final int logLevel;

  /// Whether or not to print logs to the console.
  @override
  final bool printLog;

  /// The Sentry DSN to use if for example you are using Sentry.
  @override
  final String sentryDSN;

  /// A function that will be called to setup Sentry.
  @override
  final FutureOr<void> Function(SentryFlutterOptions)? sentryOptions = null;

  const MyEnvironment({
    this.apiBaseUrl = const String.fromEnvironment('API_BASE_URL'),
    this.apiKey = const String.fromEnvironment('API_KEY'),
    this.logLevel =
        const int.fromEnvironment('LOG_LEVEL', defaultValue: -kPataInHex),
    this.printLog =
        const bool.fromEnvironment('PRINT_LOG', defaultValue: kDebugMode),
    this.sentryDSN = const String.fromEnvironment('SENTRY_DSN'),
  });
}

void main() async {
  App(
    environment: const Environment(),
    ....
  )
  .run();
}
```

### App

The [App](https://pub.dev/documentation/patapata_core/latest/patapata_core/App-class.html) class is the main entry point for your application.
It is responsible for setting up all of Patapata's systems and plugins, and then running your application.

Your entire application will be run inside a special `Zone` that Patapata manages.
When in this `Zone`, you can access the current `App` via the [getApp](https://pub.dev/documentation/patapata_core/latest/patapata_core/getApp.html) function.

```dart
getApp<Environment>().environment.apiBaseUrl;
```

Your application will also be the child of several `Provider` widgets that are provided by Patapata that allow you to listen to changes via [context.watch](https://pub.dev/documentation/provider/latest/provider/WatchContext/watch.html), [context.select](https://pub.dev/documentation/provider/latest/provider/SelectContext/select.html) and friends.

```dart
Widget build(BuildContext context) {
  final tOnline = context.select<NetworkInformation, bool>(
    (v) => v.connectivity != NetworkConnectivity.none
  );

  if (tOnline) {
    return const Text('Online');
  } else {
    return const Text('Offline');
  }
}
```

`App` also exposes `Provider`s for:
- The `App` itself
- The genericly typed `Environment` version of your `App` as `App<Environment>`
- The `Environment`
- [User](https://pub.dev/documentation/patapata_core/latest/patapata_core/User-class.html)
  - A class to manage the concept of a 'user' in your application
- [RemoteConfig](https://pub.dev/documentation/patapata_core/latest/patapata_core/RemoteConfig-class.html)
  - A class to access remote configuration data for your application
- [LocalConfig](https://pub.dev/documentation/patapata_core/latest/patapata_core/LocalConfig-class.html)
  - A class to access locally stored simple key value data for your application
- [RemoteMessaging](https://pub.dev/documentation/patapata_core/latest/patapata_core/RemoteMessaging-class.html)
  - A class to access remote messaging data for your application, such as push notifications.
- [Analytics](https://pub.dev/documentation/patapata_core/latest/patapata_core/Analytics-class.html)
  - A class to collect and send analytics data for your application
- The global [AnalyticsContext](https://pub.dev/documentation/patapata_core/latest/patapata_core/AnalyticsContext-class.html)
- [NetworkInformation](https://pub.dev/documentation/patapata_core/latest/patapata_core/NetworkInformation-class.html) as a [StreamProvider](https://pub.dev/documentation/provider/latest/provider/StreamProvider-class.html)
- [PackageInfoPlugin](https://pub.dev/documentation/patapata_core/latest/patapata_core/PackageInfoPlugin-class.html)
  - Quick access to all meta information about your application
- [DeviceInfoPlugin](https://pub.dev/documentation/patapata_core/latest/patapata_core/DeviceInfoPlugin-class.html)
  - Quick access to all information about the device your application is running on

Some of which are listenable (and therefore watch and selectable).

#### App startup flow

The `App` class goes through a series of steps to setup your application that have specific rules for when things are initialized and when you are allowed to access the various systems of Patapata.

In general, as a developer who is not customizing with `Plugin`s, you should not have to worry about this and can just use the `App` class as is.

`App` goes through the steps are defined in [AppStage](https://pub.dev/documentation/patapata_core/latest/patapata_core/AppStage.html).

1. `setup` - The first stage where the `App` hasn't done any operations and `run` hasn't been executed yet. Nothing is initialized at this point and attempts to access any API except for `the add/remove/hasPlugin` methods will result in undefined behavior. Usually an exception will be thrown.
2. `bootstrap` - This stage is entered upon execution of `run`. Immediately after entering this stage, the following are executed synchronously:
    1. Flutter's services are initialized made useable
    2. The special `Zone` that Patapata manages is created an entered
    3. The [Log](https://pub.dev/documentation/patapata_core/latest/patapata_core/Log-class.html) system becomes useable
    4. Flutter's [ErrorWidget.builder](https://api.flutter.dev/flutter/widgets/ErrorWidget/builder.html) is set to [nonDebugErrorWidgetBuilder](https://pub.dev/documentation/patapata_core/latest/patapata_core/App/nonDebugErrorWidgetBuilder.html)
    5. The callback passed to `run` will be executed in a non-asynchronous manner so you are guaranteed that you are still on the same dart task as when `main` was executed During this stage
3. `initializingPlugins` - The default `Plugin`s and `Plugins`s passed to the `App` are initialized. First, `Plugin`s that have [requireRemoteConfig](https://pub.dev/documentation/patapata_core/latest/patapata_core/Plugin/requireRemoteConfig.html) set to `false` are initialized, allowing for `RemoteConfig` `Plugin`s to be be available and allow remote disabling of `Plugin`s via `RemoteConfig`. If any `Plugin`s fail to initialize, [onInitFailure](https://pub.dev/documentation/patapata_core/latest/patapata_core/App/onInitFailure.html) is called or if null, the error is printed to the console and your app fails to start.
4. `setupRemoteConfig` - The `RemoteConfig` system is initialized and is useable after this point. Patapata will attempt to fetch the newest remote config data with a 2 second timeout. A timeout will not generate an error and will just delay the start of your application by those 2 seconds.
5. `initializingPluginsWithRemoteConfig` - The remaining non-initialized `Plugin`s are initialized and remotely removed `Plugin`s are removed (and are never initialized). If any `Plugin`s fail to initialize, [onInitFailure](https://pub.dev/documentation/patapata_core/latest/patapata_core/App/onInitFailure.html) is called or if null, the error is printed to the console and your app fails to start.
6. `running` - At this stage, all of `Patapata`'s systems are useable. [createAppWidget](https://pub.dev/documentation/patapata_core/latest/patapata_core/App/createAppWidget.html) is wrapped with all the `Provider`s set up by `App`, and wrapped with the `Analytics` system's pointer listener for tracking all pointer events.

If at any point during the above sequence an unhandled error is thrown, `App` will remove the native splash screen, and attempt to report the error to the logging system.

### Startup Sequence

The [StartupSequence](https://pub.dev/documentation/patapata_core/latest/patapata_core/StartupSequence-class.html) class can help you create a startup flow for your application.

You should almost always use this though it is not required.

A Startup Sequence would be a list of actions your app _always_ performs on startup.
You can provide conditions for each action to be executed, and provide a flow until the processing of the initial actual 'home' page of your application is ready to be shown (or a deep linked page).

The most general use case for this is to show a splash screen, then show a terms of service page, then show a login page, then show the home page.

### User

The [User](https://pub.dev/documentation/patapata_core/latest/patapata_core/User-class.html) class is a class that represents a user of your application.
It is a `ChangeNotifier` so you can listen to changes to the user's data.

The `User` class is a generic class that you can use to represent any type of user you want.

You can extend this class to make a unique user class for your application, and let Patapata know about it by passing the [userFactory](https://pub.dev/documentation/patapata_core/latest/patapata_core/App/userFactory.html) parameter to `App`.

The `User` is used by the `Analytics` system to track user data, and `Plugin`s can use it to track user data and to provide user specific functionality, log in and out functionality, etc automatically.

For example, the `patapata_firebase_analytics`, `patapata_firebase_crashlytics`, and `patapata_sentry` plugins all use the `User` class to assign properties to the user in their respective systems.

### Standard App

Standard App is an optional, but highly recommended `Plugin` that is enabled by default that you can use to add the concept of a 'page' to your application, and add full support for running an production quality application with very little code.

To use it, you pass either the [StandardMaterialApp](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/StandardMaterialApp-class.html) or [StandardCupertinoApp](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/StandardMaterialApp-class.html) to your `App`'s `createAppWidget` parameter.

From there, you define your standard Flutter `MaterialApp` or `CupertinoApp` settings as normal as well as a list of 'pages' that exist in your application.

Each of these pages is a `StatefulWidget` that extends [StandardPage](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/StandardPage-class.html).

```dart
void main() {
  App(
    createAppWidget: (context, app) => StandardMaterialApp(
      onGenerateTitle: (context) => l(context, 'title'),
      pages: [
        // This is the landing page for the application.
        StandardPageFactory<HomePage, void>(
          create: (_) => HomePage(),
          links: {
            // An empty deep link means this page will be shown when the app is opened externally without directly specifying a page.
            r'': (match, uri) {},
          },
          linkGenerator: (pageData) => '',
          // Home will _always_ exist in the navigation stack with this setting.
          groupRoot: true,
        ),
        // This is just an example of another simple page definition.
        StandardPageFactory<SettingsPage, void>(
          create: (_) => SettingsPage(),
          links: {
            r'settings': (match, uri) {},
          },
          linkGenerator: (pageData) => 'settings',
        ),
        // This is an example of a page that has a page data object.
        StandardPageFactory<SearchPage, SearchPageData>(
          create: (_) => SearchPage(),
          links: {
            // When 'search' as a deep link is opened, this page will be shown,
            // mapping the uri data to the required page data object.
            r'search': (match, uri) {
              return SearchPageData(
                query: uri.queryParameters['q'] ?? '',
                reverseSort: uri.queryParameters['r'] == '1',
              );
            },
          },
          // This regenerates the deep link for this page based off the current page data.
          linkGenerator: (pageData) => Uri(
            path: 'search',
            queryParameters: {
              'q': pageData.query,
              'r': pageData.reverseSort ? '1' : '0',
            },
          ).toString(),
        ),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    ),
  )
  .run();
}

/// This is the simplest page definition.
class HomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'home.title')),
      ),
      body: Center(
        child: Text(l(context, 'home.body')),
      ),
    );
  }
}

class SearchPageData {
  final String query;
  final bool reverseSort;

  const SearchPageData({
    required this.query,
    this.reverseSort = false,
  });
}

/// This is a page that has a page data object.
class SearchPage extends StandardPage<SearchPageData> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'search.title')),
      ),
      body: Center(
        // You can access the pageData anywhere.
        child: Text(pageData.query),
      ),
    );
  }
}
```

You can also define a page that returns a result to whoever if opened it.

```dart
void checkWhatUserWants() {
  if (await context.goWithResult<AskUserPage, void, bool>) {
    // The user said yes.
  } else {
    // The user said no.
  }
}

/// This time use [StandardPageWithResult] instead of [StandardPage].
/// The final generic type is the return type.
class AskUserPage extends StandardPageWithResult<void, bool> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(l(context, 'ask.body')),
            ElevatedButton(
              onPressed: () {
                // The traditional, not type safe way
                Navigator.pop(context, true);
              },
              child: Text(l(context, 'ask.yes')),
            ),
            ElevatedButton(
              onPressed: () {
                // The new type safe way.
                // Set the result any time you want.
                pageResult = false;

                // Then remove the current route later.
                context.removeRoute();
                // or Navigator.pop(context);
              },
              child: Text(l(context, 'ask.no')),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  App(
    createAppWidget: (context, app) => StandardMaterialApp(
      onGenerateTitle: (context) => l(context, 'title'),
      pages: [
        // Use this factory for result pages.
        StandardPageWithResultFactory<AskUserPage, void, bool>(
          create: (_) => AskUserPage(),
        ),
      ],
    ),
  )
  .run();
}
```

Quite often, for example, in a search page, you can change the original page data object and want to update the deep link to the current page. `StandardPage` has a `pageData` property that you can set to update the deep link. The `StandardPage` itself is also set in a provider so you can access it from anywhere in your page's widget tree. This allows child widgets to access the page data as well.

```dart
class SearchPageData {
  final String query;
  final bool reverseSort;

  const SearchPageData({
    required this.query,
    this.reverseSort = false,
  });
}

final _logger = Logger('SearchPage');

class SearchPage extends StandardPage<SearchPageData> {
  @override
  void onPageData() {
    // If you want to do something every time the page data changes,
    // you can override this method.
    _logger.info('pageData changed: $pageData');
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'search.title')),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // This will update the deep link to the current page.
              // As well as fire off related analytics events.
              setState(() {
                pageData = SearchPageData(
                  query: pageData.query,
                  reverseSort: !pageData.reverseSort,
                );
              });
            },
            child: Text(l(context, 'search.toggleSort')),
          ),
          Text('${pageData.query}: ${pageData.reverseSort}'),
        ],
      ),
    );
  }
}
```

A `StandardPage` automatically sets up several analytics features related to page navigation and lifecycle events, as well as when page data changes. Watch the flow of analytics events in your debug log to see what is happening.

You may often want to customize your entire application but need access to `MaterialApp`'s various features such as `Theme`, `MediaQuery` and more. You may also want to provide a global user interface that wraps all of your pages.

To do all of this, use the [routableBuilder](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/StandardMaterialApp/routableBuilder.html) parameter of `MaterialStandardApp` and `CupertinoStandardApp`.

```dart
void main() {
  App(
    createAppWidget: (context, app) => StandardMaterialApp(
      onGenerateTitle: (context) => l(context, 'title'),
      pages: [
        // your pages here
      ],
      routableBuilder: (context, child) {
        return Stack(
          children: [
            child,
            Positioned(
              bottom: 0,
              right: 0,
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  // You can use this context to navigate.
                  // However, Navigator.of will not work.
                  // The reason is [child] is the [Navigator].
                  context.go<MyPage, void>(null);
                },
                child: Text(l(context, 'mypage')),
              )
            ),
          ],
        );
      },
    ),
  )
  .run();
}
```

`StandardPage` also keeps track of your page's active and inactive lifecycle events.
A page is 'active' when it is the top page in the navigation stack. A page is 'inactive' when it is not the top page in the navigation stack.
  
```dart
class MyPage extends StandardPage<void> {
  @override
  void onActive(bool first) {
    // This will be called when the page becomes active.
    // [first] will be true on the first time a page becomes active.
    // Usually that is when the page is first created.
    super.onActive();
  }

  @override
  void onInactive() {
    // This will be called when the page becomes inactive.
    super.onInactive();
  }

  @override
  void onRefocus() {
    // This will be called when the page is already active and is navigated to again.
  }
}
```

To enable 100% automatic handling of deep links at startup, be sure to use [StartupSequence](https://pub.dev/documentation/patapata_core/latest/patapata_core/StartupSequence-class.html) and enable Flutter's default deep link handling.
All of this is done if you use the `bootstrap` command.

## Internationalization and localization (I18n and L10n)

Patapata has a built in system for internationalization and localization.
It will first of all automatially initialize the [timezone](https://pub.dev/packages/timezone) package so you can use all of it's features out of the box.

As a small feature, Patapata provides an extension to `DateTime` that provides a few common methods for DateTime string formatting commonly used with APIs.
- [toUTCIso8601StringNoMSUS](https://pub.dev/documentation/patapata_core/latest/patapata_core/DateDateTimeExtension/toUTCIso8601StringNoMSUS.html)
- [asDateString](https://pub.dev/documentation/patapata_core/latest/patapata_core/DateDateTimeExtension/asDateString.html)

The localization system of Patapata is a core feature that every app should heavily be using.
It is based on writing yaml files that contain your localized strings as a tree of key value pairs.

It supports Flutter's [MessageFormat](https://api.flutter.dev/flutter/message_format/MessageFormat-class.html) system, which is a subset of the ICU MessageFormat syntax that can handle plurals and select statements (for genders, etc), as well just simple string interpolation.

The yaml files can be hot reloaded and so development is easy and fast.

You use the system with the [l](https://pub.dev/documentation/patapata_core/latest/patapata_core/l.html) function.

```dart
Text(l(context, 'page1.title'));
```

Languages will change automatically when the user changes the language of their device.

## Logging and error handling

Logging is accomplished with dart's standard [logging](https://pub.dev/packages/logging) package.

Patapata hooks in to the root Logger and provides a 'reporting' system you and plugins can use to filter, transform, and send to 3rd party services.

```dart
getApp().log.addFilter((report) {
  // Only log things that have errors attached.
  return switch (report.error) {
    null => null,
    _ => report,
  };
});
```

```dart
getApp().log.reports.listen((report) {
  // Do something with this report.
});
```

Logging to console is automatically disabled in release builds, and Patapata disables debugPrint and print for release builds automatically as well for security reasons.

Patapata also provides a system for handling errors in your application.

If you make all of your errors inherit from [PatapataException](https://pub.dev/documentation/patapata_core/latest/patapata_core/PatapataException-class.html), the logging system and various other systems can automatically perform actions when errors occur. They also will use the L10n system to localize errors.
Errors are also namespaced to that each section of your code or each plugin can have it's own error namespace and therefore error code to show to the user for quick user support.

## Notifications

Patapata currently uses [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) for local notifications.

Patapata will automatically set up the package for you with decent default settings.
To use it in your application, `import package:patapata_core/patapata_core_libs.dart` and follow the documentation for [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) to display notifications. You should be able to jump right in to executing the API to show a notification.

If you use `StandardApp`, notifications will automatically be wired to open deep links in your application or, if you want to handle a custom notification yourself with `StandardApp`, you can add a [link handler](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/StandardAppPlugin/addLinkHandler.html).

If you do not use `StandardApp`, you can use the [NotificationPlugin's notification stream](https://pub.dev/documentation/patapata_core/latest/patapata_core/NotificationsPlugin/notifications.html) directly.

```dart
getApp().getPlugin<NotificationsPlugin>()?.notifications.listen((notification) {
  // Do something with the notification.
});
```

## Utilities

There are a few utilities that Patapata provides that you can use in your application. 

### Finite State Machine

Patapata has a [LogicStateMachine](https://pub.dev/documentation/patapata_core/latest/patapata_core/LogicStateMachine-class.html) class that you can use to create a finite state machine for your application. [StartupSequence](https://pub.dev/documentation/patapata_core/latest/patapata_core/StartupSequence-class.html) uses this class to manage it's state.

### Sequential Work Queue

Patapata has a [SequentialWorkQueue](https://pub.dev/documentation/patapata_core/latest/patapata_core/SequentialWorkQueue-class.html) class that you can use to create a work queue that will execute jobs in order, one at a time.

It optionally supports adding jobs that can cancel previous jobs, including stopping the execution of actual dart code with callbacks to allow for cleanup.

### Fake DateTime

Patapata exposes a global getter called [now](https://pub.dev/documentation/patapata_core/latest/patapata_core/now.html) that you can use to get the current date and time.

The definition of 'the current date and time' can be changed by using [setFakeNow](https://pub.dev/documentation/patapata_core/latest/patapata_core/setFakeNow.html), with options to persist the fake time across app restarts as well as having `now` to return the elapsed time since the fake time was set.

This is useful for testing and debugging, as well as syncing your application to a 'server time'.

We recommend using `now` instead of `DateTime.now()` for all uses of the current date and time in your application, except for when something relies on the user's actual local device time, or a time that must be accurate to an external source.

### Provider Model

Often while designing a model based system in dart, the 'model' needs to execute code asynchroniously to complete a modification to itself. For example, a model that needs to fetch data from a server.

In these cases, it is very possible for that same model to get another request to update itself again with newer values.

Sometimes, you want to cancel the previous request and only use the latest request. Sometimes, you want to queue up the requests and execute them in order. While other times, you want to make the second request invalid and not execute it at all.

Setting up a system like this is error prone and time consuming.

Patapata provides a class called [ProviderModel](https://pub.dev/documentation/patapata_core/latest/patapata_core/ProviderModel-class.html) that you can use to easily create a model that can handle all of these cases.

It supports concepts such as 'variables' that are managed and 'transactions' that can be either queued, cancelled, or invalidated. We call these 'transactions' 'batches'.

```dart
class MyModel extends ProviderModel<MyModel> {
  final _key = ProviderLockKey('forUpdating');

  late final _myVariable = createVariable<String>('defaultValueHere');
  String get myVariable => _myVariable.unsafeValue;

  late final _myCounter = createVariable<int>(0);
  int get myCounter => _myCounter.unsafeValue;

  /// Update [myVariable] and [myCounter] 'atomically'.
  /// If this is called in succession before the previous
  /// execution finishes, the second execution will cancel
  /// the first, and only the last value will be committed.
  Future<void> updateMyVariable(String newValue) {
    return lock(
      _key,
      (batch) async {
        // Increment the counter.
        // At this point, we haven't commited the results
        // to the model, so any access to [myCounter] will still
        // not be updated.
        batch.set(_myCounter, batch.get(_myCounter) + 1);

        if (newValue.isEmpty) {
          batch.cancel();

          return;
        }

        // We pretend an API will update remote data.
        // If it fails, we cancel the batch, and once again
        // nothing will be updated locally.
        // [blockOverride] is used to prevent the batch from
        // being cancelled while in the middle of API execution
        // because we don't want the API classes' Zone execution
        // stop and not cleanup.
        // If this batch was cancelled or overriden it will
        // cancel after this API call finishes.
        if (!await batch.blockOverride(() => api.updateMyVariable(newValue))) {
          batch.cancel();

          return;
        }

        // Set the variable and commit the result to the model.
        // On commit, anything listening to this
        // variable will be updated.
        batch.set(_myVariable, newValue);
        batch.commit();
      },
      overridable: true,
      override: true,
    );
  }

  /// Update [myVariable] and [myCounter] 'atomically'.
  /// This one will not cancel the previous execution,
  /// but will instead fail immediately if another
  /// execution is in progress.
  bool updateMyVariableOnlyLocally(String newValue) {
    try {
      // If another lock is in progress, this will throw immediately.
      final tBatch = begin(_key);

      tBatch.set(_myCounter, tBatch.get(_myCounter) + 1);
      tBatch.set(_myVariable, newValue);
      tBatch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }
}

Widget build(BuildContext context) {
  return Provider(
    create: (_) => MyModel(),
    child: Selector<MyModel, String>(
      selector: (context, model) => model.myVariable,
      builder: (context, myVariable, child) {
        return Column(
          children: [
            Text(myVariable),
            ElevatedButton(
              onPressed: () {
                context.read<MyModel>().updateMyVariable('new value');
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    ),
  );
}
```

As you can see, this is fairly complex to setup, but once you have it setup, it is both easy to use, and can be very powerful. It is designed to cover that 1% case where users do strange things to your application, and prevent your application from crashing or entering an invalid state or other odd issues.

### Screen Layout

Patapata has a helper layout Widget that has the capability to layout all child widgets as if the screen was a certain size. After layout, the child widgets will be scaled to fit the screen.

This is very useful for applications that want to have a single design for screen sizes based off breakpoints, and want to scale the design instead of reflow the design for different screen sizes.

See [ScreenLayout](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/ScreenLayout-class.html) for more information.

### Platform Dialog

Patapata has a [PlatformDialog](https://pub.dev/documentation/patapata_core/latest/patapata_widgets/PlatformDialog-class.html) widget that you can use to show a platform specific dialog.

```dart
PlatformDialog.show(
  context: context,
  title: l(context, 'dialog.title'),
  message: l(context, 'dialog.message'),
  actions: [
    PlatformDialogAction(
      result: () => true,
      text: l(context, 'dialog.yes'),
      isDefault: true,
    ),
    PlatformDialogAction(
      result: () => false,
      text: l(context, 'dialog.no'),
    ),
  ],
);
```

## Testing your application

Patapata's plugins and features use native APIs and rely on running on real devices to generally work.
In a testing environment, you can't use the native APIs, so you need to mock them.
Patapata itself will automatically mock itself if you set the environment variable `IS_TEST` to true.

```bash
flutter test --dart-define=IS_TEST=true
```

Once you have set this environment variable, you can use a few tools in your own tests to quickly and easily leaverage Patapata's features in your tests.
Typically, you would write a test as follows:

```dart
void main() {
  // These two lines are required to mock the native APIs
  // and _must_ be set before any other code is run.
  TestWidgetsFlutterBinding.ensureInitialized();
  testSetMockMethodCallHandler = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger.setMockMethodCallHandler;

  // This StreamHandler is necessary when mocking streams from native APIs, and its responses should be handled
  // in the onListen and onCancel methods of a class that inherits from the MockStreamHandler class.
  testSetMockStreamHandler = (channel, handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      channel,
      _MockStreamHandler(handler),
    );
  };

  testWidgets('My App should run', (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(....),
      startupSequence: StartupSequence(....),
      plugins: [....],
    );
    
    // It is important to await this, otherwise [App] will not be able
    // to initialize correctly.
    await tApp.run();

    // Always run your tests in a [runProcess] block.
    // Flutter's test system runs code in a different Zone
    // than what you app runs in, and functions like [getApp] or the logging system
    // require to be run in a Zone that Patapata is managing.
    await tApp.runProcess(() async {
      // Always pumpAndSettle to let Patapata finish initializing.
      await tester.pumpAndSettle();

      // Write your tests here.
    });

    // You must call this before executing the next test.
    tApp.dispose();
  });
}

// This class is necessary when preparing a mock stream handler.
class _MockStreamHandler extends MockStreamHandler {
  _MockStreamHandler(this.handler);

  final TestMockStreamHandler? handler;

  @override
  void onCancel(Object? arguments) {
    // This is where you can handle the onCancel event.
  }

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    // This is where you can handle the onListen event.
  }
}
```

If you are a `Plugin` developer and want to mock your own plugin, you can do so by overriding `setMockMethodCallHandler` in your plugin.
Currently supported by `App`, `Plugin` and `Config`.

Example: TestPlugin
```dart
class TestPlugin extends Plugin {
  @override
  @visibleForTesting
  void setMockMethodCallHandler() {
    testSetMockMethodCallHandler(
      const MethodChannel('com.mock.testplugin'),
      (methodCall) async {
        methodCallLogs.add(methodCall);
        switch (methodCall.method) {
          case 'flight':
            debugPrint('patapata');
          default:
            break;
        }
        return null;
      },
    );
  }
}
```

Note that there are no hard dependencies on the Flutter test package in this code.

Furthermore, when testing events on the custom plugin side, you can conduct tests using the mock event channel `setMockStreamHandler`.
```dart
class TestStreamHandlerPlugin extends Plugin {
  @override
  @visibleForTesting
  void setMockStreamHandler() {
    testSetMockStreamHandler(
      const EventChannel('com.mock.testplugin'),
      _TestMockStreamHandler(),
    );
  }
}

class _TestMockStreamHandler extends TestMockStreamHandler {
  @override
  void onCancel(Object? arguments) {}

  @override
  void onListen(Object? arguments, TestMockStreamHandlerEventSink events) {
    events.success('sucess event');
  }
}

```

This can also be written using the inline function `TestMockStreamHandler.inline`.

Example: TestStreamHandlerInlinePlugin
```dart
class TestStreamHandlerInlinePlugin extends Plugin {
  @override
  @visibleForTesting
  void setMockStreamHandler() {
    testSetMockStreamHandler(
      const EventChannel('com.mock.testplugin'),
      TestMockStreamHandler.inline(
        onListen: (_, events) {
          events.success('sucess event');
        },
      ),
    );
  }
}
```

### Testing in the IDE

If you run tests from an IDE, you can set the environment variable in the IDE's settings.
Example: for .vscode/settings.json
```json
{
    "dart.flutterTestAdditionalArgs": ["--dart-define=IS_TEST=true"]
}
```

## Contributing

Check out the [CONTRIBUTING](https://github.com/gree/patapata/blob/main/CONTRIBUTING.md) guide to get started.

## License

[See the LICENSE file](https://github.com/gree/patapata/blob/main/packages/patapata_core/LICENSE)
