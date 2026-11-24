import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import 'core/config/app_config.dart';
import 'core/error/exceptions.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';
import 'core/network/dio_factory.dart';
import 'core/router/app_router.dart';
import 'core/security/device_id_provider.dart';
import 'core/security/mobile_session_store.dart';
import 'core/security/session_data.dart';
import 'core/security/session_manager.dart';
import 'core/security/session_store.dart';
import 'core/security/web_session_store.dart';

/// Contenedor de dependencias. Solo se usa para armar los objetos al arrancar; las
/// pantallas reciben lo que necesitan por constructor o por BlocProvider.
final GetIt getIt = GetIt.instance;

void configurarDependencias({bool isWeb = kIsWeb}) {
  getIt
    ..registerLazySingleton<Logger>(
      () => Logger(
        // En produccion no se registra nada en consola.
        level: AppConfig.isDev ? Level.debug : Level.off,
        printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true),
      ),
    )
    ..registerLazySingleton<SessionStore>(
      () => isWeb ? WebSessionStore() : MobileSessionStore(),
    )
    ..registerLazySingleton<DeviceIdProvider>(
      () => DeviceIdProvider(isWeb: isWeb),
    )
    ..registerLazySingleton<SessionManager>(
      () => SessionManager(
        store: getIt<SessionStore>(),
        isWeb: isWeb,
        consultarSesionRemota: () => _consultarSesion(getIt<ApiClient>()),
      ),
    )
    ..registerLazySingleton<Dio>(
      () => crearDio(
        sessionStore: getIt<SessionStore>(),
        sessionManager: getIt<SessionManager>(),
        logger: getIt<Logger>(),
        isWeb: isWeb,
      ),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()))
    ..registerLazySingleton<GoRouter>(
      () => crearRouter(getIt<SessionManager>()),
    );
}

/// GET /auth/sesion: en web recupera la sesion a partir de la cookie HttpOnly.
/// Un 401 significa que no hay sesion activa.
Future<SessionData?> _consultarSesion(ApiClient api) async {
  try {
    final respuesta = await api.get(ApiEndpoints.sesion);
    return SessionData.fromApi(respuesta.data);
  } on UnauthorizedException {
    return null;
  }
}
