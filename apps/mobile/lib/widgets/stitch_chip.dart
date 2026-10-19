import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';

/// Google Stitch Selectable Chip
/// Filter and selector chip with smooth state transitions and accessible touch sizes.
class StitchSelectableChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onSelected;

  const StitchSelectableChip({
    super.key,
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? StitchTokens.green100 : Colors.white,
          borderRadius: BorderRadius.circular(StitchTokens.radiusSm),
          border: Border.all(
            color: isSelected ? StitchTokens.green600 : StitchTokens.slate200,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected ? StitchTokens.shadowSm : StitchTokens.shadow2xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? StitchTokens.green900 : StitchTokens.slate800,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: StitchTokens.green600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
