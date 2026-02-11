import 'package:flutter/material.dart';

/// ألوان التطبيق
class AppColors {
  AppColors._();

  // Primary Colors - أخضر إسلامي
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF0D3311);

  // Secondary Colors - ذهبي
  static const Color secondary = Color(0xFFD4AF37);
  static const Color secondaryLight = Color(0xFFE6C866);
  static const Color secondaryDark = Color(0xFFB8860B);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  // Divider Colors
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Prayer Time Colors
  static const Color fajrColor = Color(0xFF3F51B5);
  static const Color sunriseColor = Color(0xFFFF9800);
  static const Color dhuhrColor = Color(0xFFFFEB3B);
  static const Color asrColor = Color(0xFFFF5722);
  static const Color maghribColor = Color(0xFFE91E63);
  static const Color ishaColor = Color(0xFF673AB7);

  // Ramadan Colors
  static const Color ramadanGold = Color(0xFFD4AF37);
  static const Color ramadanPurple = Color(0xFF6A1B9A);
  static const Color ramadanBlue = Color(0xFF1565C0);
  static const Color laylatalQadr = Color(0xFF311B92);

  // Category Colors
  static const Color duaCategory = Color(0xFF00796B);
  static const Color ziyaratCategory = Color(0xFF5D4037);
  static const Color eventCategory = Color(0xFF7B1FA2);
  static const Color dailyCategory = Color(0xFF1976D2);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [secondaryDark, secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nightGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4A148C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient ramadanGradient = LinearGradient(
    colors: [ramadanPurple, ramadanBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Night Primary Color
  static const Color nightPrimary = Color(0xFF1A237E);
}
