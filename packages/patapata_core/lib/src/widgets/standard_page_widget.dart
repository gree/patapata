// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of "standard_app.dart";

/// A back button specified at the top of the AppBar of a child page,
/// which includes multiple navigators, in both Material and Cupertino Design.
///
class StandardPageBackButton extends StatelessWidget {
  const StandardPageBackButton({
    super.key,
    this.color,
    this.previousPageTitle,
    this.onPressed,
  });

  /// The color to be used for the icon.
  /// See [BackButton.color] of [BackButton] for more details.
  final Color? color;

  /// The previousPageTitle to be used for the title.
  /// See [CupertinoNavigationBarBackButton.previousPageTitle] of [CupertinoNavigationBarBackButton] for more details.
  /// Defaults to [CupertinoTheme]'s `primaryColor` if null.
  final String? previousPageTitle;

  /// A callback that can be optionally defined and called by the user before popping when the button is tapped.
  final VoidCallback? onPressed;

  void _findClosestNavigatorStateCanPop(BuildContext context) {
    // Find closest NavigatorState and pop if canPop
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is NavigatorState) {
        NavigatorState tNavigatorState = element.state as NavigatorState;
        if (tNavigatorState.canPop()) {
          tNavigatorState.pop();
          return false;
        } else if (element.widget.key == _childNavigatorKey) {
          // Delete the page that exists in pageChildInstances if it could not be popped
          final tPage = element.pageInstances.last;
          element.pageChildInstances[tPage]!.clear();
        }
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final StandardAppType tType = context.watch<StandardAppType>();

    if (tType == StandardAppType.material) {
      assert(debugCheckHasMaterialLocalizations(context));
      return IconButton(
        icon: const BackButtonIcon(),
        color: color,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          onPressed?.call();
          _findClosestNavigatorStateCanPop(context);
        },
      );
    } else if (tType == StandardAppType.cupertino) {
      assert(debugCheckHasCupertinoLocalizations(context));
      return CupertinoNavigationBarBackButton(
        color: color,
        previousPageTitle: previousPageTitle,
        onPressed: () {
          onPressed?.call();
          _findClosestNavigatorStateCanPop(context);
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
