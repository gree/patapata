// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:test/test.dart';
import 'package:patapata_core/src/repository.dart';

void main() {
  group('TestableRepositoryCacheMap', () {
    late TestableRepositoryCacheMap<int, String> tCacheMap;

    setUp(() {
      tCacheMap = TestableRepositoryCacheMap<int, String>(maximumSize: 3);
    });

    test('empty', () {
      expect(tCacheMap.isEmpty, isTrue);
      expect(tCacheMap.isNotEmpty, isFalse);
      expect(tCacheMap.length, 0);
      expect(tCacheMap.entries.toList(), []);
    });

    test('should add and retrieve elements correctly', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      expect(tCacheMap.isEmpty, isFalse);
      expect(tCacheMap.isNotEmpty, isTrue);
      expect(tCacheMap.length, 3);

      expect(tCacheMap[1], 'A');
      expect(tCacheMap[2], 'B');
      expect(tCacheMap[3], 'C');
      expect(tCacheMap.keys, [1, 2, 3]);
      expect(tCacheMap.values, ['A', 'B', 'C']);
      expect(tCacheMap.entries.map((e) => e.key), [1, 2, 3]);
      expect(tCacheMap.entries.map((e) => e.value), ['A', 'B', 'C']);
    });

    test('should remove the oldest element when exceeding max size', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';
      tCacheMap[4] = 'D';

      expect(tCacheMap.containsKey(1), isFalse);
      expect(tCacheMap.containsKey(2), isTrue);
      expect(tCacheMap.containsKey(3), isTrue);
      expect(tCacheMap.containsKey(4), isTrue);
    });

    test('should remove elements that match condition', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      tCacheMap.removeWhere((key, value) => value == 'B');

      expect(tCacheMap.containsKey(1), isTrue);
      expect(tCacheMap.containsKey(2), isFalse);
      expect(tCacheMap.containsKey(3), isTrue);
    });

    test('should update the order of elements when accessed', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      expect(tCacheMap[1], 'A');
      tCacheMap[4] = 'D';

      expect(tCacheMap.containsKey(2), isFalse);
      expect(tCacheMap.containsKey(1), isTrue);
      expect(tCacheMap.containsKey(3), isTrue);
      expect(tCacheMap.containsKey(4), isTrue);
    });

    test('should remove elements correctly', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';

      expect(tCacheMap.remove(1), 'A');
      expect(tCacheMap.containsKey(1), isFalse);
      expect(tCacheMap.containsKey(2), isTrue);
    });

    test('should clear all elements', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';

      tCacheMap.clear();

      expect(tCacheMap.isEmpty, isTrue);
      expect(tCacheMap.containsKey(1), isFalse);
      expect(tCacheMap.containsKey(2), isFalse);
    });

    test('should check key and value existence', () {
      tCacheMap[1] = 'A';

      expect(tCacheMap.containsKey(1), isTrue);
      expect(tCacheMap.containsKey(2), isFalse);
      expect(tCacheMap.containsValue('A'), isTrue);
      expect(tCacheMap.containsValue('B'), isFalse);
    });

    test('putIfAbsent should not overwrite existing keys', () {
      tCacheMap[1] = 'A';
      tCacheMap.putIfAbsent(1, () => 'B');

      expect(tCacheMap[1], 'A');
    });

    test(
      'putIfAbsent should remove the oldest element when exceeding max size',
      () {
        tCacheMap.putIfAbsent(1, () => 'A');
        tCacheMap.putIfAbsent(2, () => 'B');
        tCacheMap.putIfAbsent(3, () => 'C');
        tCacheMap.putIfAbsent(4, () => 'D');

        expect(tCacheMap.containsKey(1), isFalse);
        expect(tCacheMap.containsKey(2), isTrue);
        expect(tCacheMap.containsKey(3), isTrue);
        expect(tCacheMap.containsKey(4), isTrue);
      },
    );

    test('update should modify an existing value', () {
      tCacheMap[1] = 'A';
      tCacheMap.update(1, (value) => 'B');

      expect(tCacheMap[1], 'B');

      tCacheMap.update(1, (value) => 'C', ifAbsent: () => 'D');

      expect(tCacheMap[1], 'C');
    });

    test('update should add a new key if ifAbsent is provided', () {
      tCacheMap.update(1, (value) => 'B', ifAbsent: () => 'A');

      expect(tCacheMap[1], 'A');
    });

    test(
      'update should throw error if key is missing and ifAbsent is null',
      () {
        expect(() => tCacheMap.update(1, (value) => 'B'), throwsArgumentError);
      },
    );

    test(
      'update with ifAbsent should remove the oldest when exceeding max size',
      () {
        tCacheMap.update(1, (value) => 'A', ifAbsent: () => 'A');
        tCacheMap.update(2, (value) => 'B', ifAbsent: () => 'B');
        tCacheMap.update(3, (value) => 'C', ifAbsent: () => 'C');
        tCacheMap.update(4, (value) => 'D', ifAbsent: () => 'D');

        expect(tCacheMap.containsKey(1), isFalse);
        expect(tCacheMap.containsKey(2), isTrue);
        expect(tCacheMap.containsKey(3), isTrue);
        expect(tCacheMap.containsKey(4), isTrue);
      },
    );

    test('update without ifAbsent should not remove oldest', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      tCacheMap.update(2, (value) => 'B2');

      expect(tCacheMap[1], 'A');
      expect(tCacheMap[2], 'B2');
      expect(tCacheMap[3], 'C');
    });

    test('updateAll should modify all values', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      tCacheMap.updateAll((key, value) => '$value$key');

      expect(tCacheMap[1], 'A1');
      expect(tCacheMap[2], 'B2');
      expect(tCacheMap[3], 'C3');
    });

    test('map should correctly transform keys and values', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';

      final tNewMap = tCacheMap.map<String, int>(
        (key, value) => MapEntry(value, key),
      );

      expect(tNewMap, {'A': 1, 'B': 2});
    });

    test('should maintain correct order of keys and values', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      expect(tCacheMap.orderKeys.toList(), [1, 2, 3]);
      expect(tCacheMap.orderValues.toList(), ['A', 'B', 'C']);

      tCacheMap[2];

      expect(tCacheMap.orderKeys.toList(), [1, 3, 2]);
      expect(tCacheMap.orderValues.toList(), ['A', 'C', 'B']);
    });

    test('oldest returns the oldest item', () {
      tCacheMap[1] = 'A';
      tCacheMap[2] = 'B';
      tCacheMap[3] = 'C';

      expect(tCacheMap.oldest, 'A');

      tCacheMap[1];

      expect(tCacheMap.oldest, 'B');
    });
  });
}
