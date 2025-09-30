// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/errors.dart';
import 'package:patapata_example_app/src/pages/device_and_package_info_page.dart';
import 'package:patapata_example_app/src/pages/standard_page_example_page.dart';
import 'package:provider/provider.dart';

import 'page_data.dart';
import 'src/cupertino/widgets/app_container.dart';
import 'src/cupertino/pages/top_page.dart';
import 'src/cupertino/pages/home_page.dart';
import 'src/cupertino/pages/my_page.dart';
import 'src/environment.dart';
import 'src/pages/config_page.dart';
import 'src/widgets/app_container.dart';
import 'src/pages/home_page.dart';
import 'src/pages/my_page.dart';
import 'src/pages/screen_layout_example_page.dart';
import 'src/pages/top_page.dart';
import 'src/startup.dart';
import 'src/pages/error_page.dart';
import 'src/pages/splash_page.dart';
import 'src/pages/agreement_page.dart';
import 'src/repository/repository_example1.dart';
import 'src/repository/repository_example2.dart';
import 'src/repository/default_example.dart';
import 'src/repository/object_example.dart';

final _providerKey = GlobalKey(debugLabel: 'AppProviderKey');
final logger = Logger('patapata.example');

void main() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  App(
    environment: const Environment(),
    startupSequence: StartupSequence(
      startupStateFactories: [
        StartupStateFactory<StartupStateCheckVersion>(
          (startupSequence) => StartupStateCheckVersion(startupSequence),
          [
            LogicStateTransition<StartupStateAgreements>(),
          ],
        ),
        StartupStateFactory<StartupStateAgreements>(
          (startupSequence) => StartupStateAgreements(startupSequence),
          [],
        ),
      ],
    ),
    createAppWidget: _createAppWidget,
    plugins: [],
    providerKey: _providerKey,
  )
    ..getPlugin<NotificationsPlugin>()?.enableStandardAppIntegration()
    ..run(() async {
      // Do any initialization here
      // Here's a good default

      // Set a default orientation of only portrait
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
      ]);

      // Enable Edge-to-Edge mode
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Make the status bars transparent
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ));

      // Set your RemoteConfig defaults here
      await getApp().remoteConfig.setDefaults(const <String, Object>{});
    });
}

final _globalAppKey = GlobalKey<NavigatorState>(
  debugLabel: 'patapataExampleGlobalAppKey',
);
BuildContext get globalAppContext => _globalAppKey.currentContext!;

/// Returns either [StandardMaterialApp] or [StandardCupertinoApp] to be passed to [App.createAppWidget].
/// The choice between the two depends on [Environment.appType] in [App.environment].
/// If [flutter run --dart-define=APP_TYPE=cupertino] is used, it uses [StandardCupertinoApp].
/// Otherwise, it uses [StandardMaterialApp].
Widget _createAppWidget(BuildContext context, App<Environment> app) {
  if (app.environment.appType == 'cupertino') {
    return StandardCupertinoApp(
      onGenerateTitle: (context) => l(context, 'title'),
      pages: [
        // Splash screen page.
        // This uses a special factory that has good defaults for splash screens.
        if (!kIsWeb)
          SplashPageFactory<SplashPage>(
            create: (_) => SplashPage(),
          ),
        // Agreement page.
        // This uses a special factory that all StartupSequence pages should use.
        StartupPageFactory<AgreementPage>(
          create: (_) => AgreementPage(),
        ),
        // Cupertino Top Page.
        // This is the top page to navigate to after the AgreementPage.
        // On this page, there are links to sample pages showcasing various features available in Patapata.
        StandardPageFactory<CupertinoTopPage, void>(
          create: (_) => CupertinoTopPage(),
          links: {
            r'': (match, uri) {},
          },
          linkGenerator: (pageData) => '',
          groupRoot: true,
        ),
        // Cupertino Tab and pages.
        StandardPageWithNestedNavigatorFactory<CupertinoAppContainer>(
          create: (data) => CupertinoAppContainer(),
          links: {
            r'/tab': (match, uri) {},
          },
          linkGenerator: (pageData) => '/tab',
          nestedPageFactories: [
            StandardPageWithNestedNavigatorFactory<CupertinoHomePageParent>(
              create: (data) => CupertinoHomePageParent(),
              nestedPageFactories: [
                StandardPageFactory<CupertinoHomePage, void>(
                  create: (data) => CupertinoHomePage(),
                  links: {
                    r'home': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'home',
                ),
                StandardChildPageFactory<CupertinoTestPageA, void, void>(
                  create: (data) => CupertinoTestPageA(),
                  links: {
                    r'page_a': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'page_a',
                  createParentPageData: (_) {},
                ),
              ],
            ),
            StandardPageWithNestedNavigatorFactory<CupertinoMyPageParent>(
              create: (data) => CupertinoMyPageParent(),
              nestedPageFactories: [
                StandardPageFactory<CupertinoMyPage, void>(
                  create: (data) => CupertinoMyPage(),
                  links: {
                    r'my_page': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'my_page',
                ),
                StandardChildPageFactory<CupertinoTestPageB, void, void>(
                  create: (data) => CupertinoTestPageB(),
                  links: {
                    r'page_b': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'page_b',
                  createParentPageData: (_) {},
                ),
              ],
            ),
          ],
          anyNestedPageFactories: [
            StandardPageFactory<CupertinoTestPageC, void>(
              create: (data) => CupertinoTestPageC(),
              links: {
                r'page_c': (match, uri) {},
              },
              linkGenerator: (pageData) => 'page_c',
              childPageFactories: [
                StandardChildPageFactory<CupertinoTestPageD, void, void>(
                  create: (data) => CupertinoTestPageD(),
                  links: {
                    r'page_d': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'page_d',
                  createParentPageData: (_) {},
                ),
              ],
            ),
          ],
        ),
      ],
      routableBuilder: (context, child) {
        // Setup [ScreenLayout]
        // You may want to move this to the body section of your Scaffold
        // or somewhere where it makes sense for your app's design.
        child = ScreenLayout(child: child);

        // Wrap the app in a key provided by you
        // so you can access your providers from anywhere
        // via context.read and context.watch.
        child = KeyedSubtree(
          key: _providerKey,
          child: child,
        );

        return child;
      },
    );
  } else {
    return StandardMaterialApp(
      onGenerateTitle: (context) => l(context, 'title'),
      theme: ThemeData(
        // pageTransitionsTheme is explicitly set to the old transition on Android.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          },
        ),
      ),
      pages: [
        // Splash screen page.
        if (!kIsWeb)
          SplashPageFactory<SplashPage>(
            create: (_) => SplashPage(),
          ),
        // Agreement page.
        StartupPageFactory<AgreementPage>(
          create: (_) => AgreementPage(),
        ),
        // Error page.
        StandardErrorPageFactory(
          create: (exception) => switch (exception.error) {
            AppException _ => AppExceptionPage(),
            WebPageNotFound _ => WebPageNotFoundPage(),
            _ => UnknownExceptionPage(),
          },
        ),
        // Top Page.
        StandardPageFactory<TopPage, void>(
          create: (_) => TopPage(),
          links: {
            r'': (match, uri) {},
          },
          linkGenerator: (pageData) => '/',
          groupRoot: true,
        ),
        // LocalConfig Sample Page.
        StandardPageFactory<ConfigPage, void>(
          create: (_) => ConfigPage(),
          links: {
            r'config': (match, uri) {},
          },
          linkGenerator: (pageData) => '/config',
        ),
        // DeviceInfo and PackageInfo Sample Page.
        StandardPageFactory<DeviceAndPackageInfoPage, void>(
          create: (_) => DeviceAndPackageInfoPage(),
          links: {
            r'package': (match, uri) {},
          },
          linkGenerator: (pageData) => '/package',
        ),
        // Error Select Page.
        StandardPageFactory<ErrorSelectPage, void>(
          create: (_) => ErrorSelectPage(),
          links: {
            r'error': (match, uri) {},
          },
          linkGenerator: (pageData) => '/error',
        ),
        StandardPageFactory<ErrorPageSpecificPage, void>(
          create: (_) => ErrorPageSpecificPage(),
        ),
        // The page with an example implementation of ScreenLayout.
        StandardPageFactory<ScreenLayoutExamplePage, void>(
          create: (data) => ScreenLayoutExamplePage(),
        ),
        StandardPageFactory<RepositoryExample1, void>(
          create: (data) => RepositoryExample1(),
        ),
        StandardPageFactory<RepositoryExample2, RepositoryExsamplePageData>(
          create: (data) => RepositoryExample2(),
        ),
        // StandardPage And PageData Sample Page.
        StandardPageFactory<StandardPageExamplePage, void>(
          create: (_) => StandardPageExamplePage(),
        ),
        // HasDataPage is a page that receives PageData and displays it.
        StandardPageFactory<HasDataPage, PageData>(
          create: (data) => HasDataPage(),
        ),
        // CustomStandardPage is a page where the functionality of StandardPage is customized using pageBuilder.
        // It customizes things like transition animations during navigation.
        StandardPageFactory<CustomStandardPage, void>(
          create: (data) => CustomStandardPage(),
          pageBuilder: (
            child,
            name,
            pageData,
            pageKey,
            restorationId,
            standardPageKey,
            factoryObject,
          ) {
            return StandardCustomPage(
              name: "Custom Page",
              arguments: PageData(),
              key: pageKey,
              restorationId: restorationId,
              standardPageKey: standardPageKey,
              factoryObject: factoryObject,
              opaque: true,
              barrierDismissible: true,
              barrierColor: Colors.blueAccent,
              child: Column(
                children: [
                  Expanded(child: child),
                  const Text("test"),
                ],
              ),
              transitionDuration: const Duration(milliseconds: 500),
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                          .animate(animation),
                  child: child,
                );
              },
            );
          },
        ),
        // ChangeListenablePage is an example where, instead of PageData,
        // it can observe changes such as ChangeNotifier.
        // BaseListenable inherits from ChangeNotifier.
        StandardPageFactory<ChangeListenablePage, BaseListenable>(
          create: (data) => ChangeListenablePage(),
        ),
        // Tab page with footer navigation.
        StandardPageWithNestedNavigatorFactory<AppContainer>(
          create: (data) => AppContainer(),
          links: {
            r'/tab': (match, uri) {},
          },
          linkGenerator: (pageData) => '/tab',
          nestedPageFactories: [
            StandardPageWithNestedNavigatorFactory<HomePageParent>(
              create: (data) => HomePageParent(),
              nestedPageFactories: [
                StandardPageFactory<HomePage, void>(
                  create: (data) => HomePage(),
                  links: {
                    r'home': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'home',
                ),
                StandardPageFactory<TestPageA, void>(
                  create: (data) => TestPageA(),
                  links: {
                    r'page_a': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'page_a',
                ),
              ],
            ),
            StandardPageWithNestedNavigatorFactory<MyPageParent>(
              create: (data) => MyPageParent(),
              nestedPageFactories: [
                StandardPageFactory<MyPage, void>(
                  create: (data) => MyPage(),
                  links: {
                    r'my_page': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'my_page',
                ),
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
                  links: {
                    r'page_b': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'page_b',
                ),
              ],
            ),
          ],
          anyNestedPageFactories: [
            StandardPageFactory<TestPageC, void>(
              create: (data) => TestPageC(),
              links: {
                r'page_c': (match, uri) {},
              },
              linkGenerator: (pageData) => 'page_c',
              childPageFactories: [
                StandardChildPageFactory<TestPageD, void, void>(
                  create: (data) => TestPageD(),
                  links: {
                    r'page_d': (match, uri) {},
                  },
                  linkGenerator: (pageData) => 'page_d',
                  createParentPageData: (_) {},
                ),
              ],
            ),
          ],
        ),
      ],
      routableBuilder: (context, child) {
        // Setup [ScreenLayout]
        // You may want to move this to the body section of your Scaffold
        // or somewhere where it makes sense for your app's design.
        child = ScreenLayout(child: child);

        // Wrap the app in a key provided by you
        // so you can access your providers from anywhere
        // via context.read and context.watch.
        child = KeyedSubtree(
          key: _providerKey,
          child: child,
        );

        // If you want to customize a Theme, you can do it here
        // by wrapping the child with a Theme widget.
        // You can also wrap anything here and that Widget will
        // be available to all pages.
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<CountData>(
              create: (context) => CountData(),
            ),
            ChangeNotifierProvider<ChangeListenableBool>(
              create: (context) => ChangeListenableBool(),
            ),
            ChangeNotifierProvider<ChangeListenableNumber>(
              create: (context) => ChangeListenableNumber(),
            ),
            Provider(
              create: (context) => DataRepository(),
            ),
            Provider(
              create: (context) => ObjectRepository(),
            ),
          ],
          child: child,
        );
      },
    );
  }
}
