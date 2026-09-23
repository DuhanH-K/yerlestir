import 'package:flutter/material.dart';

/// A complete menu that contracts only when the viewport cannot fit it.
class FitPage extends StatelessWidget {
  const FitPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(12),
  });
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: bounds.maxWidth,
          child: Padding(
            padding: padding,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    ),
  );
}

class FitViewport extends StatelessWidget {
  const FitViewport({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: bounds.maxWidth,
          height: bounds.maxHeight < 480 ? 480 : bounds.maxHeight,
          child: child,
        ),
      ),
    ),
  );
}
