import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme Kaamelott "Le Parchemin Royal"
/// Inspired by medieval manuscripts and the legendary castle of Camelot
class AppTheme {
  // Parchment colors
  static const _parchment = Color(0xFFF4E4BC);
  static const _parchmentDark = Color(0xFFE8D4A8);
  static const _parchmentDarker = Color(0xFFD4C094);

  // Ink colors
  static const _inkBlack = Color(0xFF2C1810);
  static const _inkBrown = Color(0xFF4A3728);

  // Accent colors
  static const _gold = Color(0xFFC9A227);
  static const _goldLight = Color(0xFFE8C547);
  static const _goldDim = Color(0xFFA08030);
  static const _burgundy = Color(0xFF722F37);
  static const _burgundyDark = Color(0xFF5A252C);
  static const _forest = Color(0xFF2D4A3E);
  static const _forestLight = Color(0xFF3D5A4E);
  static const _waxRed = Color(0xFF8B2500);

  // Dark mode - Castle stone colors
  static const _stoneDark = Color(0xFF1A1A1A);
  static const _stoneMid = Color(0xFF2D2D2D);
  static const _stoneLight = Color(0xFF3D3D3D);
  static const _stoneHighlight = Color(0xFF4A4A4A);

  static TextTheme _buildTextTheme(TextTheme base, Color textColor, bool isDark) {
    // Cinzel for headers (medieval elegant), Crimson Text for body (manuscript style)
    return base.copyWith(
      displayLarge: GoogleFonts.cinzel(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: isDark ? _gold : _burgundy,
      ),
      displayMedium: GoogleFonts.cinzel(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: isDark ? _gold : _burgundy,
      ),
      displaySmall: GoogleFonts.cinzel(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.cinzel(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
      ),
      titleMedium: GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
      ),
      titleSmall: GoogleFonts.cinzel(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.crimsonText(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.crimsonText(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.crimsonText(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelMedium: GoogleFonts.crimsonText(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: textColor,
      ),
      labelSmall: GoogleFonts.crimsonText(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: textColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _burgundy,
      onPrimary: _parchment,
      primaryContainer: _burgundyDark,
      onPrimaryContainer: _parchment,
      secondary: _gold,
      onSecondary: _inkBlack,
      secondaryContainer: _goldDim,
      onSecondaryContainer: _inkBlack,
      tertiary: _forest,
      onTertiary: _parchment,
      tertiaryContainer: _forestLight,
      onTertiaryContainer: _parchment,
      error: _waxRed,
      onError: _parchment,
      errorContainer: const Color(0xFFFFDAD4),
      onErrorContainer: _waxRed,
      surface: _parchment,
      onSurface: _inkBlack,
      surfaceContainerLowest: const Color(0xFFFFF8EC),
      surfaceContainerLow: _parchment,
      surfaceContainer: _parchmentDark,
      surfaceContainerHigh: _parchmentDarker,
      surfaceContainerHighest: const Color(0xFFC4B088),
      onSurfaceVariant: _inkBrown,
      outline: _inkBrown,
      outlineVariant: _parchmentDarker,
      shadow: Colors.black.withValues(alpha: 0.2),
      scrim: Colors.black.withValues(alpha: 0.4),
      inverseSurface: _inkBlack,
      onInverseSurface: _parchment,
      inversePrimary: _goldLight,
    );

    final textTheme = _buildTextTheme(
      ThemeData.light().textTheme,
      colorScheme.onSurface,
      false,
    );

    return _buildTheme(colorScheme, textTheme, Brightness.light);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _gold,
      onPrimary: _stoneDark,
      primaryContainer: _goldDim,
      onPrimaryContainer: _parchment,
      secondary: _burgundy,
      onSecondary: _parchment,
      secondaryContainer: _burgundyDark,
      onSecondaryContainer: _parchment,
      tertiary: _forest,
      onTertiary: _parchment,
      tertiaryContainer: _forestLight,
      onTertiaryContainer: _parchment,
      error: const Color(0xFFFF6B6B),
      onError: _stoneDark,
      errorContainer: const Color(0xFF4A0000),
      onErrorContainer: const Color(0xFFFFB4A9),
      surface: _stoneDark,
      onSurface: _parchment,
      surfaceContainerLowest: const Color(0xFF101010),
      surfaceContainerLow: _stoneMid,
      surfaceContainer: _stoneLight,
      surfaceContainerHigh: _stoneHighlight,
      surfaceContainerHighest: const Color(0xFF5A5A5A),
      onSurfaceVariant: _parchmentDark,
      outline: _goldDim,
      outlineVariant: _stoneHighlight,
      shadow: Colors.black.withValues(alpha: 0.5),
      scrim: Colors.black.withValues(alpha: 0.7),
      inverseSurface: _parchment,
      onInverseSurface: _inkBlack,
      inversePrimary: _burgundy,
    );

    final textTheme = _buildTextTheme(
      ThemeData.dark().textTheme,
      colorScheme.onSurface,
      true,
    );

    return _buildTheme(colorScheme, textTheme, Brightness.dark);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? _burgundyDark : _burgundy,
        foregroundColor: isDark ? _gold : _parchment,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? _gold : _parchment,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(
          color: isDark ? _gold : _parchment,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _stoneMid : _parchment,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isDark ? _goldDim : _inkBrown,
            width: 1.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? _stoneLight.withValues(alpha: 0.5)
            : _parchmentDark.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: _inkBrown, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark ? _goldDim : _inkBrown,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: isDark ? _gold : _burgundy,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: _waxRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.crimsonText(
          fontStyle: FontStyle.italic,
          color: isDark ? _parchmentDarker : _inkBrown.withValues(alpha: 0.6),
        ),
        labelStyle: GoogleFonts.cinzel(
          fontSize: 12,
          color: isDark ? _parchmentDark : _inkBrown,
        ),
        prefixIconColor: isDark ? _gold : _burgundy,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? _gold : _burgundy,
          foregroundColor: isDark ? _inkBlack : _parchment,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isDark ? _goldLight : _goldDim,
              width: 2,
            ),
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? _gold : _burgundy,
          foregroundColor: isDark ? _inkBlack : _parchment,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isDark ? _goldLight : _goldDim,
              width: 2,
            ),
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? _gold : _burgundy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          side: BorderSide(
            color: isDark ? _gold : _burgundy,
            width: 2,
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? _gold : _burgundy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: isDark ? _gold : _burgundy,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? _gold : _burgundy,
        foregroundColor: isDark ? _inkBlack : _parchment,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? _goldLight : _goldDim,
            width: 2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _stoneLight : _parchmentDark,
        labelStyle: GoogleFonts.crimsonText(
          fontSize: 12,
          color: isDark ? _parchment : _inkBlack,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? _goldDim : _inkBrown,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? _goldDim.withValues(alpha: 0.3) : _inkBrown.withValues(alpha: 0.3),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        iconColor: isDark ? _gold : _burgundy,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? _stoneMid : _parchment,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDark ? _gold : _burgundy,
            width: 2,
          ),
        ),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? _gold : _burgundy,
        ),
        contentTextStyle: GoogleFonts.crimsonText(
          fontSize: 14,
          color: isDark ? _parchment : _inkBlack,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? _stoneMid : _parchment,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          side: BorderSide(
            color: isDark ? _gold : _burgundy,
            width: 2,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _forest : _burgundyDark,
        contentTextStyle: GoogleFonts.crimsonText(
          fontSize: 14,
          color: _parchment,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: _gold,
            width: 1,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? _gold : _burgundy,
        linearTrackColor: isDark ? _stoneHighlight : _parchmentDarker,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: isDark ? _gold : _burgundy,
        inactiveTrackColor: isDark ? _stoneHighlight : _parchmentDarker,
        thumbColor: isDark ? _goldLight : _burgundy,
        overlayColor: (isDark ? _gold : _burgundy).withValues(alpha: 0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? _gold : _burgundy;
          }
          return isDark ? _stoneHighlight : _parchmentDarker;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark ? _gold : _burgundy).withValues(alpha: 0.4);
          }
          return isDark ? _stoneLight : _parchmentDark;
        }),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? _stoneMid : _inkBlack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? _gold : _goldDim,
          ),
        ),
        textStyle: GoogleFonts.crimsonText(
          fontSize: 12,
          color: _parchment,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? _stoneMid : _parchment,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isDark ? _goldDim : _inkBrown,
            width: 1,
          ),
        ),
        textStyle: GoogleFonts.crimsonText(
          fontSize: 14,
          color: isDark ? _parchment : _inkBlack,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? _burgundyDark : _burgundy,
        selectedItemColor: isDark ? _gold : _parchment,
        unselectedItemColor: isDark ? _parchmentDark : _parchmentDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _burgundyDark : _burgundy,
        indicatorColor: isDark ? _gold.withValues(alpha: 0.3) : _parchment.withValues(alpha: 0.3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: isDark ? _gold : _parchment);
          }
          return IconThemeData(color: isDark ? _parchmentDark : _parchmentDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? _gold : _parchment,
            );
          }
          return GoogleFonts.cinzel(
            fontSize: 12,
            color: isDark ? _parchmentDark : _parchmentDark,
          );
        }),
      ),
    );
  }

  // Helper method for consistent medieval decorative elements
  static BoxDecoration get parchmentDecoration => BoxDecoration(
    color: _parchment,
    border: Border.all(color: _inkBrown, width: 2),
    borderRadius: BorderRadius.circular(4),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(2, 2),
      ),
    ],
  );

  static BoxDecoration get scrollDecoration => BoxDecoration(
    color: _parchmentDark,
    border: Border.all(color: _inkBrown, width: 2),
    borderRadius: BorderRadius.circular(4),
  );

  // Medieval color constants for custom widgets
  static Color get parchmentColor => _parchment;
  static Color get inkColor => _inkBlack;
  static Color get goldColor => _gold;
  static Color get burgundyColor => _burgundy;
  static Color get forestColor => _forest;
  static Color get waxRedColor => _waxRed;
}
