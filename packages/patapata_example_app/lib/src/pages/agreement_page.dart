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
              // Calling the sequence processing again will resume the sequence from the beginning.
              getApp().startupSequence?.resetMachine();
            },
          ),
        ],
      ),
    );
  }
}
