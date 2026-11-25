import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:pagosapp/core/network/interceptors/auth_interceptor.dart';
import 'package:pagosapp/core/network/interceptors/csrf_interceptor.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';
import 'package:pagosapp/core/network/interceptors/logging_interceptor.dart';
import 'package:pagosapp/core/network/interceptors/session_interceptor.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/core/security/web_session_store.dart';

import '../../helpers/fake_http.dart';

/// Store que solo entrega un token fijo.
class _StoreConToken extends WebSessionStore {
  @override
  Future<String?> leerToken() async => 'token-secreto';
}

/// Captura todo lo que se escribe en el log.
class _MemoriaLog extends LogOutput {
  final lineas = <String>[];

  @override
  void output(OutputEvent event) => lineas.addAll(event.lines);
}

Future<RequestOptions> _enviar(
  List<Interceptor> interceptores, {
  String metodo = 'POST',
  String ruta = '/cuentas/saldo',
}) async {
  final adapter = FakeAdapter((_) async => respuestaJson(200, {'codigo': 0, 'mensaje': 'ok'}));
  await dioDePrueba(adapter, interceptores: interceptores)
      .request<Object?>(ruta, options: Options(method: metodo), data: {});
  return adapter.peticiones.single;
}

void main() {
  group('AuthInterceptor', () {
    AuthInterceptor crear({required bool isWeb}) => AuthInterceptor(
          sessionStore: _StoreConToken(),
          isWeb: isWeb,
          esPublica: (ruta, _) => ruta == '/auth/login',
        );

    test('en movil agrega el Bearer en rutas protegidas', () async {
      final peticion = await _enviar([crear(isWeb: false)]);
      expect(peticion.headers['Authorization'], 'Bearer token-secreto');
    });

    test('no lo agrega en rutas publicas', () async {
      final peticion = await _enviar([crear(isWeb: false)], ruta: '/auth/login');
      expect(peticion.headers.containsKey('Authorization'), isFalse);
    });

    test('nunca lo agrega en web (la sesion va en cookie HttpOnly)', () async {
      final peticion = await _enviar([crear(isWeb: true)]);
      expect(peticion.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('CsrfInterceptor', () {
    CsrfInterceptor crear({required bool isWeb}) =>
        CsrfInterceptor(isWeb: isWeb, cookieReader: () => 'csrf-123');

    for (final metodo in ['POST', 'PUT', 'PATCH', 'DELETE']) {
      test('en web agrega X-XSRF-TOKEN en $metodo', () async {
        final peticion = await _enviar([crear(isWeb: true)], metodo: metodo);
        expect(peticion.headers['X-XSRF-TOKEN'], 'csrf-123');
      });
    }

    test('no lo agrega en GET', () async {
      final peticion = await _enviar([crear(isWeb: true)], metodo: 'GET');
      expect(peticion.headers.containsKey('X-XSRF-TOKEN'), isFalse);
    });

    test('no lo agrega en movil', () async {
      final peticion = await _enviar([crear(isWeb: false)]);
      expect(peticion.headers.containsKey('X-XSRF-TOKEN'), isFalse);
    });
  });

  group('SessionInterceptor', () {
    late SessionManager sesion;

    setUp(() async {
      sesion = SessionManager(store: WebSessionStore(), isWeb: false);
      await sesion.iniciar(
        SessionData(
          usuario: 'cliente@mail.com',
          rol: 'CLIENTE',
          clienteId: 1,
          expiracion: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
    });

    tearDown(() => sesion.dispose());

    Future<void> responder401(String ruta, {int estatus = 401}) async {
      final dio = dioDePrueba(
        FakeAdapter((_) async => respuestaJson(estatus, {'codigo': 1, 'mensaje': 'x'})),
        interceptores: [
          SessionInterceptor(
            sessionManager: sesion,
            avisaExpiracion: (r, _) => r != '/auth/sesion',
          ),
          const ErrorInterceptor(),
        ],
      );
      await expectLater(dio.get<Object?>(ruta), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);
    }

    test('un 401 en ruta protegida cierra la sesion con motivo expirada', () async {
      await responder401('/cuentas/saldo');
      expect(sesion.status, SessionStatus.noAutenticada);
      expect(sesion.motivoCierre, MotivoCierre.expirada);
    });

    test('un 401 de /auth/sesion no se trata como expiracion', () async {
      await responder401('/auth/sesion');
      expect(sesion.status, SessionStatus.autenticada);
    });

    test('un 403 no cierra la sesion', () async {
      await responder401('/cuentas/saldo', estatus: 403);
      expect(sesion.status, SessionStatus.autenticada);
    });
  });

  group('LoggingInterceptor', () {
    test('registra metodo, ruta y estatus sin headers ni datos sensibles', () async {
      final memoria = _MemoriaLog();
      final logger = Logger(output: memoria, printer: SimplePrinter(), level: Level.debug);
      final adapter = FakeAdapter((_) async => respuestaJson(200, {'codigo': 0, 'mensaje': 'ok'}));
      final dio = dioDePrueba(
        adapter,
        interceptores: [LoggingInterceptor(logger: logger, enabled: true)],
      );

      await dio.post<Object?>(
        '/auth/login?token=en-url',
        data: {'correo': 'a@b.com', 'password': 'Secreta#2026', 'codigo': '123456'},
        options: Options(
          headers: {
            'Authorization': 'Bearer token-secreto',
            'X-XSRF-TOKEN': 'csrf-123',
            'Idempotency-Key': 'clave-unica',
          },
        ),
      );

      final log = memoria.lineas.join('\n');
      expect(log, contains('POST /auth/login'));
      expect(log, contains('200'));
      for (final sensible in [
        'token-secreto',
        'Bearer',
        'csrf-123',
        'clave-unica',
        'Secreta#2026',
        '123456',
        'en-url',
        'a@b.com',
      ]) {
        expect(log, isNot(contains(sensible)), reason: 'El log no debe incluir "$sensible"');
      }
    });

    test('deshabilitado no registra nada (produccion)', () async {
      final memoria = _MemoriaLog();
      final logger = Logger(output: memoria, printer: SimplePrinter(), level: Level.debug);
      await _enviar([LoggingInterceptor(logger: logger, enabled: false)]);
      expect(memoria.lineas, isEmpty);
    });
  });
}
