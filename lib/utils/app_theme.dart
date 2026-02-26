import 'package:flutter/material.dart';

class AppTheme {
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  static Color backgroundColor(BuildContext context) {
    return isDark(context) ? const Color(0xFF1A1A1A) : const Color(0xFFF5F1E8);
  }
  
  static Color cardColor(BuildContext context) {
    return isDark(context) ? const Color(0xFF2C2C2C) : Colors.white;
  }
  
  static Color textColor(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xFF2C2C2C);
  }
  
  static Color subtextColor(BuildContext context) {
    return isDark(context) ? Colors.white70 : Colors.black.withOpacity(0.5);
  }
  
  static Color iconBackgroundColor(BuildContext context) {
    return isDark(context) ? const Color(0xFF3C3C3C) : const Color(0xFFF5F1E8);
  }
  
  static Color dividerColor(BuildContext context) {
    return isDark(context) ? Colors.white24 : Colors.black.withOpacity(0.1);
  }
}

