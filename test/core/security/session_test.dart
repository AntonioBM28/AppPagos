import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/security/mobile_session_store.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/core/security/web_session_store.dart';

SessionData _datos({Duration vigencia = const Duration(hours: 1)}) => SessionData(
      usuario: 'cliente@mail.com',
      rol: 'CLIENTE',
      clienteId: 7,
      expiracion: DateTime.now().add(vigencia),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionData', () {
    test('fromApi calcula la expiracion a partir de expiraEnSegundos', () {
      final ahora = DateTime(2026, 1, 1, 12);
      final datos = SessionData.fromApi(
        const {'usuario': 'u@mail.com', 'rol': 'EJECUTIVO', 'clienteId': null, 'expiraEnSegundos': 3600},
        ahora: ahora,
      );
      expect(datos.expiracion, DateTime(2026, 1, 1, 13));
      expect(datos.esEjecutivo, isTrue);
      expect(datos.estaExpirada(DateTime(2026, 1, 1, 13)), isTrue);
    });

    test('fromApi rechaza respuestas incompletas', () {
      expect(() => SessionData.fromApi(const {'usuario': 'u'}), throwsFormatException);
    });
  });

  group('WebSessionStore', () {
    test('nunca guarda ni devuelve el token', () async {
      final store = WebSessionStore();
      final datos = _datos();
      await store.guardar(datos: datos, token: 'jwt-que-no-debe-guardarse');

      expect(await store.leerToken(), isNull);
      expect(await store.leerDatos(), datos);
    });
  });

  group('MobileSessionStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('guarda, lee y borra token y datos', () async {
      final store = MobileSessionStore();
      final datos = _datos();
      await store.guardar(datos: datos, token: 'jwt');

      expect(await store.leerToken(), 'jwt');
      expect(await store.leerDatos(), datos);

      await store.borrar();
      expect(await store.leerToken(), isNull);
      expect(await store.leerDatos(), isNull);
    });

    test('descarta datos corruptos', () async {
      FlutterSecureStorage.setMockInitialValues({'sesion_datos': '{no es json'});
      expect(await MobileSessionStore().leerDatos(), isNull);
    });
  });

  group('SessionManager', () {
    test('movil: restaura una sesion vigente', () async {
      final store = WebSessionStore();
      await store.guardar(datos: _datos());
      final sesion = SessionManager(store: store, isWeb: false);

      await sesion.restaurar();

      expect(sesion.status, SessionStatus.autenticada);
      sesion.dispose();
    });

    test('movil: una sesion expirada se borra', () async {
      final store = WebSessionStore();
      await store.guardar(datos: _datos(vigencia: const Duration(minutes: -1)));
      final sesion = SessionManager(store: store, isWeb: false);

      await sesion.restaurar();

      expect(sesion.status, SessionStatus.noAutenticada);
      expect(await store.leerDatos(), isNull);
      sesion.dispose();
    });

    test('web: recupera la sesion del servidor', () async {
      final store = WebSessionStore();
      final sesion = SessionManager(
        store: store,
        isWeb: true,
        consultarSesionRemota: () async => _datos(),
      );

      await sesion.restaurar();

      expect(sesion.status, SessionStatus.autenticada);
      expect(sesion.datos?.clienteId, 7);
      expect(await store.leerToken(), isNull);
      sesion.dispose();
    });

    test('web: sin sesion en el servidor o sin red queda sin autenticar', () async {
      final sinSesion = SessionManager(
        store: WebSessionStore(),
        isWeb: true,
        consultarSesionRemota: () async => null,
      );
      final sinRed = SessionManager(
        store: WebSessionStore(),
        isWeb: true,
        consultarSesionRemota: () async => throw Exception('sin red'),
      );

      await sinSesion.restaurar();
      await sinRed.restaurar();

      expect(sinSesion.status, SessionStatus.noAutenticada);
      expect(sinRed.status, SessionStatus.noAutenticada);
      sinSesion.dispose();
      sinRed.dispose();
    });

    test('expira sola cuando se cumple la vigencia', () async {
      final sesion = SessionManager(store: WebSessionStore(), isWeb: false);
      await sesion.iniciar(_datos(vigencia: const Duration(milliseconds: 50)));
      expect(sesion.status, SessionStatus.autenticada);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(sesion.status, SessionStatus.noAutenticada);
      expect(sesion.motivoCierre, MotivoCierre.expirada);
      sesion.dispose();
    });

    test('cerrar sesion voluntariamente no marca expiracion', () async {
      final sesion = SessionManager(store: WebSessionStore(), isWeb: false);
      await sesion.iniciar(_datos());

      await sesion.cerrar();

      expect(sesion.status, SessionStatus.noAutenticada);
      expect(sesion.motivoCierre, MotivoCierre.ninguno);
      sesion.dispose();
    });
  });
}
