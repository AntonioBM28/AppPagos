import '../security/session_manager.dart';

/// Rutas de la app y regla de redireccion segun el estado de la sesion.
abstract final class AppRoutes {
  static const cargando = '/cargando';
  static const login = '/login';
  static const verificarCodigo = '/verificar-codigo';
  static const inicio = '/inicio';
  static const catalogo = '/catalogo';
  static const historial = '/historial';
  static const perfil = '/perfil';

  /// Accesibles sin sesion (el flujo de inicio de sesion).
  static const publicas = {login, verificarCodigo};

  /// Parametro que recuerda a donde iba el usuario antes de pasar por /cargando.
  static const paramDesde = 'desde';

  static bool esProtegida(String path) =>
      path != cargando && !publicas.contains(path);

  /// Decide la redireccion. Devuelve null si la ruta pedida es valida.
  ///
  /// - verificando: todo pasa por /cargando, asi nunca se pinta una pantalla
  ///   protegida antes de confirmar la sesion (importante al refrescar en web).
  /// - autenticada: el flujo de login y /cargando llevan al destino original o a /inicio.
  /// - noAutenticada: cualquier ruta protegida lleva a /login.
  static String? redireccion({required SessionStatus status, required Uri uri}) {
    final ruta = uri.path;
    switch (status) {
      case SessionStatus.verificando:
        if (ruta == cargando) return null;
        return Uri(
          path: cargando,
          queryParameters: {paramDesde: uri.toString()},
        ).toString();
      case SessionStatus.autenticada:
        if (ruta == cargando || publicas.contains(ruta)) {
          return destinoSeguro(uri.queryParameters[paramDesde]) ?? inicio;
        }
        return null;
      case SessionStatus.noAutenticada:
        if (ruta == cargando || esProtegida(ruta)) return login;
        return null;
    }
  }

  /// Solo acepta rutas internas y protegidas, para que "desde" no pueda usarse para
  /// redirigir a otro sitio (open redirect) ni de vuelta al login.
  static String? destinoSeguro(String? desde) {
    if (desde == null || !desde.startsWith('/') || desde.startsWith('//')) {
      return null;
    }
    final uri = Uri.tryParse(desde);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    return esProtegida(uri.path) ? desde : null;
  }
}
