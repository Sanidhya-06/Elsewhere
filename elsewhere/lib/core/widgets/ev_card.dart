import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A quiet, lightly bordered surface. Cards are integrated into the page
/// (border and tone, no heavy shadow), per the design spec.
class EvCard extends StatelessWidget {
  const EvCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = EvColors.white,
    this.borderColor = EvColors.border,
    this.padding = const EdgeInsets.all(EvSpace.cardPad),
    this.radius = EvRadius.card,
    this.semanticLabel,
  });

  /// A warm neutral surface, used for summaries (e.g. expense totals).
  const EvCard.warm({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(EvSpace.s20),
    this.radius = EvRadius.card,
    this.semanticLabel,
  })  : color = EvColors.sand,
        borderColor = EvColors.sand;

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        customBorder: shape,
        child: content,
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
