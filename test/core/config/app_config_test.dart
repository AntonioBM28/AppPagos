import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/config/app_config.dart';

void main() {
  group('AppConfig.validateConfig', () {
    test('en prod rechaza http', () {
      expect(
        () => AppConfig.validateConfig(
          baseUrl: 'http://api.ejemplo.com',
          env: 'prod',
          isWeb: false,
        ),
        throwsStateError,
      );
    });

    test('en prod acepta https', () {
      AppConfig.validateConfig(
        baseUrl: 'https://pwa-n2mh.onrender.com',
        env: 'prod',
        isWeb: false,
      );
    });

    test('en dev acepta http (backend local)', () {
      AppConfig.validateConfig(
        baseUrl: 'http://10.0.2.2:8080',
        env: 'dev',
        isWeb: false,
      );
    });

    test('en web una URL vacia significa mismo origen', () {
      AppConfig.validateConfig(baseUrl: '', env: 'prod', isWeb: true);
    });

    test('en movil la URL es obligatoria', () {
      expect(
        () => AppConfig.validateConfig(baseUrl: '', env: 'dev', isWeb: false),
        throwsStateError,
      );
    });

    test('rechaza URLs mal formadas y ambientes desconocidos', () {
      expect(
        () => AppConfig.validateConfig(
          baseUrl: 'pwa-n2mh.onrender.com',
          env: 'prod',
          isWeb: false,
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validateConfig(
          baseUrl: 'https://x.com',
          env: 'qa',
          isWeb: false,
        ),
        throwsStateError,
      );
    });
  });
}
