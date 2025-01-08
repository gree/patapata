# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

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

