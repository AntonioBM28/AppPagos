import 'package:dio/dio.dart';

import 'csrf_cookie_reader.dart';

/// Solo en web: copia la cookie legible XSRF-TOKEN al header X-XSRF-TOKEN en las
/// peticiones que modifican datos.
///
/// Como en web la sesion viaja en una cookie que el navegador envia sola, el
/// servidor exige este header para comprobar que la peticion salio de la app y no
/// de otro sitio (proteccion CSRF).
class CsrfInterceptor extends Interceptor {
  CsrfInterceptor({required this._isWeb, String? Function()? cookieReader})
      : _leerCookie = cookieReader ?? readCsrfTokenCookie;

  final bool _isWeb;
  final String? Function() _leerCookie;

  static const _metodosQueModifican = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isWeb && _metodosQueModifican.contains(options.method.toUpperCase())) {
      final token = _leerCookie();
      if (token != null && token.isNotEmpty) {
        options.headers['X-XSRF-TOKEN'] = token;
      }
    }
    handler.next(options);
  }
}
