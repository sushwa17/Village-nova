import 'package:flutter/material.dart';
import 'package:villagenova/core/theme/stitch_tokens.dart';

enum StitchButtonVariant {
  primary,
  secondary,
  gold,
  alert,
}

/// Google Stitch Button Component
/// Accessible, high-contrast action button adhering to Google Stitch specifications.
class StitchButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final StitchButtonVariant variant;
  final IconData? icon;
  final double height;

  const StitchButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.variant = StitchButtonVariant.primary,
    this.icon,
    this.height = 52.0, // High-accessibility rural touch target
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary || variant == StitchButtonVariant.secondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          side: const BorderSide(color: StitchTokens.green700, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
          ),
        ),
        child: _buildChild(StitchTokens.green700),
      );
    }

    Color bgColor = StitchTokens.green700;
    Color textColor = Colors.white;

    if (variant == StitchButtonVariant.gold) {
      bgColor = StitchTokens.gold500;
      textColor = StitchTokens.slate900;
    } else if (variant == StitchButtonVariant.alert) {
      bgColor = StitchTokens.rose700;
      textColor = Colors.white;
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        minimumSize: Size(double.infinity, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StitchTokens.radiusMd),
        ),
      ),
      child: _buildChild(textColor),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: StitchTokens.bodyMedium.copyWith(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: StitchTokens.bodyMedium.copyWith(
        fontSize: 16,
        color: textColor,
      ),
    );
  }
}
