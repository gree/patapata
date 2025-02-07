// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of 'repository.dart';

class _RepositoryCacheMap<K, V> extends MapBase<K, V> {
  _RepositoryCacheMap({
    required this.maximumSize,
  });

  final _accessor = HashMap<K, V>();
  // ignore: prefer_collection_literals
  final _usedOrder = LinkedHashSet<K>();
  final int maximumSize;

  @override
  Iterable<K> get keys => _accessor.keys;

  @override
  Iterable<V> get values => _accessor.values;

  @override
  Iterable<MapEntry<K, V>> get entries => _accessor.entries;

  @override
  int get length => _accessor.length;

  @override
  bool get isEmpty => _accessor.isEmpty;

  @override
  bool get isNotEmpty => _accessor.isNotEmpty;

  @override
  V? operator [](Object? key) {
    final tValue = _accessor[key];
    if (tValue != null) {
      _updateOrder(key as K);
      return tValue;
    }

    return null;
  }

  @override
  void operator []=(K key, V value) {
    _accessor[key] = value;
    _updateOrder(key);

    if (length > maximumSize) {
      // It is intentional that the order of processing is different only here.
      // If deletion is executed first, unintended elements may be deleted.
      _removeOldest();
    }
  }

  @override
  V? remove(Object? key) {
    final tValue = _accessor.remove(key);
    if (tValue == null) {
      return null;
    }

    _usedOrder.remove(key);
    return tValue;
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    var tKeysToRemove = <K>[];
    for (final e in _accessor.entries) {
      if (test(e.key, e.value)) {
        tKeysToRemove.add(e.key);
      }
    }

    for (final key in tKeysToRemove) {
      remove(key);
    }
  }

  @override
  void clear() {
    _accessor.clear();
    _usedOrder.clear();
  }

  @override
  bool containsKey(Object? key) => _accessor.containsKey(key);

  @override
  bool containsValue(Object? value) => _accessor.values.contains(value);

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) transform) {
    var tResult = <K2, V2>{};
    for (var key in this.keys) {
      var tEntry = transform(key, _accessor[key] as V);
      tResult[tEntry.key] = tEntry.value;
    }

    return tResult;
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final tValue = _accessor.putIfAbsent(key, () => ifAbsent());
    if (length > maximumSize) {
      _removeOldest();
    }

    _updateOrder(key);
    return tValue;
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    if (containsKey(key)) {
      return this[key] = update(this[key] as V);
    }

    if (ifAbsent != null) {
      if (length > maximumSize) {
        _removeOldest();
      }

      return this[key] = ifAbsent();
    }

    throw ArgumentError.value(key, 'key', 'Key not in map.');
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    for (final e in _accessor.entries) {
      _accessor[e.key] = update(e.key, e.value);
    }
  }

  V get oldest {
    final tLatestKey = _usedOrder.first;
    return _accessor[tLatestKey]!;
  }

  Iterable<K> get orderKeys => _usedOrder;
  Iterable<V> get orderValues {
    final tList = <V>[];

    for (final k in _usedOrder) {
      tList.add(_accessor[k] as V);
    }

    return tList;
  }

  void _updateOrder(K key) {
    _usedOrder.remove(key);
    _usedOrder.add(key);
  }

  void _removeOldest() {
    final tLast = _usedOrder.first;
    _accessor.remove(tLast);
    _usedOrder.remove(tLast);
  }
}
