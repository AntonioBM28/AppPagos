import '../security/session_manager.dart';

/// Rutas de la app y regla de redireccion segun el estado de la sesion y el rol.
abstract final class AppRoutes {
  static const cargando = '/cargando';
  static const login = '/login';
  static const verificarCodigo = '/verificar-codigo';
  static const registro = '/registro';
  static const inicio = '/inicio';
  static const clientes = '/clientes';
  static const catalogo = '/catalogo';
  static const historial = '/historial';
  static const perfil = '/perfil';
  static const misDatos = '/perfil/datos';

  /// Compra de un producto del catalogo (solo CLIENTE; el producto viaja en `extra`).
  static const compra = '$catalogo/comprar';

  /// Configurar o cambiar el NIP de transacciones (solo CLIENTE).
  static const nipTransacciones = '$perfil/nip';

  static String clienteDetalle(int id) => '$clientes/$id';
  static String clienteEditar(int id) => '$clientes/$id/editar';
  static const clienteNuevo = '$clientes/nuevo';

  /// Accesibles sin sesion: inicio de sesion y autoregistro.
  static const publicas = {login, verificarCodigo, registro};

  /// Parametro que recuerda a donde iba el usuario antes de pasar por /cargando.
  static const paramDesde = 'desde';

  static bool esProtegida(String path) =>
      path != cargando && !publicas.contains(path);

  static bool soloEjecutivo(String path) => path == clientes || path.startsWith('$clientes/');

  /// El ejecutivo no compra ni tiene NIP de transacciones.
  static bool soloCliente(String path) => path == compra || path == nipTransacciones;

  /// Decide la redireccion. Devuelve null si la ruta pedida es valida.
  ///
  /// - verificando: todo pasa por /cargando, asi nunca se pinta una pantalla
  ///   protegida antes de confirmar la sesion (importante al refrescar en web).
  /// - autenticada: el flujo de login y /cargando llevan al destino original o a /inicio;
  ///   la administracion de clientes es solo del EJECUTIVO.
  /// - noAutenticada: cualquier ruta protegida lleva a /login.
  static String? redireccion({
    required SessionStatus status,
    required Uri uri,
    bool esEjecutivo = false,
  }) {
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
          final destino = destinoSeguro(uri.queryParameters[paramDesde]);
          final rutaDestino = destino == null ? null : Uri.parse(destino).path;
          return rutaDestino != null && _permitida(rutaDestino, esEjecutivo) ? destino : inicio;
        }
        if (!_permitida(ruta, esEjecutivo)) return inicio;
        return null;
      case SessionStatus.noAutenticada:
        if (ruta == cargando || esProtegida(ruta)) return login;
        return null;
    }
  }

  static bool _permitida(String ruta, bool esEjecutivo) =>
      esEjecutivo ? !soloCliente(ruta) : !soloEjecutivo(ruta);

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
