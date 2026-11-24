import 'session_data.dart';
import 'session_store.dart';

/// Flutter Web: el token vive en una cookie HttpOnly que el navegador envia solo y
/// que JavaScript no puede leer, asi un ataque XSS no puede robarlo.
///
/// Aqui solo se guardan en memoria los datos NO sensibles. No se usa localStorage,
/// sessionStorage ni flutter_secure_storage. Al recargar la pagina, la sesion se
/// recupera con GET /auth/sesion.
class WebSessionStore implements SessionStore {
  SessionData? _datos;

  @override
  Future<void> guardar({required SessionData datos, String? token}) async {
    _datos = datos; // el token se ignora a proposito
  }

  @override
  Future<String?> leerToken() async => null;

  @override
  Future<SessionData?> leerDatos() async => _datos;

  @override
  Future<void> borrar() async => _datos = null;
}
