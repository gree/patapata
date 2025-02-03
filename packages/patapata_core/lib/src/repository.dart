// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_annotation.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_interface.dart';
import 'package:provider/provider.dart';

import 'exception.dart';
import 'synchronous_future.dart';

part 'repository_cache_map.dart';

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

/// Base class that serves as the foundation for the repository model.
/// [RepositoryModel] and [SimpleRepositoryModel] inherit from this class.
mixin RepositoryModelBase<T extends RepositoryModelBase<T, I>,
    I extends Object> {
  /// The unique ID in the repository.
  I get repositoryId;

  /// A map of variables entrusted to the repository for management.
  /// Set the keys of the map to the sets specified in [RepositoryClass].
  /// Please configure the combinations of parameter sets and variables used in each parameter set.
  ///
  /// For example:
  /// ```dart
  ///
  /// @override
  /// Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
  ///       Set1: {_value1, _value2},
  ///       Set2: {_value1, _value2, _value3},
  ///     };
  /// ```
  Map<Type, Set<ProviderModelVariable>> get repositorySetVariables;

  /// Called by a Repository to create a default object of type [T] from [id].
  T repositoryDefaultFactory(I id);

  /// Function for creating a widget that encapsulates a data model.
  /// Add it to the Widget tree using [Provider] or [InheritedWidget], etc.
  /// You may need to change the created widget depending on the type of data model and how it is used.
  ///
  /// For example, if you are using [RepositoryClass.sets], you need to prepare a data model and a [MultiProvider] for the set.
  /// For example:
  /// ```dart
  ///
  /// @override
  /// Widget providersBuilder(Widget child) {
  ///   return MultiProvider(
  ///     providers: [
  ///       InheritedProvider<DataModel>.value(
  ///         value: this,
  ///         startListening: (c, v) {
  ///           v.addListener(c.markNeedsNotifyDependents);
  ///           return () => v.removeListener(c.markNeedsNotifyDependents);
  ///         },
  ///       ),
  ///       InheritedProvider<DataModelSet>.value(
  ///         value: this,
  ///         startListening: (c, v) {
  ///           final tInstance = (v as DataModel);
  ///           tInstance.addListener(c.markNeedsNotifyDependents);
  ///           return () => tInstance.removeListener(c.markNeedsNotifyDependents);
  ///         },
  ///       ),
  ///     ],
  ///     child: child,
  ///   );
  /// }
  /// ```
  ///
  /// If you prepare data using global (such as riverpod), there is no need to override it.
  /// However, since the repository system needs to understand how to retrieve data,
  /// please specify that method in [RepositoryProvider.reader].
  Widget providersBuilder(Widget child);

  /// Returns a list of sets specified in [RepositoryClass].
  Set<Type> get repositorySets;

  /// Checks if the specified parameter set is included in [repositorySets].
  bool repositoryHasSet(Type set);

  /// Returns whether the repository has change notifications.
  bool get _repositoryHasListeners;

  /// Notifies the repository of changes.
  void _repositoryNotifyListeners();

  /// Clones this [RepositoryObjectBase] object.
  /// Setting deep to true will also copy the contents if the source is [RepositoryModelBase].
  T clone([bool deep = true]);

  static T2 _clone<T2 extends RepositoryModelBase<T2, I>, I extends Object>(
    RepositoryModelBase<T2, I> original, [
    bool deep = true,
  ]) {
    final tClone = original.repositoryDefaultFactory(original.repositoryId);
    if (tClone is! ProviderModel) {
      if (tClone is SimpleRepositoryModel) {
        (tClone as SimpleRepositoryModel).update(original);
      }

      return tClone;
    }

    final tCloneBatch = (tClone as ProviderModel).begin();

    for (var i in original.repositorySetVariables.entries) {
      final tCloneSetVariables = tClone.repositorySetVariables[i.key]!;
      final tOriginalSetVariables = i.value;

      for (var j = 0, jl = tCloneSetVariables.length; j < jl; j++) {
        final tOriginalVariable = tOriginalSetVariables.elementAt(j);

        if (tOriginalVariable.set) {
          final tOriginalValue = tOriginalVariable.unsafeValue;

          tCloneBatch.set(
            tCloneSetVariables.elementAt(j),
            deep && tOriginalValue is RepositoryModelBase
                ? tOriginalValue.clone(true)
                : tOriginalValue,
          );
        }
      }
    }

    tCloneBatch.commit(notify: false);

    return tClone;
  }
}

/// When creating a repository model that requires change notifications, mix-in this class.
/// It is assumed that the inheriting class is a [ProviderModel].
mixin RepositoryModel<T extends RepositoryModelBase<T, I>, I extends Object>
    on ProviderModel<T> implements RepositoryModelBase<T, I> {
  /// Updates the variables held by the repository.
  /// The data is copied from [object].
  /// Using [batch] allows for bulk updates and simultaneous change notifications.
  void update(ProviderModelBatch batch, T object) {
    final tVariables = repositorySetVariables[T]!;
    final tObjectVariables =
        object.repositorySetVariables[T]!.toList(growable: false);

    for (final v in tObjectVariables.where((e) => e.set)) {
      final i = tObjectVariables.indexOf(v);
      batch.set(tVariables.elementAt(i), v.unsafeValue);
    }
  }

  @override
  Set<Type> get repositorySets => {
        for (var i in repositorySetVariables.entries)
          if (i.value.every((e) => e.set)) i.key,
      };

  @override
  bool repositoryHasSet(Type set) =>
      repositorySetVariables[set]?.every((e) => e.set) ?? false;

  @override
  Widget providersBuilder(Widget child) => child;

  @override
  bool get _repositoryHasListeners => hasListeners;

  @override
  void _repositoryNotifyListeners() {
    if (hasListeners) {
      scheduleFunction(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  @override
  T clone([bool deep = true]) {
    return RepositoryModelBase._clone<T, I>(this, deep);
  }

  @override
  int get hashCode => repositoryId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is T && other.repositoryId == repositoryId) {
      return true;
    }

    return false;
  }
}

/// Mix-in when creating a simple repository model that does not require change notifications.
/// It is possible to have change notifications, but it is often preferable to use [RepositoryModel].
/// Use this when, due to the structure of the data model, [RepositoryModel] cannot be used.
mixin SimpleRepositoryModel<T extends RepositoryModelBase<T, I>,
    I extends Object> implements RepositoryModelBase<T, I> {
  /// Updates the variables held by the repository.
  /// The specifics of the update are left to the derived class.
  void update(T object);

  @override
  Set<Type> get repositorySets => {T};

  @override
  Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
        T: {},
      };

  // coverage:ignore-start
  // This method is not used in SimpleRepositoryModel.
  @override
  Widget providersBuilder(Widget child) => child;
  // coverage:ignore-end

  @override
  bool repositoryHasSet(Type set) => true;

  @override
  void _repositoryNotifyListeners() {
    // Do nothing.
  }

  @override
  T clone([deep = true]) {
    return RepositoryModelBase._clone<T, I>(this, deep);
  }

  @override
  int get hashCode => repositoryId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is T && other.repositoryId == repositoryId) {
      return true;
    }

    return false;
  }
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
abstract class Repository<T extends RepositoryModelBase<T, I>,
    I extends Object> {
  /// Standard maximum cache size.
  static const kDefaultMaxObjectCacheSize = 100;

  /// Specifies the number of [fetch] operations that can be executed concurrently in [refreshMany] and [refreshAll].
  ///
  /// If the value is 0 or less, it will be treated as 1.
  int get maxConcurrentFetches => 1;

  /// Maximum size of the cache.
  @protected
  int get maxObjectCacheSize => kDefaultMaxObjectCacheSize;

  late final _objectCache =
      _RepositoryCacheMap<I, T>(maximumSize: maxObjectCacheSize);
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

  void _scheduleMany(
    List<I> ids,
    Type set,
    List<Completer<T?>> completers,
  ) {
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

        multiSetFetchers[set]!(tIds).then((objects) {
          for (var v in objects) {
            final tEntry =
                tEntryList.firstWhere((e) => e.id == v?.repositoryId);
            tEntryList.remove(tEntry);

            _handleObject(v, set, tEntry.completer);
          }

          for (var f in tEntryList) {
            f.completer.complete(null);
          }
        }).catchError((error, stackTrace) {
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
  late final _cacheDurationTimers =
      Expando<Timer>('$runtimeType cache duration timers');

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
                  'Object cache duration expired: Have listeners: ${object._repositoryHasListeners}');

              if (object._repositoryHasListeners) {
                refresh(object);
              }
            };
          })(object),
        );
      }
    }
  }

  T? _handleObject(
    T? object,
    Type set,
    Completer<T?> completer,
  ) {
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
        tMainObject.lock(
          (batch) {
            tMainObject.update(batch, object);
            _handleObjectCacheDuration(tMainObject);
            batch.commit();
            completer.complete(tMainObject);
          },
        ).catchError((error, stackTrace) {
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
        await tMainObject.lock(
          (batch) {
            tMainObject.update(batch, object);
            _handleObjectCacheDuration(tMainObject);
            batch.commit();
          },
        );
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
    assert(singleSetFetchers.containsKey(set) ||
        multiSetFetchers.containsKey(set));

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
        final tSynchronousCache = synchronousCache ??
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

      singleSetFetchers[set]!(id).then(
        (object) {
          return _handleObject(object, set, tCompleter);
        },
        onError: (error, stackTrace) {
          tCompleter.completeError(error, stackTrace);
        },
      ).whenComplete(() {
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
      final tSynchronousCache = synchronousCache ??
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

      tFinalFutures.add(Future.wait(tFuturesToWaitFor).then((objects) {
        for (var i = 0, il = objects.length; i < il; i++) {
          tResults[tToWaitFor[tFuturesToWaitFor[i]]!] = objects[i];
        }

        return objects;
      }));
    }

    if (tToFetch.isNotEmpty) {
      final tToFetchIds = tToFetch.keys.toList(growable: false);
      final tToFetchCompleters =
          tToFetchIds.map((v) => Completer<T?>()).toList(growable: false);

      for (var i = 0; i < tToFetchIds.length; i++) {
        final tIdSet = _FetchSetEntry(tToFetchIds[i], set);
        _objectFetchMap[tIdSet] = tToFetchCompleters[i];

        tToFetchCompleters[i].future.then((v) {
          if (v != null) {
            tResults[tToFetch[v.repositoryId]!] = v;
          }
        }).whenComplete(() {
          _objectFetchMap.remove(tIdSet);
        });
      }

      tFinalFutures.addAll(tToFetchCompleters.map((e) => e.future));
      _scheduleMany(tToFetchIds, set, tToFetchCompleters);
    }

    Future.wait(tFinalFutures).then<void>((value) {
      tCompleter.complete(tResults);
    }).catchError((error, stackTrace) {
      tCompleter.completeError(error, stackTrace);
    });

    return tCompleter.future;
  }

  Iterable<Type> _setsToRefresh(T object) {
    // The set with the most variables is likely to have the most variables
    // in other sets as well, so process it first.
    final tSetVariablesSorted = object.repositorySetVariables.entries
        .where((e) =>
            (singleSetFetchers.containsKey(e.key) ||
                multiSetFetchers.containsKey(e.key)) &&
            object.repositoryHasSet(e.key))
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
      await fetch(
        tId,
        tSet,
        fetchPolicy: RepositoryFetchPolicy.noCache,
      );
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
        final tMaxConcurrentFetches =
            (maxConcurrentFetches > 0) ? maxConcurrentFetches : 1;
        for (var j = 0; j < i.value.length; j += tMaxConcurrentFetches) {
          final tSlice = i.value.skip(j).take(tMaxConcurrentFetches);
          final tFutures = tSlice
              .map((e) => fetch(
                    e,
                    i.key,
                    fetchPolicy: RepositoryFetchPolicy.noCache,
                  ))
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

class _SynchronousTracker {
  bool callerFinished = false;
  bool calledFinished = false;
}

typedef _RepositoryDataHolderBuilder<T> = Widget Function(
    BuildContext context, T? data);

class _RepositoryCore<T extends RepositoryModelBase<T, I>, I extends Object,
    R extends Repository<T, I>> extends StatefulWidget {
  final I id;
  final Future<T?> Function(R repository) fetcher;
  final R repository;
  final _RepositoryDataHolderBuilder<T> holderBuilder;
  final Widget? loading;
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  const _RepositoryCore({
    super.key,
    required this.id,
    required this.fetcher,
    required this.repository,
    required this.holderBuilder,
    this.loading,
    this.errorBuilder,
  });

  @override
  State<_RepositoryCore<T, I, R>> createState() =>
      _RepositoryCoreState<T, I, R>();
}

class _RepositoryCoreState<
    T extends RepositoryModelBase<T, I>,
    I extends Object,
    R extends Repository<T, I>> extends State<_RepositoryCore<T, I, R>> {
  bool? _loading;
  Object? _error;
  StackTrace? _stackTrace;
  T? _data;

  void _updateData(_SynchronousTracker tracker) {
    _loading = true;
    _data = null;
    _error = null;
    _stackTrace = null;

    runZoned(() {
      widget.fetcher(widget.repository).then((data) {
        _data = data;

        return data;
      }).catchError((e, stackTrace) {
        _error = e;
        _stackTrace = stackTrace;

        throw e;
      }).whenComplete(() {
        _loading = false;
        tracker.calledFinished = true;

        if (tracker.callerFinished) {
          if (mounted) {
            setState(() {});
          }
        }
      });
    }, zoneValues: {
      #repositorySynchronousCache: true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget tWidget;
    final Key tKey;

    if (_loading == null) {
      final tTracker = _SynchronousTracker();
      _updateData(tTracker);
      tTracker.callerFinished = true;
    }

    if (_loading == true) {
      tKey = const ValueKey('loading');
      tWidget = widget.loading ?? const SizedBox.shrink();
    } else if (_error != null) {
      tKey = const ValueKey('error');
      tWidget = widget.errorBuilder?.call(context, _error!, _stackTrace) ??
          const SizedBox.shrink();
    } else if (_data == null) {
      tKey = const ValueKey('error');
      tWidget = widget.errorBuilder?.call(
              context, ProviderNullException(null.runtimeType, T), null) ??
          const SizedBox.shrink();
    } else {
      if (_data is Listenable) {
        tKey = ValueKey('listenable:${_data.hashCode}');
        tWidget = widget.holderBuilder(context, _data);
      } else {
        tKey = ValueKey('nonListenable:${_data.hashCode}');
        tWidget = widget.holderBuilder(context, _data);
      }
    }

    return KeyedSubtree(
      key: tKey,
      child: tWidget,
    );
  }
}

class _RepositoryMultiCore<T extends RepositoryModelBase<T, I>,
    I extends Object, R extends Repository<T, I>> extends StatefulWidget {
  final Future<List<T?>> Function(R repository) fetcher;
  final R repository;
  final _RepositoryDataHolderBuilder<List<T?>> holderBuilder;
  final Widget? loading;
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  const _RepositoryMultiCore({
    super.key,
    required this.fetcher,
    required this.repository,
    required this.holderBuilder,
    this.loading,
    this.errorBuilder,
  });

  @override
  State<_RepositoryMultiCore<T, I, R>> createState() =>
      _RepositoryMultiCoreState<T, I, R>();
}

class _RepositoryMultiCoreState<
    T extends RepositoryModelBase<T, I>,
    I extends Object,
    R extends Repository<T, I>> extends State<_RepositoryMultiCore<T, I, R>> {
  bool? _loading;
  Object? _error;
  StackTrace? _stackTrace;
  List<T?>? _data;

  void _updateData(_SynchronousTracker tracker) {
    _loading = true;
    _data = null;
    _error = null;
    _stackTrace = null;

    runZoned(() {
      widget.fetcher(widget.repository).then((data) {
        _data = data;

        return data;
      }).catchError((e, stackTrace) {
        _error = e;
        _stackTrace = stackTrace;

        throw e;
      }).whenComplete(() {
        _loading = false;
        tracker.calledFinished = true;

        if (tracker.callerFinished) {
          if (mounted) {
            setState(() {});
          }
        }
      });
    }, zoneValues: {
      #repositorySynchronousCache: true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget tWidget;
    final Key tKey;

    if (_loading == null) {
      final tTracker = _SynchronousTracker();
      _updateData(tTracker);
      tTracker.callerFinished = true;
    }

    if (_loading == true) {
      tKey = const ValueKey('loading');
      tWidget = widget.loading ?? const SizedBox.shrink();
    } else if (_error != null) {
      tKey = const ValueKey('error');
      tWidget = widget.errorBuilder?.call(context, _error!, _stackTrace) ??
          const SizedBox.shrink();
    } else {
      assert(_data != null);

      tKey = ValueKey('list:${_data.hashCode}');
      tWidget = widget.holderBuilder(context, _data);
    }

    return KeyedSubtree(
      key: tKey,
      child: tWidget,
    );
  }
}

/// Widget that interacts with [RepositoryModel] and [Repository].
/// When retrieving data from the lower hierarchy where this is placed,
/// [RepositoryModel] is provided in the type specified by [RepositoryClass].
///
/// The actual stored data depends on the ID passed to [Repository.fetch].
/// The necessary [Repository] is provided from [fetcher], so use it to retrieve data.
///
/// Please pass the means to access [Repository] to [reader].
/// For example, when obtaining it through [BuildContext] and with the library provider,
/// it will be "() => context.read<Repository>()".
class RepositoryProvider<T extends RepositoryModelBase<T, I>, I extends Object,
    R extends Repository<T, I>> extends StatelessWidget {
  final I id;
  final Future<T?> Function(R repository) fetcher;
  final R repository;
  final WidgetBuilder builder;
  final Widget? loading;
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  const RepositoryProvider({
    super.key,
    required this.id,
    required this.fetcher,
    required this.repository,
    required this.builder,
    this.loading,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _RepositoryCore<T, I, R>(
      id: id,
      fetcher: fetcher,
      repository: repository,
      holderBuilder: (context, data) {
        return data!.providersBuilder(Builder(builder: builder));
      },
      loading: loading,
      errorBuilder: errorBuilder,
    );
  }
}

/// A version of [RepositoryProvider] that supports multiple items.
/// For details, please refer to [RepositoryProvider].
class RepositoryMultiProvider<
    T extends RepositoryModelBase<T, I>,
    I extends Object,
    R extends Repository<T, I>,
    S extends Object> extends StatelessWidget {
  final Future<List<T?>> Function(R repository) fetcher;
  final R repository;
  final WidgetBuilder builder;
  final Widget? loading;
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  const RepositoryMultiProvider({
    super.key,
    required this.fetcher,
    required this.repository,
    required this.builder,
    this.loading,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _RepositoryMultiCore(
      fetcher: fetcher,
      repository: repository,
      holderBuilder: (context, data) {
        return Provider<List<S>>.value(
          value: data!.map((e) => e as S).toList(),
          child: Builder(builder: builder),
        );
      },
      loading: loading,
      errorBuilder: errorBuilder,
    );
  }
}

typedef RepositoryObserverBuilder<T> = Widget Function(
    BuildContext context, Widget? child, T? data);

/// The basic functionality is the same as [RepositoryProvider].
/// The difference is that it is used when change notifications are not needed, such as in the case of [SimpleRepositoryModel],
/// or when dealing with simple data models.
class RepositoryObserver<T extends RepositoryModelBase<T, I>, I extends Object,
    R extends Repository<T, I>> extends StatelessWidget {
  final I id;
  final Future<T?> Function(R repository) fetcher;
  final R repository;
  final RepositoryObserverBuilder<T> builder;
  final bool notify;
  final Widget? loading;
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget? child;

  const RepositoryObserver({
    super.key,
    required this.id,
    required this.fetcher,
    required this.repository,
    required this.builder,
    required this.notify,
    this.loading,
    this.errorBuilder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _RepositoryCore<T, I, R>(
      id: id,
      fetcher: fetcher,
      repository: repository,
      holderBuilder: (context, data) {
        if (data != null && notify) {
          assert(data is Listenable);
          if (data is Listenable) {
            return ListenableBuilder(
              listenable: data as Listenable,
              child: child,
              builder: (context, child) {
                return builder(context, child, data);
              },
            );
          }
        }

        return builder(context, child, data);
      },
      loading: loading,
      errorBuilder: errorBuilder,
    );
  }
}

/// A version of [RepositoryObserver] that supports multiple items.
/// For details, please refer to [RepositoryObserver].
class RepositoryMultiObserver<T extends RepositoryModelBase<T, I>,
    I extends Object, R extends Repository<T, I>> extends StatelessWidget {
  final Future<List<T?>> Function(R repository) fetcher;
  final R repository;
  final RepositoryObserverBuilder<List<T?>> builder;
  final bool notify;
  final Widget? loading;
  final Widget Function(
      BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget? child;

  const RepositoryMultiObserver({
    super.key,
    required this.fetcher,
    required this.repository,
    required this.builder,
    required this.notify,
    this.loading,
    this.errorBuilder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _RepositoryMultiCore(
      fetcher: fetcher,
      repository: repository,
      holderBuilder: (context, data) {
        if (notify && data != null) {
          final tListenableList = data.whereType<Listenable>();

          assert(tListenableList.isNotEmpty);
          if (tListenableList.isNotEmpty) {
            return _ObjectListenable(
              listenables: tListenableList.toList(),
              child: child,
              builder: (context, child) {
                return builder(context, child, data);
              },
            );
          }
        }

        return builder(context, child, data);
      },
      loading: loading,
      errorBuilder: errorBuilder,
    );
  }
}

class _ObjectListenable extends StatefulWidget {
  const _ObjectListenable({
    required this.listenables,
    required this.builder,
    required this.child,
  });

  final List<Listenable> listenables;
  final Widget? child;
  final TransitionBuilder builder;

  @override
  State<_ObjectListenable> createState() => _ObjectListenableState();
}

class _ObjectListenableState extends State<_ObjectListenable> {
  _ObjectNotifier? _notifier;

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _notifier?.dispose();
    return ListenableBuilder(
      listenable: _notifier = _ObjectNotifier(
        listenables: widget.listenables,
      ),
      builder: widget.builder,
    );
  }
}

class _ObjectNotifier extends ChangeNotifier {
  _ObjectNotifier({
    required this.listenables,
  }) {
    for (final v in listenables) {
      v.addListener(notifyListeners);
    }
  }

  final List<Listenable> listenables;

  @override
  void dispose() {
    for (final v in listenables) {
      v.removeListener(notifyListeners);
    }

    super.dispose();
  }
}
