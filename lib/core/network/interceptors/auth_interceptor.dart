import 'package:dio/dio.dart';

import '../../security/session_store.dart';
import '../api_endpoints.dart';

/// Agrega `Authorization: Bearer <token>` en movil.
///
/// En web no hace nada: la sesion viaja en una cookie HttpOnly que pone el servidor
/// y que JavaScript no puede leer.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._sessionStore,
    required this._isWeb,
    bool Function(String path, String metodo)? esPublica,
  }) : _esPublica = esPublica ?? ApiEndpoints.esPublica;

  final SessionStore _sessionStore;
  final bool _isWeb;
  final bool Function(String path, String metodo) _esPublica;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isWeb && !_esPublica(options.path, options.method)) {
      final token = await _sessionStore.leerToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
