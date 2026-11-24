import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import '../utils/breakpoints.dart';

/// Elige un layout segun el ancho disponible. [mediano] y [expandido] son opcionales:
/// si faltan, se usa el siguiente mas pequeno.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.compacto,
    this.mediano,
    this.expandido,
    super.key,
  });

  final WidgetBuilder compacto;
  final WidgetBuilder? mediano;
  final WidgetBuilder? expandido;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final builder = switch (TamanoVentana.deAncho(restricciones.maxWidth)) {
          TamanoVentana.compacto => compacto,
          TamanoVentana.mediano => mediano ?? compacto,
          TamanoVentana.expandido => expandido ?? mediano ?? compacto,
        };
        return builder(context);
      },
    );
  }
}

/// Centra el contenido y limita su ancho en pantallas grandes. Incluye scroll
/// vertical para que nada se desborde en resoluciones pequenas.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({
    required this.child,
    this.anchoMaximo = AppSizes.anchoMaximoContenido,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final Widget child;
  final double anchoMaximo;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: anchoMaximo),
          child: child,
        ),
      ),
    );
  }
}
