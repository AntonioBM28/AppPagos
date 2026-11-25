import 'package:flutter/services.dart';

/// Formateadores de entrada: impiden escribir caracteres invalidos en lugar de solo
/// marcar el error despues.
abstract final class Formateadores {
  /// Solo letras (con acentos y ene) y espacios. Nada de numeros ni simbolos.
  static final List<TextInputFormatter> soloLetras = [
    FilteringTextInputFormatter.allow(RegExp('[A-Za-zÁÉÍÓÚÜÑáéíóúüñ ]')),
    LengthLimitingTextInputFormatter(50),
  ];

  /// Solo digitos, con un maximo de [maximo].
  static List<TextInputFormatter> soloDigitos(int maximo) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maximo),
      ];

  /// Letras y numeros en mayusculas (CURP, RFC, nacionalidad).
  static List<TextInputFormatter> claveMayusculas(int maximo, {bool permitirNumeros = true}) => [
        FilteringTextInputFormatter.allow(RegExp(permitirNumeros ? '[A-Za-zÑñ&0-9]' : '[A-Za-z]')),
        const MayusculasFormatter(),
        LengthLimitingTextInputFormatter(maximo),
      ];

  /// Importe con hasta 10 enteros y 2 decimales.
  static final List<TextInputFormatter> importe = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}(\.\d{0,2})?')),
  ];

  /// Texto libre seguro (calle, colonia, empresa...).
  static List<TextInputFormatter> textoSeguro(int maximo) => [
        FilteringTextInputFormatter.allow(RegExp("[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,#/&()'°ºª-]")),
        LengthLimitingTextInputFormatter(maximo),
      ];

  /// Correo: sin espacios y en minusculas.
  static final List<TextInputFormatter> correo = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    const MinusculasFormatter(),
    LengthLimitingTextInputFormatter(100),
  ];
}

class MayusculasFormatter extends TextInputFormatter {
  const MayusculasFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class MinusculasFormatter extends TextInputFormatter {
  const MinusculasFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
