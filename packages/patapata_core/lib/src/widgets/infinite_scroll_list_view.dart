// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:provider/provider.dart';

/// A widget that provides infinite scrolling functionality to [ListView] or [GridView].
///
/// This widget fetches data of type [T] using either of the [fetchNext] or [fetchPrevious] methods
/// when the user scrolls the list or grid and calls the [itemBuilder].
///
/// Each item's Widget has a Provider in its parent, and you can access each item's information
/// using methods like `context.read<T>()` or `context.read<InfiniteScrollItemInformation>()`, etc.
///
/// If the item implements [Listenable], the parent uses [InheritedProvider] to register listeners.
/// This enables the detection of changes to the item and the rebuilding of the item accordingly.
///
/// It also supports pull-to-refresh functionality.
///
/// For example:
/// ```dart
/// const int kMaxFetchCount = 20;
/// const int kItemMaxLength = 100;
///
/// InfiniteScrollListView<String>.list(
///   initialIndex: () => 0,
///   fetchPrev: (index, crossAxisCount) async {
///     final tStartIndex = max(0, index - kMaxFetchCount + 1);
///     final tFetchCount = index + 1 - tStartIndex;
///
///     return List.generate(tFetchCount, (i) => 'Item ${tStartIndex + i}');
///   },
///   fetchNext: (index, crossAxisCount) async {
///     final tFetchCount = min(kMaxFetchCount, kItemMaxLength - index);
///
///     return List.generate(tFetchCount, (i) => 'Item ${index + i}');
///   },
///   canFetchPrev: (index) => index >= 0,
///   canFetchNext: (index) => index < kItemMaxLength,
///   itemBuilder: (context, item, index) {
///     return ListTile(
///       title: Text(item),
///     );
///   },
/// );
/// ```
class InfiniteScrollListView<T> extends StatefulWidget {
  /// Changing this key resets the data and fetches data again starting from [initialIndex].
  final Key? dataKey;

  /// Function to fetch the next set of items when scrolling forward.
  ///
  /// [index] is the starting index of the data to be fetched next.
  /// For example, if data 0-19 is currently displayed, the next data will be fetched starting from 20.
  ///
  /// [crossAxisCount] is the number of children along the horizontal axis in a GridView.
  /// For a ListView, it is 1.
  ///
  /// If this method returns an empty List, it is determined that data fetching has ended,
  /// and no further data will be fetched.
  final Future<List<T>> Function(int index, int crossAxisCount) fetchNext;

  /// Function to fetch the previous set of items when scrolling backward.
  ///
  /// [index] is the last index of the data to be fetched next.
  /// For example, if data 20-39 is currently displayed, the previous data will be fetched starting from 19.
  ///
  /// [crossAxisCount] is the number of children along the horizontal axis in a GridView.
  /// For a ListView, it is 1.
  ///
  /// If this method returns an empty List, it is determined that data fetching has ended,
  /// and no further data will be fetched.
  final Future<List<T>> Function(int index, int crossAxisCount)? fetchPrev;

  /// Determines whether more data can be fetched when scrolling forward.
  ///
  /// If this method returns false, it is determined that data fetching has ended,
  /// [fetchNext] is not executed, and no further data will be fetched.
  ///
  /// [index] is the starting index of the data to be fetched next.
  /// For example, if data 0-19 is currently displayed, the next data will be fetched starting from 20.
  final bool Function(int index)? canFetchNext;

  /// Determines whether more data can be fetched when scrolling backward.
  ///
  /// If this method returns false, it is determined that data fetching has ended,
  /// [fetchPrev] is not executed, and no further data will be fetched.
  ///
  /// [index] is the last index of the data to be fetched next.
  /// For example, if data 20-39 is currently displayed, the previous data will be fetched starting from 19.
  final bool Function(int index)? canFetchPrev;

  /// Called when the list scroll ends and returns the topmost index of the list.
  ///
  /// If [overlaySlivers] or [prefix] are included, the bottom of those areas at a
  /// scroll offset of 0 is considered the top of the list.
  ///
  /// [crossAxisCount] is the number of children along the horizontal axis in a GridView.
  /// For a ListView, it is 1.
  final void Function(int index, int crossAxisCount)? onIndexChanged;

  /// Function that returns the initial index to scroll to.
  ///
  /// [fetchNext] is called with the index specified by [initialIndex] during initialization.
  ///
  /// If a value less than 0 is returned, it is set to 0.
  ///
  /// In the case of a GridView, it is rounded to a multiple of crossAxisCount.
  final int Function()? initialIndex;

  /// Callback invoked when the index specified by [initialIndex] cannot be fetched by [fetchNext]
  /// during initialization (e.g., when [fetchNext] returns an empty List).
  ///
  /// [index] is the index used when calling [fetchNext]. This value is the same as [initialIndex].
  ///
  /// Returning true will re-initialize, causing [initialIndex] to be called again.
  /// Returning false will abort the initialization and display an empty list.
  ///
  /// If the number of retry attempts exceeds 10, [giveup] becomes true,
  /// and initialization is forcibly aborted even if this method returns true.
  final bool Function(int index, bool giveup)? initialIndexNotFoundCallback;

  /// A list of slivers to overlay on top of the scroll view.
  final List<Widget>? overlaySlivers;

  /// The amount of space by which to inset the children.
  final EdgeInsets? padding;

  /// Whether pull-to-refresh is enabled.
  final bool canRefresh;

  /// Callback when a refresh is triggered.
  final void Function()? onRefresh;

  /// A widget to display before the list of items.
  final Widget? prefix;

  /// A widget to display after the list of items.
  final Widget? suffix;

  /// Widget to display when the list is empty.
  final Widget? empty;

  /// Widget to display while the initial data is loading.
  final Widget? loading;

  /// Widget to display while loading more data.
  final Widget? loadingMore;

  /// Builder function to render each item in the list or grid.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Builder to display an error message when data loading fails.
  ///
  /// This is displayed when an exception occurs during the calls to [fetchNext] or [fetchPrev].
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builder for the refresh indicator widget.
  final Widget Function(
    BuildContext context,
    Widget child,
    Future<void> Function() refresh,
  )?
  refreshIndicatorBuilder;

  /// The delegate that controls the layout of the grid tiles.
  final SliverGridDelegate? gridDelegate;

  /// A controller for an infinite scroll list view.
  final ScrollController? controller;

  /// The axis along which the scroll view scrolls.
  final Axis scrollDirection;

  /// How to clip overflowing content.
  final Clip clipBehavior;

  /// The extent of the area in which content is cached.
  final double? cacheExtent;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// Whether this is the primary scroll view associated with the parent PrimaryScrollController.
  final bool? primary;

  final Widget Function(
    BuildContext context,
    Widget? Function(BuildContext context, int index) itemBuilder,
    int count,
  )
  _listBuilder;

  /// Creates an infinite scrolling list view.
  InfiniteScrollListView.list({
    super.key,
    required this.fetchNext,
    this.fetchPrev,
    required this.itemBuilder,
    this.onIndexChanged,
    this.dataKey,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.primary,
    this.initialIndex,
    this.initialIndexNotFoundCallback,
    this.controller,
    this.clipBehavior = Clip.hardEdge,
    this.cacheExtent,
    this.overlaySlivers,
    this.padding,
    this.canRefresh = true,
    this.refreshIndicatorBuilder,
    this.prefix,
    this.suffix,
    this.empty,
    this.loading,
    this.loadingMore,
    this.errorBuilder,
    this.onRefresh,
    this.canFetchNext,
    this.canFetchPrev,
  }) : gridDelegate = null,
       _listBuilder = ((context, itemBuilder, count) => SliverList(
         delegate: SliverChildBuilderDelegate(childCount: count, itemBuilder),
       ));

  /// Creates an infinite scrolling grid view.
  InfiniteScrollListView.grid({
    super.key,
    required this.fetchNext,
    this.fetchPrev,
    required this.itemBuilder,
    required this.gridDelegate,
    this.onIndexChanged,
    this.dataKey,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.primary,
    this.initialIndex,
    this.initialIndexNotFoundCallback,
    this.controller,
    this.clipBehavior = Clip.hardEdge,
    this.cacheExtent,
    this.overlaySlivers,
    this.padding,
    this.canRefresh = true,
    this.refreshIndicatorBuilder,
    this.prefix,
    this.suffix,
    this.empty,
    this.loading,
    this.loadingMore,
    this.errorBuilder,
    this.onRefresh,
    this.canFetchNext,
    this.canFetchPrev,
  }) : _listBuilder = ((context, itemBuilder, count) => SliverGrid(
         delegate: SliverChildBuilderDelegate(childCount: count, itemBuilder),
         gridDelegate: gridDelegate!,
       ));

  @override
  State<InfiniteScrollListView<T>> createState() =>
      _InfiniteScrollListViewState<T>();
}

class _InfiniteScrollListViewState<T> extends State<InfiniteScrollListView<T>> {
  Object _key = Object();
  bool _initialized = false;
  bool _readyViewed = false;
  bool _backwardLoadTriggerFirstLayout = true;
  int _initialIndex = 0;
  int _topIndex = 0;
  int _crossAxisCount = 0;

  final Map<String, ValueKey<String>> _sliverListKeys = {};
  final _shouldLoadDataIndex = <int>[0, 0];
  final _data = <int, T>{};
  final List<int> _backedItemSizeList = [];
  final _dataSourceExhausted = [false, false];

  double _prefixScrollExtent = 0.0;
  double _backedLoadTriggerSize = 0.0;

  Object? _error;
  Object? _fetchNextKey;
  Object? _fetchPrevKey;

  bool _canFetchNext(int index) =>
      !_dataSourceExhausted.last && (widget.canFetchNext?.call(index) ?? true);
  bool _canFetchPrev(int index) =>
      (widget.fetchPrev != null && !_dataSourceExhausted.first) &&
      (widget.canFetchPrev?.call(index) ?? true);

  @override
  void initState() {
    super.initState();
    _reset();

    _initialize();
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataKey != widget.dataKey) {
      _reset();
      _initialize();
    }
  }

  Future<void> _initialize([int retryCount = 0]) async {
    void fSetState() {
      if (mounted) {
        setState(() {
          if (_data.isEmpty) {
            _readyViewed = true;
          }

          _initialized = true;
        });
      }
    }

    try {
      if (widget.gridDelegate != null) {
        if (_crossAxisCount < 1) {
          return;
        }
        _initialIndex = _initialIndex - (_initialIndex % _crossAxisCount);
        assert(_initialIndex >= 0);

        _topIndex = _initialIndex;
        _shouldLoadDataIndex.first = _initialIndex - 1;
        _shouldLoadDataIndex.last = _initialIndex;
      } else {
        _crossAxisCount = 1;
      }

      if (_canFetchNext(_initialIndex)) {
        bool tResult = false;
        tResult = await _fetch(_initialIndex, backward: false, doSetter: false);
        if (!tResult || !mounted) {
          return;
        }
      }

      if (widget.initialIndex != null) {
        if (!_data.containsKey(_initialIndex)) {
          final tCanRetry = (retryCount < 10);
          if (widget.initialIndexNotFoundCallback?.call(
                    _initialIndex,
                    !tCanRetry,
                  ) ==
                  true &&
              tCanRetry) {
            final tCrossAxisCount = _crossAxisCount;
            _reset();
            _crossAxisCount = tCrossAxisCount;
            await _initialize(retryCount + 1);
            return;
          }

          _data.clear();
          _dataSourceExhausted.first = true;
          _dataSourceExhausted.last = true;
        }
      }

      fSetState();
    } catch (e) {
      _error = e;

      fSetState();
      rethrow;
    }
  }

  void _reset() {
    _key = Object();
    _initialized = false;
    _readyViewed = false;
    _backwardLoadTriggerFirstLayout = true;
    _initialIndex = widget.initialIndex?.call() ?? 0;
    if (_initialIndex < 0) {
      _initialIndex = 0;
    }
    _topIndex = _initialIndex;
    _crossAxisCount = 0;
    _sliverListKeys.clear();
    _shouldLoadDataIndex.first = _initialIndex - 1;
    _shouldLoadDataIndex.last = _initialIndex;
    _data.clear();
    _backedItemSizeList.clear();
    _dataSourceExhausted.first = false;
    _dataSourceExhausted.last = false;

    _prefixScrollExtent = 0.0;
    _backedLoadTriggerSize = 0.0;

    _error = null;
    _fetchNextKey = null;
    _fetchPrevKey = null;
  }

  Future<bool> _fetch(
    int index, {
    required bool backward,
    bool doSetter = true,
    bool layoutInProgress = false,
  }) async {
    if (backward) {
      if (!_canFetchPrev(index) || _fetchPrevKey != null) {
        return false;
      }
    } else {
      if (!_canFetchNext(index) || _fetchNextKey != null) {
        return false;
      }
    }

    final tFetchKey = Object();
    if (backward) {
      _fetchPrevKey = tFetchKey;
    } else {
      _fetchNextKey = tFetchKey;
    }

    bool fCanContinue() {
      if (!mounted) {
        return false;
      }
      if (backward) {
        if (tFetchKey != _fetchPrevKey) {
          return false;
        }
      } else if (tFetchKey != _fetchNextKey) {
        return false;
      }

      return true;
    }

    try {
      final tItems = await (backward
          ? widget.fetchPrev?.call(index, _crossAxisCount)
          : widget.fetchNext.call(index, _crossAxisCount));
      if (tItems == null || !fCanContinue()) {
        return false;
      }

      fFinally() {
        if (backward) {
          _fetchPrevKey = null;
          _shouldLoadDataIndex.first -= tItems.length;
          for (int i = 0; i < tItems.length; i++) {
            _data[index + 1 - tItems.length + i] = tItems[i];
          }
          if (tItems.isNotEmpty) {
            _backedItemSizeList.add(tItems.length);
          }
          _dataSourceExhausted.first = tItems.isEmpty;
        } else {
          _fetchNextKey = null;
          _shouldLoadDataIndex.last += tItems.length;
          for (int i = 0; i < tItems.length; i++) {
            _data[index + i] = tItems[i];
          }
          _dataSourceExhausted.last = tItems.isEmpty;
        }
      }

      if (doSetter) {
        // This method may be called while the widget is being built, laid out, or painted.
        // If fetchNext or fetchPrev completes synchronously, calling setState will trigger an assert.
        // Therefore, to avoid asserts, call it asynchronously using Future.microtask.
        if (layoutInProgress) {
          Future.microtask(() {
            if (fCanContinue()) {
              setState(fFinally);
            }
          });
        } else {
          // There is no pattern going in here in the current implementation.
          setState(fFinally); // coverage:ignore-line
        }
      } else {
        fFinally();
      }

      return true;
    } catch (e) {
      fSetState() {
        Future.microtask(() {
          if (mounted) {
            setState(() {});
          }
        });
      }

      if (backward && (tFetchKey == _fetchPrevKey)) {
        _fetchPrevKey = null;
        _error = e;
        fSetState();
      } else if (tFetchKey == _fetchNextKey) {
        _fetchNextKey = null;
        _error = e;
        fSetState();
      }

      rethrow;
    }
  }

  bool _onShortage(bool backward, VoidCallback onProgressive) {
    Future<bool>? tFuture;

    if (backward) {
      if (_canFetchPrev(_shouldLoadDataIndex.first)) {
        tFuture = _fetch(
          _shouldLoadDataIndex.first,
          backward: true,
          doSetter: false,
        );
      }
    } else if (_canFetchNext(_shouldLoadDataIndex.last)) {
      tFuture = _fetch(
        _shouldLoadDataIndex.last,
        backward: false,
        doSetter: false,
      );
    }

    tFuture?.whenComplete(() {
      if (mounted) {
        setState(onProgressive);
      }
    });

    return tFuture != null;
  }

  @override
  Widget build(BuildContext context) {
    late Widget tWidget;

    final tLoading =
        widget.loading ?? const Center(child: CircularProgressIndicator());

    tWidget = _CustomScrollView(
      key: ObjectKey(_key),
      physics: widget.physics,
      scrollDirection: widget.scrollDirection,
      primary: widget.primary,
      controller: widget.controller,
      clipBehavior: widget.clipBehavior,
      cacheExtent: widget.cacheExtent,
      onShortage: _onShortage,
      initializing: !_initialized,
      onReady: () {
        scheduleFunction(() {
          if (!mounted) {
            return;
          }

          setState(() {
            _readyViewed = true;
          });
        });
      },
      onUpdatePrefixExtent: (prefixScrollExtent) {
        _prefixScrollExtent = prefixScrollExtent;
        if (_readyViewed) {
          scheduleFunction(() {
            if (!mounted) {
              return;
            }

            setState(() {});
          });
        }
      },
      slivers: [
        if (_initialized) ...[
          for (int i = 0; i < (widget.overlaySlivers?.length ?? -1); i++)
            _PrefixSliverProxy(
              key: ValueKey<String>('Overlay:$i'),
              child: widget.overlaySlivers![i],
            ),
          if (widget.prefix != null)
            _PrefixSliverProxy(
              key: const ValueKey<String>('Prefix'),
              child: SliverToBoxAdapter(child: widget.prefix!),
            ),
          ..._buildList(),
          if (widget.suffix != null && _readyViewed)
            SliverToBoxAdapter(child: widget.suffix!),
        ] else if (widget.gridDelegate != null && _crossAxisCount < 1) ...[
          _SliverListIndexListener(
            onNotification: (index, crossAxisCount) {
              _crossAxisCount = crossAxisCount;
              scheduleFunction(() {
                if (!mounted) {
                  return;
                }
                _initialize();
              });
            },
            backward: false,
            offsetCorrection: false,
            child: SliverGrid(
              gridDelegate: widget.gridDelegate!,
              delegate: SliverChildBuilderDelegate(
                childCount: 1,
                (context, index) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ],
    );

    tWidget = Stack(
      fit: StackFit.expand,
      children: [
        Visibility.maintain(
          visible:
              _readyViewed ||
              (widget.gridDelegate != null && _crossAxisCount < 1),
          child: tWidget,
        ),
        if (!_readyViewed) SizedBox.expand(child: tLoading),
      ],
    );

    if (widget.canRefresh) {
      if (widget.refreshIndicatorBuilder != null) {
        tWidget = widget.refreshIndicatorBuilder!(context, tWidget, _onRefresh);
      } else {
        tWidget = RefreshIndicator(onRefresh: _onRefresh, child: tWidget);
      }
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (_readyViewed && _data.isNotEmpty) {
          widget.onIndexChanged?.call(_topIndex, _crossAxisCount);
        }
        return false;
      },
      child: tWidget,
    );
  }

  List<Widget> _buildList() {
    if (_error != null) {
      return [
        SliverFillRemaining(
          child:
              widget.errorBuilder?.call(context, _error!) ??
              const SizedBox.shrink(),
        ),
      ];
    }
    if (_data.isEmpty) {
      return [
        SliverFillRemaining(child: widget.empty ?? const SizedBox.shrink()),
      ];
    }

    Widget fBuildSliverList(
      int startIndex,
      int length,
      bool backward,
      double backedLoadTriggerSize,
    ) {
      final tKeyValue = 'List:$startIndex';
      ValueKey<String>? tKey = _sliverListKeys[tKeyValue];
      final tFirstLayout = tKey == null;

      tKey ??= ValueKey<String>(tKeyValue);
      _sliverListKeys[tKeyValue] = tKey;

      // Do not wrap _SliverListIndexListener in another widget at this point.
      return _SliverListIndexListener(
        key: tKey,
        backward: backward,
        backedLoadTriggerSize: backedLoadTriggerSize,
        notificationOffset: () => _prefixScrollExtent,
        offsetCorrection: tFirstLayout && backward,
        onNotification: (index, crossAxisCount) {
          if (_readyViewed) {
            _topIndex = index + startIndex;
            _crossAxisCount = crossAxisCount;
          }
        },
        child: widget._listBuilder(
          context,
          (context, index) => _builder(context, startIndex + index),
          length,
        ),
      );
    }

    fBuildLoadTrigger(bool backward) {
      final tKeyValue = (backward)
          ? 'Load:${_shouldLoadDataIndex.first}'
          : 'Load:${_shouldLoadDataIndex.last}';
      ValueKey<String>? tKey = _sliverListKeys[tKeyValue];
      final tFirstLayout = tKey == null;

      tKey ??= ValueKey<String>(tKeyValue);
      _sliverListKeys[tKeyValue] = tKey;

      final Widget tWidget;
      if (backward) {
        final tBackwardLoadTriggerFirstLayout = _backwardLoadTriggerFirstLayout;
        _backwardLoadTriggerFirstLayout = false;

        tWidget = _LoadTrigger(
          key: tKey,
          backward: true,
          offsetCorrection: tBackwardLoadTriggerFirstLayout && tFirstLayout,
          load: (triggerWidgetSize) {
            _backedLoadTriggerSize = triggerWidgetSize;
            _fetch(
              _shouldLoadDataIndex.first,
              backward: true,
              doSetter: true,
              layoutInProgress: true,
            );
          },
          child: Builder(
            builder: (_) {
              return _buildLoading();
            },
          ),
        );
      } else {
        tWidget = _LoadTrigger(
          key: tKey,
          backward: false,
          offsetCorrection: false,
          load: (_) {
            _fetch(
              _shouldLoadDataIndex.last,
              backward: false,
              doSetter: true,
              layoutInProgress: true,
            );
          },
          child: Builder(
            builder: (_) {
              return _buildLoading();
            },
          ),
        );
      }

      return tWidget;
    }

    final tBackwardWidgetList = <Widget>[];

    if (_backedItemSizeList.isNotEmpty) {
      int tListFirstIndex = _shouldLoadDataIndex.first + 1;
      for (int i = _backedItemSizeList.length - 1; i >= 0; i--) {
        final tLength = _backedItemSizeList[i];
        tBackwardWidgetList.add(
          fBuildSliverList(
            tListFirstIndex,
            tLength,
            true,
            (i == _backedItemSizeList.length - 1
                ? _backedLoadTriggerSize
                : 0.0),
          ),
        );

        tListFirstIndex += tLength;
      }
    }

    final Widget tForwardWidget = fBuildSliverList(
      _initialIndex,
      _shouldLoadDataIndex.last - _initialIndex,
      false,
      0.0,
    );

    // Widgets within tWidgetList are not intended to be wrapped in a widget other than SliverPadding.
    final tWidgetList = [
      if (_readyViewed && _canFetchPrev(_shouldLoadDataIndex.first))
        fBuildLoadTrigger(true),
      ...tBackwardWidgetList,
      tForwardWidget,
      if (_readyViewed && _canFetchNext(_shouldLoadDataIndex.last))
        fBuildLoadTrigger(false),
    ];
    if (widget.padding != null) {
      Widget fWrapPadding(Widget widget, EdgeInsets padding) {
        return SliverPadding(key: widget.key, padding: padding, sliver: widget);
      }

      if (tWidgetList.length == 1) {
        tWidgetList[0] = fWrapPadding(tWidgetList[0], widget.padding!);
      } else {
        for (int i = 0; i < tWidgetList.length; i++) {
          final tPadding = (tWidgetList[i] == tWidgetList.first)
              ? widget.padding!.copyWith(bottom: 0)
              : (tWidgetList[i] == tWidgetList.last)
              ? widget.padding!.copyWith(top: 0)
              : widget.padding!.copyWith(top: 0, bottom: 0);

          tWidgetList[i] = fWrapPadding(tWidgetList[i], tPadding);
        }
      }
    }

    return tWidgetList;
  }

  Future<void> _onRefresh() async {
    setState(() {
      widget.onRefresh?.call();
      _reset();
      _initialize();
    });
  }

  VoidCallback _startListening(InheritedContext<T?> e, T value) {
    (value as Listenable).addListener(e.markNeedsNotifyDependents);
    return () => value.removeListener(e.markNeedsNotifyDependents);
  }

  Widget _buildLoading() {
    return widget.loadingMore ??
        const SizedBox(
          height: 104,
          child: Center(child: CircularProgressIndicator()),
        );
  }

  Widget _builder(BuildContext context, int index) {
    final tItem = _data[index];
    if (tItem != null) {
      return MultiProvider(
        key: ValueKey<int>(index),
        providers: [
          Provider<InfiniteScrollItemInformation>(
            create: (context) => InfiniteScrollItemInformation(index),
          ),
          if (tItem is Listenable) ...[
            InheritedProvider<T>.value(
              value: tItem,
              startListening: _startListening,
            ),
          ] else ...[
            Provider<T>.value(value: tItem),
          ],
        ],
        builder: (context, _) => widget.itemBuilder(context, tItem, index),
      );
    }

    // coverage:ignore-start
    assert(false, 'Invalid index');
    return const SizedBox.shrink();
    // coverage:ignore-end
  }
}

/// Provides information about an item in the infinite scroll list.
///
/// Registered as a Provider in each item's parent Widget, and can be accessed
/// using [context.read], etc.
class InfiniteScrollItemInformation {
  /// The index of the item.
  final int index;

  /// Creates an [InfiniteScrollItemInformation] with the given index.
  const InfiniteScrollItemInformation(this.index);
}

class _PrefixSliverProxy extends SingleChildRenderObjectWidget {
  const _PrefixSliverProxy({super.key, required super.child});

  @override
  _RenderPrefixSliverProxy createRenderObject(BuildContext context) {
    return _RenderPrefixSliverProxy();
  }
}

class _RenderPrefixSliverProxy extends RenderProxySliver {}

typedef _OnShortage = bool Function(bool backward, VoidCallback onProgressive);
typedef _OnReady = void Function();
typedef _OnUpdatePrefixExtent = void Function(double prefixScrollExtent);

class _CustomScrollView extends CustomScrollView {
  const _CustomScrollView({
    super.key,
    super.scrollDirection,
    super.controller,
    super.primary,
    super.physics,
    super.cacheExtent,
    super.slivers,
    super.clipBehavior,
    required this.onShortage,
    required this.onReady,
    required this.onUpdatePrefixExtent,
    this.initializing = false,
  });

  final _OnShortage onShortage;
  final _OnReady onReady;
  final _OnUpdatePrefixExtent onUpdatePrefixExtent;
  final bool initializing;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    return _Viewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
      clipBehavior: clipBehavior,
      onShortage: onShortage,
      onReady: onReady,
      onUpdatePrefixExtent: onUpdatePrefixExtent,
      initializing: initializing,
    );
  }
}

class _Viewport extends Viewport {
  _Viewport({
    super.axisDirection,
    super.anchor,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.clipBehavior,
    super.slivers,
    required this.onShortage,
    required this.onReady,
    required this.onUpdatePrefixExtent,
    this.initializing = false,
  });

  final _OnShortage onShortage;
  final _OnReady onReady;
  final _OnUpdatePrefixExtent onUpdatePrefixExtent;
  final bool initializing;

  @override
  _RenderViewport createRenderObject(BuildContext context) {
    return _RenderViewport(
      axisDirection: axisDirection,
      crossAxisDirection:
          crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
      onShortage: onShortage,
      onReady: onReady,
      onUpdatePrefixExtent: onUpdatePrefixExtent,
      initializing: initializing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderViewport renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject.initializing = initializing;
  }
}

class _RenderViewport extends RenderViewport {
  _RenderViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    required this.onShortage,
    required this.onReady,
    required this.onUpdatePrefixExtent,
    this.initializing = false,
  });

  final _OnShortage onShortage;
  final _OnReady onReady;
  final _OnUpdatePrefixExtent onUpdatePrefixExtent;
  bool initializing;

  bool _forWait = false;
  bool _isReady = false;

  double _prefixScrollExtent = 0.0;

  @override
  void performLayout() {
    super.performLayout();

    if (firstChild == null || lastChild == null || initializing) {
      return;
    }

    double tPrefixScrollExtent = 0.0;
    for (
      RenderSliver? tChild = firstChild;
      tChild != null;
      (tChild = childAfter(tChild))
    ) {
      if (tChild is! _RenderPrefixSliverProxy) {
        break;
      }
      tPrefixScrollExtent += tChild.geometry!.scrollExtent;
    }
    if (tPrefixScrollExtent != _prefixScrollExtent) {
      _prefixScrollExtent = tPrefixScrollExtent;

      onUpdatePrefixExtent(_prefixScrollExtent);
    }

    if (_isReady || _forWait) {
      return;
    }

    double tForwardListScrollExtent = lastChild!.geometry!.scrollExtent;
    double tBackwardListScrollExtent = 0.0;
    for (
      RenderSliver? tChild = childBefore(lastChild!);
      tChild != null;
      (tChild = childBefore(tChild))
    ) {
      if (tChild is _RenderPrefixSliverProxy) {
        break;
      }
      tBackwardListScrollExtent += tChild.geometry!.scrollExtent;
    }

    final tExtent = switch (axis) {
      Axis.vertical => size.height,
      Axis.horizontal => size.width,
    };

    final tForwardAbundance =
        tForwardListScrollExtent >= (tExtent - _prefixScrollExtent);
    final tBackwardAbundance = tBackwardListScrollExtent >= _prefixScrollExtent;

    if (tForwardAbundance && tBackwardAbundance) {
      _isReady = true;
      onReady();
      return;
    }

    _forWait = true;

    bool tShortageResult;
    if (!tForwardAbundance &&
        (tForwardListScrollExtent + tBackwardListScrollExtent) < tExtent) {
      tShortageResult = onShortage.call(false, _onProgressive);
      if (!tShortageResult) {
        tShortageResult = onShortage.call(true, _onProgressive);
      }
    } else if (!tBackwardAbundance) {
      tShortageResult = onShortage.call(true, _onProgressive);
    } else {
      tShortageResult = false;
    }

    if (!tShortageResult) {
      _isReady = true;
      onReady();
      return;
    }
  }

  void _onProgressive() {
    _forWait = false;
    markNeedsLayout();
  }
}

mixin _ScrollSliversBaseMixin on RenderSliver {
  double _endScrollOffsetCorrection = 0.0;
  double get endScrollOffsetCorrection => _endScrollOffsetCorrection;
  double _scrollExtent = 0.0;

  void calcEndScrollOffsetCorrection(SliverGeometry geometry) {
    _endScrollOffsetCorrection = geometry.scrollExtent - _scrollExtent;
    _scrollExtent = geometry.scrollExtent;
  }

  SliverPhysicalContainerParentData getViewportParentData(RenderObject sliver) {
    RenderObject? tRenderObject = sliver;
    while (tRenderObject != null &&
        tRenderObject.parentData is! SliverPhysicalContainerParentData) {
      tRenderObject = tRenderObject.parent;
    }

    return tRenderObject!.parentData as SliverPhysicalContainerParentData;
  }

  RenderObject? getViewportNextSibling(RenderObject sliver) {
    final tNextSibling = getViewportParentData(sliver).nextSibling;
    return (tNextSibling is RenderSliverPadding)
        ? tNextSibling.child
        : tNextSibling;
  }

  RenderObject? getViewportPreviousSibling(RenderObject sliver) {
    final tPreviousSibling = getViewportParentData(sliver).previousSibling;
    return (tPreviousSibling is RenderSliverPadding)
        ? tPreviousSibling.child
        : tPreviousSibling;
  }

  double getPaintOffset(RenderObject sliver) {
    final tParentData = getViewportParentData(sliver);
    return tParentData.paintOffset.distance;
  }
}

typedef _OnTriggerCallback = void Function(double triggerWidgetSize);

class _LoadTrigger extends SliverToBoxAdapter {
  const _LoadTrigger({
    super.key,
    super.child,
    required this.backward,
    required this.load,
    this.offsetCorrection = true,
  });

  final bool backward;
  final _OnTriggerCallback load;
  final bool offsetCorrection;

  @override
  RenderSliverToBoxAdapter createRenderObject(BuildContext context) {
    return _LoadingAnchorRender(
      backward: backward,
      load: load,
      offsetCorrection: offsetCorrection,
    );
  }
}

class _LoadingAnchorRender extends RenderSliverToBoxAdapter
    with _ScrollSliversBaseMixin {
  _LoadingAnchorRender({
    required this.backward,
    required this.load,
    required this.offsetCorrection,
  });

  final bool backward;
  final _OnTriggerCallback load;
  final bool offsetCorrection;
  bool _isReady = false;
  bool _isNotified = false;

  _RenderSliverListIndexListener? _sliverList;

  @override
  void performLayout() {
    super.performLayout();

    if (!_isReady) {
      if (offsetCorrection) {
        calcEndScrollOffsetCorrection(geometry!);
        if (backward && endScrollOffsetCorrection != 0.0) {
          geometry = SliverGeometry(
            scrollOffsetCorrection: endScrollOffsetCorrection,
          );
          return;
        }
      }
      final RenderObject? tRenderObject;
      if (backward) {
        tRenderObject = getViewportNextSibling(this);
      } else {
        tRenderObject = getViewportPreviousSibling(this);
      }
      if (tRenderObject is _RenderSliverListIndexListener) {
        _sliverList = tRenderObject;
      }
    }
    _isReady = true;

    if (_sliverList?.isReady != true) {
      return;
    }

    bool tVisible = false;
    double tChildExtent = 0.0;
    if (backward) {
      final double tScrollOffset = constraints.scrollOffset;

      switch (constraints.axis) {
        case Axis.horizontal:
          tChildExtent = child!.size.width;
        case Axis.vertical:
          tChildExtent = child!.size.height;
      }

      tVisible = (tScrollOffset - tChildExtent) < 0.0;
    } else {
      final tRemainingExtent = constraints.remainingCacheExtent;
      tVisible = tRemainingExtent > 0;
    }

    if (tVisible) {
      _trigger(tChildExtent);
    }
  }

  void _trigger(double triggerWidgetSize) {
    if (!_isNotified) {
      _isNotified = true;
      load(triggerWidgetSize);
    }
  }
}

typedef _SliverListIndexNotifyCallback =
    void Function(int index, int crossAxisCount);
typedef _NotificationOffset = double Function();

class _SliverListIndexListener extends SingleChildRenderObjectWidget {
  const _SliverListIndexListener({
    super.key,
    required super.child,
    required this.onNotification,
    required this.backward,
    this.notificationOffset,
    this.backedLoadTriggerSize = 0.0,
    this.offsetCorrection = true,
  });

  final _SliverListIndexNotifyCallback onNotification;
  final bool backward;
  final _NotificationOffset? notificationOffset;
  final double backedLoadTriggerSize;
  final bool offsetCorrection;

  @override
  _RenderSliverListIndexListener createRenderObject(BuildContext context) {
    return _RenderSliverListIndexListener(
      onNotification: onNotification,
      backward: backward,
      notificationOffset: notificationOffset,
      backedLoadTriggerSize: backedLoadTriggerSize,
      offsetCorrection: offsetCorrection,
    );
  }
}

class _RenderSliverListIndexListener extends RenderProxySliver
    with _ScrollSliversBaseMixin {
  _RenderSliverListIndexListener({
    required this.onNotification,
    required this.backward,
    required this.notificationOffset,
    required this.backedLoadTriggerSize,
    required this.offsetCorrection,
  });

  final _SliverListIndexNotifyCallback onNotification;
  final bool backward;
  final _NotificationOffset? notificationOffset;
  final double backedLoadTriggerSize;
  final bool offsetCorrection;

  RenderSliverList? _sliverList;
  RenderSliverGrid? _sliverGrid;
  int _corssAxisCount = 0;

  bool _isReady = false;
  bool get isReady => _isReady;

  bool _notify = false;

  @override
  void paint(context, offset) {
    super.paint(context, offset);

    if (_notify) {
      _notifyListTopIndex();
      _notify = false;
    }
  }

  @override
  void performLayout() {
    _notify = false;
    _sliverList = null;
    _sliverGrid = null;

    super.performLayout();

    if ((child is RenderSliverList)) {
      _sliverList = child as RenderSliverList;
    } else if (child is RenderSliverGrid) {
      _sliverGrid = child as RenderSliverGrid;
    }

    if (_sliverGrid != null) {
      final tLayout = _sliverGrid!.gridDelegate.getLayout(constraints);
      // Any value for scrollOffset is fine, but specifying 0.0 will result in an
      // internal mainAxisCount of 0, so 0.1 is specified.
      _corssAxisCount =
          (tLayout.getMaxChildIndexForScrollOffset(0.1) -
              tLayout.getMinChildIndexForScrollOffset(0.1)) +
          1;

      if (backward || getViewportNextSibling(this) is _LoadingAnchorRender) {
        final tCrossGeometry = tLayout.getGeometryForChildIndex(
          _corssAxisCount,
        );
        final tSpacing =
            tCrossGeometry.scrollOffset % tCrossGeometry.mainAxisExtent;

        double fExtentWithSpacing(
          double extent, [
          double maxExtent = double.infinity,
        ]) {
          double tAddExtent = tSpacing;
          if (extent <= 0.0) {
            tAddExtent -= (constraints.scrollOffset - geometry!.scrollExtent);
          }
          if (tAddExtent < 0.0) {
            tAddExtent = 0.0;
          }

          final tResult = extent + tAddExtent;
          return (tResult > maxExtent) ? maxExtent : tResult;
        }

        final tPaintExtent = fExtentWithSpacing(
          geometry!.paintExtent,
          constraints.remainingPaintExtent,
        );
        final tLayoutExtent = fExtentWithSpacing(
          geometry!.layoutExtent,
          tPaintExtent,
        );
        final tCacheExtent = fExtentWithSpacing(
          geometry!.cacheExtent,
          constraints.remainingCacheExtent,
        );
        final tMaxPaintExtent = fExtentWithSpacing(geometry!.maxPaintExtent);
        final tScrollExtent = fExtentWithSpacing(geometry!.scrollExtent);

        geometry = geometry!.copyWith(
          paintExtent: tPaintExtent,
          layoutExtent: tLayoutExtent,
          cacheExtent: tCacheExtent,
          maxPaintExtent: tMaxPaintExtent,
          scrollExtent: tScrollExtent,
        );
      }
    } else {
      _corssAxisCount = 1;
    }

    if (!_isReady) {
      if (offsetCorrection) {
        calcEndScrollOffsetCorrection(geometry!);
        if (backward) {
          if (endScrollOffsetCorrection != 0.0) {
            geometry = SliverGeometry(
              scrollOffsetCorrection: endScrollOffsetCorrection,
            );
            return;
          }

          final tPreviousSibling = getViewportPreviousSibling(this);
          if (tPreviousSibling is! _LoadingAnchorRender &&
              backedLoadTriggerSize != 0.0) {
            geometry = SliverGeometry(
              scrollOffsetCorrection: -backedLoadTriggerSize,
            );
            _isReady = true;
            return;
          }
        }
      }
    }
    _isReady = true;

    // Do not notify if there is no drawing area.
    // The reason for specifying 0.01 instead of 0 is that floating-point errors
    // can result in a value very close to 0 being set.
    if (constraints.remainingPaintExtent < 0.01 ||
        constraints.remainingCacheExtent < 0.01) {
      return;
    }

    if (_sliverList == null && _sliverGrid == null) {
      return;
    }

    if (geometry!.paintExtent <= 0.0) {
      return;
    }

    _notify = true;
  }

  void _notifyListTopIndex() {
    final tNotifyOffset = notificationOffset?.call() ?? 0.0;
    final tScrollOffset = constraints.scrollOffset - getPaintOffset(this);
    if ((tScrollOffset >= geometry!.scrollExtent - tNotifyOffset) ||
        (tScrollOffset < -tNotifyOffset)) {
      return;
    }

    int tIndex = -1;
    if (_sliverGrid != null) {
      final tGrid = _sliverGrid!;

      RenderBox? tItem = tGrid.firstChild;
      do {
        final tItemScrollOffset = tGrid.childScrollOffset(tItem!)!;
        if ((tItemScrollOffset - tNotifyOffset) > tScrollOffset) {
          break;
        }
        tIndex = tGrid.indexOf(tItem);
        for (int i = 0; i < _corssAxisCount; i++) {
          if (tItem == null) {
            break;
          }
          tItem = tGrid.childAfter(tItem);
        }
      } while (tItem != null);
    } else if (_sliverList != null) {
      final tList = _sliverList!;

      RenderBox? tItem = tList.firstChild;
      do {
        final tItemScrollOffset = tList.childScrollOffset(tItem!)!;
        if ((tItemScrollOffset - tNotifyOffset) > tScrollOffset) {
          break;
        }
        tIndex = tList.indexOf(tItem);
      } while ((tItem = tList.childAfter(tItem)) != null);
    }

    if (tIndex >= 0) {
      onNotification(tIndex, _corssAxisCount);
    }
  }
}
