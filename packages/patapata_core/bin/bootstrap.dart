// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:xml/xml.dart';
import 'package:yaml_edit/yaml_edit.dart';

void main(List<String> arguments) {
  late final ArgParser tParser;

  tParser = ArgParser()
    ..addSeparator(
      'Bootstrap your Patapata project.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message.',
      negatable: false,
      defaultsTo: false,
    )
    ..addFlag(
      'force',
      abbr: 'f',
      help: 'Rewrite existing files.',
      negatable: false,
      defaultsTo: false,
    )
    ..addFlag(
      'i18n',
      help: 'Enable I18n support.',
      defaultsTo: true,
    )
    ..addMultiOption(
      'locale',
      abbr: 'l',
      help: 'Which locale codes to support.',
      defaultsTo: ['en'],
    )
    ..addFlag(
      'errors',
      help: 'Enable customization of the error handling system.',
      defaultsTo: false,
    )
    ..addFlag(
      'log',
      help: 'Enable customization of the logging system.',
      defaultsTo: true,
    )
    ..addFlag(
      'notifications',
      help: 'Enable customization of the notifications system.',
      defaultsTo: false,
    )
    ..addFlag(
      'screenlayout',
      help: 'Enable customization of ScreenLayout breakpoints.',
      defaultsTo: false,
    );

  try {
    final tResults = tParser.parse(arguments);

    if (tResults['help'] == true) {
      stdout.writeln(tParser.usage);
      return;
    }

    if (tResults.rest.isNotEmpty) {
      throw UsageException(
        'Unexpected arguments: ${tResults.rest.join(', ')}',
        tParser.usage,
      );
    }

    // Check if an environment.dart file exists.
    // And if not, create it with a default Environment class.
    _checkEnvironmentFile(tResults);

    // Check if a splash_page.dart file exists.
    // And if not, create it with a default SplashPage class.
    _checkSplashPageFile(tResults);

    // Check if a agreement_page.dart file exists.
    // And if not, create it with a default AgreementPage class.
    _checkAgreementPageFile(tResults);

    // Check if a home_page.dart file exists.
    // And if not, create it with a default HomePage class.
    _checkHomePageFile(tResults);

    // Check if a startup.dart file exists.
    // And if not, create it with several default startup sequence states.
    _checkStartupFile(tResults);

    // Check if a errors.dart file exists.
    // And if not, create it with some default errors.
    _checkErrorsFile(tResults);

    // Check if a main.dart file exists.
    // And if not, create it with a default main function.
    _checkMainFile(tResults);

    // Check if an AndroidManifest.xml file exists.
    // And if so, check if it contains the flutter_deeplinking_enabled meta-data.
    _checkAndroidManifestFile(tResults);

    // Change Android Gradle Plugin version to 8.7.0
    _checkAndroidGradleSettingsFile(tResults);

    // Change Android Gradle Wrapper version to 8.10.2
    _checkAndroidGradleWrapperFile(tResults);

    // Check if coreLibraryDesugaringEnabled is set; if not, add it.
    _checkAndroidGradleFile(tResults);

    // Check if Info.plist file contains the FlutterDeepLinkingEnabled key.
    // And if not, set it to true.
    _checkInfoPlistFile(tResults);

    // Check if the minumum version of iOS is unset.
    // If it is, set it to 13.0.
    _checkPodFile(tResults);

    // Check if the l10n directory exists.
    // And if not, create it.
    _checkL10nFiles(tResults);

    // Check if a widget_test.dart file exists.
    // And if not, create it with a empty code.
    _checkWidgetTestFile(tResults);
  } catch (e) {
    switch (e) {
      case UsageException():
        stderr.writeln(e.message);
        stderr.writeln(e.usage);
        exit(64);
      case FormatException():
        stderr.writeln(e.message);
        stderr.writeln(tParser.usage);
        exit(64);
      default:
        rethrow;
    }
  }
}

void _checkEnvironmentFile(ArgResults results) {
  stdout.writeln('Checking environment.dart file...');

  final tFile = File('lib/src/environment.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating environment.dart file...');
    final tMixins = <String>{
      if (results['i18n'] == true) 'I18nEnvironment',
      if (results['errors'] == true) 'ErrorEnvironment',
      if (results['log'] == true) 'LogEnvironment',
      if (results['notifications'] == true) 'NotificationsEnvironment',
      if (results['screenlayout'] == true) 'ScreenLayoutEnvironment',
    };

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter/foundation.dart';
import 'package:patapata_core/patapata_core.dart';
${tMixins.contains('ScreenLayoutEnvironment') ? '''
import 'package:patapata_core/patapata_widgets.dart';
''' : ''}
${tMixins.contains('ScreenLayoutEnvironment') || tMixins.contains('LogEnvironment') ? '''
import 'package:flutter/widgets.dart';
''' : ''}

/// The Environment class for this app.
/// Controls all static settings for the app.
/// Pass this to the [App] constructor.
class Environment${tMixins.isNotEmpty ? ' with\n${tMixins.join(',\n')}' : ''} {

  ${tMixins.contains('I18nEnvironment') ? '''
  @override
  final List<Locale> supportedL10ns = const [
${[
                    for (final tLocale in results['locale'] as List<String>)
                      "Locale('$tLocale')",
                  ].join(',\n')}
  ];

  @override
  final List<String> l10nPaths = const [
    'l10n',
  ];

''' : ''}
  ${tMixins.contains('ErrorEnvironment') ? '''
  @override
  final Map<String, String>? errorReplacePrefixMap;

  @override
  final Widget Function(PatapataException)? errorDefaultWidget;

  @override
  final Future<void> Function(BuildContext, PatapataException)? errorDefaultShowDialog;

''' : ''}
${tMixins.contains('LogEnvironment') ? '''
  @override
  final int logLevel;

  @override
  final bool printLog;

''' : ''}
${tMixins.contains('NotificationsEnvironment') ? '''
  @override
  final String notificationsAndroidDefaultIcon;

  @override
  final bool notificationsDarwinDefaultPresentAlert;

  @override
  final bool notificationsDarwinDefaultPresentSound;

  @override
  final bool notificationsDarwinDefaultPresentBadge;

  @override
  final bool notificationsDarwinDefaultPresentBanner;

  @override
  final bool notificationsDarwinDefaultPresentList;

  @override
  final List<AndroidNotificationChannel> notificationsAndroidChannels;

  @override
  final String notificationsPayloadLocationKey;

''' : ''}
${tMixins.contains('ScreenLayoutEnvironment') ? '''
  @override
  final Map<String, ScreenLayoutBreakpoints> screenLayoutBreakpoints;

''' : ''}

  const Environment({
    ${tMixins.contains('ErrorEnvironment') ? '''
    this.errorReplacePrefixMap,
    this.errorDefaultWidget,
    this.errorDefaultShowDialog,
''' : ''}
    ${tMixins.contains('LogEnvironment') ? '''
    this.logLevel = const int.fromEnvironment('LOG_LEVEL', defaultValue: -kPataInHex),
    this.printLog = const bool.fromEnvironment('PRINT_LOG', defaultValue: kDebugMode),
''' : ''}
    ${tMixins.contains('NotificationsEnvironment') ? '''
    this.notificationsAndroidDefaultIcon = '@mipmap/ic_launcher',
    this.notificationsDarwinDefaultPresentAlert = true,
    this.notificationsDarwinDefaultPresentSound = true,
    this.notificationsDarwinDefaultPresentBadge = true,
    this.notificationsDarwinDefaultPresentBanner = true,
    this.notificationsDarwinDefaultPresentList = true,
    this.notificationsAndroidChannels = const [
      NotificationsPlugin.kDefaultAndroidChannel,
    ],
    this.notificationsPayloadLocationKey = 'location',
''' : ''}
    ${tMixins.contains('ScreenLayoutEnvironment') ? '''
    this.screenLayoutBreakpoints = const {
      'normal': ScreenLayoutDefaultBreakpoints.normal,
      'large': ScreenLayoutDefaultBreakpoints.large,
    },
''' : ''}
  });
}
'''));
  }

  stdout.writeln('Done.');
}

void _checkMainFile(ArgResults results) {
  stdout.writeln('Checking main.dart file...');

  final tFile = File('lib/main.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating main.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import 'src/environment.dart';
import 'src/startup.dart';
import 'src/errors.dart';
import 'src/pages/error.dart';
import 'src/pages/splash_page.dart';
import 'src/pages/agreement_page.dart';
import 'src/pages/home_page.dart';

final _providerKey = GlobalKey(debugLabel: 'AppProviderKey');

void main() {
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
    createAppWidget: (context, app) => StandardMaterialApp(
      onGenerateTitle: (context) => l(context, 'title'),
      pages: [
        // Splash screen page.
        // This uses a special factory that has good defaults for splash screens.
        if (!kIsWeb)
          SplashPageFactory<SplashPage>(
            create: (_) => SplashPage(),
          ),
        // Agreement page.
        // This uses a special factory that all [StartupSequence] pages should use.
        StartupPageFactory<AgreementPage>(
          create: (_) => AgreementPage(),
        ),
        // Error page.
        // This uses a special factory that all full screen error pages should use.
        StandardErrorPageFactory(
          create: (exception) => switch (exception.error) {
            AppException _ => AppExceptionPage(),
            WebPageNotFound _ => WebPageNotFoundPage(),
            _ => UnknownExceptionPage(),
          },
        ),
        StandardPageFactory<HomePage, void>(
          create: (_) => HomePage(),
          links: {
            r'': (match, uri) {},
          },
          linkGenerator: (pageData) => '',
          groupRoot: true,
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

        // Add your [Provider]s here
        // child = MultiProvider(
        //   providers: const [
        //     // Provider<YourProvider>(
        //     //   create: (_) => YourProvider(),
        //     // ),
        //   ],
        //   child: child,
        // );

        return child;
      },
    ),
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
'''));
  }

  stdout.writeln('Done.');
}

void _checkSplashPageFile(ArgResults results) {
  stdout.writeln('Checking splash_page.dart file...');

  final tFile = File('lib/src/pages/splash_page.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating splash_page.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_widgets.dart';

class SplashPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return const Center(
      child: FlutterLogo(
        size: 128,
      ),
    );
  }
}
'''));
  }

  stdout.writeln('Done.');
}

void _checkAgreementPageFile(ArgResults results) {
  stdout.writeln('Checking agreement_page.dart file...');

  final tFile = File('lib/src/pages/agreement_page.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating agreement_page.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

class AgreementPage extends StandardPage<StartupPageCompleter> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.agreement.title')),
      ),
      body: Column(
        children: [
          Center(
            child: Text(
              l(context, 'pages.agreement.body'),
            ),
          ),
          TextButton(
            child: Text(l(context, 'pages.agreement.yes')),
            onPressed: () {
              pageData(null);
            },
          ),
          TextButton(
            child: Text(l(context, 'pages.agreement.no')),
            onPressed: () {
              getApp().startupSequence?.resetMachine();
            },
          ),
        ],
      ),
    );
  }
}
'''));
  }

  stdout.writeln('Done.');
}

void _checkHomePageFile(ArgResults results) {
  stdout.writeln('Checking home_page.dart file...');

  final tFile = File('lib/src/pages/home_page.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating home_page.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

class HomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.home.title')),
      ),
      body: Center(
        child: Text(l(context, 'pages.home.body')),
      ),
    );
  }
}
'''));
  }

  stdout.writeln('Done.');
}

void _checkStartupFile(ArgResults results) {
  stdout.writeln('Checking startup.dart file...');

  final tFile = File('lib/src/startup.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating startup.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:patapata_core/patapata_core.dart';

import 'errors.dart';
import 'pages/agreement_page.dart';

class StartupStateCheckVersion extends StartupState {
  StartupStateCheckVersion(StartupSequence startupSequence) : super(startupSequence);

  @override
  Future<void> process(Object? data) async {
    // Check the version here
    // If the version is not supported, throw an exception
    // and the app will show the error page.
    // If the version is supported, transition to the next state.
    final tIsNewestVersion = true; // TODO: Change this with your own logic.

    if (!tIsNewestVersion) {
      throw AppVersionException();
    }
  }
}

class StartupStateAgreements extends StartupState {
  /// The version of the agreement.
  /// This should be incremented when the agreement changes.
  static const kVersion = '1';

  static const _kAgreementVersionKey = 'agreementVersion';

  StartupStateAgreements(StartupSequence startupSequence) : super(startupSequence);

  @override
  Future<void> process(Object? data) async {
    // Check if the user has agreed to the agreement.
    // If the user has agreed, return.
    if (getApp().localConfig.getString(_kAgreementVersionKey) == kVersion) {
      return;
    }

    // Show the agreement page here.
    // If the user agrees, call pageData(null);
    // If the user does not agree, call getApp().startupSequence?.resetMachine();
    // which will reset the startup sequence.
    if (await navigateToPage(AgreementPage, (result) {})) {
      await getApp().localConfig.setString(_kAgreementVersionKey, kVersion);
    }
  }
}
'''));
  }

  stdout.writeln('Done.');
}

void _checkErrorsFile(ArgResults results) {
  stdout.writeln('Checking errors.dart file...');

  final tFile = File('lib/src/errors.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating errors.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';

abstract base class AppException extends PatapataException {
  AppException({
    super.app,
    super.message,
    super.original,
    super.fingerprint,
    super.localeTitleData,
    super.localeMessageData,
    super.localeFixData,
    super.fix,
    super.logLevel,
    super.userLogLevel,
    super.overridableLocalization,
  });

  @override
  // TODO: This should be a 3 letter code that is unique to your app.
  // TODO: We recommend using a mapping like the first two letters being
  // TODO: related to your app, and the last letter being related to the
  // TODO: type of error. E for error, W for warning, etc.
  String get defaultPrefix => 'APE';

  @override
  String get namespace => 'app';
}

/// An exception that is thrown when the app encounters an unknown error.
final class AppUnknownException extends AppException {
  AppUnknownException();

  @override
  String get internalCode => '000';
}

/// Thrown when an unsupported version (usually old) of the app is detected.
final class AppVersionException extends AppException {
  AppVersionException() : super(logLevel: Level.INFO);

  @override
  String get internalCode => '010';

  @override
  void onReported(ReportRecord record) {
    showDialog(getApp().navigatorContext);
  }

  @override
  Future<void> Function()? get fix => () async {
    // Launch the app store.
  };
}
'''));
  }

  // Also check and create the ErrorPage.
  final tErrorPageFile = File('lib/src/pages/error.dart');
  final tErrorPageFileExists = tErrorPageFile.existsSync();

  if (results['force'] == true || !tErrorPageFileExists) {
    stdout.writeln('Creating error.dart file...');

    if (!tErrorPageFileExists) {
      tErrorPageFile.createSync(recursive: true);
    }

    tErrorPageFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import '../errors.dart';

class AppExceptionPage extends StandardPage<ReportRecord> {
  @override
  Widget buildPage(BuildContext context) {
    final tAppException = pageData.error as AppException;

    return Scaffold(
      appBar: AppBar(
        title: Text(tAppException.localizedTitle),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(tAppException.localizedMessage),
            if (tAppException.hasFix)
              TextButton(
                child: Text(tAppException.localizedFix),
                onPressed: () {
                  tAppException.fix!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class WebPageNotFoundPage extends StandardPage<ReportRecord> {
  @override
  Widget buildPage(BuildContext context) {
    final tException = pageData.error as WebPageNotFound;

    return Scaffold(
      appBar: AppBar(
        title: Text(tException.localizedTitle),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(tException.localizedMessage),
          ],
        ),
      ),
    );
  }
}

class UnknownExceptionPage extends StandardPage<ReportRecord> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'errors.app.000.title')),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(l(context, 'errors.app.000.message')),
          ],
        ),
      ),
    );
  }
}
'''));
  }

  stdout.writeln('Done.');
}

void _checkAndroidManifestFile(ArgResults results) {
  stdout.writeln('Checking AndroidManifest.xml file...');

  // Check if the AndroidManifest.xml file contains an main activity that has
  // meta-data of flutter_deeplinking_enabled, and if not, add it.
  final tFile = File('android/app/src/main/AndroidManifest.xml');
  final tFileExists = tFile.existsSync();

  if (!tFileExists) {
    stdout.writeln('AndroidManifest.xml file not found.');

    return;
  }

  final tDocument = XmlDocument.parse(tFile.readAsStringSync());
  final tMainActivities =
      tDocument.findAllElements('activity').where((element) {
    final tIntentFilters =
        element.findAllElements('intent-filter').where((element) {
      final tActions = element.findAllElements('action').where((element) {
        return element.getAttribute('android:name') ==
            'android.intent.action.MAIN';
      });

      final tCategories = element.findAllElements('category').where((element) {
        return element.getAttribute('android:name') ==
            'android.intent.category.LAUNCHER';
      });

      return tActions.isNotEmpty && tCategories.isNotEmpty;
    });

    return tIntentFilters.isNotEmpty;
  });

  if (tMainActivities.isEmpty) {
    stdout.writeln('No main activity found.');

    return;
  }

  final tMainActivity = tMainActivities.first;

  final tMetaData = tMainActivity.findAllElements('meta-data').where((element) {
    return element.getAttribute('android:name') ==
        'flutter_deeplinking_enabled';
  });

  if (tMetaData.isEmpty) {
    stdout.writeln(
        'No meta-data found. Adding the Flutter Deep Linking feature.');

    tMainActivity.children.add(XmlElement(
      XmlName('meta-data'),
      [
        XmlAttribute(XmlName('android:name'), 'flutter_deeplinking_enabled'),
        XmlAttribute(XmlName('android:value'), 'true'),
      ],
      [],
      false,
    ));

    tFile.writeAsStringSync(tDocument.toXmlString(pretty: true));
  }
}

void _checkAndroidGradleSettingsFile(ArgResults results) {
  stdout.writeln('Checking Android Gradle Settings file...');

  const kFileKtsPath = 'android/settings.gradle.kts';
  const kFileGradlePath = 'android/settings.gradle';

  final File tFile;
  final bool tIsKts;
  if (!File(kFileKtsPath).existsSync()) {
    if (!File(kFileGradlePath).existsSync()) {
      stdout.writeln('Android Gradle Settings file not found.');

      return;
    }

    tFile = File(kFileGradlePath);
    tIsKts = false;
  } else {
    tFile = File(kFileKtsPath);
    tIsKts = true;
  }

  String tDocument = tFile.readAsStringSync();

  // Replace the Android Gradle Plugin with 8.7.0
  tDocument = tDocument.replaceAll(
    (tIsKts)
        ? 'id("com.android.application") version "8.1.0" apply false'
        : 'id "com.android.application" version "8.1.0" apply false',
    (tIsKts)
        ? 'id("com.android.application") version "8.7.0" apply false'
        : 'id "com.android.application" version "8.7.0" apply false',
  );

  tFile.writeAsStringSync(tDocument.toString());
}

void _checkAndroidGradleWrapperFile(ArgResults results) {
  stdout.writeln('Checking Android Gradle Wrapper file...');

  final tFile = File('android/gradle/wrapper/gradle-wrapper.properties');

  if (!tFile.existsSync()) {
    stdout.writeln('Android Gradle Wrapper file not found.');

    return;
  }

  String tDocument = tFile.readAsStringSync();

  // Replace the Gradle with 8.10.2
  tDocument = tDocument.replaceAll(
    'gradle-8.3-all.zip',
    'gradle-8.10.2-all.zip',
  );

  tFile.writeAsStringSync(tDocument.toString());
}

void _checkAndroidGradleFile(ArgResults results) {
  stdout.writeln('Checking Android Gradle file...');

  const kFileKtsPath = 'android/app/build.gradle.kts';
  const kFileGradlePath = 'android/app/build.gradle';

  final File tFile;
  final bool tIsKts;
  if (!File(kFileKtsPath).existsSync()) {
    if (!File(kFileGradlePath).existsSync()) {
      stdout.writeln('Android Gradle file not found.');

      return;
    }

    tFile = File(kFileGradlePath);
    tIsKts = false;
  } else {
    tFile = File(kFileKtsPath);
    tIsKts = true;
  }

  String tDocument = tFile.readAsStringSync();

  // Add configuration for coreLibraryDesugaring
  // This is because flutter_local_notifications, which patapata_core depends on, uses Java 8 features.

  final tDesugarEnableText = (tIsKts)
      ? 'isCoreLibraryDesugaringEnabled = true'
      : 'coreLibraryDesugaringEnabled = true';
  final tDesugarLibraryText = (tIsKts)
      ? 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")'
      : 'coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"';

  if (!tDocument.contains(tDesugarEnableText)) {
    final tCompileOptionsRegex = RegExp(
      r'compileOptions\s*\{([^}]*)\}',
      dotAll: true,
    );
    final tMatch = tCompileOptionsRegex.firstMatch(tDocument)!;
    final tBlockInside = tMatch.group(1)!.trimRight();

    final tNewBlockInside = '''
$tBlockInside
        $tDesugarEnableText
''';

    tDocument = tDocument.replaceRange(
      tMatch.start,
      tMatch.end,
      'compileOptions {$tNewBlockInside    }',
    );
  }

  if (!tDocument.contains(tDesugarLibraryText)) {
    final tDependenciesRegex = RegExp(
      r'dependencies\s*\{([^}]*)\}',
      dotAll: true,
    );
    final tMatch = tDependenciesRegex.firstMatch(tDocument);
    if (tMatch != null) {
      final tBlockInside = tMatch.group(1)!.trimRight();

      final tNewBlockInside = '''
$tBlockInside
    $tDesugarLibraryText
''';

      tDocument = tDocument.replaceRange(
        tMatch.start,
        tMatch.end,
        'dependencies {$tNewBlockInside}',
      );
    } else {
      tDocument = '''
$tDocument
dependencies {
    $tDesugarLibraryText
}
''';
    }
  }

  tFile.writeAsStringSync(tDocument.toString());
}

void _checkInfoPlistFile(ArgResults results) {
  stdout.writeln('Checking Info.plist file...');

  // Check if the Info.plist file contains the FlutterDeepLinkingEnabled key.
  // And if not, set it to true.
  final tFile = File('ios/Runner/Info.plist');
  final tFileExists = tFile.existsSync();

  if (!tFileExists) {
    stdout.writeln('Info.plist file not found.');

    return;
  }

  final tDocument = XmlDocument.parse(tFile.readAsStringSync());
  // This should be the first element under plist.
  final tDictElement = tDocument.findAllElements('dict').first;
  final tKeys = tDictElement.findAllElements('key').where((element) {
    return element.innerText == 'FlutterDeepLinkingEnabled';
  });

  if (tKeys.isEmpty) {
    stdout.writeln(
        'No FlutterDeepLinkingEnabled key found. Adding the Flutter Deep Linking feature.');

    tDictElement.children.add(XmlElement(
      XmlName('key'),
      [],
      [
        XmlText('FlutterDeepLinkingEnabled'),
      ],
      false,
    ));

    tDictElement.children.add(XmlElement(
      XmlName('true'),
      [],
      [],
      true,
    ));

    tFile.writeAsStringSync(tDocument.toXmlString(pretty: true));
  }

  stdout.writeln('Done.');
}

void _checkPodFile(ArgResults results) {
  stdout.writeln('Checking Podfile file...');

  // Check if the Podfile file contains the minimum version of iOS of 13.0.
  // And if not, change it to 13.0.
  final tFile = File('ios/Podfile');
  final tFileExists = tFile.existsSync();

  if (!tFileExists) {
    stdout.writeln('Podfile file not found.');

    return;
  }

  // Replace the minimum version of iOS with 13.0 as plain text
  // The default setting after flutter create is a commented out line.
  // So we remove that whole line and replace it.
  // As of writting this code, the default line is:
  // # platform :ios, '12.0'
  final tDocument = tFile
      .readAsStringSync()
      .replaceAll('# platform :ios, \'12.0\'', 'platform :ios, \'13.0\'');

  tFile.writeAsStringSync(tDocument.toString());
}

void _checkL10nFiles(ArgResults results) {
  stdout.writeln('Checking l10n files...');

  // Check if the l10n directory exists.
  // And if not, create it.
  final tDirectory = Directory('l10n');
  final tDirectoryExists = tDirectory.existsSync();

  if (!tDirectoryExists) {
    stdout.writeln('l10n directory not found. Creating it.');
    tDirectory.createSync(recursive: true);
  }

  // Check if each of the Locales specified in the arguments exists.
  // If not, create them.
  for (final tLocale in results['locale'] as List<String>) {
    final tFile = File('l10n/$tLocale.yaml');
    final tFileExists = tFile.existsSync();

    if (!tFileExists) {
      stdout.writeln('l10n/$tLocale.yaml file not found. Creating it.');
      tFile.createSync(recursive: true);

      tFile.writeAsStringSync('''
title: App Title
pages:
  agreement:
    title: Agreement
    body: This is the agreement page. Do you accept?
    yes: Yes
    no: No
  home:
    title: Home
    body: This is the home page.
errors:
  patapata:
    '601':
      title: Page not found
      message: Page not found.
  app:
    '000':
      title: Unknown Error
      message: An unknown error has occurred.
    '010':
      title: Unsupported Version
      message: This version of the app is no longer supported.
      fix: Please update the app.
''');
    }
  }

  stdout.writeln('Adding l10n.yaml files to flutter assets in pubspec.yaml...');

  final tPubspecFile = File('pubspec.yaml');
  final tPubspecFileExists = tPubspecFile.existsSync();

  if (!tPubspecFileExists) {
    stdout.writeln('pubspec.yaml file not found.');

    return;
  }

  final tPubspecDocument = YamlEditor(tPubspecFile.readAsStringSync());

  final tFlutterNode = tPubspecDocument.parseAt(
    ['flutter'],
    orElse: () {
      tPubspecDocument.update(['flutter'], null);
      return tPubspecDocument.parseAt(['flutter']);
    },
  );

  final tAssetsNode = tPubspecDocument.parseAt(
    ['flutter', 'assets'],
    orElse: () {
      if (tFlutterNode.value is Map) {
        tPubspecDocument.update(['flutter', 'assets'], []);
      } else {
        tPubspecDocument.update(['flutter'], {'assets': []});
      }

      return tPubspecDocument.parseAt(['flutter', 'assets']);
    },
  );

  final tAssetsList = tAssetsNode.value as List;
  for (final tLocale in results['locale'] as List<String>) {
    final tPath = 'l10n/$tLocale.yaml';
    if (!tAssetsList.contains(tPath)) {
      tPubspecDocument.appendToList(['flutter', 'assets'], tPath);
    }
  }

  tPubspecFile.writeAsStringSync(tPubspecDocument.toString());

  stdout.writeln('Done.');
}

void _checkWidgetTestFile(ArgResults results) {
  stdout.writeln('Checking widget_test.dart file...');

  final tFile = File('test/widget_test.dart');
  final tFileExists = tFile.existsSync();

  if (results['force'] == true || !tFileExists) {
    stdout.writeln('Creating widget_test.dart file...');

    if (!tFileExists) {
      tFile.createSync(recursive: true);
    }

    tFile.writeAsStringSync(
        DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
            .format('''
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty', (WidgetTester tester) async {});
}
'''));
  }

  stdout.writeln('Done.');
}
