import 'package:dio/dio.dart';

import '../../security/session_manager.dart';
import '../api_endpoints.dart';

/// Un 401 en una ruta protegida significa que la sesion expiro o fue cerrada desde
/// otro dispositivo: se borra la sesion local y el router lleva al login.
class SessionInterceptor extends Interceptor {
  SessionInterceptor({
    required this._sessionManager,
    bool Function(String path)? avisaExpiracion,
  }) : _avisaExpiracion = avisaExpiracion ?? ApiEndpoints.avisaExpiracion;

  final SessionManager _sessionManager;
  final bool Function(String path) _avisaExpiracion;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        _avisaExpiracion(err.requestOptions.path)) {
      _sessionManager.notificarSesionExpirada();
    }
    handler.next(err);
  }
}
