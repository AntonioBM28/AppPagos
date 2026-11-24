import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/router/app_routes.dart';
import 'package:pagosapp/core/security/session_manager.dart';

String? _redireccion(SessionStatus status, String ubicacion) =>
    AppRoutes.redireccion(status: status, uri: Uri.parse(ubicacion));

void main() {
  group('mientras se verifica la sesion', () {
    test('toda ruta pasa por /cargando y recuerda el destino', () {
      expect(_redireccion(SessionStatus.verificando, '/historial'), '/cargando?desde=%2Fhistorial');
      expect(_redireccion(SessionStatus.verificando, '/cargando'), isNull);
    });
  });

  group('sin sesion', () {
    test('las rutas protegidas llevan a /login', () {
      for (final ruta in ['/inicio', '/catalogo', '/historial', '/perfil', '/cargando']) {
        expect(_redireccion(SessionStatus.noAutenticada, ruta), '/login', reason: ruta);
      }
    });

    test('el flujo de login es accesible', () {
      expect(_redireccion(SessionStatus.noAutenticada, '/login'), isNull);
      expect(_redireccion(SessionStatus.noAutenticada, '/verificar-codigo'), isNull);
    });
  });

  group('con sesion', () {
    test('las rutas protegidas se permiten', () {
      expect(_redireccion(SessionStatus.autenticada, '/catalogo'), isNull);
    });

    test('login y /cargando llevan a /inicio o al destino recordado', () {
      expect(_redireccion(SessionStatus.autenticada, '/login'), '/inicio');
      expect(
        _redireccion(SessionStatus.autenticada, '/cargando?desde=%2Fhistorial'),
        '/historial',
      );
    });
  });

  group('destinoSeguro evita redirecciones abiertas', () {
    test('solo acepta rutas internas protegidas', () {
      expect(AppRoutes.destinoSeguro('/perfil'), '/perfil');
      expect(AppRoutes.destinoSeguro('https://sitio-malicioso.com'), isNull);
      expect(AppRoutes.destinoSeguro('//sitio-malicioso.com'), isNull);
      expect(AppRoutes.destinoSeguro('/login'), isNull);
      expect(AppRoutes.destinoSeguro(null), isNull);
    });
  });
}
