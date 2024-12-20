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
import 'src/cupertino/pages/top_page.dart';
import 'src/cupertino/pages/home_page.dart';
import 'src/cupertino/pages/my_page.dart';
import 'src/environment.dart';
import 'src/pages/config_page.dart';
import 'src/pages/home_page.dart';
import 'src/pages/my_page.dart';
import 'src/pages/screen_layout_example_page.dart';
import 'src/pages/top_page.dart';
import 'src/startup.dart';
import 'src/pages/error_page.dart';
import 'src/pages/splash_page.dart';
import 'src/pages/agreement_page.dart';

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
        // CupertinoTitlePage are pages related to the tabs on the CupertinoHomePage.
        // The parent of the tabs in Home is the CupertinoHomePage, and the first child page displayed within that tab is the CupertinoTitlePage.
        StandardPageFactory<CupertinoHomePage, void>(
          create: (data) => CupertinoHomePage(),
        ),
        StandardPageFactory<CupertinoTitlePage, void>(
          create: (data) => CupertinoTitlePage(),
          parentPageType: CupertinoHomePage,
        ),
        // CupertinoMyFavoritePage is a page related to the tabs on CupertinoMyPage.
        // The parent of the tabs in CupertinoMyPage is CupertinoMyPage itself, and the first child page displayed within that tab is CupertinoMyFavoritePage.
        StandardPageFactory<CupertinoMyPage, void>(
          create: (data) => CupertinoMyPage(),
        ),
        StandardPageFactory<CupertinoMyFavoritePage, void>(
          create: (data) => CupertinoMyFavoritePage(),
          parentPageType: CupertinoMyPage,
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
        // Material Tab and pages.
        // TitlePage and TitleDetailsPage are pages related to the tabs on the HomePage.
        // The parent of the tabs in Home is the HomePage,
        // and the first child page displayed within that tab is the TitlePage.
        StandardPageFactory<HomePage, void>(
          create: (data) => HomePage(),
        ),
        StandardPageFactory<TitlePage, void>(
          create: (data) => TitlePage(),
          parentPageType: HomePage,
        ),
        StandardPageFactory<TitleDetailsPage, void>(
          create: (data) => TitleDetailsPage(),
          parentPageType: HomePage,
        ),
        // MyFavoritePage is a page related to the tabs on MyPage.
        // The parent of the tabs in MyPage is MyPage itself,
        // and the first child page displayed within that tab is MyFavoritePage.
        StandardPageFactory<MyPage, void>(
          create: (data) => MyPage(),
        ),
        StandardPageFactory<MyFavoritePage, void>(
          create: (data) => MyFavoritePage(),
          parentPageType: MyPage,
        ),
        // The page with an example implementation of ScreenLayout.
        StandardPageFactory<ScreenLayoutExamplePage, void>(
          create: (data) => ScreenLayoutExamplePage(),
        ),
        // StandardPage And PageData Sample Page.
        StandardPageFactory<StandardPageExamplePage, void>(
          create: (_) => StandardPageExamplePage(),
          links: {
            r'': (match, uri) {},
          },
          linkGenerator: (pageData) => '',
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
        )
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
          ],
          child: child,
        );
      },
    );
  }
}
