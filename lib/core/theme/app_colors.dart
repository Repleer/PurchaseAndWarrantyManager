import 'package:flutter/material.dart';

/// Кольорові токени, перенесені з макета Figma.
abstract final class AppColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color sidebar = Color(0xFFF0F4F8);
  static const Color surface = Colors.white;

  static const Color border = Color(0xFFD9E1EA);
  static const Color inputBorder = Color(0xFFC5D0DC);

  static const Color primary = Color(0xFF2764D7);
  static const Color primaryLight = Color(0xFFE8F0FF);

  static const Color textPrimary = Color(0xFF182433);
  static const Color textSecondary = Color(0xFF5D6B7A);

  static const Color warning = Color(0xFFB86117);
  static const Color warningBackground = Color(0xFFFFF3E4);
  static const Color success = Color(0xFF237A55);
  static const Color successBackground = Color(0xFFE8F6EF);
  static const Color error = Color(0xFFC0392B);
  static const Color errorBackground = Color(0xFFFDECEA);

  static const Color google = Color(0xFF4285F4);
  static const Color shadow = Color.fromRGBO(35, 50, 71, 0.05);
}
