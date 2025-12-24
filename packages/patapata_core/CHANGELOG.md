## 2.0.0

> Note: This release has breaking changes.

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.
 - **FEAT**: Implementation of `StandardChildPageWithResultFactory` and `StandardChildPageFactory`. This allows pages to have parent-child relationships, enabling the parent page to be automatically pushed when navigating to a child page. See the documentation for details.
 - **FEAT**: Implementation of `StandardPageWithNestedNavigatorFactory`. This creates pages with nested navigators. It is useful, for example, when you want to create a footer menu where each tab maintains its own navigation stack. See the documentation for details.
 - **FEAT**: Added `pushParentPage` parameter to navigation methods such as `context.go`. This option determines whether to push the parent page when navigating to pages defined with `StandardChildPageFactory` and similar factories.
 - **BREAKING** **CHANGE**: Removed `StandardPageWithResultFactory.parentPageType`. Use `StandardPageWithNestedNavigatorFactory` instead.
 - **BREAKING** **CHANGE**: Removed `willPopPage` from `StandardMaterialApp` and `StandardCupertinoApp`. This is because `Navigator`'s `onPopPage` has been deprecated, making it impossible to cancel a pop operation just before it occurs. Please use `PopScope` or similar alternatives.
 - **BREAKING** **CHANGE**: `StandardPageBackButton` has been removed. This class is no longer necessary due to the implementation of `StandardPageWithNestedNavigator`.
 - **BREAKING** **CHANGE**: `StandardPageWithResult.childNavigator` has been removed. Please use `StandardPageWithNestedNavigator` instead.
 - **BREAKING** **CHANGE**: Restrict capture groups in deep link regular expressions. See the StandardPageFactory documentation for details.
 - **FEAT**: Added `onDidRemovePage` to `StandardMaterialApp` and `StandardCupertinoApp`. This is passed to `Navigator`'s `onDidRemovePage`.

## 1.4.0

 - **FIX**: local_web_config, Monitor StorageEvent to detect changes from another tab.
 - **FIX**: setMany in web_local_config causes cast error.
 - **FEAT**: bump minimum Flutter version to 3.29.0.
 - **FEAT**: support flutter 3.35.0.
 - **DOCS**: Added description of StandardPage.buildPage.

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