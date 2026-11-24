import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../security/session_manager.dart';
import '../security/session_store.dart';
import 'dio_adapter.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/csrf_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/session_interceptor.dart';

/// Construye el Dio de la app con tiempos de espera, adaptador por plataforma e
/// interceptores en el orden correcto.
Dio crearDio({
  required SessionStore sessionStore,
  required SessionManager sessionManager,
  required Logger logger,
  required bool isWeb,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );

  // En web: BrowserHttpClientAdapter con withCredentials para enviar la cookie.
  final adapter = createPlatformHttpClientAdapter();
  if (adapter != null) dio.httpClientAdapter = adapter;

  dio.interceptors.addAll([
    LoggingInterceptor(logger: logger, enabled: AppConfig.isDev),
    AuthInterceptor(sessionStore: sessionStore, isWeb: isWeb),
    CsrfInterceptor(isWeb: isWeb),
    SessionInterceptor(sessionManager: sessionManager),
    const ErrorInterceptor(),
  ]);
  return dio;
}
