import 'package:flutter/foundation.dart';

/// Ambientes soportados.
enum AppEnv { dev, prod }

/// Configuracion leida en tiempo de compilacion con --dart-define(-from-file).
///
/// No contiene secretos ni valores por defecto sensibles: la URL de la API se
/// define por ambiente en config/dev.json y config/prod.json (fuera de Git).
abstract final class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// URL de la API. Si no se paso --dart-define-from-file (por ejemplo, con el boton
  /// Run del IDE) y la app corre en modo debug, usa el backend local. En release
  /// nunca hay valor por defecto: la URL siempre viene de config/*.json.
  static String get apiBaseUrl => resolverUrl(
        configurada: _apiBaseUrl,
        esDebug: kDebugMode,
        isWeb: kIsWeb,
        plataforma: defaultTargetPlatform,
      );

  /// Backend local de desarrollo. En el emulador de Android, "localhost" es el propio
  /// emulador; 10.0.2.2 es la computadora que lo ejecuta.
  static String resolverUrl({
    required String configurada,
    required bool esDebug,
    required bool isWeb,
    required TargetPlatform plataforma,
  }) {
    if (configurada.trim().isNotEmpty || !esDebug) return configurada;
    return !isWeb && plataforma == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  static AppEnv get env => parseEnv(_appEnv);
  static bool get isDev => env == AppEnv.dev;
  static bool get isProd => env == AppEnv.prod;

  /// Valida la configuracion al arrancar; lanza [StateError] con un mensaje claro.
  static void validate() =>
      validateConfig(baseUrl: apiBaseUrl, env: _appEnv, isWeb: kIsWeb);

  static AppEnv parseEnv(String valor) => switch (valor.trim().toLowerCase()) {
        'dev' => AppEnv.dev,
        'prod' => AppEnv.prod,
        _ => throw StateError(
            'APP_ENV="$valor" no es valido. Usa "dev" o "prod".',
          ),
      };

  /// Reglas:
  /// - En movil la URL es obligatoria (no existe un "mismo origen").
  /// - En web una URL vacia significa "mismo dominio que la API".
  /// - En prod la URL debe usar https.
  static void validateConfig({
    required String baseUrl,
    required String env,
    required bool isWeb,
  }) {
    final ambiente = parseEnv(env);
    final url = baseUrl.trim();

    if (url.isEmpty) {
      if (!isWeb) {
        throw StateError(
          'API_BASE_URL es obligatoria en movil. Ejecuta con '
          '--dart-define-from-file=config/dev.json',
        );
      }
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL="$url" no es una URL valida.');
    }
    if (ambiente == AppEnv.prod && uri.scheme != 'https') {
      throw StateError('En produccion API_BASE_URL debe usar https.');
    }
  }
}
