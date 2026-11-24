import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Registra metodo, ruta, estatus y duracion de cada peticion (solo en dev).
///
/// A proposito NO registra headers, cuerpos, query strings ni mensajes de error de
/// Dio: ahi podrian ir tokens, contrasenas, codigos OTP o claves de idempotencia.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required this._logger, required this._enabled});

  final Logger _logger;
  final bool _enabled;

  static const _inicioKey = 'logging_inicio_ms';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      options.extra[_inicioKey] = DateTime.now().millisecondsSinceEpoch;
      _logger.d('--> ${options.method} ${_ruta(options)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (_enabled) {
      final options = response.requestOptions;
      _logger.d(
        '<-- ${response.statusCode} ${options.method} ${_ruta(options)} '
        '(${_duracion(options)} ms)',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      final options = err.requestOptions;
      final estatus = err.response?.statusCode?.toString() ?? err.type.name;
      _logger.w(
        '<-- $estatus ${options.method} ${_ruta(options)} '
        '(${_duracion(options)} ms)',
      );
    }
    handler.next(err);
  }

  /// Solo la ruta, sin dominio ni query string.
  static String _ruta(RequestOptions options) => options.uri.path;

  static int _duracion(RequestOptions options) {
    final inicio = options.extra[_inicioKey] as int?;
    return inicio == null ? 0 : DateTime.now().millisecondsSinceEpoch - inicio;
  }
}
