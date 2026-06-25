import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/colors.dart';
import '../design_system/border_radius.dart';

/// Apex Design System — Theme Configuration
///
/// Uses design system tokens for consistent styling.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ApexColors.primary,
        brightness: Brightness.light,
        primary: ApexColors.primary,
        secondary: ApexColors.secondary,
        tertiary: ApexColors.accent,
        surface: ApexColors.neutral50,
        background: ApexColors.neutral0,
        error: ApexColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      scaffoldBackgroundColor: ApexColors.neutral50,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ApexColors.neutral800),
        titleTextStyle: TextStyle(
          color: ApexColors.neutral800,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ApexRadius.lgAll,
          side: const BorderSide(color: ApexColors.neutral200),
        ),
        color: ApexColors.neutral0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ApexColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: const BorderSide(color: ApexColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: const BorderSide(color: ApexColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: const BorderSide(color: ApexColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ApexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ApexColors.neutral700,
          side: const BorderSide(color: ApexColors.neutral300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ApexColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ApexColors.neutral0,
        indicatorColor: ApexColors.primary50,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ApexColors.neutral200,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ApexColors.neutral100,
        selectedColor: ApexColors.primary100,
        shape: RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
        side: const BorderSide(color: ApexColors.neutral200),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: ApexRadius.xlAll),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ApexColors.primary,
        brightness: Brightness.dark,
        primary: ApexColors.primary400,
        secondary: ApexColors.secondary400,
        tertiary: ApexColors.accent,
        background: ApexColors.darkBackground,
        surface: ApexColors.darkSurface,
        error: ApexColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: ApexColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ApexColors.darkOnSurface),
        titleTextStyle: TextStyle(
          color: ApexColors.darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ApexRadius.lgAll,
          side: const BorderSide(color: ApexColors.neutral700),
        ),
        color: ApexColors.darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ApexColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: const BorderSide(color: ApexColors.neutral700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: const BorderSide(color: ApexColors.primary400, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ApexRadius.mdAll,
          borderSide: const BorderSide(color: ApexColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ApexColors.primary400,
          foregroundColor: ApexColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ApexColors.darkBackground,
        indicatorColor: ApexColors.primary400.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ApexColors.darkOnSurfaceVariant),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ApexColors.neutral700,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: ApexRadius.xlAll),
        elevation: 8,
      ),
    );
  }
}
