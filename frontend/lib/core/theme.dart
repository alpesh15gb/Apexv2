import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/colors.dart';
import '../design_system/border_radius.dart';
import '../design_system/typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ApexColors.primary,
        brightness: Brightness.light,
        primary: ApexColors.primary,
        secondary: ApexColors.secondary,
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
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ApexRadius.mdAll,
          side: const BorderSide(color: ApexColors.neutral200),
        ),
        color: ApexColors.neutral0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ApexColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: ApexRadius.smAll,
          borderSide: const BorderSide(color: ApexColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ApexRadius.smAll,
          borderSide: const BorderSide(color: ApexColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ApexRadius.smAll,
          borderSide: const BorderSide(color: ApexColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ApexColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: ApexRadius.smAll),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ApexColors.neutral700,
          side: const BorderSide(color: ApexColors.neutral300),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: ApexRadius.smAll),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ApexColors.neutral200,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: ApexTypography.tableHeader,
        dataTextStyle: ApexTypography.tableCell,
        dataRowHeight: 44,
        headingRowHeight: 36,
        dividerThickness: 0.5,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: ApexRadius.lgAll),
        elevation: 8,
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
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ApexRadius.mdAll,
          side: const BorderSide(color: ApexColors.neutral700),
        ),
        color: ApexColors.darkSurface,
      ),
    );
  }
}
