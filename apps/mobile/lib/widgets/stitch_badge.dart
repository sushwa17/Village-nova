import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';

enum StitchBadgeVariant {
  verified,
  urgent,
  panchayat,
  agriculture,
  health,
  warning,
  neutral,
  mandi,
  scheme,
}

/// Google Stitch Pill Badge
/// Compact, high-contrast tag for categories, verification status, and alerts.
class StitchBadge extends StatelessWidget {
  final String label;
  final String? icon;
  final StitchBadgeVariant variant;

  const StitchBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = StitchBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (variant) {
      case StitchBadgeVariant.verified:
        bg = StitchTokens.green100;
        border = StitchTokens.green300;
        text = StitchTokens.green800;
        break;
      case StitchBadgeVariant.urgent:
        bg = StitchTokens.rose100;
        border = StitchTokens.rose200;
        text = StitchTokens.rose700;
        break;
      case StitchBadgeVariant.panchayat:
        bg = StitchTokens.sky100;
        border = StitchTokens.sky200;
        text = StitchTokens.sky800;
        break;
      case StitchBadgeVariant.agriculture:
        bg = StitchTokens.green50;
        border = StitchTokens.green200;
        text = StitchTokens.green900;
        break;
      case StitchBadgeVariant.health:
        bg = StitchTokens.rose50;
        border = StitchTokens.rose200;
        text = StitchTokens.rose900;
        break;
      case StitchBadgeVariant.warning:
        bg = StitchTokens.gold100;
        border = StitchTokens.gold300;
        text = StitchTokens.gold900;
        break;
      case StitchBadgeVariant.mandi:
        bg = StitchTokens.green50;
        border = StitchTokens.green300;
        text = StitchTokens.green800;
        break;
      case StitchBadgeVariant.scheme:
        bg = StitchTokens.gold50;
        border = StitchTokens.gold200;
        text = StitchTokens.gold800;
        break;
      case StitchBadgeVariant.neutral:
      default:
        bg = StitchTokens.slate100;
        border = StitchTokens.slate200;
        text = StitchTokens.slate700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StitchTokens.radiusFull),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 10.5)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: StitchTokens.badge.copyWith(color: text),
          ),
        ],
      ),
    );
  }
}
