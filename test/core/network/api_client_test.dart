import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/error/exceptions.dart';
import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/network/api_client.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';

import '../../helpers/fake_http.dart';

void main() {
  ApiClient clienteQueResponde(Responder responder) => ApiClient(
        dioDePrueba(
          FakeAdapter(responder),
          interceptores: [const ErrorInterceptor()],
        ),
      );

  Map<String, Object> error(String mensaje) => {'codigo': 1, 'mensaje': mensaje};

  group('respuestas exitosas', () {
    test('devuelve el cuerpo y conserva el estatus (202 = pendiente)', () async {
      final api = clienteQueResponde(
        (_) async => respuestaJson(202, {'codigo': 0, 'mensaje': 'Pendiente', 'id': 'x'}),
      );

      final respuesta = await api.post('/transacciones');

      expect(respuesta.statusCode, 202);
      expect(respuesta.data['id'], 'x');
      expect(respuesta.mensaje, 'Pendiente');
    });

    test('sin el sobre {codigo} lanza InvalidResponseException', () async {
      final api = clienteQueResponde((_) async => respuestaJson(200, {'id': 1}));
      await expectLater(api.get('/x'), throwsA(isA<InvalidResponseException>()));
    });

    test('un cuerpo que no es JSON lanza InvalidResponseException', () async {
      final api = clienteQueResponde((_) async => respuestaTexto(200, '<html></html>'));
      await expectLater(api.get('/x'), throwsA(isA<InvalidResponseException>()));
    });

    test('codigo distinto de 0 con estatus 2xx se trata como error de negocio', () async {
      final api = clienteQueResponde((_) async => respuestaJson(200, error('No permitido')));
      await expectLater(
        api.get('/x'),
        throwsA(isA<BusinessRuleException>().having((e) => e.message, 'message', 'No permitido')),
      );
    });
  });

  group('errores HTTP', () {
    final casos = <int, TypeMatcher<AppException>>{
      400: isA<ValidationException>(),
      401: isA<UnauthorizedException>(),
      403: isA<ForbiddenException>(),
      404: isA<NotFoundException>(),
      409: isA<ConflictException>(),
      413: isA<PayloadTooLargeException>(),
      422: isA<BusinessRuleException>(),
    };

    casos.forEach((estatus, esperado) {
      test('$estatus usa el mensaje de la API', () async {
        final api = clienteQueResponde(
          (_) async => respuestaJson(estatus, error('Mensaje $estatus')),
        );
        await expectLater(
          api.post('/x'),
          throwsA(esperado.having((e) => e.message, 'message', 'Mensaje $estatus')),
        );
      });
    });

    test('429 lee Retry-After', () async {
      final api = clienteQueResponde(
        (_) async => respuestaJson(
          429,
          error('Demasiados intentos'),
          headers: {'retry-after': ['30']},
        ),
      );
      await expectLater(
        api.post('/x'),
        throwsA(
          isA<TooManyRequestsException>()
              .having((e) => e.retryAfterSeconds, 'retryAfter', 30)
              .having((e) => e.message, 'message', 'Demasiados intentos'),
        ),
      );
    });

    for (final estatus in [500, 502, 503, 504]) {
      test('$estatus usa un mensaje generico, sin texto del servidor', () async {
        final api = clienteQueResponde(
          (_) async => respuestaJson(estatus, error('NullPointerException en GestoPago')),
        );
        await expectLater(
          api.get('/x'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'El servicio no está disponible, intenta más tarde',
            ),
          ),
        );
      });
    }

    test('sin sobre en el error usa el mensaje por defecto', () async {
      final api = clienteQueResponde((_) async => respuestaTexto(404, 'Not Found'));
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<NotFoundException>()
              .having((e) => e.message, 'message', 'El recurso solicitado no existe'),
        ),
      );
    });
  });

  group('errores de red', () {
    test('timeout', () async {
      final api = clienteQueResponde(
        (o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      await expectLater(api.get('/x'), throwsA(isA<AppTimeoutException>()));
    });

    test('sin conexion', () async {
      final api = clienteQueResponde(
        (_) async => throw const SocketException('Failed host lookup'),
      );
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<NetworkException>()
              .having((e) => e.message, 'message', 'Revisa tu conexión a internet'),
        ),
      );
    });
  });

  test('Failure.fromException conserva mensaje y Retry-After', () {
    expect(
      Failure.fromException(const TooManyRequestsException(retryAfterSeconds: 10)),
      isA<TooManyRequestsFailure>().having((f) => f.retryAfterSeconds, 'retry', 10),
    );
    expect(
      Failure.fromException(const ValidationException('Dato invalido')),
      const ValidationFailure('Dato invalido'),
    );
  });
}
