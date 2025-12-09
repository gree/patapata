// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_annotation.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_interface.dart';
import 'package:provider/provider.dart';

import 'exception.dart';

part 'repository_cache_map.dart';
part 'repository_model.dart';
part 'repository_provider.dart';

final _logger = Logger('patapata.Repository');

const repositorySetCannotUsedAssertionMessage =
    'In SimpleRepositoryModel, the use of sets is not allowed. Please consider using RepositoryModel.';

/// Exception thrown when a list exceeding the configured fetch cache size is provided during [fetch].
class RepositoryCacheSizeOverflow extends PatapataCoreException {
  // coverage:ignore-start
  RepositoryCacheSizeOverflow() : super(code: PatapataCoreExceptionCode.PPE701);
  // coverage:ignore-end
}

/// Defines the handling of the cache during [fetch].
enum RepositoryFetchPolicy {
  /// Prioritize the cache.
  cacheFirst,

  /// Do not use the cache.
  noCache,
}

class _FetchSetEntry<I extends Object> {
  final I id;
  final Type set;

  const _FetchSetEntry(this.id, this.set);

  @override
  int get hashCode => Object.hash(id, set);

  @override
  bool operator ==(Object other) {
    return other is _FetchSetEntry<I> && other.id == id && other.set == set;
  }
}

class _ScheduledEntry<T extends RepositoryModelBase<T, I>, I extends Object> {
  final I id;
  final Completer<T?> completer;

  _ScheduledEntry(this.id, this.completer);

  @override
  int get hashCode => Object.hash(id, completer);

  // coverage:ignore-start
  @override
  bool operator ==(Object other) {
    return other is _ScheduledEntry<T, I> &&
        other.id == id &&
        other.completer == completer;
  }

  // coverage:ignore-end
}

/// Class for holding repository models.
/// Usually you should add this to your Widget tree using something like [Provider] or [InheritedWidget]
///
/// This class serves as the root of the repository system.
/// It interacts with logic and [RepositoryModel] through [RepositoryProvider].
/// Be sure to place it higher in the hierarchy than [RepositoryProvider].
abstract class Repository<
  T extends RepositoryModelBase<T, I>,
  I extends Object
> {
  /// Standard maximum cache size.
  static const kDefaultMaxObjectCacheSize = 100;

  /// Specifies the number of [fetch] operations that can be executed concurrently in [refreshMany] and [refreshAll].
  ///
  /// If the value is 0 or less, it will be treated as 1.
  int get maxConcurrentFetches => 1;

  /// Maximum size of the cache.
  @protected
  int get maxObjectCacheSize => kDefaultMaxObjectCacheSize;

  late final _objectCache = _RepositoryCacheMap<I, T>(
    maximumSize: maxObjectCacheSize,
  );
  final _objectFetchMap = HashMap<_FetchSetEntry<I>, Completer<T?>>();

  @visibleForTesting
  // ignore: library_private_types_in_public_api
  HashMap<_FetchSetEntry<I>, Completer<T?>> get objectFetchMap =>
      _objectFetchMap;

  /// Function to retrieve an individual repository model.
  /// Configure this to return the corresponding repository model for each set.
  @protected
  Map<Type, Future<T?> Function(I id)> get singleSetFetchers;

  /// Function to retrieve multiple repository models.
  /// Configure this to return the corresponding repository model for each set.
  @protected
  Map<Type, Future<List<T?>> Function(List<I> ids)> get multiSetFetchers;

  /// Specifies the delay in milliseconds when executing [fetch].
  /// It can be specified for each set.
  /// Depending on the data retrieval method, there may be overlap in content between [multiSetFetchers] and [singleSetFetchers].
  /// Within the range of [scheduleThresholds], if there is a [fetch] for the same set, it will be adjusted to be executed together.
  /// Sets that are frequently called with [fetch] can prevent the app from becoming sluggish by increasing this value.
  @protected
  Map<Type, Duration> get scheduleThresholds => {};

  final _scheduledFetches = <Type, Set<_ScheduledEntry<T, I>>>{};
  bool _scheduled = false;

  void _schedule(I id, Type set, Completer<T?> completer) {
    _scheduledFetches
        .putIfAbsent(set, () => {})
        .add(_ScheduledEntry<T, I>(id, completer));
    _scheduleIfNeeded(set);
  }

  void _scheduleMany(List<I> ids, Type set, List<Completer<T?>> completers) {
    final tEntries = _scheduledFetches.putIfAbsent(set, () => {});

    for (var i = 0; i < ids.length; i++) {
      tEntries.add(_ScheduledEntry<T, I>(ids[i], completers[i]));
    }

    _scheduleIfNeeded(set);
  }

  void _scheduleIfNeeded(Type set) {
    if (_scheduled) {
      return;
    }

    _scheduled = true;

    if (scheduleThresholds.containsKey(set)) {
      Future.delayed(scheduleThresholds[set]!).then((_) => _fetchScheduled());
    } else {
      scheduleFunction(_fetchScheduled);
    }
  }

  void _fetchScheduled() async {
    _scheduled = false;

    final tEntries = _scheduledFetches.entries.toList(growable: false);
    _scheduledFetches.clear();

    for (var e in tEntries) {
      ((Type set, Set<_ScheduledEntry<T, I>> entries) {
        final tIds = entries.map((e) => e.id).toList(growable: false);
        final tEntryList = entries.toList();

        multiSetFetchers[set]!(tIds)
            .then((objects) {
              for (var v in objects) {
                final tEntry = tEntryList.firstWhere(
                  (e) => e.id == v?.repositoryId,
                );
                tEntryList.remove(tEntry);

                _handleObject(v, set, tEntry.completer);
              }

              for (var f in tEntryList) {
                f.completer.complete(null);
              }
            })
            .catchError((error, stackTrace) {
              for (var i in entries.toList(growable: false)) {
                i.completer.completeError(error, stackTrace);
              }

              throw error;
            });
      })(e.key, e.value);
    }
  }

  T? _accessCache(I id) {
    final tObject = _objectCache[id];

    return tObject;
  }

  void _removeCache(T object) {
    _objectCache.remove(object.repositoryId);
    _handleCacheRemove(object);
  }

  void _handleCacheRemove(T object) {
    _cacheDurationTimers[object]?.cancel();

    // Force anyone listening to know we've been removed.
    // Things like [RepositoryProvider] will know that this object is not in the cache anymore,
    // and request a new fresh copy of the object to use.
    object._repositoryNotifyListeners();
  }

  void _setCache(I id, T object) {
    // Grab the last value that might get pushed out of the LRU.
    // so we can properly handle the removal.
    final tLastObject = _objectCache.isEmpty ? null : _objectCache.oldest;

    _objectCache[id] = object;

    if (tLastObject != object && tLastObject != _objectCache.oldest) {
      // It was removed.
      // This check is faster than iterating through the whole map.
      _handleCacheRemove(object);
    }
  }

  bool _cacheContains(I id) => _objectCache.containsKey(id);

  // TODO: runtime time
  late final _cacheDurationTimers = Expando<Timer>(
    '$runtimeType cache duration timers',
  );

  void _handleObjectCacheDuration(T object) {
    if (object is RepositoryModelCache) {
      final tDuration =
          (object as RepositoryModelCache).repositoryCacheDuration;
      if (tDuration != null) {
        // [Web] Browsers' setTimeout internally treat the delay time as a 32-bit signed integer.
        // Therefore, using a delay time exceeding 2,147,483,647 milliseconds (approximately 24.8 days)
        // will cause an integer overflow, and the timer will execute immediately.
        _cacheDurationTimers[object] = Timer(
          Duration(
            milliseconds: min(tDuration.inMilliseconds, ((1 << 31) - 1)),
          ),
          ((T object) {
            // Create a clean closure with 0 references to outside.
            return () {
              _logger.info(
                'Object cache duration expired: Have listeners: ${object._repositoryHasListeners}',
              );

              if (object._repositoryHasListeners) {
                refresh(object);
              }
            };
          })(object),
        );
      }
    }
  }

  T? _handleObject(T? object, Type set, Completer<T?> completer) {
    if (object == null) {
      completer.complete(null);

      return null;
    }

    if (!object.repositorySets.contains(set)) {
      if (object is! SimpleRepositoryModel) {
        _logger.warning(
          'Retrieved RepositoryModel does not contain expected set: $set',
        );
      } else {
        assert(false, repositorySetCannotUsedAssertionMessage);
      }

      completer.complete(null);

      return null;
    }

    final tId = object.repositoryId;

    if (_cacheContains(tId)) {
      // Update the set, don't create a new one.
      final tMainObject = _accessCache(tId)!;

      if (tMainObject is RepositoryModel<T, I>) {
        tMainObject
            .lock((batch) {
              tMainObject.update(batch, object);
              _handleObjectCacheDuration(tMainObject);
              batch.commit();
              completer.complete(tMainObject);
            })
            .catchError((error, stackTrace) {
              completer.completeError(error, stackTrace);
              return false;
            });
      } else {
        if (tMainObject is SimpleRepositoryModel<T, I>) {
          tMainObject.update(object);
        }

        completer.complete(tMainObject);
      }

      return tMainObject;
    } else {
      _setCache(tId, object);
      _handleObjectCacheDuration(object);
      completer.complete(object);

      return object;
    }
  }

  /// Stores the repository model in the cache.
  ///
  /// If an identical model exists within the cache, it will overwrite the existing model.
  /// The determination of identity is based on [RepositoryModelBase.repositoryId].
  ///
  /// For [RepositoryModel], the data to overwrite depends on the parameter set configured in [RepositoryClass.sets].
  /// Only the variables held by the parameter set to which the [RepositoryModel] belongs will be overwritten.
  ///
  /// For [SimpleRepositoryModel], the data to overwrite depends on the [SimpleRepositoryModel.update] in the derived class.
  Future<T> store(T object) async {
    final tId = object.repositoryId;

    if (_cacheContains(tId)) {
      // Update the set, don't create a new one.
      final tMainObject = _accessCache(tId)!;

      if (tMainObject is RepositoryModel<T, I>) {
        await tMainObject.lock((batch) {
          tMainObject.update(batch, object);
          _handleObjectCacheDuration(tMainObject);
          batch.commit();
        });
      } else {
        _handleObjectCacheDuration(tMainObject);

        if (tMainObject is SimpleRepositoryModel<T, I>) {
          tMainObject.update(object);
        }
      }

      return tMainObject;
    } else {
      _setCache(tId, object);
      _handleObjectCacheDuration(object);

      return object;
    }
  }

  /// A version of [store] that supports multiple items.
  /// For details, please refer to [store].
  Future<Iterable<T>> storeMany(Iterable<T> objects) async {
    final tLength = objects.length;
    if (tLength > maxObjectCacheSize) {
      assert(false, 'The size of the list exceeds the maximum cache size.');
      // coverage:ignore-start
      final tError = RepositoryCacheSizeOverflow();
      return Future.error(tError);
      // coverage:ignore-end
    }

    return Future.wait([for (var object in objects) store(object)]);
  }

  /// Retrieves repository model from the cache based on the specified ID.
  T? get(I id) {
    return _accessCache(id);
  }

  /// A version of [get] that supports multiple items.
  /// For details, please refer to [get].
  List<T> getMany(List<I> ids) {
    return ids.map((e) => _accessCache(e)).whereType<T>().toList();
  }

  /// Fetches the repository model.
  /// The fetched data will be stored in the cache.
  ///
  /// The difference from [store] is whether to specify the data to be stored directly or to obtain the data via the fetcher.
  Future<T?> fetch(
    I id,
    Type set, {
    RepositoryFetchPolicy fetchPolicy = RepositoryFetchPolicy.cacheFirst,
    bool? synchronousCache,
  }) {
    assert(
      singleSetFetchers.containsKey(set) || multiSetFetchers.containsKey(set),
    );

    // This access will make this id the Most Recently Used (MRU).
    // Even without a set and without actual use,
    // since this id will be used in the future,
    // it's okay for it to be in the MRU.
    if (fetchPolicy != RepositoryFetchPolicy.noCache) {
      final tObject = _accessCache(id);

      if (tObject != null && tObject is SimpleRepositoryModel) {
        assert(T == set, repositorySetCannotUsedAssertionMessage);
      }

      if (tObject?.repositorySets.contains(set) == true) {
        final tSynchronousCache =
            synchronousCache ??
            (Zone.current[#repositorySynchronousCache] as bool?) ??
            false;
        // Return as quickly as possible.
        return (tSynchronousCache)
            ? SynchronousErrorableFuture(tObject)
            : Future.value(tObject);
      }
    }

    final tIdSet = _FetchSetEntry(id, set);

    if (_objectFetchMap.containsKey(tIdSet)) {
      return _objectFetchMap[tIdSet]!.future;
    }

    return _objectFetchMap.putIfAbsent(tIdSet, () {
      final tCompleter = Completer<T?>();

      if (multiSetFetchers.containsKey(set)) {
        tCompleter.future.whenComplete(() {
          _objectFetchMap.remove(tIdSet);
        });

        _schedule(id, set, tCompleter);

        return tCompleter;
      }

      singleSetFetchers[set]!(id)
          .then(
            (object) {
              return _handleObject(object, set, tCompleter);
            },
            onError: (error, stackTrace) {
              tCompleter.completeError(error, stackTrace);
            },
          )
          .whenComplete(() {
            _objectFetchMap.remove(tIdSet);
          });

      return tCompleter;
    }).future;
  }

  /// A version of [fetch] that supports multiple items.
  /// For details, please refer to [fetch].
  Future<List<T?>> fetchMany(
    List<I?> ids,
    Type set, {
    RepositoryFetchPolicy fetchPolicy = RepositoryFetchPolicy.cacheFirst,
    bool? synchronousCache,
  }) {
    assert(multiSetFetchers.containsKey(set));

    final tLength = ids.length;
    if (tLength > maxObjectCacheSize) {
      assert(false, 'The size of the list exceeds the maximum cache size.');
      // coverage:ignore-start
      final tError = RepositoryCacheSizeOverflow();
      return Future.error(tError);
      // coverage:ignore-end
    }

    final tResults = List<T?>.filled(tLength, null);
    final tToWaitFor = <Future<T?>, int>{};
    final tToFetch = <I, int>{};

    for (var i = 0; i < tLength; i++) {
      late final _FetchSetEntry<I> tSetId;
      final tId = ids[i];

      if (tId == null) {
        continue;
      }

      if (fetchPolicy != RepositoryFetchPolicy.noCache) {
        // This access will make this id the Most Recently Used (MRU).
        // Even without a set and without actual use,
        // since this id will be used in the future,
        // it's okay for it to be in the MRU.
        final tObject = _accessCache(tId);

        if (tObject != null && tObject is SimpleRepositoryModel) {
          assert(T == set, repositorySetCannotUsedAssertionMessage);
        }

        if (tObject?.repositorySets.contains(set) == true) {
          tResults[i] = tObject;

          continue;
        }
      }

      if (_objectFetchMap.containsKey((tSetId = _FetchSetEntry(tId, set)))) {
        tToWaitFor[_objectFetchMap[tSetId]!.future] = i;
      } else {
        tToFetch[tId] = i;
      }
    }

    if (tToFetch.isEmpty && tToWaitFor.isEmpty) {
      final tSynchronousCache =
          synchronousCache ??
          (Zone.current[#repositorySynchronousCache] as bool?) ??
          false;
      // Return as quickly as possible.
      return (tSynchronousCache)
          ? SynchronousErrorableFuture(tResults)
          : Future.value(tResults);
    }

    final tCompleter = Completer<List<T?>>();
    final tFinalFutures = <Future>[];

    if (tToWaitFor.isNotEmpty) {
      final tFuturesToWaitFor = tToWaitFor.keys.toList(growable: false);

      tFinalFutures.add(
        Future.wait(tFuturesToWaitFor).then((objects) {
          for (var i = 0, il = objects.length; i < il; i++) {
            tResults[tToWaitFor[tFuturesToWaitFor[i]]!] = objects[i];
          }

          return objects;
        }),
      );
    }

    if (tToFetch.isNotEmpty) {
      final tToFetchIds = tToFetch.keys.toList(growable: false);
      final tToFetchCompleters = tToFetchIds
          .map((v) => Completer<T?>())
          .toList(growable: false);

      for (var i = 0; i < tToFetchIds.length; i++) {
        final tIdSet = _FetchSetEntry(tToFetchIds[i], set);
        _objectFetchMap[tIdSet] = tToFetchCompleters[i];

        tToFetchCompleters[i].future
            .then((v) {
              if (v != null) {
                tResults[tToFetch[v.repositoryId]!] = v;
              }
            })
            .whenComplete(() {
              _objectFetchMap.remove(tIdSet);
            });
      }

      tFinalFutures.addAll(tToFetchCompleters.map((e) => e.future));
      _scheduleMany(tToFetchIds, set, tToFetchCompleters);
    }

    Future.wait(tFinalFutures)
        .then<void>((value) {
          tCompleter.complete(tResults);
        })
        .catchError((error, stackTrace) {
          tCompleter.completeError(error, stackTrace);
        });

    return tCompleter.future;
  }

  Iterable<Type> _setsToRefresh(T object) {
    // The set with the most variables is likely to have the most variables
    // in other sets as well, so process it first.
    final tSetVariablesSorted =
        object.repositorySetVariables.entries
            .where(
              (e) =>
                  (singleSetFetchers.containsKey(e.key) ||
                      multiSetFetchers.containsKey(e.key)) &&
                  object.repositoryHasSet(e.key),
            )
            .toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));

    var tKeepChecking = true;

    while (tKeepChecking && tSetVariablesSorted.isNotEmpty) {
      tKeepChecking = false;
      final tToCheck = tSetVariablesSorted.toList(growable: false);

      for (var tPossibleSuperset in tToCheck) {
        for (var tPossibleSubset in tToCheck) {
          if (tPossibleSuperset == tPossibleSubset) {
            continue;
          }

          if (tPossibleSuperset.value.containsAll(tPossibleSubset.value)) {
            tKeepChecking = true;
            tSetVariablesSorted.remove(tPossibleSubset);
          }
        }
      }
    }

    return tSetVariablesSorted.map((e) => e.key);
  }

  /// Retrieves the provided repository model again, ignoring the cache.
  /// The reacquired data will be stored in the cache.
  Future<void> refresh(T object) async {
    final tId = object.repositoryId;

    for (var tSet in _setsToRefresh(object)) {
      await fetch(tId, tSet, fetchPolicy: RepositoryFetchPolicy.noCache);
    }
  }

  /// A version of [refresh] that supports multiple items.
  /// For details, please refer to [refresh].
  Future<void> refreshMany(List<T> objects) async {
    final tSetsToRefresh = <Type, List<I>>{};

    for (var i in objects) {
      for (var j in _setsToRefresh(i)) {
        final tId = i.repositoryId;
        tSetsToRefresh.putIfAbsent(j, () => []).add(tId);
      }
    }

    for (var i in tSetsToRefresh.entries) {
      if (multiSetFetchers.containsKey(i.key)) {
        await fetchMany(
          i.value,
          i.key,
          fetchPolicy: RepositoryFetchPolicy.noCache,
        );
      } else {
        final tMaxConcurrentFetches = (maxConcurrentFetches > 0)
            ? maxConcurrentFetches
            : 1;
        for (var j = 0; j < i.value.length; j += tMaxConcurrentFetches) {
          final tSlice = i.value.skip(j).take(tMaxConcurrentFetches);
          final tFutures = tSlice
              .map(
                (e) =>
                    fetch(e, i.key, fetchPolicy: RepositoryFetchPolicy.noCache),
              )
              .toList(growable: false);
          await SynchronousErrorableFuture.wait(tFutures);
        }
      }
    }
  }

  /// Retrieves all repository models again, ignoring the cache.
  /// The reacquired data will be stored in the cache.
  Future<void> refreshAll() async {
    await refreshMany(_objectCache.values.toList(growable: false));
  }

  /// Removes all repository models from the cache.
  /// No data reacquisition is performed.
  Future<void> clear() async {
    final tObjects = _objectCache.values.toList(growable: false);

    for (var i in tObjects) {
      _removeCache(i);
    }
  }
}
