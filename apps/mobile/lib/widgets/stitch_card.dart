import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';

enum StitchCardVariant {
  surface,
  green,
  gold,
  sky,
  alert,
  subtle,
}

/// Google Stitch Card Component
/// Standard tactile surface container used across Home, My Farm, My Village, and Ask AI.
class StitchCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final StitchCardVariant variant;
  final bool hasShadow;

  const StitchCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.variant = StitchCardVariant.surface,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;

    switch (variant) {
      case StitchCardVariant.green:
        bg = StitchTokens.green50;
        border = StitchTokens.green200;
        break;
      case StitchCardVariant.gold:
        bg = StitchTokens.gold50;
        border = StitchTokens.gold200;
        break;
      case StitchCardVariant.sky:
        bg = StitchTokens.sky50;
        border = StitchTokens.sky200;
        break;
      case StitchCardVariant.alert:
        bg = StitchTokens.rose50;
        border = StitchTokens.rose200;
        break;
      case StitchCardVariant.subtle:
        bg = StitchTokens.slate50;
        border = StitchTokens.slate200;
        break;
      case StitchCardVariant.surface:
      default:
        bg = Colors.white;
        border = StitchTokens.slate200;
    }

    final radius = borderRadius ?? StitchTokens.radiusLg;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? border,
          width: 1.2,
        ),
        boxShadow: hasShadow ? StitchTokens.shadowSm : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
