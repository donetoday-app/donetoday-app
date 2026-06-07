import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double huge = 64.0;

  // Screen level spacing
  static const double screenHorizontal = 14.0;
  static const double screenVertical = 6;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(
    vertical: screenVertical,
  );
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static BorderRadius radiusSm = BorderRadius.circular(sm);
  static BorderRadius radiusMd = BorderRadius.circular(md);
  static BorderRadius radiusLg = BorderRadius.circular(lg);
  static BorderRadius radiusXl = BorderRadius.circular(xl);
}

class AppTextStyles {
  // Common text style overrides or extra definitions if needed
  // But generally should prefer Theme.of(context).textTheme
}
