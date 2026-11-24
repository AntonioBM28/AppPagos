import 'package:material_ui/material_ui.dart';

/// Colores de marca. El resto de la paleta la deriva Material 3 a partir de [semilla].
abstract final class AppColors {
  static const Color semilla = Color(0xFF0B5C6B); // verde petroleo
  static const Color exito = Color(0xFF1E7D45);
  static const Color advertencia = Color(0xFF9A6200);
}

/// Espaciados (multiplos de 4). Evita valores sueltos en las pantallas.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Radios de esquinas.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

/// Medidas de accesibilidad y de diseno.
abstract final class AppSizes {
  /// Area tactil minima recomendada (WCAG / Material).
  static const double areaTactilMinima = 48;

  /// Ancho maximo del contenido en pantallas grandes, para que formularios y textos
  /// no se estiren de lado a lado.
  static const double anchoMaximoContenido = 720;
  static const double anchoMaximoFormulario = 440;
}

/// Duraciones de animacion.
abstract final class AppDurations {
  static const Duration corta = Duration(milliseconds: 150);
  static const Duration media = Duration(milliseconds: 250);
}
