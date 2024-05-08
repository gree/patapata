// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:patapata_core/patapata_core.dart';

import 'pages/agreement_page.dart';

class StartupStateCheckVersion extends StartupState {
  StartupStateCheckVersion(super.startupSequence);

  @override
  Future<void> process(Object? data) async {
    // Check the version here
    // If the version is not supported, throw an exception
    // and the app will show the error page.
    // If the version is supported, transition to the next state.

    return Future.delayed(const Duration(milliseconds: 1000));
  }
}

class StartupStateAgreements extends StartupState {
  /// The version of the agreement.
  /// This should be incremented when the agreement changes.
  static const kVersion = '1';

  // static const _kAgreementVersionKey = 'agreementVersion';

  StartupStateAgreements(super.startupSequence);

  @override
  Future<void> process(Object? data) async {
    // Check if the user has agreed to the agreement.
    // If the user has agreed, return.
    // if (getApp().localConfig.getString(_kAgreementVersionKey) == kVersion) {
    //   return;
    // }

    await navigateToPage(AgreementPage, (result) {});

    // Show the agreement page here.
    // If the user agrees, call pageData(null);
    // If the user does not agree, call getApp().startupSequence?.resetMachine();
    // which will reset the startup sequence.
    // if (await navigateToPage(AgreementPage, (result) {})) {
    //   await getApp().localConfig.setString(_kAgreementVersionKey, kVersion);
    // }
  }
}
