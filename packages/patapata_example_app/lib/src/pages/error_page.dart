// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

import '../../exceptions.dart';
import '../../main.dart';
import '../errors.dart';

/// ErrorPage is a page that is displayed when an error occurs in the application.
class ErrorPage extends StandardPage<ReportRecord> {
  @override
  Widget buildPage(BuildContext context) {
    if (pageData.error is AppException) {
      return _buildAppExceptionPage(context);
    } else {
      return _buildUnknownExceptionPage(context);
    }
  }

  Widget _buildAppExceptionPage(BuildContext context) {
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

  Widget _buildUnknownExceptionPage(BuildContext context) {
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

/// ErrorSelectPage is a page that allows you to select the type of error to display.
class ErrorSelectPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.error.title')),
      ),
      body: ListView(
        children: [
          // Throw an exception named ExampleException, defined in the sample app, and log it.
          TextButton(
            onPressed: () {
              try {
                throw const ExampleException();
              } on PatapataException catch (e) {
                e.showDialog(context);
                logger.severe(e.toString(), e);
              }
            },
            child: Text(l(context, 'pages.error.example')),
          ),
          // Throw a network exception named ExampleNetworkException, defined in the sample app, and log it.
          // Specify the network status code in the statusCode argument of ExampleNetworkException.
          TextButton(
            onPressed: () {
              try {
                throw const ExampleNetworkException(statusCode: 404);
              } on PatapataException catch (e) {
                e.showDialog(context);
                logger.severe(e.toString(), e);
              }
            },
            child: Text(l(context, 'pages.error.network', {'prefix': '404'})),
          ),
          TextButton(
            onPressed: () {
              try {
                throw const ExampleNetworkException(statusCode: 500);
              } on PatapataException catch (e) {
                e.showDialog(context);
                logger.severe(e.toString(), e);
              }
            },
            child: Text(l(context, 'pages.error.network', {'prefix': '500'})),
          ),
          // Throw ExampleMaintenanceException, transition to the maintenance page, and navigate to ErrorSelectPage.
          TextButton(
            onPressed: () {
              final tDelegate = context.read<App>().standardAppPlugin.delegate;
              try {
                throw ExampleMaintenanceException(fix: () async {
                  tDelegate?.go<ErrorSelectPage, void>(
                      null, StandardPageNavigationMode.removeAll);
                });
              } catch (e) {
                logger.severe(e.toString(), e);
              }
            },
            child: Text(l(context, 'pages.error.maintenance')),
          ),
        ],
      ),
    );
  }
}
