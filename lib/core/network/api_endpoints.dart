/// Rutas del backend. Todas se declaran aqui para no repetir cadenas en el codigo.
///
/// La API no usa parametros en la URL ni query strings: las consultas son POST con
/// un cuerpo JSON. Cada parte del proyecto agrega aqui las rutas que necesita.
abstract final class ApiEndpoints {
  // ---------------------------------------------------------------- Autenticacion
  /// POST: paso 1, correo y contrasena. Envia el codigo por correo.
  static const String login = '/auth/login';

  /// POST: paso 2, codigo de verificacion. Abre la sesion.
  static const String verificarCodigo = '/auth/verificar-codigo';

  /// POST: envia un codigo nuevo para el mismo desafio.
  static const String reenviarCodigo = '/auth/reenviar-codigo';

  /// GET: recupera la sesion activa (en web, a partir de la cookie HttpOnly).
  static const String sesion = '/auth/sesion';

  /// POST: cierra la sesion en el servidor.
  static const String logout = '/auth/logout';

  // ---------------------------------------------------------------- Clientes
  /// POST: alta (publica, para el autoregistro). PATCH: actualizacion (protegida).
  static const String clientes = '/clientes';

  /// POST: busqueda paginada con filtros (EJECUTIVO).
  static const String clientesConsulta = '/clientes/consulta';

  /// POST: detalle de un cliente con su domicilio y cuentas.
  static const String clientesDetalle = '/clientes/detalle';

  /// POST: estado, municipio y colonias de un codigo postal (publica).
  static const String codigosPostales = '/codigos-postales/consulta';

  /// POST: consulta del catalogo de productos con filtros (solo lectura).
  static const String productosConsulta = '/productos/consulta';

  /// POST: historial de operaciones (ejecutivo: de todos los clientes; cliente: las suyas).
  static const String historial = '/transacciones/historial';

  /// GET estado / POST alta / PATCH cambio del NIP de transacciones (solo CLIENTE).
  static const String nip = '/nip';

  /// POST: confirma una compra con el NIP y devuelve el token dinamico.
  static const String autorizacionCompra = '/transacciones/autorizacion';

  /// POST: ejecuta la compra con el token dinamico (header Idempotency-Key).
  static const String transacciones = '/transacciones';

  /// POST: abono de saldo a una cuenta (solo EJECUTIVO).
  static const String cuentasAbonos = '/cuentas/abonos';

  /// Peticiones que no requieren sesion, como "METODO ruta": no llevan Authorization y
  /// un 401 en ellas no significa que la sesion expiro. Se incluye el metodo porque
  /// /clientes es publico para registrarse (POST) pero protegido para actualizar (PATCH).
  static const Set<String> publicas = <String>{
    'POST $login',
    'POST $verificarCodigo',
    'POST $reenviarCodigo',
    'POST $clientes',
    'POST $codigosPostales',
  };

  /// Rutas cuyo 401 no debe mostrarse como "tu sesion expiro": [sesion] devuelve 401
  /// cuando simplemente no hay sesion (primera visita en web) y [logout] cuando la
  /// sesion ya estaba cerrada.
  static const Set<String> sinAvisoDeExpiracion = <String>{sesion, logout};

  static bool esPublica(String path, String metodo) =>
      publicas.contains('${metodo.toUpperCase()} ${_normalizar(path)}');

  static bool avisaExpiracion(String path, String metodo) {
    final ruta = _normalizar(path);
    return !esPublica(ruta, metodo) && !sinAvisoDeExpiracion.contains(ruta);
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
