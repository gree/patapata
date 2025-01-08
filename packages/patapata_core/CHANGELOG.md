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