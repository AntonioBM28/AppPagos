import 'package:material_ui/material_ui.dart';

import 'app_tokens.dart';

/// Temas claro y oscuro de la app (Material 3).
abstract final class AppTheme {
  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get oscuro => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final colores = ColorScheme.fromSeed(
      seedColor: AppColors.semilla,
      brightness: brillo,
    );
    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    const tamanoBoton = Size(AppSizes.areaTactilMinima, AppSizes.areaTactilMinima);
    final formaBoton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colores,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colores.surface,
        foregroundColor: colores.onSurface,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colores.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colores.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: bordeCampo,
        enabledBorder: bordeCampo,
        filled: true,
        fillColor: colores.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: tamanoBoton, shape: formaBoton),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: tamanoBoton, shape: formaBoton),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: tamanoBoton, shape: formaBoton),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
