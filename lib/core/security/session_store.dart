import 'session_data.dart';

/// Donde se guarda la sesion. Hay una implementacion por plataforma:
/// [MobileSessionStore] (almacenamiento seguro del sistema) y [WebSessionStore]
/// (solo memoria; el token vive en una cookie HttpOnly).
abstract interface class SessionStore {
  /// En web [token] se ignora a proposito.
  Future<void> guardar({required SessionData datos, String? token});

  /// Token Bearer; siempre null en web.
  Future<String?> leerToken();

  Future<SessionData?> leerDatos();

  Future<void> borrar();
}
