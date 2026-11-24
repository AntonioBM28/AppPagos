import 'package:dio/dio.dart';

import '../../error/exceptions.dart';

/// Convierte cualquier [DioException] en una [AppException] con un mensaje para el
/// usuario. La excepcion propia viaja en [DioException.error] y [ApiClient] la extrae.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = mapDioException(err);
    handler.next(
      err.copyWith(error: exception, message: exception.message),
    );
  }

  /// Expuesto para pruebas: misma regla que usa el interceptor.
  static AppException mapDioException(DioException err) {
    if (err.error is AppException) return err.error! as AppException;
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        const AppTimeoutException(),
      DioExceptionType.cancel => const RequestCancelledException(),
      DioExceptionType.badCertificate => const NetworkException(
          'No fue posible establecer una conexión segura con el servidor',
        ),
      DioExceptionType.badResponse => _porEstatus(err.response),
      DioExceptionType.connectionError ||
      DioExceptionType.unknown =>
        const NetworkException(),
    };
  }

  static AppException _porEstatus(Response<dynamic>? response) {
    final status = response?.statusCode ?? 0;
    final mensaje = _mensajeDeApi(response?.data);

    return switch (status) {
      400 => mensaje == null
          ? const ValidationException()
          : ValidationException(mensaje),
      401 => mensaje == null
          ? const UnauthorizedException()
          : UnauthorizedException(mensaje),
      403 => mensaje == null
          ? const ForbiddenException()
          : ForbiddenException(mensaje),
      404 => mensaje == null
          ? const NotFoundException()
          : NotFoundException(mensaje),
      409 => mensaje == null
          ? const ConflictException()
          : ConflictException(mensaje),
      413 => mensaje == null
          ? const PayloadTooLargeException()
          : PayloadTooLargeException(mensaje),
      422 => mensaje == null
          ? const BusinessRuleException()
          : BusinessRuleException(mensaje),
      429 => mensaje == null
          ? TooManyRequestsException(
              retryAfterSeconds: _retryAfter(response),
            )
          : TooManyRequestsException(
              message: mensaje,
              retryAfterSeconds: _retryAfter(response),
            ),
      // Para 5xx no se usa el mensaje de la API: el generico es suficiente y evita
      // mostrar textos de servicios externos.
      >= 500 => const ServerException(),
      _ => mensaje == null
          ? const ServerException()
          : ServerException(mensaje),
    };
  }

  /// Solo toma "mensaje" si la respuesta respeta el sobre de la API.
  static String? _mensajeDeApi(Object? body) {
    if (body is Map && body['codigo'] is int) {
      final mensaje = body['mensaje'];
      if (mensaje is String && mensaje.trim().isNotEmpty) return mensaje;
    }
    return null;
  }

  static int? _retryAfter(Response<dynamic>? response) {
    final valor = response?.headers.value('retry-after');
    return valor == null ? null : int.tryParse(valor.trim());
  }
}
