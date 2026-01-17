import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Violet
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF7C3AED);

  // Secondary Colors - Rose/Pink
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondaryDark = Color(0xFFDB2777);

  // Accent Colors
  static const Color accent = Color(0xFF00D9FF);
  static const Color accentLight = Color(0xFF4DE8FF);
  static const Color accentDark = Color(0xFF00B8D9);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDAA0A);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF0984E3);

  // Flame Colors
  static const Color flameYellow = Color(0xFFFFD700);
  static const Color flameOrange = Color(0xFFFF8C00);
  static const Color flamePurple = Color(0xFF9B59B6);

  // Gift Tier Colors
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierDiamond = Color(0xFFB9F2FF);

  // Premium Colors
  static const Color premiumGold = Color(0xFFFFD700);
  static const Color premiumGradientStart = Color(0xFFFFD700);
  static const Color premiumGradientEnd = Color(0xFFFFA500);

  // Chat Colors
  static const Color messageSent = Color(0xFF6C5CE7);
  static const Color messageReceived = Color(0xFFE8E8E8);
  static const Color messageReceivedDark = Color(0xFF2D2D2D);

  // Divider
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2D2D2D);

  // Shimmer
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient pour la navbar et autres éléments UI
  static const LinearGradient navbarGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7), Color(0xFFEC4899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradient vertical pour AppBar
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [premiumGradientStart, premiumGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFFFCAF45), Color(0xFFE1306C), Color(0xFF833AB4)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}
