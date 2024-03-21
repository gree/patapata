// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';

import 'utils/patapata_core_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PackageInfoPlugin', () async {
    PackageInfoPlugin.setMockValues(
      appName: 'mock_patapata_core',
      packageName: 'io.flutter.plugins.mockpatapatacore',
      version: '1.0',
      buildNumber: '1',
      buildSignature: 'patapata_core_build_signature',
      installerStore: null,
    );

    final PackageInfoPlugin tPackageInfo = PackageInfoPlugin();

    final tApp = createApp();
    final bool tResult = await tPackageInfo.init(tApp);

    expect(
      tResult,
      isTrue,
    );

    expect(
      tPackageInfo.info.appName == 'mock_patapata_core',
      isTrue,
    );
  });
}
