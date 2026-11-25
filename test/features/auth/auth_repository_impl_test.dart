import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/network/api_client.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';
import 'package:pagosapp/core/security/device_id_provider.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/core/security/web_session_store.dart';
import 'package:pagosapp/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pagosapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pagosapp/features/auth/domain/entities/credenciales.dart';

import '../../helpers/fake_http.dart';

class _DispositivoFijo extends DeviceIdProvider {
  _DispositivoFijo() : super(isWeb: true);

  @override
  Future<String> obtener() async => 'dispositivo-1';
}

const _credenciales = Credenciales(correo: 'antonio@gmail.com', password: 'Linux123!');

Map<String, Object?> _desafio() => {
      'codigo': 0,
      'mensaje': 'Te enviamos un codigo',
      'desafioId': 'desafio-1',
      'correoEnmascarado': 'an***@gmail.com',
      'expiraEnSegundos': 300,
      'reenviarEnSegundos': 60,
    };

Map<String, Object?> _login({String? token}) => {
      'codigo': 0,
      'mensaje': 'Inicio de sesion exitoso',
      'token': ?token,
      'expiraEnSegundos': 3600,
      'usuario': 'antonio@gmail.com',
      'rol': 'EJECUTIVO',
      'clienteId': null,
    };

void main() {
  late SessionManager sesion;
  late WebSessionStore store;
  late FakeAdapter adapter;

  AuthRepositoryImpl repositorio(Responder responder, {bool isWeb = false}) {
    adapter = FakeAdapter(responder);
    final api = ApiClient(dioDePrueba(adapter, interceptores: [const ErrorInterceptor()]));
    return AuthRepositoryImpl(
      remoto: AuthRemoteDataSource(api: api, dispositivo: _DispositivoFijo(), isWeb: isWeb),
      sesion: sesion,
    );
  }

  setUp(() {
    store = WebSessionStore();
    sesion = SessionManager(store: store, isWeb: false);
  });

  tearDown(() => sesion.dispose());

  group('iniciarSesion', () {
    test('envia correo, contrasena, plataforma y dispositivo y devuelve el desafio', () async {
      final repo = repositorio((_) async => respuestaJson(202, _desafio()), isWeb: true);

      final resultado = await repo.iniciarSesion(_credenciales);

      final desafio = resultado.dataOrNull!;
      expect(desafio.id, 'desafio-1');
      expect(desafio.reenviarEn, const Duration(seconds: 60));
      final cuerpo = adapter.peticiones.single.data as Map<String, dynamic>;
      expect(cuerpo['plataforma'], 'WEB');
      expect(cuerpo['dispositivo'], 'dispositivo-1');
      expect(cuerpo['cerrarSesionAnterior'], false);
    });

    test('un 409 con sesionActiva se convierte en SesionActivaFailure', () async {
      final repo = repositorio(
        (_) async => respuestaJson(409, {
          'codigo': 1,
          'mensaje': 'Ya tienes una sesion activa en otro dispositivo',
          'sesionActiva': {'plataforma': 'MOVIL', 'iniciadaEn': '2026-11-24T18:00:00Z'},
        }),
      );

      final falla = (await repo.iniciarSesion(_credenciales)).failureOrNull;

      expect(falla, isA<SesionActivaFailure>());
      final sesionActiva = falla! as SesionActivaFailure;
      expect(sesionActiva.esMovil, isTrue);
      expect(sesionActiva.iniciadaEn, DateTime.utc(2026, 11, 24, 18).toLocal());
    });

    test('credenciales incorrectas devuelven el mensaje del servidor', () async {
      final repo = repositorio(
        (_) async => respuestaJson(401, {'codigo': 1, 'mensaje': 'Correo o contrasena incorrectos'}),
      );

      final falla = (await repo.iniciarSesion(_credenciales)).failureOrNull;

      expect(falla, const UnauthorizedFailure('Correo o contrasena incorrectos'));
    });
  });

  group('verificarCodigo', () {
    test('movil: guarda el token y abre la sesion', () async {
      final repo = repositorio((_) async => respuestaJson(200, _login(token: 'jwt-movil')));

      final resultado = await repo.verificarCodigo(desafioId: 'desafio-1', codigo: '123456');

      expect(resultado.isSuccess, isTrue);
      expect(sesion.status, SessionStatus.autenticada);
      expect(sesion.datos?.esEjecutivo, isTrue);
      // WebSessionStore se usa como doble: devuelve null aunque se le pase el token
      expect(await store.leerToken(), isNull);
    });

    test('un codigo ya usado (410) devuelve GoneFailure y no abre sesion', () async {
      final repo = repositorio(
        (_) async => respuestaJson(410, {'codigo': 1, 'mensaje': 'Este codigo ya se utilizo'}),
      );

      final falla = (await repo.verificarCodigo(desafioId: 'desafio-1', codigo: '123456')).failureOrNull;

      expect(falla, const GoneFailure('Este codigo ya se utilizo'));
      expect(sesion.status, isNot(SessionStatus.autenticada));
    });

    test('una respuesta sin datos de sesion es invalida', () async {
      final repo = repositorio((_) async => respuestaJson(200, {'codigo': 0, 'mensaje': 'ok'}));

      final falla = (await repo.verificarCodigo(desafioId: 'd', codigo: '123456')).failureOrNull;

      expect(falla, isA<InvalidResponseFailure>());
    });
  });

  test('reenviarCodigo: 429 conserva el tiempo de espera', () async {
    final repo = repositorio(
      (_) async => respuestaJson(
        429,
        {'codigo': 1, 'mensaje': 'Espera 40 segundos'},
        headers: {'retry-after': ['40']},
      ),
    );

    final falla = (await repo.reenviarCodigo('desafio-1')).failureOrNull;

    expect(falla, isA<TooManyRequestsFailure>().having((f) => f.retryAfterSeconds, 'retry', 40));
  });

  test('cerrarSesion borra la sesion local aunque el servidor falle', () async {
    final repo = repositorio((_) async => respuestaJson(500, {'codigo': 1, 'mensaje': 'x'}));
    await sesion.iniciar(
      SessionData(
        usuario: 'antonio@gmail.com',
        rol: 'EJECUTIVO',
        expiracion: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    await repo.cerrarSesion();

    expect(adapter.peticiones.single.path, '/auth/logout');
    expect(sesion.status, SessionStatus.noAutenticada);
  });
}
