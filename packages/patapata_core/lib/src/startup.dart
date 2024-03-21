// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/src/exception.dart';

final _logger = Logger('StartupSequence');

/// A factory for states used in the [StartupSequence] system.
class StartupStateFactory<T extends StartupState> {
  /// Creates a [StartupState].
  /// [startupSequence] is the [StartupSequence] that generated this state.
  final T Function(StartupSequence startupSequence) create;
  final List<LogicStateTransition<StartupState>> _transitions;

  const StartupStateFactory(
    this.create,
    List<LogicStateTransition<StartupState>> transitions,
  ) : _transitions = transitions;

  LogicStateFactory<T> _toLogicStateFactory(StartupSequence startupSequence) {
    return LogicStateFactory<T>(
      () => create(startupSequence)..onComplete.ignore(),
      _transitions,
    );
  }
}

typedef StartupPageCompleter = void Function(Object? result);

/// [LogicState] executed in [StartupSequence].
abstract class StartupState extends LogicState {
  StartupState(this.startupSequence);

  /// The [StartupSequence] that executed this state.
  final StartupSequence startupSequence;

  Completer<bool>? _navigateCompleter;

  /// Navigate to page.
  ///
  /// When using [StandardAppPlugin], navigation to the page defined in
  /// [StandardMaterialApp.pages] or [StandardCupertinoApp.pages]
  /// can be achieved by passing the page's [Type].
  /// If you want custom navigation, implement a [Plugin] that overrides
  /// [StartupNavigatorMixin.startupNavigateToPage].
  ///
  /// Please pass [completer] to every page navigated to using this method.
  /// When using [StandardAppPlugin], this would be [StandardPage.pageData].
  ///
  /// By calling [completer] within the page, the internal processes are executed
  /// and the [Future] of this method returns true.
  /// If another state switches without calling [completer],
  /// the [Future] returns false.
  Future<bool> navigateToPage(
      Object page, StartupPageCompleter completer) async {
    final tPlugin = startupSequence._startupNavigator;
    assert(tPlugin != null);

    await startupSequence.waitForSplash();

    if (!this()) {
      throw LogicStateNotCurrent(this);
    }
    assert(
        _navigateCompleter == null || _navigateCompleter?.isCompleted == true);
    final tCompleter = Completer<bool>();
    _navigateCompleter = tCompleter;

    backAllowed = true;
    tPlugin?.startupNavigateToPage(page, (result) {
      if (tCompleter.isCompleted) {
        return;
      }

      tCompleter.complete(true);
      completer(result);
    });

    return tCompleter.future;
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_navigateCompleter?.isCompleted == false) {
      _navigateCompleter!.complete(false);
    }
    super.dispose();
  }

  @override
  @mustCallSuper
  void init(Object? data) {
    super.init(data);

    Timer.run(() {
      process(data).then<void>((_) {
        if (this()) {
          complete();
        }
      }).catchError((e, stackTrace) {
        return startupSequence.waitForSplash().whenComplete(() async {
          if (this()) {
            completeError(e, stackTrace);
          }
        });
      });
    });
  }

  /// The process to be executed in the state.
  /// When the Future of this method completes, it transitions to the next state.
  ///
  /// If defined in [LogicStateTransition], you can transition to another state using [to].
  /// In that case, this method does nothing even after completion.
  Future<void> process(Object? data);
}

/// Manages the series of processes from app launch to the display of
/// the initial screen using [LogicStateMachine].
/// When executing [StartupSequence.resetMachine], it starts execution from
/// the first state provided in the [StartupStateFactory] list.
///
/// When all states succeed, [StartupSequence] calls [StartupNavigatorMixin.startupProcessInitialRoute].
/// When using [StandardAppPlugin], this is synonymous with calling
/// [StandardRouterDelegate.processInitialRoute]. In other words,
/// If a deep link was used to start the app, that deep link's page will be displayed.
/// If no deep link was used, the route with a link of nothing (`r''`) will be navigated to.
///
/// If the app is rendering widgets using the [StandardAppPlugin] system,
/// [StartupSequence.resetMachine] is automatically executed only once when the app is launched.
///
/// [startupStateFactories] specifies the states to be executed sequentially.
/// This is the same as [LogicState] in [LogicStateMachine].
///
/// [waitSplashScreenDuration] specifies the waiting time for the splash screen.
/// [StartupState.navigateToPage] or [StartupNavigatorMixin.startupProcessInitialRoute]
/// will be executed after waiting for this duration to elapse.
/// Also, [removeNativeSplashScreen] is called once this time has passed.
/// (default is 1 second)
class StartupSequence {
  StartupSequence({
    required List<StartupStateFactory> startupStateFactories,
    Duration? waitSplashScreenDuration,
    this.onSuccess,
    this.onError,
  })  : _startupStateFactories = startupStateFactories,
        _waitSplashScreenDuration =
            waitSplashScreenDuration ?? const Duration(milliseconds: 1000);

  LogicStateMachine? _machine;
  final List<StartupStateFactory> _startupStateFactories;

  /// Called when all sequence processing is completed.
  final void Function()? onSuccess;

  /// Called when an error occurs during the sequence.
  /// If null, it will call [Logger.severe] instead.
  final void Function(Object error, StackTrace? stackTrace)? onError;

  /// The details of the error that occurred during execution.
  LogicStateError? get error => _error;
  LogicStateError? _error;

  /// Whether the sequence has completed, successfully or due to an error.
  bool get complete => _startupCompleted;
  Completer<void>? _startupCompleter;
  bool _startupCompleted = false;

  final Duration _waitSplashScreenDuration;
  Timer? _waitSplashScreenTimer;
  Completer<void>? _splashScreenCompleter;
  bool _splashFinished = false;

  /// Whether the time specified by [waitSplashScreenDuration] has elapsed.
  bool get splashFinished => _splashFinished;

  StartupNavigatorMixin? get _startupNavigator =>
      getApp().getPluginsOfType<StartupNavigatorMixin>().reversed.firstOrNull;

  List<LogicStateFactory> _createLogicStateFactories() {
    return [
      for (final factory in _startupStateFactories)
        factory._toLogicStateFactory(this)
    ];
  }

  /// Starts the sequence processing.
  /// If called again, it restarts from the beginning.
  ///
  /// When using [StandardAppPlugin], upon restart,
  /// navigation will be directed to the first page in
  /// [StandardMaterialApp.pages] or [StandardCupertinoApp.pages].
  /// To customize this behavior, implement a [Plugin] that overrides
  /// [StartupNavigatorMixin.startupOnReset].
  void resetMachine() {
    final tIsFirstRun = !(_machine != null || complete);
    if (_waitSplashScreenTimer?.isActive == true) {
      _waitSplashScreenTimer?.cancel();
    }

    _waitSplashScreenTimer = Timer(_waitSplashScreenDuration, () {
      getApp().removeNativeSplashScreen().whenComplete(() {
        _splashFinished = true;
        _splashScreenCompleter?.complete();
        _waitSplashScreenTimer = null;
      });
    });

    final tPreMachine = _machine;
    _machine?.removeListener(_onUpdate);
    _error = null;
    _splashFinished = false;
    _startupCompleted = false;
    _machine = LogicStateMachine(_createLogicStateFactories())
      ..addListener(_onUpdate);

    if (!tIsFirstRun) {
      if (tPreMachine?.complete == false) {
        tPreMachine?.current.completeError(const ResetStartupSequence());
      }
      _startupNavigator?.startupOnReset();
    }
  }

  /// Waits until the time specified by [waitSplashScreenDuration] has elapsed.
  Future<void> waitForSplash() {
    if (splashFinished) {
      return SynchronousFuture(null);
    }
    if (_splashScreenCompleter == null ||
        _splashScreenCompleter?.isCompleted == true) {
      _splashScreenCompleter = Completer<void>();
    }
    return _splashScreenCompleter!.future;
  }

  /// Waits until the process is completed.
  Future<void> waitForComplete() {
    if (complete) {
      if (error != null) {
        if (error?.stackTrace != null) {
          throw Error.throwWithStackTrace(error!.error, error!.stackTrace!);
        }
        throw error!.error;
      }
      return SynchronousFuture(null);
    }
    if (_startupCompleter == null || _startupCompleter?.isCompleted == true) {
      _startupCompleter = Completer<void>();
    }
    return _startupCompleter!.future;
  }

  void _onUpdate() {
    _logger.info(_machine!);

    final tMachine = _machine;

    if (tMachine != null && tMachine.complete) {
      tMachine.removeListener(_onUpdate);

      waitForSplash().whenComplete(() {
        if (tMachine.hashCode != _machine?.hashCode) {
          return;
        }
        final tError = tMachine.error;
        _error = tError;
        _machine = null;
        _startupCompleted = true;
        if (tError != null) {
          _startupCompleter?.completeError(tError.error, tError.stackTrace);

          if (onError != null) {
            onError?.call(tError.error, tError.stackTrace);
          } else {
            _logger.severe(
                tError.error.toString(), tError.error, tError.stackTrace);
          }
        } else {
          _startupCompleter?.complete();

          _startupNavigator?.startupProcessInitialRoute();
          onSuccess?.call();
        }
      });
    }
  }
}

/// Implements page navigation during [StartupSequence] processing.
/// If you are performing page navigation outside of the [StandardAppPlugin] system,
/// implement a [Plugin] that uses this with a mixin.
mixin StartupNavigatorMixin {
  /// Called from [StartupState.navigateToPage]. Implements page navigation.
  void startupNavigateToPage(Object page, StartupPageCompleter completer) =>
      () {}; // coverage:ignore-line

  /// Called when all the processes of [StartupSequence] have successfully completed.
  /// Implements the navigation process to the application home.
  void startupProcessInitialRoute() => () {};

  /// Called when [StartupSequence.resetMachine] is invoked during the processing of [StartupSequence].
  void startupOnReset() => () {};
}

class StartupNavigatorObserver extends NavigatorObserver {
  final StartupSequence _startupSequence;
  final Map<Route, Type> _routeHashStateMap = {};

  StartupNavigatorObserver({
    required StartupSequence startupSequence,
  }) : _startupSequence = startupSequence;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_startupSequence.complete || _startupSequence._machine == null) {
      if (_routeHashStateMap.isNotEmpty) {
        _routeHashStateMap.clear();
      }
      return;
    }

    if (route.isActive && route.isCurrent) {
      _routeHashStateMap[route] =
          _startupSequence._machine!.current.runtimeType;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_startupSequence.complete || _startupSequence._machine == null) {
      return;
    }
    if (previousRoute == null) {
      return;
    }

    if (previousRoute.isActive && previousRoute.isCurrent) {
      final tBackState = _routeHashStateMap[previousRoute];
      if (tBackState != null &&
          tBackState != _startupSequence._machine?.current.runtimeType) {
        _startupSequence._machine!.current.backByType(tBackState);
      }
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_startupSequence.complete || _startupSequence._machine == null) {
      return;
    }

    if (previousRoute == null) {
      return;
    }

    if (previousRoute.isActive && previousRoute.isCurrent) {
      final tBackState = _routeHashStateMap[previousRoute];
      if (tBackState != null &&
          tBackState != _startupSequence._machine?.current.runtimeType) {
        _startupSequence._machine!.current.backByType(tBackState);
      }
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_startupSequence.complete || _startupSequence._machine == null) {
      return;
    }
    if (newRoute == null) {
      return;
    }

    if (newRoute.isActive && newRoute.isCurrent) {
      _routeHashStateMap[newRoute] =
          _startupSequence._machine!.current.runtimeType;
    }
  }
}

/// Thrown when [StartupSequence.resetMachine] is called while [StartupSequence] is already running.
class ResetStartupSequence extends PatapataCoreException {
  const ResetStartupSequence() : super(code: PatapataCoreExceptionCode.PPE301);
}
