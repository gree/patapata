// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:provider/provider.dart';

/// Application screen layout settings. Used in [ScreenLayout.breakpoints].
mixin ScreenLayoutEnvironment {
  /// Map of names and their configuration values for [ScreenLayoutBreakpoints].
  Map<String, ScreenLayoutBreakpoints> get screenLayoutBreakpoints;
}

/// A class representing breakpoints for screen layout. Breakpoints refer to the widths determined by the application's design.
/// You can set the breakpoints for portrait mode and landscape mode ([portraitStandardBreakpoint], [landscapeStandardBreakpoint]),
/// as well as width constraints for portrait mode and landscape mode ([portraitConstrainedWidth], [landscapeConstrainedWidth]).
/// Additionally, by setting [maxScale], you can limit the scale to prevent the RenderSize of child elements from exceeding it.
/// Pass these settings to [ScreenLayout.breakpoints].
///
/// example:
/// ```dart
/// ScreenLayout(
///   breakpoints: const ScreenLayoutBreakpoints(
///     portraitStandardBreakpoint: 375.0,
///     portraitConstrainedWidth: double.infinity,
///     landscapeStandardBreakpoint: 375.0,
///     landscapeConstrainedWidth: double.infinity,
///     maxScale: 1.2,
///   ),
///   child: HogehogeWidget(),
/// ),
/// ```
class ScreenLayoutBreakpoints {
  /// This function creates a breakpoint with the specified [name].
  /// You can specify the portrait breakpoint ([portraitStandardBreakpoint]) and its width constraint ([portraitConstrainedWidth]),
  /// as well as the landscape breakpoint ([landscapeStandardBreakpoint]) and its width constraint ([landscapeConstrainedWidth]).
  /// The [maxScale] is a value that limits the scale to ensure it does not exceed the RenderSize of the child element.
  const ScreenLayoutBreakpoints({
    this.name,
    required this.portraitStandardBreakpoint,
    required this.portraitConstrainedWidth,
    required this.landscapeStandardBreakpoint,
    required this.landscapeConstrainedWidth,
    required this.maxScale,
  });

  /// Name of the breakpoint
  final String? name;

  /// Value of the breakpoint in portrait mode
  final double portraitStandardBreakpoint;

  /// Value of the width constraint in portrait mode
  final double portraitConstrainedWidth;

  /// Value of the breakpoint in landscape mode
  final double landscapeStandardBreakpoint;

  /// Value of the width constraint in landscape mode
  final double landscapeConstrainedWidth;

  /// Value to limit the scale to prevent the RenderSize of child elements from exceeding it
  final double maxScale;

  /// Partially modifies the properties of the existing [ScreenLayoutBreakpoints].
  /// If a property is not specified, the existing value will be used.
  ScreenLayoutBreakpoints copyWith({
    String? name,
    double? portraitStandardBreakpoint,
    double? portraitConstrainedWidth,
    double? landscapeStandardBreakpoint,
    double? landscapeConstrainedWidth,
    double? maxScale,
  }) {
    return ScreenLayoutBreakpoints(
      name: name ?? this.name,
      portraitStandardBreakpoint:
          portraitStandardBreakpoint ?? this.portraitStandardBreakpoint,
      portraitConstrainedWidth:
          portraitConstrainedWidth ?? this.portraitConstrainedWidth,
      landscapeStandardBreakpoint:
          landscapeStandardBreakpoint ?? this.landscapeStandardBreakpoint,
      landscapeConstrainedWidth:
          landscapeConstrainedWidth ?? this.landscapeConstrainedWidth,
      maxScale: maxScale ?? this.maxScale,
    );
  }

  @override
  operator ==(Object other) => other is ScreenLayoutBreakpoints
      ? name == other.name &&
          portraitStandardBreakpoint == other.portraitStandardBreakpoint &&
          portraitConstrainedWidth == other.portraitConstrainedWidth &&
          landscapeStandardBreakpoint == other.landscapeStandardBreakpoint &&
          landscapeConstrainedWidth == other.landscapeConstrainedWidth &&
          maxScale == other.maxScale
      : false;

  @override
  int get hashCode => Object.hash(
        name,
        portraitStandardBreakpoint,
        portraitConstrainedWidth,
        landscapeStandardBreakpoint,
        landscapeConstrainedWidth,
        maxScale,
      );
}

/// A class that defines default screen layout breakpoints.
class ScreenLayoutDefaultBreakpoints {
  /// A default breakpoint named 'normal'.
  /// The breakpoint values for [ScreenLayoutBreakpoints.portraitStandardBreakpoint] and [ScreenLayoutBreakpoints.landscapeStandardBreakpoint] are `375.0`.
  /// The constrained width values for [ScreenLayoutBreakpoints.portraitConstrainedWidth] and [ScreenLayoutBreakpoints.landscapeConstrainedWidth] are `482.0`.
  /// The maximum scale value for [ScreenLayoutBreakpoints.maxScale] is `1.2`.
  static const normal = ScreenLayoutBreakpoints(
    name: 'normal',
    portraitStandardBreakpoint: 375.0,
    portraitConstrainedWidth: 16.0 + 450.0 + 16.0,
    landscapeStandardBreakpoint: 375.0,
    landscapeConstrainedWidth: 16.0 + 450.0 + 16.0,
    maxScale: 1.2,
  );

  /// A default breakpoint named 'large'.
  /// The breakpoint values for [ScreenLayoutBreakpoints.portraitStandardBreakpoint] and [ScreenLayoutBreakpoints.landscapeStandardBreakpoint] are `812.0`.
  /// The constrained width values for [ScreenLayoutBreakpoints.portraitConstrainedWidth] and [ScreenLayoutBreakpoints.landscapeConstrainedWidth] are `1006.4`.
  /// The maximum scale value for [ScreenLayoutBreakpoints.maxScale] is `1.2`.
  static const large = ScreenLayoutBreakpoints(
    name: 'large',
    portraitStandardBreakpoint: 812.0,
    portraitConstrainedWidth: 16.0 + 974.4 + 16.0,
    landscapeStandardBreakpoint: 812.0,
    landscapeConstrainedWidth: 16.0 + 974.4 + 16.0,
    maxScale: 1.2,
  );

  /// The Map of default screen layout breakpoints.
  static Map<String, ScreenLayoutBreakpoints> toMap() {
    return {
      'normal': normal,
      'large': large,
    };
  }
}

/// A widget that will layout [child] at the given size in [breakpoints].
/// [ScreenLayoutBreakpoints.portraitStandardBreakpoint] while in portrait mode, or
/// [ScreenLayoutBreakpoints.landscapeStandardBreakpoint] while in landscape mode.
/// After laying out at that size, [ScreenLayout] will scale the [child] so as to fix the current screen size,
/// up to a maximum scale ratio of [maxScale], or [ScreenLayoutBreakpoints.portraitConstrainedWidth] while in portrait mode,
/// or [ScreenLayoutBreakpoints.landscapeConstrainedWidth] while in landscape mode.
///
/// This is useful for when you have a design where the base design is created with a given width,
/// and all UI elements are meant to be shown exactly as the design shows relative to the current device's screen size.
/// In other words, this widget will implement a non-responsive UI that automatically scales children up or down to match the current screen size.
/// It is usually a bad design practice to scale up to fullscreen on devices like a tablet or PC, and you can control the maximum things will scale by using the above-mentioned settings to avoid that and show a more reasonable UI design.
///
/// example:
/// ```dart
/// ScreenLayout(
///   breakpoints: const ScreenLayoutBreakpoints(
///     portraitStandardBreakpoint: 375.0,
///     portraitConstrainedWidth: double.infinity,
///     landscapeStandardBreakpoint: 375.0,
///     landscapeConstrainedWidth: double.infinity,
///     maxScale: 1.2,
///   ),
///   child: HogehogeWidget(),
/// ),
/// ```
class ScreenLayout extends SingleChildRenderObjectWidget {
  /// Creates a [ScreenLayout] with the name [name] that adjusts the size of the widget specified in [child] based on the configuration in [breakpoints].
  const ScreenLayout({
    super.key,
    super.child,
    this.breakpoints,
    this.name,
  });

  /// Creates a [ScreenLayout] with the name [name] that adjusts the size of the widget specified in [child].
  factory ScreenLayout.named({
    Key? key,
    Widget? child,
    required String name,
  }) {
    return ScreenLayout(
      key: key,
      name: name,
      child: child,
    );
  }

  /// Breakpoints for adjusting the size of the widget.
  final ScreenLayoutBreakpoints? breakpoints;

  /// Name of the [ScreenLayout] widget.
  final String? name;

  ScreenLayoutBreakpoints _getTargetBreakpoints(BuildContext context) {
    ScreenLayoutBreakpoints? tBreakpoints = breakpoints;
    if (tBreakpoints == null && name != null) {
      final tEnvironment = context.read<App>().environment;
      if (tEnvironment is ScreenLayoutEnvironment) {
        // It is assumed that defaults will be overridden.
        final tBreakpointsMap = <String, ScreenLayoutBreakpoints>{
          ...ScreenLayoutDefaultBreakpoints.toMap(),
          ...tEnvironment.screenLayoutBreakpoints,
        };
        tBreakpoints = tBreakpointsMap[name];
      }
    }

    return tBreakpoints ?? ScreenLayoutDefaultBreakpoints.normal;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ScreenLayoutRenderObject(
      breakpoints: _getTargetBreakpoints(context),
      orientation: MediaQuery.of(context).orientation,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    covariant _ScreenLayoutRenderObject renderObject,
  ) {
    renderObject.breakpoints = _getTargetBreakpoints(context);
    renderObject.orientation = MediaQuery.of(context).orientation;
  }
}

class _ScreenLayoutRenderObject extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  Orientation _orientation;
  set orientation(Orientation value) {
    if (_orientation != value) {
      _orientation = value;
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  ScreenLayoutBreakpoints _breakpoints;
  set breakpoints(ScreenLayoutBreakpoints value) {
    if (_breakpoints != value) {
      _breakpoints = value;
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  late Matrix4 _transform;
  late double _scale;

  _ScreenLayoutRenderObject({
    required ScreenLayoutBreakpoints breakpoints,
    required Orientation orientation,
  })  : _breakpoints = breakpoints,
        _orientation = orientation;

  double get standardBreakpoint {
    switch (_orientation) {
      case Orientation.portrait:
        return _breakpoints.portraitStandardBreakpoint;
      case Orientation.landscape:
        return _breakpoints.landscapeStandardBreakpoint;
    }
  }

  double get constrainedWidth {
    switch (_orientation) {
      case Orientation.portrait:
        return _breakpoints.portraitConstrainedWidth;
      case Orientation.landscape:
        return _breakpoints.landscapeConstrainedWidth;
    }
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => false;

  @override
  void performLayout() {
    final tChild = child;
    final tWidth = constraints
        .enforce(BoxConstraints.loose(Size(constrainedWidth, double.infinity)))
        .constrainWidth();

    if (tWidth.isInfinite || tWidth == 0) {
      _transform = Matrix4.identity();
      _scale = 1.0;
    } else {
      _scale = min(_breakpoints.maxScale, tWidth / standardBreakpoint);
      _transform = Matrix4.identity()..scale(_scale, _scale, _scale);
    }

    if (tChild != null) {
      tChild.layout(
        BoxConstraints(
          minWidth: constrainedWidth.isInfinite
              ? constraints.minWidth / _scale
              : standardBreakpoint,
          maxWidth: constrainedWidth.isInfinite
              ? constraints.maxWidth / _scale
              : standardBreakpoint,
          minHeight: constraints.minHeight / _scale,
          maxHeight: constraints.maxHeight / _scale,
        ),
        parentUsesSize: true,
      );
    }

    if (tChild is RenderBox) {
      size = constraints.constrain(Size(tWidth, tChild.size.height * _scale));
      _transform.translate(
        (tWidth - tChild.size.width * _scale) / 2,
        (size.height - tChild.size.height * _scale) / 2,
      );
    } else {
      // coverage:ignore-start
      size = constraints.constrain(Size(tWidth, 0));
      // coverage:ignore-end
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) {
      return false;
    }

    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        final tChild = child;

        if (tChild is RenderBox) {
          return tChild.hitTest(result, position: position);
        }

        return false;
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    Offset? tChildOffset = MatrixUtils.getAsTranslation(_transform);

    if (tChildOffset == null) {
      // if the matrix is singular the children would be compressed to a line or
      // single point, instead short-circuit and paint nothing.
      final double tDet = _transform.determinant();
      // coverage:ignore-start
      if (tDet == 0 || !tDet.isFinite) {
        layer = null;
        return;
      }
      // coverage:ignore-end

      layer = context.pushTransform(
        needsCompositing,
        offset,
        _transform,
        (context, offset) {
          context.paintChild(child!, offset);
        },
        oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
      );
    } else {
      context.paintChild(child!, offset + tChildOffset);
      layer = null;
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

/// A widget that disables the screen layout of the child widget [child].
class ScreenLayoutDisable extends SingleChildRenderObjectWidget {
  /// Create a [ScreenLayoutDisable]
  /// [child] is the widget for which the screen layout is to be disabled.
  const ScreenLayoutDisable({
    super.key,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ScreenLayoutDisableRenderObject();
}

class _ScreenLayoutDisableRenderObject extends RenderBox
    with RenderObjectWithChildMixin {
  late Matrix4 _transform;
  late double _scale;

  _ScreenLayoutDisableRenderObject();

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => false;

  @override
  void performLayout() {
    double tParentScale = 1.0;
    RenderObject? tNode = parent;

    while (tNode != null) {
      if (tNode is _ScreenLayoutRenderObject) {
        tParentScale /= tNode._scale;
        break;
      }

      tNode = tNode.parent;
    }

    final tChild = child;
    _scale = tParentScale;
    _transform = Matrix4.identity()..scale(_scale, _scale, _scale);

    if (tChild != null) {
      tChild.layout(
        BoxConstraints(
          minWidth: constraints.minWidth / _scale,
          maxWidth: constraints.maxWidth / _scale,
          minHeight: constraints.minHeight / _scale,
          maxHeight: constraints.maxHeight / _scale,
        ),
        parentUsesSize: true,
      );
    }

    if (tChild is RenderBox) {
      size = constraints.constrain(
          Size(tChild.size.width * _scale, tChild.size.height * _scale));
      _transform.translate(
        (size.width - tChild.size.width * _scale) / 2,
        (size.height - tChild.size.height * _scale) / 2,
      );
    } else {
      // coverage:ignore-start
      size = const Size(0, 0);
      // coverage:ignore-end
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) {
      return false;
    }

    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        final tChild = child;

        if (tChild is RenderBox) {
          return tChild.hitTest(result, position: position);
        }

        return false;
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final Offset? tChildOffset = MatrixUtils.getAsTranslation(_transform);

    if (tChildOffset == null) {
      // if the matrix is singular the children would be compressed to a line or
      // single point, instead short-circuit and paint nothing.
      final double tDet = _transform.determinant();
      // coverage:ignore-start
      if (tDet == 0 || !tDet.isFinite) {
        layer = null;
        return;
      }
      // coverage:ignore-end

      layer = context.pushTransform(
        needsCompositing,
        offset,
        _transform,
        (context, offset) {
          context.paintChild(child!, offset);
        },
        oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
      );
    } else {
      context.paintChild(child!, offset + tChildOffset);
      layer = null;
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

/// An extension class that adds the screen layout scaling functionality to [BuildContext].
extension ScreenLayoutContext on BuildContext {
  /// The scale value of the screen layout.
  double get screenLayoutScale {
    double tScale = 1.0;

    visitAncestorElements((element) {
      final tRenderObject = element.renderObject;

      if (tRenderObject is _ScreenLayoutRenderObject) {
        tScale = tRenderObject._scale;
        return false;
      } else if (tRenderObject is _ScreenLayoutDisableRenderObject) {
        return false;
      }

      return true;
    });

    return tScale;
  }
}
