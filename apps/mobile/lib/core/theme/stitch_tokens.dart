import 'package:flutter/material.dart';

/// Google Stitch Design Tokens for VillageNova
/// Hand-crafted to match Google Stitch design-to-code component exports
/// and optimized for high-contrast, accessible rural mobile interfaces.
class StitchTokens {
  // ---------------------------------------------------------------------------
  // COLOR TOKENS
  // ---------------------------------------------------------------------------

  // Brand Greens (Primary - Agriculture & Foliage)
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green200 = Color(0xFFBBF7D0);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D); // Stitch Primary Green
  static const Color green800 = Color(0xFF166534);
  static const Color green900 = Color(0xFF14532D); // Stitch Dark Green

  // Crop Gold / Amber (Secondary - Harvest & Prosperity)
  static const Color gold50 = Color(0xFFFEFCE8);
  static const Color gold100 = Color(0xFFFEF9C3);
  static const Color gold200 = Color(0xFFFEF08A);
  static const Color gold300 = Color(0xFFFDE047);
  static const Color gold400 = Color(0xFFFACC15);
  static const Color gold500 = Color(0xFFEAB308);
  static const Color gold600 = Color(0xFFCA8A04);
  static const Color gold700 = Color(0xFFA16207);
  static const Color gold800 = Color(0xFF854D0E);
  static const Color gold900 = Color(0xFF713F12);

  // Sky Blue (Weather & Water)
  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky200 = Color(0xFFBAE6FD);
  static const Color sky300 = Color(0xFF7DD3FC);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky600 = Color(0xFF0284C7);
  static const Color sky700 = Color(0xFF0369A1);
  static const Color sky800 = Color(0xFF075985);
  static const Color sky900 = Color(0xFF0C4A6E);

  // Rose / Crimson (Emergency & Disease Alerts)
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose700 = Color(0xFFBE123C);
  static const Color rose900 = Color(0xFF881337);

  // Neutral Slates (Surfaces, Borders, Typography)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0); // Stitch Default Border
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A); // Stitch High-Contrast Text

  // ---------------------------------------------------------------------------
  // RADIUS TOKENS
  // ---------------------------------------------------------------------------
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0; // Stitch Standard Card Radius
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ---------------------------------------------------------------------------
  // SPACING TOKENS
  // ---------------------------------------------------------------------------
  static const double space2xs = 4.0;
  static const double spaceXs = 6.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;

  // ---------------------------------------------------------------------------
  // ELEVATION / SHADOW TOKENS
  // ---------------------------------------------------------------------------
  static const List<BoxShadow> shadow2xs = [
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowGreenGlow = [
    BoxShadow(
      color: Color(0x3315803D),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  // ---------------------------------------------------------------------------
  // TYPOGRAPHY TOKENS (High-Legibility Rural Contrast)
  // ---------------------------------------------------------------------------
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: slate900,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: slate900,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: slate900,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: slate800,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: slate900,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: slate500,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );
}
