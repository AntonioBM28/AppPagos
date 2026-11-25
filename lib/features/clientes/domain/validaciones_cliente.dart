import 'entities/cliente.dart';

/// Validaciones de los datos del cliente. Repiten las reglas del backend (para avisar
/// al momento, antes de enviar) y agregan cruces que solo tienen sentido en el
/// formulario, como que la CURP coincida con la fecha de nacimiento y el sexo.
///
/// Cada funcion devuelve el mensaje de error, o null si el valor es valido.
abstract final class ValidacionesCliente {
  static const _letras = 'A-Za-zÁÉÍÓÚÜÑáéíóúüñ';
  static final RegExp _nombre = RegExp('^[$_letras]+( [$_letras]+)*\$');
  static final RegExp _curp = RegExp(
    r'^[A-Z][AEIOUX][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[HM]'
    r'(AS|BC|BS|CC|CL|CM|CS|CH|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)'
    r'[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z][0-9]$',
  );
  static final RegExp _rfc = RegExp(r'^[A-ZÑ&]{4}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[A-Z0-9]{2}[0-9A]$');
  static final RegExp _correo = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
  static final RegExp _telefono = RegExp(r'^[0-9]{10}$');
  static final RegExp _codigoPostal = RegExp(r'^[0-9]{5}$');
  static final RegExp _nacionalidad = RegExp(r'^[A-Z]{3}$');
  static final RegExp _textoSeguro = RegExp("^[$_letras" r"0-9 .,#/&()'°ºª-]*$");

  static const edadMinima = 18;
  static const edadMaxima = 120;

  // ------------------------------------------------------------------ Nombres

  static String? nombre(String? valor, {required String campo}) {
    final texto = _limpiar(valor);
    if (texto.isEmpty) return '$campo es obligatorio';
    return _formatoNombre(texto, campo);
  }

  /// Segundo nombre: opcional.
  static String? nombreOpcional(String? valor, {required String campo}) {
    final texto = _limpiar(valor);
    return texto.isEmpty ? null : _formatoNombre(texto, campo);
  }

  static String? _formatoNombre(String texto, String campo) {
    if (texto.length < 2 || texto.length > 50) return '$campo debe tener entre 2 y 50 letras';
    if (!_nombre.hasMatch(texto)) return '$campo solo admite letras y un espacio entre palabras';
    return null;
  }

  // ------------------------------------------------------------------ Identidad

  static String? fechaNacimiento(DateTime? fecha, {DateTime? hoy}) {
    if (fecha == null) return 'La fecha de nacimiento es obligatoria';
    final ahora = hoy ?? DateTime.now();
    if (!fecha.isBefore(DateTime(ahora.year, ahora.month, ahora.day))) {
      return 'La fecha de nacimiento no puede ser hoy ni una fecha futura';
    }
    final edad = calcularEdad(fecha, ahora);
    if (edad < edadMinima) return 'El cliente debe ser mayor de edad (18 años o más)';
    if (edad > edadMaxima) return 'Revisa la fecha de nacimiento';
    return null;
  }

  static int calcularEdad(DateTime nacimiento, DateTime hoy) {
    var edad = hoy.year - nacimiento.year;
    if (hoy.month < nacimiento.month || (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
      edad--;
    }
    return edad;
  }

  /// CURP con formato oficial. Si ya se capturaron fecha y sexo, deben coincidir.
  static String? curp(String? valor, {DateTime? fechaNacimiento, Sexo? sexo}) {
    final texto = _limpiar(valor).toUpperCase();
    if (texto.isEmpty) return 'La CURP es obligatoria';
    if (texto.length != 18) return 'La CURP debe tener 18 caracteres';
    if (!_curp.hasMatch(texto)) return 'La CURP no tiene un formato válido';
    if (fechaNacimiento != null && texto.substring(4, 10) != _aammdd(fechaNacimiento)) {
      return 'La fecha de la CURP no coincide con la fecha de nacimiento';
    }
    if (sexo != null && texto[10] != sexo.codigo) {
      return 'El sexo de la CURP no coincide con el sexo seleccionado';
    }
    return null;
  }

  /// RFC de persona fisica. Sus primeros 10 caracteres son los mismos que los de la CURP.
  static String? rfc(String? valor, {String? curp}) {
    final texto = _limpiar(valor).toUpperCase();
    if (texto.isEmpty) return 'El RFC es obligatorio';
    if (texto.length != 13) return 'El RFC debe tener 13 caracteres';
    if (!_rfc.hasMatch(texto)) return 'El RFC no tiene un formato válido';
    final curpLimpia = _limpiar(curp).toUpperCase();
    if (curpLimpia.length >= 10 && texto.substring(0, 10) != curpLimpia.substring(0, 10)) {
      return 'Los primeros 10 caracteres del RFC deben coincidir con la CURP';
    }
    return null;
  }

  static String? nacionalidad(String? valor) {
    final texto = _limpiar(valor).toUpperCase();
    if (texto.isEmpty) return 'La nacionalidad es obligatoria';
    if (!_nacionalidad.hasMatch(texto)) return 'Usa el código de 3 letras, por ejemplo MEX';
    return null;
  }

  static String? obligatorio(Object? valor, {required String campo}) =>
      valor == null ? '$campo es obligatorio' : null;

  // ------------------------------------------------------------------ Contacto

  static String? correo(String? valor) {
    final texto = _limpiar(valor).toLowerCase();
    if (texto.isEmpty) return 'El correo electrónico es obligatorio';
    if (texto.length > 100) return 'El correo admite máximo 100 caracteres';
    if (!_correo.hasMatch(texto)) return 'Escribe un correo válido, por ejemplo nombre@correo.com';
    return null;
  }

  static String? telefono(String? valor, {required String campo}) {
    final texto = _limpiar(valor);
    if (texto.isEmpty) return '$campo es obligatorio';
    return _formatoTelefono(texto, campo);
  }

  static String? telefonoOpcional(String? valor, {required String campo}) {
    final texto = _limpiar(valor);
    return texto.isEmpty ? null : _formatoTelefono(texto, campo);
  }

  static String? _formatoTelefono(String texto, String campo) =>
      _telefono.hasMatch(texto) ? null : '$campo debe tener exactamente 10 dígitos (solo números)';

  // ------------------------------------------------------------------ Domicilio y trabajo

  /// Calle, numeros, colonia, ocupacion y empresa: letras, numeros y puntuacion comun.
  static String? texto(String? valor, {required String campo, required int maximo, bool obligatorio = true}) {
    final texto = _limpiar(valor);
    if (texto.isEmpty) return obligatorio ? '$campo es obligatorio' : null;
    if (texto.length > maximo) return '$campo admite máximo $maximo caracteres';
    if (!_textoSeguro.hasMatch(texto)) {
      return "$campo solo admite letras, números, espacios y . , # / & ( ) ' -";
    }
    return null;
  }

  static String? codigoPostal(String? valor) {
    final texto = _limpiar(valor);
    if (texto.isEmpty) return 'El código postal es obligatorio';
    if (!_codigoPostal.hasMatch(texto)) return 'El código postal tiene exactamente 5 dígitos';
    return null;
  }


  // ------------------------------------------------------------------ Acceso

  /// Misma politica que el backend: 8 a 72 caracteres, mayuscula, minuscula, numero y
  /// caracter especial.
  static String? password(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'La contraseña es obligatoria';
    final faltantes = [
      if (texto.length < 8) 'mínimo 8 caracteres',
      if (!texto.contains(RegExp('[A-ZÁÉÍÓÚÑ]'))) 'una mayúscula',
      if (!texto.contains(RegExp('[a-záéíóúñ]'))) 'una minúscula',
      if (!texto.contains(RegExp('[0-9]'))) 'un número',
      if (!texto.contains(RegExp('[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9]'))) 'un carácter especial',
    ];
    if (texto.length > 72) return 'La contraseña admite máximo 72 caracteres';
    return faltantes.isEmpty ? null : 'La contraseña necesita: ${faltantes.join(', ')}';
  }

  static String? confirmarPassword(String? valor, String password) {
    if (valor == null || valor.isEmpty) return 'Confirma la contraseña';
    return valor == password ? null : 'Las contraseñas no coinciden';
  }

  // ------------------------------------------------------------------ Utilidades

  /// Quita espacios al inicio y al final y deja uno solo entre palabras.
  static String _limpiar(String? valor) => (valor ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

  static String limpiar(String? valor) => _limpiar(valor);

  static String _aammdd(DateTime fecha) =>
      '${(fecha.year % 100).toString().padLeft(2, '0')}'
      '${fecha.month.toString().padLeft(2, '0')}'
      '${fecha.day.toString().padLeft(2, '0')}';
}
