// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

final _logger = Logger('patapata.Analytics');

class _AnalyticsGlobalContextRouteKey {}

/// A mixin for an [App.environment] that can filter [AnalyticsEvent]s.
mixin AnalyticsEventFilterEnvironment {
  /// A map of [Type] to a function that takes an [AnalyticsEvent] and returns
  /// an [AnalyticsEvent] or null if the event should be filtered.
  /// The [Type] is usually a [Plugin] type or another custom type.
  /// You can use this to force certain events to only be sent to certain
  /// plugins or other types as well as transform the event.
  Map<Type, AnalyticsEvent? Function(AnalyticsEvent event)>
      get analyticsEventFilter;
}

/// An analytics class that notifies and monitors information related to events within the app,
/// user tracking, and more, to external services or within the app itself.
class Analytics {
  final _eventStreamController = StreamController<AnalyticsEvent>.broadcast();

  /// The stream of [AnalyticsEvent] that are sent via [event], [rawEvent], and other method that send events.
  Stream<AnalyticsEvent> get events => _eventStreamController.stream;

  /// Listen to analytics events.
  /// These will be filtered by checking [T] in the
  /// [App.environment] if it's a [AnalyticsEventFilterEnvironment]
  /// to see if a given event should be sent to that type [T].
  Stream<AnalyticsEvent> eventsFor<T>() {
    return events
        .map<AnalyticsEvent?>((event) {
          final tEnvironment =
              getApp().environmentAs<AnalyticsEventFilterEnvironment>();

          if (tEnvironment?.analyticsEventFilter.containsKey(T) == true) {
            return tEnvironment!.analyticsEventFilter[T]!(event);
          }
          return event;
        })
        .where((event) => event != null)
        .map((event) => event!);
  }

  late final _globalContext = _MultiAnalyticsContext()
    ..add(_globalContextRouteKey, _globalRouteContext);

  /// Analytics Context found in the route.
  AnalyticsContext get globalContext => _globalContext;

  /// Adds an [AnalyticsContext] with the [key] name to the global context.
  /// Passing null for [context] will remove it from the global context.
  ///
  /// example:
  ///
  /// ```dart
  /// // If you want to add context information to all events
  /// final _key = Object();
  /// getApp().analytics.setGlobalContext(_key, AnalyticsContext(
  ///   data: {
  ///     'key1': 1,
  ///   },
  /// ));
  /// // When you want to remove it
  /// getApp().analytics.setGlobalContext(_key, null);
  /// ```
  void setGlobalContext(Object key, AnalyticsContext? context) {
    _logger.fine('Changing global context: key: $key, context: $context');

    if (context == null) {
      _globalContext.remove(key);
    } else {
      _globalContext.add(key, context);
    }
  }

  /// The [AnalyticsContext] that was set with [key] in the global context.
  AnalyticsContext? getGlobalContext(Object key) => _globalContext.get(key);

  final _globalContextRouteKey = _AnalyticsGlobalContextRouteKey();
  final _globalRouteContext = _MultiAnalyticsContext();

  /// Add an [AnalyticsContext] with the [key] name to the global route context.
  /// If you pass null for the argument [context] of this function, it will be removed from the global route context.
  /// The values set in this Route Context will disappear when transitioning to other pages.
  /// example:
  ///
  /// ```dart
  /// final _key = Object();
  /// getApp().analytics.setRouteContext(_key, AnalyticsContext(
  ///   data: {
  ///     'key1': 1,
  ///   },
  /// ));
  ///
  /// // When deleting manually
  /// getApp().analytics.setRouteContext(_key, null);
  /// ```
  void setRouteContext(Object key, AnalyticsContext? context) {
    if (context == null) {
      _globalRouteContext.remove(key);
    } else {
      _globalRouteContext.add(key, context);
    }
  }

  /// The [AnalyticsContext] that was set with [key] in the global route context.
  AnalyticsContext? getRouteContext(Object key) => _globalRouteContext.get(key);

  AnalyticsContext? __interactionContext;
  Map<String, Object?>? _interactionContextData;

  /// A Map of data from the Context of a Widget with the most recently interacted (touched) with Analytics information by the user.
  Map<String, Object?>? get interactionContextData => _interactionContextData;
  set _interactionContext(AnalyticsContext? context) {
    if (context != __interactionContext) {
      _logger.fine('Changing interaction context: $context');
      __interactionContext = context;
      _interactionContextData = context?.resolve();
    }
  }

  Map<String, Object?>? _navigationInteractionContextData;

  /// A Map of data to retain analytics information for page transitions.
  Map<String, Object?>? get navigationInteractionContextData =>
      _navigationInteractionContextData;

  void _promoteInteractionContextToNavigationContext() {
    _logger.finer('Promoting interaction context...');
    _navigationInteractionContextData = interactionContextData;
    _interactionContext = null;
  }

  /// Send analytics for the information in [event].
  /// Used when you want to send custom analytics events.
  ///
  /// example:
  ///
  /// ```dart
  /// getApp().analytics.rawEvent(AnalyticsEvent(
  ///   name: 'Custom Hogehoge Event',
  /// ));
  /// ```
  void rawEvent(
    AnalyticsEvent event, {
    Level logLevel = Level.INFO,
  }) {
    event._navigationInteractionContextData = navigationInteractionContextData;

    _logger.log(logLevel, () => '$event');
    _eventStreamController.add(event);
  }

  /// Send analytics for the event with the name [name].
  /// When you cannot use Patapata's standard Analytics-related Widget or when you want to manually send events, you can follow this approach.
  ///
  /// example:
  ///
  /// ```dart
  /// getApp().analytics.event(
  ///   name: 'Hogehoge Event',
  /// );
  /// ```
  void event({
    required String name,
    Map<String, Object?>? data,
    BuildContext? context,
    Level logLevel = Level.INFO,
  }) {
    AnalyticsContext? tAnalyticsContext;

    if (context != null) {
      tAnalyticsContext = Provider.of<AnalyticsContext>(context, listen: false);
    } else {
      tAnalyticsContext = globalContext;
    }

    final tEvent = AnalyticsEvent(
      name: name,
      data: data,
      context: tAnalyticsContext,
    );

    tEvent._navigationInteractionContextData = navigationInteractionContextData;

    _logger.log(logLevel, () => '$tEvent');
    _eventStreamController.add(tEvent);
  }

  /// Send analytics for the [route].
  /// Used when you want to send events related to page transitions.
  ///
  /// example:
  ///
  /// ```dart
  /// getApp().analytics.routeViewEvent(
  ///   route: Route.of(context),
  ///   navigationType: AnalyticsNavigationType.push,
  /// );
  /// ```
  void routeViewEvent(
    Route route, {
    String navigationType = AnalyticsNavigationType.push,
  }) {
    _promoteInteractionContextToNavigationContext();
    rawEvent(
      AnalyticsRouteViewEvent(
        analytics: this,
        route: route,
        navigationType: navigationType,
      ),
    );
  }

  /// Send analytics for revenue.
  /// 'Revenue' refers to numeric values related to sales or earnings.
  ///
  /// example:
  ///
  /// ```dart
  /// getApp().analytics.revenueEvent(
  ///   revenue: 100.0,
  /// );
  /// ```
  void revenueEvent({
    required double revenue,
    String? currency,
    String? orderId,
    String? receipt,
    String? productId,
    String? productName,
    String? eventName,
    Map<String, Object?>? data,
    AnalyticsContext? context,
    Level logLevel = Level.INFO,
  }) {
    rawEvent(
      AnalyticsRevenueEvent(
        revenue: revenue,
        currency: currency,
        orderId: orderId,
        receipt: receipt,
        productId: productId,
        productName: productName,
        eventName: eventName,
        context: context,
      ),
      logLevel: logLevel,
    );
  }

  /// Convert the data type of [object] to int, double, or String using the default judgment and return it.
  /// Additionally, in this function, data for the Analytics system trims the value side of key-value pairs to a maximum of 100 characters.
  /// This is because the average length limitation for the value strings of third-party Analytics systems is around 100 characters.
  static Object? defaultMakeLoggableToNative(Object? object) {
    if (object == null) {
      return '';
    } else if (object is int || object is double || object is String) {
      if (object is String) {
        return object.characters.take(100).toString();
      }

      return object;
    } else {
      try {
        return jsonEncode(object).characters.take(100).toString();
      } catch (_) {
        return object.toString();
      }
    }
  }

  static const _kMaxJsonParameterLength = 100;

  /// Convert [object] into a loggable JSON parameter with the prefix [prefix].
  static Map<String, Object> tryConvertToLoggableJsonParameters(
      String prefix, Object? object) {
    if (object == null) {
      return const {};
    }

    final String tJson;

    if (object is String) {
      tJson = object;
    } else if (object is int || object is double) {
      tJson = object.toString();
    } else {
      try {
        tJson = jsonEncode(object);
      } catch (e) {
        return const {};
      }
    }

    final tMap = <String, Object>{};
    final tCharacters = tJson.characters;

    var i = 0;
    for (;; i++) {
      final tPart = tCharacters.getRange(
          _kMaxJsonParameterLength * i, _kMaxJsonParameterLength * (i + 1));

      if (tPart.isEmpty) {
        break;
      }

      tMap['$prefix${i + 1}'] = tPart.toString();
    }

    return tMap;
  }

  @override
  String toString() => 'interactionContext:$interactionContextData';
}

/// Analytics event class
class AnalyticsEvent {
  /// The name of this event.
  final String name;

  /// Analytics data.
  final Map<String, Object?>? data;

  /// A Map created from the AnalyticsContext passed to this event.
  final Map<String, Object?>? contextData;

  Map<String, Object?>? _navigationInteractionContextData;

  /// Data for NavigationInteractionContext.
  Map<String, Object?>? get navigationInteractionContextData =>
      _navigationInteractionContextData;

  /// Creates an [AnalyticsEvent].
  /// Specify the name for this [AnalyticsEvent] to be created with [name], and pass the data for this event to [data].
  /// If you provide [context], it will merge the data specified in [context] in to [data] with [data] being prioritized.
  AnalyticsEvent({
    required this.name,
    this.data,
    AnalyticsContext? context,
  }) : contextData = context?.resolve();

  /// A flat map from [contextData] and [data].
  Map<String, Object?>? get flatData => <String, Object?>{}
    ..addAll(contextData ?? const {})
    ..addAll(data ?? const {})
    ..removeWhere((key, value) => value == null);

  @override
  String toString() =>
      'AnalyticsEvent:$name: data=$data, context=$contextData, navigationInteractionContext=$navigationInteractionContextData';

  @override
  operator ==(Object other) => other is AnalyticsEvent
      ? name == other.name &&
          mapEquals(data, other.data) &&
          mapEquals(contextData, contextData)
      : false;

  @override
  int get hashCode => Object.hashAll([
        name,
        const MapEquality<String, Object?>().hash(data),
        const MapEquality<String, Object?>().hash(contextData),
      ]);
}

/// Context class for using analytics functionality,
/// to be used in conjunction with [AnalyticsContextProvider].
class AnalyticsContext {
  final Map<String, Object?> _data = {};
  AnalyticsContext? _parent;

  /// Creates a [AnalyticsContext] with event data [data].
  AnalyticsContext(Map<String, Object?> data) {
    _data.addAll(data);
  }

  factory AnalyticsContext._withParent(
    AnalyticsContext parent,
    AnalyticsContext child,
  ) =>
      AnalyticsContext(
        Map<String, Object?>.from(child._data),
      ).._parent = parent;

  /// Recursively examines parent [AnalyticsContext]s,
  /// and merges any data from them in to this [AnalyticsContext]'s data and returns the result.
  Map<String, Object?> resolve() => _parent != null
      ? {
          ..._parent!.resolve(),
          ..._data,
        }
      : Map<String, Object?>.from(_data);

  @override
  operator ==(Object other) => other is AnalyticsContext
      ? _parent == other._parent && mapEquals(_data, other._data)
      : false;

  @override
  int get hashCode => Object.hashAll([
        _parent,
        const MapEquality<String, Object?>().hash(_data),
      ]);

  @override
  String toString() => 'AnalyticsContext:${resolve()}';
}

class _MultiAnalyticsContext implements AnalyticsContext {
  @override
  AnalyticsContext? _parent;

  @override
  Map<String, Object?> get _data => {
        for (var i in _globalContextMap.values) ...i.resolve(),
      };

  final _globalContextMap = <Object, AnalyticsContext>{};

  void add(Object key, AnalyticsContext value) {
    _globalContextMap[key] = value;
  }

  void remove(Object key) {
    _globalContextMap.remove(key);
  }

  void clear() {
    _globalContextMap.clear();
  }

  AnalyticsContext? get(Object key) => _globalContextMap[key];

  @override
  Map<String, Object?> resolve() => _data;
}

/// A widget that provides [AnalyticsContext] to it's child widgets via [Provider].
///
/// example:
///
/// ```dart
/// class MyWidget extends StatelessWidget {
///   const MyWidget({super.key});
///   @override
///   Widget build(BuildContext context) {
///     return AnalyticsContextProvider(
///       analyticsContext: AnalyticsContext({
///         'hogehoge': 'fugafuga',
///       }),
///       child: ...,
///     );
///   }
/// }
/// ```
class AnalyticsContextProvider extends SingleChildStatelessWidget {
  /// This [AnalyticsContext] is passed to child widgets via [Provider].
  final AnalyticsContext analyticsContext;

  /// A flag to reset [analyticsContext]. Default is `false.`
  /// If set to true, a new analytics context will be created.
  /// If set to false, it will merge with the existing analytics context.
  final bool reset;

  /// Creates a AnalyticsContextProvider.
  /// Provide an [analyticsContext] and pass the widget to be wrapped as [child].
  /// Optionally, use the [reset] flag to specify whether to reset the [analyticsContext].
  const AnalyticsContextProvider({
    Key? key,
    required this.analyticsContext,
    required Widget child,
    this.reset = false,
  }) : super(
          key: key,
          child: child,
        );

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final tContext = reset
        ? analyticsContext
        : AnalyticsContext._withParent(
            context.watch<AnalyticsContext>(),
            analyticsContext,
          );

    return _AnalyticsContextProviderRenderWidget(
      analyticsContext: tContext,
      child: Provider<AnalyticsContext>.value(
        value: tContext,
        child: child,
      ),
    );
  }
}

class _AnalyticsContextProviderRenderWidget
    extends SingleChildRenderObjectWidget {
  final AnalyticsContext analyticsContext;

  const _AnalyticsContextProviderRenderWidget({
    Key? key,
    required this.analyticsContext,
    required Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  _AnalyticsContextProviderRenderObject createRenderObject(
          BuildContext context) =>
      _AnalyticsContextProviderRenderObject(analyticsContext);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _AnalyticsContextProviderRenderObject renderObject,
  ) {
    renderObject.analyticsContext = analyticsContext;
  }
}

class _AnalyticsContextProviderRenderObject extends RenderProxyBox {
  AnalyticsContext analyticsContext;

  _AnalyticsContextProviderRenderObject(this.analyticsContext);
}

/// Class that keeps track of which widgets the user has interacted with.
/// While this class is publicly accessible, it is not typically used directly by an application.
/// @nodoc
class AnalyticsPointerEventListener extends SingleChildRenderObjectWidget {
  const AnalyticsPointerEventListener({
    Key? key,
    required Widget child,
  }) : super(
          key: key,
          child: child,
        );

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _AnalyticsPointerEventListenerRenderObject(context.read<Analytics>());

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    covariant _AnalyticsPointerEventListenerRenderObject renderObject,
  ) {
    renderObject.analytics = context.read<Analytics>();
  }
}

class _AnalyticsPointerEventListenerRenderObject extends RenderProxyBox {
  Analytics analytics;

  _AnalyticsPointerEventListenerRenderObject(this.analytics);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      AnalyticsContext? tContext;
      RenderObject? tRenderObject;

      for (var i in result.path) {
        if (i.target is RenderObject) {
          tRenderObject = i.target as RenderObject;

          break;
        }
      }

      while (tRenderObject != null) {
        if (tRenderObject is _AnalyticsContextProviderRenderObject) {
          tContext = tRenderObject.analyticsContext;

          break;
        }

        tRenderObject = tRenderObject.parent;
      }

      analytics._interactionContext = tContext;

      return true;
    }

    return false;
  }

  // coverage:ignore-start
  @override
  bool hitTestSelf(Offset position) => false;
  // coverage:ignore-end
}

/// A widget that sends analytics events when the user taps the widget and releases their finger,
/// in other words, using [Listener.onPointerUp].
class AnalyticsEventWidget extends StatelessWidget {
  /// The name of the analytics event.
  final String? name;

  /// Analytics data.
  /// If [event] is not set, this property will be used.
  final Map<String, Object?>? data;

  /// The event to be set for analytics.
  final AnalyticsEvent? event;

  /// Widgets to target for analytics.
  final Widget? child;

  /// Creates a AnalyticsEventWidget.
  /// Specify the widget targeted for analytics operations in [child] and send analytics data.
  /// If you want to send a custom event, specify an AnalyticsEvent in [event]. If [event] is not set,
  /// send analytics data with the analytics event name specified in [name].
  const AnalyticsEventWidget({
    Key? key,
    this.name,
    this.data,
    this.event,
    this.child,
  })  : assert(event == null || name == null),
        assert(data == null || event == null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerUp: (_) {
        // ignore: todo
        // TODO: This event fires even when the child event cancels...
        if (event != null) {
          context.read<Analytics>().rawEvent(event!);
        } else {
          context.read<Analytics>().event(
                name: name!,
                data: data,
                context: context,
              );
        }
      },
      child: child,
    );
  }
}

/// A widget that sends an event only once when the child widget is built.
///
/// example:
///
/// ```dart
/// class MyWidget extends StatelessWidget {
///   const MyWidget({super.key});
///   @override
///   Widget build(BuildContext context) {
///     return AnalyticsSingletonEventWidget(
///       name: 'Hogehoge'
///       child: ...,
///     );
///   }
/// }
/// ```
class AnalyticsSingletonEventWidget extends SingleChildStatefulWidget {
  /// The name of the analytics event.
  final String? name;

  /// Analytics data to be sent.
  final Map<String, Object?>? data;

  /// The event to be set for analytics.
  final AnalyticsEvent? event;

  /// Creates a AnalyticsSingletonEventWidget.
  const AnalyticsSingletonEventWidget({
    Key? key,
    this.name,
    this.data,
    this.event,
    Widget? child,
  })  : assert(event == null || name == null),
        assert(data == null || event == null),
        super(
          key: key,
          child: child,
        );

  @override
  // ignore: library_private_types_in_public_api
  _AnalyticsSingletonEventWidgetState createState() =>
      _AnalyticsSingletonEventWidgetState();
}

class _AnalyticsSingletonEventWidgetState
    extends SingleChildState<AnalyticsSingletonEventWidget> {
  @override
  void initState() {
    super.initState();
    _sendEvent();
  }

  @override
  void didUpdateWidget(covariant AnalyticsSingletonEventWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Skip the data.
    if (widget.event != oldWidget.event || widget.name != oldWidget.name) {
      _sendEvent();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return child ?? const SizedBox.shrink();
  }

  void _sendEvent() {
    if (widget.event != null) {
      context.read<Analytics>().rawEvent(widget.event!);
    } else {
      context.read<Analytics>().event(
            name: widget.name!,
            data: widget.data,
            context: context,
          );
    }
  }
}

/// A widget that sends analytics when the widget is displayed, i.e., during impressions.
/// When using this widget, if you are adding this to each item in a list of items, it is recommended to set the [batchGenerator] for sending multiple analytics events with batch processing.
///
/// example:
///
/// ```dart
/// class AnalyticsHogehogePage extends StandardPage<void> {
///   @override
///   Widget buildPage(BuildContext context) {
///     return ListView.builder(
///       itemCount: 50,
///       itemBuilder: (context, index) {
///         return AnalyticsContextProvider(
///           analyticsContext: AnalyticsContext({
///             'section': 'Section $index',
///           }),
///           child: AnalyticsImpressionWidget(
///             visibleThreshold: 0.1,
///             name: 'Analytics Impression',
///             data: {
///               'name': 'Analytics Page Item $index',
///             },
///             batchToIgnore: const {'section'},
///             batchGenerator: (datas, contexts) {
///               return {
///                 'name': datas.map((e) => e['name']).join(','),
///                 'section':
///                     contexts.map((e) => e.resolve()['section']).join(','),
///               };
///             },
///             child: Text("Impression index : $index"),
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```
class AnalyticsImpressionWidget extends SingleChildStatefulWidget {
  /// The time to wait after displaying before sending
  final Duration durationThreshold;

  /// The value of what percentage of the child to be displayed before sending an event.
  final double? visibleThreshold;

  /// This is a function that can be set when you want to use your custom logic instead of 'visibleThreshold' to determine whether it should be sent.
  final bool Function(VisibilityInfo info)? thresholdCallback;

  /// The name of the analytics event.
  final String? name;

  /// Analytics data.
  final Map<String, Object?>? data;

  /// The event to be set for analytics.
  final AnalyticsEvent? event;

  /// Set to `true` to send events only once per lifecycle of this Widget, default is `false`.
  final bool once;

  /// This function is used to create batch data. When set, it sends impression information as a batch.
  final Map<String, Object?> Function(
          List<Map<String, Object?>> datas, List<AnalyticsContext> contexts)?
      batchGenerator;

  /// A list of names of analytics context keys to ignore in batch sending.
  final Set<String> batchDataToIgnore;

  /// Creates a AnalyticsImpressionWidget.
  const AnalyticsImpressionWidget({
    Key? key,
    required Widget child,
    this.name,
    this.data,
    this.event,
    this.durationThreshold = const Duration(
      seconds: 1,
    ),
    this.visibleThreshold,
    this.thresholdCallback,
    this.once = false,
    this.batchGenerator,
    this.batchDataToIgnore = const {},
  })  : assert(
            (event == null && name != null) || (name == null && event != null)),
        assert(data == null || event == null),
        assert(visibleThreshold != null || thresholdCallback != null),
        assert(!(event != null && batchGenerator != null)),
        super(
          key: key,
          child: child,
        );

  @override
  // ignore: library_private_types_in_public_api
  _AnalyticsImpressionWidgetState createState() =>
      _AnalyticsImpressionWidgetState();
}

class _AnalyticsImpressionWidgetState
    extends SingleChildState<AnalyticsImpressionWidget> {
  final _key = UniqueKey();
  bool _visible = false;
  bool _eventSent = false;
  Timer? _timer;
  Map<String, Object?>? _currentData;

  void _copyData() {
    _eventSent = false;
    _currentData =
        widget.data == null ? null : Map<String, Object?>.from(widget.data!);
  }

  @override
  void initState() {
    super.initState();
    _copyData();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    VisibilityDetectorController.instance.forget(_key);
  }

  @override
  void didUpdateWidget(covariant AnalyticsImpressionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ignore the data.
    if (widget.event != oldWidget.event || widget.name != oldWidget.name) {
      _copyData();
      _schedule();
    } else {
      notifyDataChanged();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: _onVisibilityChanged,
      child: child!,
    );
  }

  void notifyDataChanged() {
    if (_visible && !mapEquals(_currentData, widget.data)) {
      _copyData();
      _schedule();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (widget.visibleThreshold != null) {
      if (!_visible && info.visibleFraction >= widget.visibleThreshold!) {
        _visible = true;
        _schedule();
      } else if (_visible && info.visibleFraction < widget.visibleThreshold!) {
        _visible = false;
        _unschedule();
      }
    } else if (widget.thresholdCallback != null) {
      if (!_visible && widget.thresholdCallback!(info)) {
        _visible = true;
        _schedule();
      } else if (_visible && !widget.thresholdCallback!(info)) {
        _visible = false;
        _unschedule();
      }
    }
  }

  void _unschedule() {
    _timer?.cancel();
  }

  void _schedule() {
    if (!mounted || (widget.once && _eventSent)) {
      return;
    }

    _timer?.cancel();
    _timer = Timer(widget.durationThreshold, _sendEvent);
  }

  static final _batches = <int, _ImpressionBatch>{};
  static var _batchScheduled = false;

  int _batchHash(
    Analytics analytics,
    AnalyticsContext context,
    String name,
    Map<String, Object?> Function(
            List<Map<String, Object?>> datas, List<AnalyticsContext> contexts)
        generator,
  ) {
    final tAnalyticsContext = context.resolve()
      ..removeWhere((key, value) => widget.batchDataToIgnore.contains(key));

    return Object.hash(
        name, analytics, tAnalyticsContext.toString(), generator);
  }

  void _scheduleBatch() {
    if (_batchScheduled) {
      return;
    }

    _batchScheduled = true;
    scheduleFunction(_processBatch);
  }

  void _processBatch() {
    _batchScheduled = false;
    final tBatches = Map.of(_batches);
    _batches.clear();

    for (var i in tBatches.values) {
      // Force ignored data to null.
      final tData = widget.batchDataToIgnore.isNotEmpty
          ? {
              for (var i in widget.batchDataToIgnore) i: null,
              ...i.generator(i.datas, i.contexts),
            }
          : i.generator(i.datas, i.contexts);

      i.analytics.rawEvent(
        AnalyticsEvent(
          name: i.name,
          data: tData,
          context: i.contexts.first,
        ),
      );
    }
  }

  void _sendEvent() {
    _eventSent = true;
    final tAnalytics = context.read<Analytics>();

    if (widget.batchGenerator != null) {
      final tAnalyticsContext = context.read<AnalyticsContext>();

      _batches.putIfAbsent(
        _batchHash(tAnalytics, tAnalyticsContext, widget.name!,
            widget.batchGenerator!),
        () => _ImpressionBatch(
          widget.name!,
          tAnalytics,
          widget.batchGenerator!,
        ),
      )
        ..datas.add(widget.data ?? const {})
        ..contexts.add(tAnalyticsContext);
      _scheduleBatch();
    } else {
      if (widget.event != null) {
        tAnalytics.rawEvent(widget.event!);
      } else {
        tAnalytics.event(
          name: widget.name!,
          data: widget.data,
          context: context,
        );
      }
    }
  }
}

class _ImpressionBatch {
  final datas = <Map<String, Object?>>[];
  final contexts = <AnalyticsContext>[];
  final String name;
  final Analytics analytics;
  final Map<String, Object?> Function(
          List<Map<String, Object?>> datas, List<AnalyticsContext> contexts)
      generator;

  _ImpressionBatch(
    this.name,
    this.analytics,
    this.generator,
  );
}

/// A class representing the names of analytics events as strings.
class AnalyticsEventName {
  /// The name of the `routeView` event.
  static const String routeView = 'routeView';

  /// The name of the `revenue` event.
  static const String revenue = 'revenue';
}

/// A class representing the types of transitions as strings to be used as analytics data for page navigation.
class AnalyticsNavigationType {
  /// The string for the `push` navigation type.
  static const String push = 'push';

  /// The string for the `pop` navigation type.
  static const String pop = 'pop';

  /// The string for the `replace` navigation type.
  static const String replace = 'replace';

  /// The string for the `remove` navigation type.
  static const String remove = 'remove';
}

/// An extension to add [AnalyticsContext] functionality to [BuildContext].
extension AnalyticsTryGetContext on BuildContext {
  /// If [AnalyticsContext] can be retrieved from the widget tree, it returns that context.
  AnalyticsContext? maybeGetAnalyticsContext() {
    return Provider.of<AnalyticsContext?>(
      this,
      listen: false,
    );
  }
}

/// Class for RouteView analytics events.
class AnalyticsRouteViewEvent extends AnalyticsEvent {
  /// Flag indicating whether the route is the first (bottom most) route in the navigator's stack.
  /// For more details, refer to [Route.isFirst].
  bool get isFirst => data!['isFirst'] as bool;

  /// Arguments passed to this route.
  /// For more details, refer to [RouteSettings.arguments].
  String? get arguments => data!['arguments'] as String?;

  /// The name of this route.
  /// For more details, refer to [RouteSettings.name].
  String? get routeName => data!['routeName'] as String?;

  /// A string representing the navigation type [AnalyticsNavigationType] during page transitions.
  String get navigationType => data!['navigationType'] as String;

  /// Creates a AnalyticsRouteViewEvent
  AnalyticsRouteViewEvent({
    required Analytics analytics,
    required Route route,
    required String navigationType,
  }) : super(
          name: AnalyticsEventName.routeView,
          data: {
            'isFirst': route.isFirst,
            if (route.settings.arguments != null)
              'arguments': route.settings.arguments?.toString(),
            if (route.settings is StandardPageInterface) ...{
              'pageData': (route.settings as StandardPageInterface)
                          .standardPageKey
                          .currentState !=
                      null
                  ? (route.settings as StandardPageInterface)
                      .standardPageKey
                      .currentState!
                      .pageData
                  : route.settings.arguments,
              'pageLink': (route.settings as StandardPageInterface)
                          .standardPageKey
                          .currentState !=
                      null
                  ? (route.settings as StandardPageInterface)
                      .standardPageKey
                      .currentState!
                      .link
                  : (route.settings as StandardPageInterface)
                      .factoryObject
                      .generateLink(route.settings.arguments),
              ...Analytics.tryConvertToLoggableJsonParameters(
                  'pageDataJson',
                  (route.settings as StandardPageInterface)
                              .standardPageKey
                              .currentState !=
                          null
                      ? (route.settings as StandardPageInterface)
                          .standardPageKey
                          .currentState!
                          .pageData
                      : route.settings.arguments),
            },
            if (route.settings.name != null) 'routeName': route.settings.name,
            'navigationType': navigationType,
          },
          context: route.navigator?.context.maybeGetAnalyticsContext(),
        );
}

/// The necessary NavigatorObserver for the analytics system to monitor page navigation.
/// While this class is publicly accessible, it is not typically used directly by an application.
/// @nodoc
class AnalyticsNavigatorObserver extends NavigatorObserver {
  final Analytics _analytics;

  AnalyticsNavigatorObserver({
    required Analytics analytics,
  }) : _analytics = analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.isActive && route.isCurrent) {
      _logger.finer('AnalyticsNavigatorObserver:didPush');
      _analytics._globalRouteContext.clear();
      _analytics.routeViewEvent(
        route,
        navigationType: AnalyticsNavigationType.push,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) {
      return;
    }

    if (previousRoute.isActive && previousRoute.isCurrent) {
      _logger.finer('AnalyticsNavigatorObserver:didPop');
      _analytics._globalRouteContext.clear();
      _analytics.routeViewEvent(
        previousRoute,
        navigationType: AnalyticsNavigationType.pop,
      );
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) {
      return;
    }

    if (previousRoute.isActive && previousRoute.isCurrent) {
      _logger.finer('AnalyticsNavigatorObserver:didRemove');

      _analytics._globalRouteContext.clear();
      _analytics.routeViewEvent(
        previousRoute,
        navigationType: AnalyticsNavigationType.remove,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) {
      return;
    }

    _logger.finer('AnalyticsNavigatorObserver:didReplace');
    _analytics._globalRouteContext.clear();
    _analytics.routeViewEvent(
      newRoute,
      navigationType: AnalyticsNavigationType.replace,
    );
  }

  // coverage:ignore-start
  @override
  void didStartUserGesture(
      Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.finer('AnalyticsNavigatorObserver:didStartUserGesture');
  }
  // coverage:ignore-end

  // coverage:ignore-start
  @override
  void didStopUserGesture() {
    _logger.finer('AnalyticsNavigatorObserver:didStopUserGesture');
  }
  // coverage:ignore-end
}

/// Class for revenue-related analytics events.
class AnalyticsRevenueEvent extends AnalyticsEvent {
  /// Constants for data keys related to revenue.
  static const kDataKeyRevenue = 'revenue';

  /// Constants for data keys related to currency.
  static const kDataKeyCurrency = 'currency';

  /// Constants for data keys related to Order ID.
  static const kDataKeyOrderId = 'orderId';

  /// Constants for data keys related to receipt.
  static const kDataKeyReceipt = 'receipt';

  /// Constants for data keys related to product ID.
  static const kDataKeyProductId = 'productId';

  /// Constants for data keys related to product name.
  static const kDataKeyProductName = 'productName';

  /// Value of revenue.
  double get revenue => data![kDataKeyRevenue] as double;

  /// The name of the currency. This name is identified by the ISO 4217 currency code.
  /// For more details, refer to [ISO Web](https://www.iso.org/iso-4217-currency-codes.html).
  String? get currency => data![kDataKeyCurrency] as String?;

  /// Identifier for order.
  String? get orderId => data![kDataKeyOrderId] as String?;

  /// Receipt after purchasing a product.
  String? get receipt => data![kDataKeyReceipt] as String?;

  /// Identifier for products.
  String? get productId => data![kDataKeyProductId] as String?;

  /// Name of the product.
  String? get productName => data![kDataKeyProductName] as String?;

  /// Creates a AnalyticsRevenueEvent
  AnalyticsRevenueEvent({
    required double revenue,
    String? currency,
    String? orderId,
    String? receipt,
    String? productId,
    String? productName,
    String? eventName,
    Map<String, Object?>? data,
    super.context,
  }) : super(
          name: eventName ?? AnalyticsEventName.revenue,
          data: {
            kDataKeyRevenue: revenue,
            if (currency?.isNotEmpty == true) kDataKeyCurrency: currency,
            if (orderId?.isNotEmpty == true) kDataKeyOrderId: orderId,
            if (receipt?.isNotEmpty == true) kDataKeyReceipt: receipt,
            if (productId?.isNotEmpty == true) kDataKeyProductId: productId,
            if (productName?.isNotEmpty == true)
              kDataKeyProductName: productName,
          }..addAll(data ?? const {}),
        );
}
