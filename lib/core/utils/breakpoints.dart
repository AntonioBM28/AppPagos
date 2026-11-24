import 'package:flutter/widgets.dart';

/// Tamanos de ventana segun las guias de Material 3.
enum TamanoVentana {
  /// < 600: telefonos en vertical.
  compacto,

  /// 600 - 1023: tabletas y telefonos en horizontal.
  mediano,

  /// >= 1024: escritorio y web.
  expandido;

  static const double limiteCompacto = 600;
  static const double limiteMediano = 1024;

  static TamanoVentana deAncho(double ancho) {
    if (ancho < limiteCompacto) return TamanoVentana.compacto;
    if (ancho < limiteMediano) return TamanoVentana.mediano;
    return TamanoVentana.expandido;
  }

  static TamanoVentana de(BuildContext context) =>
      deAncho(MediaQuery.sizeOf(context).width);
}
