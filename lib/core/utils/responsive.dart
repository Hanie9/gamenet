import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width < medium;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return const EdgeInsets.all(16);
    if (width < medium) return const EdgeInsets.all(20);
    return const EdgeInsets.all(28);
  }

  static int statColumns(double width) {
    if (width >= 1100) return 4;
    if (width >= 560) return 2;
    return 1;
  }

  static int cafeColumns(double width) {
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    if (width >= 400) return 3;
    return 2;
  }

  static const double gamingCardMaxWidth = 420;

  static int gamingColumns(double width) {
    if (width >= 1000) return 2;
    return 1;
  }

  static double cafeAspectRatio(double width) {
    if (width < 400) return 1.2;
    if (width < 900) return 1.35;
    return 1.45;
  }

  static double gamingAspectRatio(double width, int columns) {
    if (columns == 1) return width < 600 ? 1.0 : 1.15;
    return 1.45;
  }
}
