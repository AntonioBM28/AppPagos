/// Rutas del backend. Todas se declaran aqui para no repetir cadenas en el codigo.
///
/// La API no usa parametros en la URL ni query strings: las consultas son POST con
/// un cuerpo JSON. Cada parte del proyecto agrega aqui las rutas que necesita.
abstract final class ApiEndpoints {
  /// GET: recupera la sesion activa (en web, a partir de la cookie HttpOnly).
  static const String sesion = '/auth/sesion';

  /// Rutas que no requieren sesion: no llevan Authorization y un 401 en ellas no
  /// significa que la sesion expiro. Las partes siguientes agregan las suyas.
  static const Set<String> publicas = <String>{};

  /// Rutas cuyo 401 no debe mostrarse como "tu sesion expiro". [sesion] devuelve 401
  /// cuando simplemente no hay sesion (por ejemplo, la primera visita en web).
  static const Set<String> sinAvisoDeExpiracion = <String>{sesion};

  static bool esPublica(String path) => publicas.contains(_normalizar(path));

  static bool avisaExpiracion(String path) {
    final ruta = _normalizar(path);
    return !publicas.contains(ruta) && !sinAvisoDeExpiracion.contains(ruta);
  }

  /// Compara solo la ruta, sin dominio ni barra final, para que "/auth/sesion/" o una
  /// URL absoluta no evadan la lista.
  static String _normalizar(String path) {
    final ruta = Uri.tryParse(path)?.path ?? path;
    return ruta.length > 1 && ruta.endsWith('/')
        ? ruta.substring(0, ruta.length - 1)
        : ruta;
  }
}
