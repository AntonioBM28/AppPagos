import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef Responder = Future<ResponseBody> Function(RequestOptions options);

/// Adaptador HTTP falso: registra las peticiones y responde lo que indique la prueba.
/// Ninguna prueba llama a la API real.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this._responder);

  final Responder _responder;
  final List<RequestOptions> peticiones = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    peticiones.add(options);
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody respuestaJson(
  int status,
  Object? body, {
  Map<String, List<String>> headers = const {},
}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );

ResponseBody respuestaTexto(int status, String body) =>
    ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );

Dio dioDePrueba(FakeAdapter adapter, {List<Interceptor> interceptores = const []}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.prueba.local'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll(interceptores);
  return dio;
}
