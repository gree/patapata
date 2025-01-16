// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

/// This is an implementation of a screen where users can agree to the app's terms and conditions.
/// It appears after the splash screen. If the user does not agree, they will be taken back to the splash screen again.
class AgreementPage extends StandardPage<StartupPageCompleter> {
  @override
  String localizationKey = 'pages.agreement';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
      ),
      body: Column(
        children: [
          Center(
            child: Text(context.pl('body')),
          ),
          TextButton(
            child: Text(context.pl('yes')),
            onPressed: () {
              pageData(null);
            },
          ),
          TextButton(
            child: Text(context.pl('no')),
            onPressed: () {
              // Calling the sequence processing again will resume the sequence from the beginning.
              getApp().startupSequence?.resetMachine();
            },
          ),
        ],
      ),
    );
  }
}
