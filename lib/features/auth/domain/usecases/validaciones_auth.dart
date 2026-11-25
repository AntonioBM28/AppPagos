/// Validaciones de entrada del login. Se usan en los formularios (mensaje inmediato) y
/// en los casos de uso (no se envia nada invalido al servidor). El servidor vuelve a
/// validar todo: estas reglas solo mejoran la experiencia.
abstract final class ValidacionesAuth {
  static final RegExp _correo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _codigo = RegExp(r'^\d{6}$');

  static const longitudCodigo = 6;

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu correo electrónico';
    if (texto.length > 100) return 'El correo admite máximo 100 caracteres';
    if (!_correo.hasMatch(texto)) return 'Escribe un correo válido, por ejemplo nombre@correo.com';
    return null;
  }

  static String? password(String? valor) {
    if (valor == null || valor.isEmpty) return 'Escribe tu contraseña';
    if (valor.length > 72) return 'La contraseña admite máximo 72 caracteres';
    return null;
  }

  static String? codigo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe el código que te enviamos';
    if (!_codigo.hasMatch(texto)) return 'El código tiene 6 dígitos';
    return null;
  }
}
