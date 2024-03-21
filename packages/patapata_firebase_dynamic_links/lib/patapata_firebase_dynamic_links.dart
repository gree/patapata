// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_firebase_dynamic_links;

import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_firebase_core/patapata_firebase_core.dart';

/// This is a plugin that provides functionality for Firebase Dynamic Links.
/// This plugin requires adding the [patapata_firebase_core](https://pub.dev/packages/patapata_firebase_core) package to your application.
class FirebaseDynamicLinksPlugin extends Plugin
    with StandardAppRoutePluginMixin {
  StreamSubscription<PendingDynamicLinkData>? _onLinkSubscription;
  PendingDynamicLinkData? _initialData;

  @override
  List<Type> get dependencies => [FirebaseCorePlugin];

  /// Initializes the [FirebaseDynamicLinksPlugin].
  /// Please note that Dynamic Links are not supported on the web.
  @override
  FutureOr<bool> init(App app) async {
    if (kIsWeb) {
      // It's not working right now.
      return false;
    }

    await super.init(app);

    _initialData = await FirebaseDynamicLinks.instance.getInitialLink();
    _onLinkSubscription = FirebaseDynamicLinks.instance.onLink.listen(_onLink);

    return true;
  }

  @override
  FutureOr<void> dispose() {
    _onLinkSubscription?.cancel();
    _onLinkSubscription = null;

    return super.dispose();
  }

  /// Retrieves the necessary [StandardRouteData] for the initial screen transition to the `Router`.
  @override
  Future<StandardRouteData?> getInitialRouteData() {
    if (_initialData == null) {
      return SynchronousFuture(null);
    }

    final tParser = app.getPlugin<StandardAppPlugin>()?.parser;

    if (tParser == null) {
      return SynchronousFuture(null);
    }

    return tParser.parseRouteInformation(
      RouteInformation(
        uri: _initialData!.link,
      ),
    );
  }

  void _onLink(PendingDynamicLinkData data) async {
    final tPlugin = app.getPlugin<StandardAppPlugin>();

    final tParser = tPlugin?.parser;

    if (tParser == null) {
      return;
    }

    final tConfiguration = await tParser.parseRouteInformation(
      RouteInformation(
        uri: data.link,
      ),
    );

    tPlugin?.delegate?.routeWithConfiguration(tConfiguration);
  }

  /// Generates an external link or shortened external link for [FirebaseDynamicLinks].
  Future<String?> generateExternalLink({
    required Uri link,
    required String uriPrefix,
    required String androidPackageName,
    required String iOSBundleId,
    required String iOSAppStoreId,
    String? googleAnalyticsCampaign,
    String? googleAnalyticsContent,
    String? googleAnalyticsMedium,
    String? googleAnalyticsSource,
    String? googleAnalyticsTerm,
    String? itunesConnectAnalyticsAffiliateToken,
    String? itunesConnectAnalyticsCampaignToken,
    String? itunesConnectAnalyticsProviderToken,
    String? description,
    Uri? image,
    String? title,
  }) async {
    var tLink = await FirebaseDynamicLinks.instance.buildLink(
      DynamicLinkParameters(
        link: link,
        uriPrefix: uriPrefix,
        androidParameters: AndroidParameters(
          packageName: androidPackageName,
        ),
        iosParameters: IOSParameters(
          bundleId: iOSBundleId,
          appStoreId: iOSAppStoreId,
        ),
        googleAnalyticsParameters: GoogleAnalyticsParameters(
          campaign: googleAnalyticsCampaign,
          content: googleAnalyticsContent,
          medium: googleAnalyticsMedium,
          source: googleAnalyticsSource,
          term: googleAnalyticsTerm,
        ),
        itunesConnectAnalyticsParameters: ITunesConnectAnalyticsParameters(
          affiliateToken: itunesConnectAnalyticsAffiliateToken,
          campaignToken: itunesConnectAnalyticsCampaignToken,
          providerToken: itunesConnectAnalyticsProviderToken,
        ),
        navigationInfoParameters: const NavigationInfoParameters(
          forcedRedirectEnabled: true,
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          description: description,
          imageUrl: image,
          title: title,
        ),
      ),
    );

    return (await FirebaseDynamicLinks.instance.buildShortLink(
      DynamicLinkParameters(
        link: link,
        uriPrefix: uriPrefix,
        longDynamicLink: tLink,
        androidParameters: AndroidParameters(
          packageName: androidPackageName,
        ),
        iosParameters: IOSParameters(
          bundleId: iOSBundleId,
          appStoreId: iOSAppStoreId,
        ),
        googleAnalyticsParameters: GoogleAnalyticsParameters(
          campaign: googleAnalyticsCampaign,
          content: googleAnalyticsContent,
          medium: googleAnalyticsMedium,
          source: googleAnalyticsSource,
          term: googleAnalyticsTerm,
        ),
        itunesConnectAnalyticsParameters: ITunesConnectAnalyticsParameters(
          affiliateToken: itunesConnectAnalyticsAffiliateToken,
          campaignToken: itunesConnectAnalyticsCampaignToken,
          providerToken: itunesConnectAnalyticsProviderToken,
        ),
        navigationInfoParameters: const NavigationInfoParameters(
          forcedRedirectEnabled: true,
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          description: description,
          imageUrl: image,
          title: title,
        ),
      ),
    ))
        .shortUrl
        .toString();
  }
}
