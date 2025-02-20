// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

typedef TestRecord = (int?, double?, String?);

enum TestPattern {
  type1,
  type2,
}

enum TestValue {
  v1,
  v2,
  v3,
}

class TestData {
  static final List<Map<int, TestRecord>> _datas = [
    {
      1: (1, 0.1, 'id: 1 / pattern 1'),
      2: (2, 0.2, 'id: 2 / pattern 1'),
      3: (3, 0.3, 'id: 3 / pattern 1'),
      4: (4, 0.4, 'id: 4 / pattern 1'),
      5: (5, 0.5, 'id: 5 / pattern 1'),
      6: (6, 0.6, 'id: 6 / pattern 1'),
    },
    {
      1: (11, 0.11, 'id: 1 / pattern 2'),
      2: (22, 0.22, 'id: 2 / pattern 2'),
      3: (33, 0.33, 'id: 3 / pattern 2'),
      4: (44, 0.44, 'id: 4 / pattern 2'),
      5: (55, 0.55, 'id: 5 / pattern 2'),
      6: (66, 0.66, 'id: 6 / pattern 2'),
    },
  ];

  TestPattern pattern = TestPattern.type1;
  Map<int, TestRecord> get data => _datas[pattern.index];
}
