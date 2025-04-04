## 1.3.0

 - **FIX**: When running bootstrap on a new Flutter project, the uses-material-design entry is unintentionally removed from pubspec.yaml.
 - **FEAT**: support flutter 3.29.0.
 - **FEAT**: Added the SynchronousErrorableFuture class. This class is used within the repository system, but it is recommended to avoid using it in general.
 - **FEAT**: Addition of the New Feature: Repository System.
 - **FEAT**: When creating a `PatapataException` , if the currently displayed page has a [StandardPageWithResult.localizationKey] set, the default key can now be overridden using the localizationKey.
 - **FEAT**: Support for WebAssembly (Wasm).
 - **FEAT**: The StandardPage now includes the `StandardPageWithResult.localizationKey` property. This allows for localization by utilizing context.pl with the specified key.
 - **DOCS**: Fix some dartdocs that are interpreted as HTML.
 - **DOCS**: Fix parts that do not match the Dart formatter.

## 1.2.0

 - **FIX**: Added enableNavigationAnalytics to StandardPageWithResultFactory. The default is true.
 - **FIX**: fix an issue when StandardPage page data's type changes from nullable to non-nullable and null data is trying to be restored on route load.
 - **FIX**: log_test fails on Windows.
 - **FIX**: update com.android.tools.build:gradle:8.1.0.
 - **FIX**: When PatapataException.userLogLevel is set to SHOUT for an unknown error, goErrorPage is not called.
 - **FEAT**: support flutter 3.27.1.
 - **FEAT**: StandardRouterDelegate.processInitialRoute to run automatically.
 - **FEAT**: A new widget, InfiniteScrollListView, has been implemented to add infinite scroll functionality to Flutter’s ListView and GridView.
 - **FEAT**: The logging system overrides PlatformDispatcher.onError. This ensures that all unknown exceptions, including those that occur outside of Patapata's Zone, are handled.
 - **FEAT**: With the fix to PatapataException, the App instance is now retrieved from the Zone when creating exceptions. As a result, it is no longer a const property.

## 1.1.0

 - **FEAT**: support flutter 3.22.0 by updating intl dependency constraints.
 - **FEAT**: Adapt to the Privacy Manifest.
 - **FEAT**: allow to choose whether to wait for microtasks, timers, and periodic timers in a SequentialWorkQueue, as well as ProviderModel's lock function.

## 1.0.2

 - **FIX**: patapata_core documentation, add widget_test.dart overwrite logic.

## 1.0.1

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.
 - **DOCS**: fix badge for github actions checks.

## 1.0.0

- initial release