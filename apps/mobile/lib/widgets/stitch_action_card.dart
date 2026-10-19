import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';
import 'package:villagenova/widgets/stitch_badge.dart';

/// Google Stitch Action Card
/// Tactile card component representing an actionable recommendation,
/// task trigger, or direct action button in Ask VillageNova and My Farm.
class StitchActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? icon;
  final String? badgeLabel;
  final StitchBadgeVariant badgeVariant;
  final VoidCallback? onTap;
  final bool isCompleted;

  const StitchActionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.badgeLabel,
    this.badgeVariant = StitchBadgeVariant.neutral,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isCompleted ? StitchTokens.slate50 : Colors.white,
        borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
        border: Border.all(
          color: isCompleted ? StitchTokens.slate200 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: isCompleted ? null : StitchTokens.shadow2xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted ? StitchTokens.slate200 : StitchTokens.slate100,
                      borderRadius: BorderRadius.circular(StitchTokens.radiusSm),
                      border: Border.all(color: StitchTokens.slate200),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      icon!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: StitchTokens.bodyMedium.copyWith(
                          fontSize: 13.5,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? StitchTokens.slate400 : StitchTokens.slate900,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: StitchTokens.caption.copyWith(
                            color: isCompleted ? StitchTokens.slate400 : StitchTokens.slate600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (badgeLabel != null) ...[
                  StitchBadge(
                    label: badgeLabel!,
                    variant: badgeVariant,
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: isCompleted ? 18 : 12,
                  color: isCompleted ? StitchTokens.green600 : StitchTokens.green700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
