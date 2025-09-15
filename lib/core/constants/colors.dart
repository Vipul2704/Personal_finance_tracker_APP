import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E8B57); // Sea Green
  static const Color primaryDark = Color(0xFF1F5F3F);
  static const Color primaryLight = Color(0xFF4CAF80);

  // Secondary Colors
  static const Color secondary = Color(0xFF3498DB); // Blue
  static const Color secondaryDark = Color(0xFF2980B9);
  static const Color secondaryLight = Color(0xFF5DADE2);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  // Expense Category Colors
  static const List<Color> categoryColors = [
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
    Color(0xFF1ABC9C), // Turquoise
    Color(0xFFF1C40F), // Yellow
    Color(0xFFE67E22), // Dark Orange
    Color(0xFF34495E), // Dark Blue
    Color(0xFF95A5A6), // Gray
  ];

  // Income Colors
  static const Color income = Color(0xFF27AE60); // Green
  static const Color expense = Color(0xFFE74C3C); // Red

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF3498DB),
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFF1C40F),
    Color(0xFFE67E22),
  ];

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}