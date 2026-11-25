import 'package:dio/dio.dart';

import '../../security/session_manager.dart';
import '../api_endpoints.dart';

/// Un 401 en una ruta protegida significa que la sesion expiro o fue cerrada desde
/// otro dispositivo: se borra la sesion local y el router lleva al login.
class SessionInterceptor extends Interceptor {
  SessionInterceptor({
    required this._sessionManager,
    bool Function(String path, String metodo)? avisaExpiracion,
  }) : _avisaExpiracion = avisaExpiracion ?? ApiEndpoints.avisaExpiracion;

  final SessionManager _sessionManager;
  final bool Function(String path, String metodo) _avisaExpiracion;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        _avisaExpiracion(err.requestOptions.path, err.requestOptions.method)) {
      final body = err.response?.data;
      final mensaje = body is Map && body['mensaje'] is String ? body['mensaje'] as String : null;
      _sessionManager.notificarSesionExpirada(mensaje);
    }
    handler.next(err);
  }
}
