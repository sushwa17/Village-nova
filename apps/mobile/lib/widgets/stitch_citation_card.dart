import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';
import 'package:villagenova/widgets/stitch_badge.dart';

/// Google Stitch Citation Card
/// Renders verified official agricultural university, government gazette,
/// or mandi market authority citations with external verification links.
class StitchCitationCard extends StatelessWidget {
  final String title;
  final String sourceType;
  final String timestamp;
  final String? url;
  final VoidCallback? onTap;

  const StitchCitationCard({
    super.key,
    required this.title,
    required this.sourceType,
    required this.timestamp,
    this.url,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: StitchTokens.slate50,
        borderRadius: BorderRadius.circular(StitchTokens.radiusSm),
        border: Border.all(color: StitchTokens.slate200, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 16,
            color: StitchTokens.green700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StitchTokens.bodyMedium.copyWith(fontSize: 12.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$sourceType • $timestamp',
                  style: StitchTokens.caption.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const StitchBadge(
            label: 'Verified ✓',
            variant: StitchBadgeVariant.verified,
          ),
          if (url != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 14, color: StitchTokens.slate600),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onTap,
            ),
          ],
        ],
      ),
    );
  }
}
