import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1F48FF); // Electric Indigo
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color alarmColor = Color(0xFFB00020);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1D1D1F);

  static TextStyle get titleStyle => GoogleFonts.saira(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  static TextStyle get valueStyle => GoogleFonts.saira(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get labelStyle => GoogleFonts.saira(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      );
}
