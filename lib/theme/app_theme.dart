import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ReadingMode { light, dark, sepia }

class AppColors {
  // Midnight Library palette
  static const bg = Color(0xFF080A18);
  static const surface = Color(0xFF0F1628);
  static const card = Color(0xFF151D35);
  static const cardBorder = Color(0xFF1E2A4A);

  static const violet = Color(0xFF8B5CF6);
  static const violetLight = Color(0xFFA78BFA);
  static const violetDark = Color(0xFF5B2CD3);
  static const gold = Color(0xFFFBBF24);
  static const goldLight = Color(0xFFFDE68A);
  static const coral = Color(0xFFFF6B9D);

  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892AD);
  static const textMuted = Color(0xFF4A5578);

  static const highlightYellow = Color(0xFFFFEB3B);
  static const highlightGreen = Color(0xFF4ADE80);
  static const highlightBlue = Color(0xFF60A5FA);
  static const highlightPink = Color(0xFFF9A8D4);
  static const highlightOrange = Color(0xFFFB923C);

  static const Gradient primaryGradient = LinearGradient(
    colors: [violet, violetDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient bgGradient = LinearGradient(
    colors: [Color(0xFF0D1030), bg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [goldLight, gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.violet,
          secondary: AppColors.gold,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800),
          titleLarge: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.inter(color: AppColors.textSecondary),
          labelSmall: GoogleFonts.inter(color: AppColors.textMuted),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.cardBorder,
          thickness: 1,
        ),
        sliderTheme: SliderThemeData(
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          trackHeight: 2,
          activeTrackColor: AppColors.violet,
          inactiveTrackColor: AppColors.textMuted,
          thumbColor: AppColors.violetLight,
          overlayShape: SliderComponentShape.noOverlay,
        ),
      );

  // ── Reader modes ───────────────────────────────────────────────────────────

  static Color readerBg(ReadingMode mode) => switch (mode) {
        ReadingMode.light => const Color(0xFFFAFAFA),
        ReadingMode.dark => const Color(0xFF0A0A12),
        ReadingMode.sepia => const Color(0xFFF5ECD7),
      };

  static Color readerToolbar(ReadingMode mode) => switch (mode) {
        ReadingMode.light => const Color(0xFF0F1628),
        ReadingMode.dark => const Color(0xFF050710),
        ReadingMode.sepia => const Color(0xFF4A3728),
      };

  static Color readerText(ReadingMode mode) => switch (mode) {
        ReadingMode.light => Colors.black87,
        ReadingMode.dark => const Color(0xFFDDE3FF),
        ReadingMode.sepia => const Color(0xFF3E2723),
      };
}
