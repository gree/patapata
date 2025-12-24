# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-12-24

### Changes

---

Packages with breaking changes:

 - [`patapata_core` - `v2.0.0`](#patapata_core---v200)

Packages with other changes:

 - [`patapata_apple_push_notifications` - `v1.3.0`](#patapata_apple_push_notifications---v130)
 - [`patapata_firebase_analytics` - `v1.3.0`](#patapata_firebase_analytics---v130)
 - [`patapata_firebase_auth` - `v1.3.0`](#patapata_firebase_auth---v130)
 - [`patapata_firebase_core` - `v1.4.0`](#patapata_firebase_core---v140)
 - [`patapata_firebase_crashlytics` - `v1.4.0`](#patapata_firebase_crashlytics---v140)
 - [`patapata_firebase_messaging` - `v1.4.0`](#patapata_firebase_messaging---v140)
 - [`patapata_firebase_remote_config` - `v1.4.0`](#patapata_firebase_remote_config---v140)
 - [`patapata_riverpod` - `v1.4.0`](#patapata_riverpod---v140)
 - [`patapata_sentry` - `v1.3.0`](#patapata_sentry---v130)
 - [`patapata_builder` - `v1.2.1`](#patapata_builder---v121)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `patapata_builder` - `v1.2.1`

---

#### `patapata_core` - `v2.0.0`

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

#### `patapata_apple_push_notifications` - `v1.3.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_firebase_analytics` - `v1.3.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_firebase_auth` - `v1.3.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_firebase_core` - `v1.4.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_firebase_crashlytics` - `v1.4.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_firebase_messaging` - `v1.4.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_firebase_remote_config` - `v1.4.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_riverpod` - `v1.4.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.

#### `patapata_sentry` - `v1.3.0`

 - **FEAT**: Support Flutter 3.38.0 and set the minimum supported version to 3.35.0.


## 2025-10-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_builder` - `v1.2.0`](#patapata_builder---v120)
 - [`patapata_core` - `v1.4.0`](#patapata_core---v140)
 - [`patapata_riverpod` - `v1.3.0`](#patapata_riverpod---v130)
 - [`patapata_sentry` - `v1.2.2`](#patapata_sentry---v122)
 - [`patapata_firebase_remote_config` - `v1.3.1`](#patapata_firebase_remote_config---v131)
 - [`patapata_firebase_analytics` - `v1.2.2`](#patapata_firebase_analytics---v122)
 - [`patapata_firebase_messaging` - `v1.3.1`](#patapata_firebase_messaging---v131)
 - [`patapata_firebase_auth` - `v1.2.2`](#patapata_firebase_auth---v122)
 - [`patapata_firebase_core` - `v1.3.1`](#patapata_firebase_core---v131)
 - [`patapata_apple_push_notifications` - `v1.2.2`](#patapata_apple_push_notifications---v122)
 - [`patapata_firebase_crashlytics` - `v1.3.1`](#patapata_firebase_crashlytics---v131)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `patapata_sentry` - `v1.2.2`
 - `patapata_firebase_remote_config` - `v1.3.1`
 - `patapata_firebase_analytics` - `v1.2.2`
 - `patapata_firebase_messaging` - `v1.3.1`
 - `patapata_firebase_auth` - `v1.2.2`
 - `patapata_firebase_core` - `v1.3.1`
 - `patapata_apple_push_notifications` - `v1.2.2`
 - `patapata_firebase_crashlytics` - `v1.3.1`

---

#### `patapata_builder` - `v1.2.0`

 - **FEAT**: support flutter 3.35.0.

#### `patapata_core` - `v1.4.0`

 - **FIX**: local_web_config, Monitor StorageEvent to detect changes from another tab.
 - **FIX**: setMany in web_local_config causes cast error.
 - **FEAT**: bump minimum Flutter version to 3.29.0.
 - **FEAT**: support flutter 3.35.0.
 - **DOCS**: Added description of StandardPage.buildPage.

#### `patapata_riverpod` - `v1.3.0`

 - **FEAT**: support flutter 3.35.0.


## 2025-04-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_builder` - `v1.1.0`](#patapata_builder---v110)
 - [`patapata_core` - `v1.3.0`](#patapata_core---v130)
 - [`patapata_firebase_auth` - `v1.2.1`](#patapata_firebase_auth---v121)
 - [`patapata_firebase_core` - `v1.3.0`](#patapata_firebase_core---v130)
 - [`patapata_firebase_crashlytics` - `v1.3.0`](#patapata_firebase_crashlytics---v130)
 - [`patapata_firebase_messaging` - `v1.3.0`](#patapata_firebase_messaging---v130)
 - [`patapata_firebase_remote_config` - `v1.3.0`](#patapata_firebase_remote_config---v130)
 - [`patapata_apple_push_notifications` - `v1.2.1`](#patapata_apple_push_notifications---v121)
 - [`patapata_sentry` - `v1.2.1`](#patapata_sentry---v121)
 - [`patapata_riverpod` - `v1.2.1`](#patapata_riverpod---v121)
 - [`patapata_firebase_analytics` - `v1.2.1`](#patapata_firebase_analytics---v121)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `patapata_apple_push_notifications` - `v1.2.1`
 - `patapata_sentry` - `v1.2.1`
 - `patapata_riverpod` - `v1.2.1`
 - `patapata_firebase_analytics` - `v1.2.1`

---

#### `patapata_builder` - `v1.1.0`

 - **FEAT**: Addition of the New Feature: Repository System.

#### `patapata_core` - `v1.3.0`

 - **FIX**: When running bootstrap on a new Flutter project, the uses-material-design entry is unintentionally removed from pubspec.yaml.
 - **FEAT**: support flutter 3.29.0.
 - **FEAT**: Added the SynchronousErrorableFuture class. This class is used within the repository system, but it is recommended to avoid using it in general.
 - **FEAT**: Addition of the New Feature: Repository System.
 - **FEAT**: When creating a `PatapataException` , if the currently displayed page has a [StandardPageWithResult.localizationKey] set, the default key can now be overridden using the localizationKey.
 - **FEAT**: Support for WebAssembly (Wasm).
 - **FEAT**: The StandardPage now includes the `StandardPageWithResult.localizationKey` property. This allows for localization by utilizing context.pl with the specified key.
 - **DOCS**: Fix some dartdocs that are interpreted as HTML.
 - **DOCS**: Fix parts that do not match the Dart formatter.

#### `patapata_firebase_auth` - `v1.2.1`

 - **DOCS**: Updated README for minimum version.

#### `patapata_firebase_core` - `v1.3.0`

 - **FEAT**: Update a dependency.

#### `patapata_firebase_crashlytics` - `v1.3.0`

 - **FEAT**: Update a dependency.

#### `patapata_firebase_messaging` - `v1.3.0`

 - **FEAT**: Update a dependency.
 - **FEAT**: support flutter 3.29.0.

#### `patapata_firebase_remote_config` - `v1.3.0`

 - **FEAT**: Update a dependency.


## 2025-01-08

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_apple_push_notifications` - `v1.2.0`](#patapata_apple_push_notifications---v120)
 - [`patapata_core` - `v1.2.0`](#patapata_core---v120)
 - [`patapata_firebase_analytics` - `v1.2.0`](#patapata_firebase_analytics---v120)
 - [`patapata_firebase_auth` - `v1.2.0`](#patapata_firebase_auth---v120)
 - [`patapata_firebase_core` - `v1.2.0`](#patapata_firebase_core---v120)
 - [`patapata_firebase_crashlytics` - `v1.2.0`](#patapata_firebase_crashlytics---v120)
 - [`patapata_firebase_messaging` - `v1.2.0`](#patapata_firebase_messaging---v120)
 - [`patapata_firebase_remote_config` - `v1.2.0`](#patapata_firebase_remote_config---v120)
 - [`patapata_riverpod` - `v1.2.0`](#patapata_riverpod---v120)
 - [`patapata_sentry` - `v1.2.0`](#patapata_sentry---v120)

---

#### `patapata_apple_push_notifications` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.

#### `patapata_core` - `v1.2.0`

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

#### `patapata_firebase_analytics` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.

#### `patapata_firebase_auth` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.

#### `patapata_firebase_core` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.

#### `patapata_firebase_crashlytics` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.

#### `patapata_firebase_messaging` - `v1.2.0`

 - **FIX**: update com.android.tools.build:gradle:8.1.0.
 - **FEAT**: support flutter 3.27.1.

#### `patapata_firebase_remote_config` - `v1.2.0`

 - **FIX**: firebase remote config can not listen to remote config changes on the web.
 - **FEAT**: support flutter 3.27.1.

#### `patapata_riverpod` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.

#### `patapata_sentry` - `v1.2.0`

 - **FEAT**: support flutter 3.27.1.


## 2024-06-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_apple_push_notifications` - `v1.1.1`](#patapata_apple_push_notifications---v111)
 - [`patapata_firebase_analytics` - `v1.1.1`](#patapata_firebase_analytics---v111)
 - [`patapata_firebase_core` - `v1.1.1`](#patapata_firebase_core---v111)
 - [`patapata_firebase_crashlytics` - `v1.1.1`](#patapata_firebase_crashlytics---v111)
 - [`patapata_firebase_messaging` - `v1.1.1`](#patapata_firebase_messaging---v111)
 - [`patapata_firebase_remote_config` - `v1.1.1`](#patapata_firebase_remote_config---v111)
 - [`patapata_sentry` - `v1.1.1`](#patapata_sentry---v111)

---

#### `patapata_apple_push_notifications` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.

#### `patapata_firebase_analytics` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.

#### `patapata_firebase_core` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.

#### `patapata_firebase_crashlytics` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.

#### `patapata_firebase_messaging` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.

#### `patapata_firebase_remote_config` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.

#### `patapata_sentry` - `v1.1.1`

 - **FIX**: when running dart doc, some documentation is not generated.


## 2024-05-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_apple_push_notifications` - `v1.1.0`](#patapata_apple_push_notifications---v110)
 - [`patapata_core` - `v1.1.0`](#patapata_core---v110)
 - [`patapata_firebase_analytics` - `v1.1.0`](#patapata_firebase_analytics---v110)
 - [`patapata_firebase_auth` - `v1.1.0`](#patapata_firebase_auth---v110)
 - [`patapata_firebase_core` - `v1.1.0`](#patapata_firebase_core---v110)
 - [`patapata_firebase_crashlytics` - `v1.1.0`](#patapata_firebase_crashlytics---v110)
 - [`patapata_firebase_messaging` - `v1.1.0`](#patapata_firebase_messaging---v110)
 - [`patapata_firebase_remote_config` - `v1.1.0`](#patapata_firebase_remote_config---v110)
 - [`patapata_riverpod` - `v1.1.0`](#patapata_riverpod---v110)
 - [`patapata_sentry` - `v1.1.0`](#patapata_sentry---v110)

---

#### `patapata_apple_push_notifications` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_core` - `v1.1.0`

 - **FEAT**: support flutter 3.22.0 by updating intl dependency constraints.
 - **FEAT**: Adapt to the Privacy Manifest.
 - **FEAT**: allow to choose whether to wait for microtasks, timers, and periodic timers in a SequentialWorkQueue, as well as ProviderModel's lock function.

#### `patapata_firebase_analytics` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_firebase_auth` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_firebase_core` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_firebase_crashlytics` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_firebase_messaging` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_firebase_remote_config` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_riverpod` - `v1.1.0`

 - **FEAT**: Adapt to the Privacy Manifest.

#### `patapata_sentry` - `v1.1.0`

 - **FIX**: patapata_sentry Invalid argument Instance of ReportRecord.
 - **FIX**: patapata_sentry null exception.
 - **FEAT**: Adapt to the Privacy Manifest.


## 2024-03-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_core` - `v1.0.2`](#patapata_core---v102)
 - [`patapata_firebase_crashlytics` - `v1.0.2`](#patapata_firebase_crashlytics---v102)
 - [`patapata_riverpod` - `v1.0.2`](#patapata_riverpod---v102)
 - [`patapata_firebase_auth` - `v1.0.2`](#patapata_firebase_auth---v102)
 - [`patapata_firebase_remote_config` - `v1.0.2`](#patapata_firebase_remote_config---v102)
 - [`patapata_firebase_messaging` - `v1.0.2`](#patapata_firebase_messaging---v102)
 - [`patapata_firebase_core` - `v1.0.2`](#patapata_firebase_core---v102)
 - [`patapata_firebase_analytics` - `v1.0.2`](#patapata_firebase_analytics---v102)
 - [`patapata_sentry` - `v1.0.2`](#patapata_sentry---v102)
 - [`patapata_apple_push_notifications` - `v1.0.2`](#patapata_apple_push_notifications---v102)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `patapata_firebase_crashlytics` - `v1.0.2`
 - `patapata_riverpod` - `v1.0.2`
 - `patapata_firebase_auth` - `v1.0.2`
 - `patapata_firebase_remote_config` - `v1.0.2`
 - `patapata_firebase_messaging` - `v1.0.2`
 - `patapata_firebase_core` - `v1.0.2`
 - `patapata_firebase_analytics` - `v1.0.2`
 - `patapata_sentry` - `v1.0.2`
 - `patapata_apple_push_notifications` - `v1.0.2`

---

#### `patapata_core` - `v1.0.2`

 - **FIX**: patapata_core documentation, add widget_test.dart overwrite logic.


## 2024-03-25

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`patapata_apple_push_notifications` - `v1.0.1`](#patapata_apple_push_notifications---v101)
 - [`patapata_core` - `v1.0.1`](#patapata_core---v101)
 - [`patapata_firebase_analytics` - `v1.0.1`](#patapata_firebase_analytics---v101)
 - [`patapata_firebase_auth` - `v1.0.1`](#patapata_firebase_auth---v101)
 - [`patapata_firebase_core` - `v1.0.1`](#patapata_firebase_core---v101)
 - [`patapata_firebase_crashlytics` - `v1.0.1`](#patapata_firebase_crashlytics---v101)
 - [`patapata_firebase_messaging` - `v1.0.1`](#patapata_firebase_messaging---v101)
 - [`patapata_firebase_remote_config` - `v1.0.1`](#patapata_firebase_remote_config---v101)
 - [`patapata_riverpod` - `v1.0.1`](#patapata_riverpod---v101)
 - [`patapata_sentry` - `v1.0.1`](#patapata_sentry---v101)

---

#### `patapata_apple_push_notifications` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_core` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.
 - **DOCS**: fix badge for github actions checks.

#### `patapata_firebase_analytics` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_firebase_auth` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_firebase_core` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_firebase_crashlytics` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_firebase_messaging` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_firebase_remote_config` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_riverpod` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

#### `patapata_sentry` - `v1.0.1`

 - **DOCS**: fix the URL of the repository written in pubspec.yaml.

