// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_widgets.dart';

/// This is the page displayed after the app is launched. It shows the Flutter logo.
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
