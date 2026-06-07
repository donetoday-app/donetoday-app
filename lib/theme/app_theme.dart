import 'package:flutter/material.dart';

class AppTheme {
  // Minimalist Palette: Zinc/Neutral
  static const Color background = Color(
    0xFF18181B,
  ); // Zinc-900 (Lighter than 950)
  static const Color surface = Color(0xFF27272A); // Zinc-800
  static const Color surfaceVariant = Color(0xFF3F3F46); // Zinc-700
  static const Color accent = Color(0xFF6366F1); // Indigo-500
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc-400

  static ThemeData darkTheme({Color? seedColor, bool useBlackMode = false}) {
    final baseColor = seedColor ?? accent;
    // Transform bright accent into a lighter, normal (pastel) color for the UI
    final softPrimary = HSVColor.fromColor(
      baseColor,
    ).withSaturation(0.3).withValue(0.90).toColor();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: softPrimary,
      brightness: Brightness.dark,
    );

    // Architectural Refinement for "Silent Void" Minimalist Dark Mode
    final refinedColorScheme = colorScheme.copyWith(
      primary: softPrimary,
      onPrimary: softPrimary.computeLuminance() > 0.5
          ? Colors.black
          : Colors.white,
      surface: useBlackMode
          ? const Color(0xFF000000)
          : const Color(0xFF121214), // Beautiful Charcoal Gray base
      onSurface: const Color(0xFFFAFAFA), // Starlight Text Primary
      surfaceContainer: useBlackMode
          ? const Color(
              0xFF111113,
            ) // Premium highlighting dark gray card container
          : const Color(0xFF1C1C1E), // Distinct lighter Charcoal Gray Container
      surfaceContainerHigh: useBlackMode
          ? const Color(0xFF18181A) // Highlighting dialog base
          : const Color(0xFF242426),
      onSurfaceVariant: const Color(
        0xB3FFFFFF,
      ), // Soft 70% translucent secondary text
      outlineVariant: Colors.transparent, // ZERO visible outlines
      secondaryContainer: softPrimary.withOpacity(0.06),
    );

    return _buildTheme(refinedColorScheme);
  }

  static ThemeData lightTheme({Color? seedColor}) {
    final baseColor = seedColor ?? accent;
    // Transform bright accent into a lighter, normal color for the UI
    final softPrimary = HSVColor.fromColor(
      baseColor,
    ).withSaturation(0.45).withValue(0.75).toColor();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: softPrimary,
      brightness: Brightness.light,
    );

    // Architectural Refinement for Crisp Light Mode
    final refinedColorScheme = colorScheme.copyWith(
      primary: softPrimary,
      onPrimary: softPrimary.computeLuminance() > 0.5
          ? Colors.black
          : Colors.white,
      surface: const Color.fromARGB(
        255,
        250,
        251,
        252,
      ), // Crisp light zinc background
      onSurface: const Color(
        0xFF18181B,
      ), // Zinc-900 (High contrast neutral text)
      surfaceContainer: const Color(0xFFFFFFFF), // Solid pure white cards
      surfaceContainerHigh: const Color(0xFFF1F5F9), // Slate-100 for dialogs
      onSurfaceVariant: const Color(0xFF52525B), // Zinc-600 secondary text
      outlineVariant: const Color(0xFFE2E8F0), // Slate-200 subtle borders
    );

    return _buildTheme(refinedColorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final isBlackMode = isDark && colorScheme.surface.value == 0xFF000000;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Typography
      textTheme: _textTheme(colorScheme),

      // Card Styling: Borderless Silent Void Layouts
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        color: isDark
            ? (isBlackMode
                  ? const Color(
                      0xFF111113,
                    ) // Beautiful solid highlighting dark gray card color
                  : colorScheme.surfaceContainer) // Faint gray plate
            : colorScheme.surfaceContainer, // Pure white card in light mode
      ),

      // AppBar Styling: Immersive Minimalist
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.1,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Button Styling: Luxury Rounded
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          textStyle: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration: Glass Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? (isBlackMode
                  ? const Color(0x0AFFFFFF)
                  : colorScheme.surfaceContainer)
            : colorScheme.surfaceContainer, // Pure white inputs in light mode
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          color: isDark ? const Color(0x99FFFFFF) : const Color(0x99000000),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: isDark ? const Color(0x66FFFFFF) : const Color(0x66000000),
        ),
      ),

      // Chip Styling: Mono Accent Style
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
        labelStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),

      // Dialog Styling: Floating Void Sheet
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
            width: 1,
          ),
        ),
      ),

      // Custom Extension
      extensions: [
        CustomColorsExtension(
          success: success,
          warning: const Color(0xFFF59E0B),
          error: const Color(0xFFEF4444),
          info: const Color(0xFF3B82F6),
          glassShadow: Colors.transparent, // Minimalist void
          accentGradient: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ],
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    final secondaryTextColor = isDark
        ? const Color(0x99FFFFFF)
        : const Color(0x99000000);

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.4,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.2,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: 0.0,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.1,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: 0.0,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: 0.0,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryTextColor,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  static CustomColorsExtension of(BuildContext context) {
    return Theme.of(context).extension<CustomColorsExtension>()!;
  }

  static Color getMoodColor(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'energized':
        return const Color(0xFFF59E0B);
      case 'peaceful':
        return const Color(0xFF10B981);
      case 'focused':
        return const Color(0xFF6366F1);
      case 'creative':
        return const Color(0xFFEC4899);
      case 'tired':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

class CustomColorsExtension extends ThemeExtension<CustomColorsExtension> {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color glassShadow;
  final List<Color> accentGradient;

  const CustomColorsExtension({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.glassShadow,
    required this.accentGradient,
  });

  @override
  CustomColorsExtension copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? glassShadow,
    List<Color>? accentGradient,
  }) {
    return CustomColorsExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      glassShadow: glassShadow ?? this.glassShadow,
      accentGradient: accentGradient ?? this.accentGradient,
    );
  }

  @override
  CustomColorsExtension lerp(
    ThemeExtension<CustomColorsExtension>? other,
    double t,
  ) {
    if (other is! CustomColorsExtension) return this;
    return CustomColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      accentGradient: accentGradient,
    );
  }
}
