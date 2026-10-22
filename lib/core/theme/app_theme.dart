import 'package:flutter/material.dart';

/// Theme Material 3 sobre, typographie Inter.
/// Lisible, rapide, sans effets superflus.
class AppTheme {
  static const _seed = Color(0xFF1D4ED8);

  /// Inter (latin) avec InterExt en secours pour les alphabets etendus.
  static const _font = 'Inter';
  static const _fallback = ['InterExt'];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _base(scheme, Brightness.dark);
  }

  /// Echelle typographique : titres serres, texte de lecture aere.
  static TextTheme _text(TextTheme base, ColorScheme scheme) {
    return base
        .apply(fontFamily: _font, fontFamilyFallback: _fallback)
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontSize: 34,
            height: 1.15,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 26,
            height: 1.2,
            letterSpacing: -0.4,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 22,
            height: 1.25,
            letterSpacing: -0.3,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 19,
            height: 1.3,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 15,
            height: 1.35,
            letterSpacing: -0.1,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.55),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 13.5, height: 1.5),
          bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.45),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        )
        .apply(
          fontFamily: _font,
          fontFamilyFallback: _fallback,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final t = _text(ThemeData(brightness: brightness).textTheme, scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: _font,
      fontFamilyFallback: _fallback,
      textTheme: t,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: t.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: t.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: t.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: t.labelLarge),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: t.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: t.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: t.titleSmall?.copyWith(color: scheme.onSurface),
        dataTextStyle: t.bodyMedium,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        selectedLabelTextStyle: t.bodySmall,
        unselectedLabelTextStyle: t.bodySmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle:
            t.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
