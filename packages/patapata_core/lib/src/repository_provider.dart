// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of 'repository.dart';

class _SynchronousTracker {
  bool callerFinished = false;
  bool calledFinished = false;
}

typedef _RepositoryDataHolderBuilder<T> =
    Widget Function(BuildContext context, T? data);

class _RepositoryCore<
  T extends RepositoryModelBase<T, I>,
  I extends Object,
  R extends Repository<T, I>
>
    extends StatefulWidget {
  final I id;
  final Future<T?> Function(R repository) fetcher;
  final R repository;
  final _RepositoryDataHolderBuilder<T> holderBuilder;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;

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
  R extends Repository<T, I>
>
    extends State<_RepositoryCore<T, I, R>> {
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
      widget
          .fetcher(widget.repository)
          .then((data) {
            _data = data;

            return data;
          })
          .catchError((e, stackTrace) {
            _error = e;
            _stackTrace = stackTrace;

            throw e;
          })
          .whenComplete(() {
            _loading = false;
            tracker.calledFinished = true;

            if (tracker.callerFinished) {
              if (mounted) {
                setState(() {});
              }
            }
          });
    }, zoneValues: {#repositorySynchronousCache: true});
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
      tWidget =
          widget.errorBuilder?.call(context, _error!, _stackTrace) ??
          const SizedBox.shrink();
    } else if (_data == null) {
      tKey = const ValueKey('error');
      tWidget =
          widget.errorBuilder?.call(
            context,
            ProviderNullException(null.runtimeType, T),
            null,
          ) ??
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

    return KeyedSubtree(key: tKey, child: tWidget);
  }
}

class _RepositoryMultiCore<
  T extends RepositoryModelBase<T, I>,
  I extends Object,
  R extends Repository<T, I>
>
    extends StatefulWidget {
  final Future<List<T?>> Function(R repository) fetcher;
  final R repository;
  final _RepositoryDataHolderBuilder<List<T?>> holderBuilder;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;

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
  R extends Repository<T, I>
>
    extends State<_RepositoryMultiCore<T, I, R>> {
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
      widget
          .fetcher(widget.repository)
          .then((data) {
            _data = data;

            return data;
          })
          .catchError((e, stackTrace) {
            _error = e;
            _stackTrace = stackTrace;

            throw e;
          })
          .whenComplete(() {
            _loading = false;
            tracker.calledFinished = true;

            if (tracker.callerFinished) {
              if (mounted) {
                setState(() {});
              }
            }
          });
    }, zoneValues: {#repositorySynchronousCache: true});
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
      tWidget =
          widget.errorBuilder?.call(context, _error!, _stackTrace) ??
          const SizedBox.shrink();
    } else {
      assert(_data != null);

      tKey = ValueKey('list:${_data.hashCode}');
      tWidget = widget.holderBuilder(context, _data);
    }

    return KeyedSubtree(key: tKey, child: tWidget);
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
/// it would be `() => context.read<Repository>()`.
class RepositoryProvider<
  T extends RepositoryModelBase<T, I>,
  I extends Object,
  R extends Repository<T, I>
>
    extends StatelessWidget {
  final I id;
  final Future<T?> Function(R repository) fetcher;
  final R repository;
  final WidgetBuilder builder;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;

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
  S extends Object
>
    extends StatelessWidget {
  final Future<List<T?>> Function(R repository) fetcher;
  final R repository;
  final WidgetBuilder builder;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;

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

typedef RepositoryObserverBuilder<T> =
    Widget Function(BuildContext context, Widget? child, T? data);

/// The basic functionality is the same as [RepositoryProvider].
/// The difference is that it is used when change notifications are not needed, such as in the case of [SimpleRepositoryModel],
/// or when dealing with simple data models.
class RepositoryObserver<
  T extends RepositoryModelBase<T, I>,
  I extends Object,
  R extends Repository<T, I>
>
    extends StatelessWidget {
  final I id;
  final Future<T?> Function(R repository) fetcher;
  final R repository;
  final RepositoryObserverBuilder<T> builder;
  final bool notify;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;
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
class RepositoryMultiObserver<
  T extends RepositoryModelBase<T, I>,
  I extends Object,
  R extends Repository<T, I>
>
    extends StatelessWidget {
  final Future<List<T?>> Function(R repository) fetcher;
  final R repository;
  final RepositoryObserverBuilder<List<T?>> builder;
  final bool notify;
  final Widget? loading;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;
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
      listenable: _notifier = _ObjectNotifier(listenables: widget.listenables),
      builder: widget.builder,
      child: widget.child,
    );
  }
}

class _ObjectNotifier extends ChangeNotifier {
  _ObjectNotifier({required this.listenables}) {
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
