// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

class ErrorPage extends StandardPage<ReportRecord> {
  @override
  Widget buildPage(BuildContext context) {
    final tError = pageData.error as PatapataException;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tError.localizedMessage,
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
