import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import 'interceptors/error_interceptor.dart';

/// Respuesta valida de la API: el cuerpo ya paso la validacion del sobre.
class ApiResponse {
  const ApiResponse({required this.statusCode, required this.data});

  /// Se conserva porque distingue casos con el mismo sobre, por ejemplo 201
  /// (compra aprobada) frente a 202 (compra pendiente).
  final int statusCode;
  final Map<String, dynamic> data;

  String? get mensaje => data['mensaje'] as String?;
}

/// Unico punto de acceso HTTP de la app. Las fuentes de datos remotas lo usan en
/// lugar de Dio directamente, asi todas las respuestas se validan igual.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse> get(String path, {CancelToken? cancelToken}) =>
      _enviar(() => _dio.get<Object?>(path, cancelToken: cancelToken));

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) =>
      _enviar(
        () => _dio.post<Object?>(
          path,
          data: body ?? const <String, dynamic>{},
          options: Options(headers: headers),
          cancelToken: cancelToken,
        ),
      );

  Future<ApiResponse> patch(
    String path, {
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  }) =>
      _enviar(
        () => _dio.patch<Object?>(path, data: body, cancelToken: cancelToken),
      );

  Future<ApiResponse> _enviar(Future<Response<Object?>> Function() peticion) async {
    try {
      final response = await peticion();
      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        data: validarSobre(response.data),
      );
    } on DioException catch (e) {
      throw ErrorInterceptor.mapDioException(e);
    }
  }

  /// Toda respuesta exitosa debe traer el sobre { "codigo": 0, "mensaje": ... }.
  static Map<String, dynamic> validarSobre(Object? body) {
    if (body is! Map<String, dynamic> || body['codigo'] is! int) {
      throw const InvalidResponseException();
    }
    if (body['codigo'] != 0) {
      final mensaje = body['mensaje'];
      throw mensaje is String && mensaje.isNotEmpty
          ? BusinessRuleException(mensaje)
          : const BusinessRuleException();
    }
    return body;
  }
}
