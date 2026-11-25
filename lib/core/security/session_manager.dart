import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_data.dart';
import 'session_store.dart';

/// Estado de la sesion que observa la navegacion.
enum SessionStatus {
  /// Al arrancar, mientras se recupera la sesion: no se muestra ninguna pantalla protegida.
  verificando,
  autenticada,
  noAutenticada,
}

/// Por que se cerro la sesion; la pantalla de login lo usa para explicarlo.
enum MotivoCierre { ninguno, expirada }

/// Consulta al servidor la sesion activa (GET /auth/sesion). Devuelve null si no hay.
typedef ConsultaSesionRemota = Future<SessionData?> Function();

/// Fuente unica de verdad sobre la sesion.
///
/// Es un [ChangeNotifier] para que go_router se refresque al cambiar el estado, y
/// expone ademas un [Stream] para quien prefiera escucharlo asi.
class SessionManager extends ChangeNotifier {
  SessionManager({
    required this._store,
    required this._isWeb,
    this._consultarSesionRemota,
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final SessionStore _store;
  final bool _isWeb;
  final ConsultaSesionRemota? _consultarSesionRemota;
  final DateTime Function() _reloj;
  final _cambios = StreamController<SessionStatus>.broadcast();

  static const mensajeExpiracion = 'Tu sesión expiró o fue cerrada. Inicia sesión de nuevo';

  SessionStatus _status = SessionStatus.verificando;
  MotivoCierre _motivoCierre = MotivoCierre.ninguno;
  String? _mensajeCierre;
  SessionData? _datos;
  Timer? _temporizador;

  SessionStatus get status => _status;
  MotivoCierre get motivoCierre => _motivoCierre;

  /// Explicacion para el usuario cuando [motivoCierre] es expirada (por ejemplo, el
  /// servidor indica que se inicio sesion en otro dispositivo).
  String? get mensajeCierre =>
      _motivoCierre == MotivoCierre.expirada ? (_mensajeCierre ?? mensajeExpiracion) : null;
  SessionData? get datos => _datos;
  bool get estaAutenticada => _status == SessionStatus.autenticada;
  Stream<SessionStatus> get cambios => _cambios.stream;

  /// Recupera la sesion al abrir la app. En web pregunta al servidor (la cookie
  /// viaja sola); en movil lee el almacenamiento seguro y revisa la expiracion.
  Future<void> restaurar() async {
    _emitir(SessionStatus.verificando);
    SessionData? datos;
    try {
      datos = _isWeb
          ? await _consultarSesionRemota?.call()
          : await _store.leerDatos();
    } on Object {
      datos = null; // sin red o respuesta invalida: se pide iniciar sesion
    }

    if (datos == null || datos.estaExpirada(_reloj())) {
      await _store.borrar();
      _datos = null;
      _emitir(SessionStatus.noAutenticada);
      return;
    }
    if (_isWeb) await _store.guardar(datos: datos);
    _activar(datos);
  }

  /// Registra una sesion nueva (tras el login).
  Future<void> iniciar(SessionData datos, {String? token}) async {
    await _store.guardar(datos: datos, token: token);
    _motivoCierre = MotivoCierre.ninguno;
    _activar(datos);
  }

  /// Cierre voluntario de sesion.
  Future<void> cerrar() => _cerrar(MotivoCierre.ninguno);

  /// La sesion expiro o el servidor respondio 401 (por ejemplo, se cerro desde otro
  /// dispositivo). [mensaje] es la explicacion del servidor, si la hay.
  void notificarSesionExpirada([String? mensaje]) {
    if (_status == SessionStatus.noAutenticada) return;
    unawaited(_cerrar(MotivoCierre.expirada, mensaje));
  }

  /// La pantalla de login llama esto despues de mostrar el aviso.
  void limpiarMotivoCierre() {
    _motivoCierre = MotivoCierre.ninguno;
    _mensajeCierre = null;
  }

  Future<void> _cerrar(MotivoCierre motivo, [String? mensaje]) async {
    _temporizador?.cancel();
    _datos = null;
    _motivoCierre = motivo;
    _mensajeCierre = mensaje;
    await _store.borrar();
    _emitir(SessionStatus.noAutenticada);
  }

  void _activar(SessionData datos) {
    _datos = datos;
    _temporizador?.cancel();
    final restante = datos.expiracion.difference(_reloj());
    _temporizador = Timer(restante, () => notificarSesionExpirada());
    _emitir(SessionStatus.autenticada);
  }

  void _emitir(SessionStatus status) {
    _status = status;
    if (!_cambios.isClosed) _cambios.add(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    unawaited(_cambios.close());
    super.dispose();
  }
}
