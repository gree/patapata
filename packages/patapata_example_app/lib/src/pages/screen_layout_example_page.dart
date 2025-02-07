// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_widgets.dart';

class ScreenLayoutExamplePage extends StandardPage<void> {
  @override
  String localizationKey = 'pages.screen_layout_example';

  final _breakpoints = const ScreenLayoutBreakpoints(
    portraitStandardBreakpoint: 375.0,
    portraitConstrainedWidth: double.infinity,
    landscapeStandardBreakpoint: 375.0,
    landscapeConstrainedWidth: double.infinity,
    maxScale: 1.2,
  );

  String createSampleDescription(double width) {
    String tDescription = context.pl('base_description_before');

    if (width == 375) {
      tDescription += context.pl(
        'description_case_equal',
        {'width': widget},
      );
    } else if (width > 375) {
      tDescription += context.pl(
        'description_case_over',
        {'width': widget},
      );
    } else {
      tDescription += context.pl(
        'description_case_other',
        {'width': widget},
      );
    }

    tDescription += context.pl('base_description_before');

    return tDescription;
  }

  @override
  Widget buildPage(BuildContext context) {
    Widget fCreateSampleChild() {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 37.5,
            height: 300,
            child: ColoredBox(
              color: Colors.blue.shade100,
              child: const Center(child: Text('37.5')),
            ),
          ),
          SizedBox(
            width: 300,
            height: 300,
            child: ColoredBox(
              color: Colors.deepOrange.shade100,
              child: const Center(child: Text('w300 x h300')),
            ),
          ),
          SizedBox(
            width: 37.5,
            height: 300,
            child: ColoredBox(
              color: Colors.blue.shade100,
              child: const Center(child: Text('37.5')),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
      ),
      body: Center(
        child: ListView(
          children: [
            Center(
              child: Text(context.pl('body')),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                createSampleDescription(MediaQuery.of(context).size.width),
              ),
            ),
            Center(
              child: Text(
                context.pl('sample_a'),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            fCreateSampleChild(),
            const SizedBox(height: 32),
            Center(
              child: Text(
                context.pl('sample_b'),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            ScreenLayout(
              breakpoints: _breakpoints,
              child: fCreateSampleChild(),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(context.pl('description')),
            ),
            Center(
              child: ScreenLayout(
                breakpoints: _breakpoints.copyWith(
                  portraitConstrainedWidth: 200,
                ),
                child: fCreateSampleChild(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                context.pl('description_example'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
