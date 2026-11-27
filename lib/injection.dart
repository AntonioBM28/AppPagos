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
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/entities/desafio_verificacion.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/cubit/login_cubit.dart';
import 'features/auth/presentation/cubit/verificacion_cubit.dart';
import 'features/catalogo/data/catalogo_repository_impl.dart';
import 'features/catalogo/domain/catalogo_repository.dart';
import 'features/catalogo/presentation/cubit/catalogo_cubit.dart';
import 'features/clientes/data/repositories/clientes_repository_impl.dart';
import 'features/compras/data/compras_repository_impl.dart';
import 'features/compras/domain/compra.dart';
import 'features/compras/presentation/compra_cubit.dart';
import 'features/compras/presentation/pages/nip_page.dart';
import 'features/historial/data/historial_repository_impl.dart';
import 'features/historial/domain/operacion.dart';
import 'features/historial/presentation/historial_cubit.dart';
import 'features/clientes/domain/repositories/clientes_repository.dart';
import 'features/clientes/domain/usecases/clientes_usecases.dart';
import 'features/clientes/presentation/cubit/clientes_cubits.dart';

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
    // ------------------------------------------------------------ Autenticacion
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(
        api: getIt<ApiClient>(),
        dispositivo: getIt<DeviceIdProvider>(),
        isWeb: isWeb,
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoto: getIt<AuthRemoteDataSource>(), sesion: getIt<SessionManager>()),
    )
    ..registerFactory(() => LoginCubit(IniciarSesion(getIt<AuthRepository>())))
    ..registerFactory(() => CerrarSesionCubit(CerrarSesion(getIt<AuthRepository>())))
    ..registerFactoryParam<VerificacionCubit, DesafioVerificacion, void>(
      (desafio, _) => VerificacionCubit(
        desafio: desafio,
        verificarCodigo: VerificarCodigo(getIt<AuthRepository>()),
        reenviarCodigo: ReenviarCodigo(getIt<AuthRepository>()),
      ),
    )
    // ------------------------------------------------------------ Clientes
    ..registerLazySingleton<ClientesRepository>(() => ClientesRepositoryImpl(getIt<ApiClient>()))
    ..registerLazySingleton<CatalogoRepository>(() => CatalogoRepositoryImpl(getIt<ApiClient>()))
    ..registerFactory(() => CatalogoCubit(ConsultarCatalogo(getIt<CatalogoRepository>())))
    ..registerLazySingleton<HistorialRepository>(() => HistorialRepositoryImpl(getIt<ApiClient>()))
    ..registerFactory(() => HistorialCubit(ConsultarHistorial(getIt<HistorialRepository>())))
    ..registerLazySingleton<ComprasRepository>(() => ComprasRepositoryImpl(getIt<ApiClient>()))
    ..registerFactory(() => NipCubit(getIt<ComprasRepository>()))
    ..registerFactory(
      () => CompraCubit(
        repositorio: getIt<ComprasRepository>(),
        misCuentas: () => getIt<ClientesRepository>().detalle(getIt<SessionManager>().datos?.clienteId ?? 0),
      ),
    )
    ..registerFactory(() => RegistroClienteCubit(RegistrarCliente(getIt<ClientesRepository>())))
    ..registerFactory(() => ClientesCubit(ConsultarClientes(getIt<ClientesRepository>())))
    ..registerFactory(() => EditarClienteCubit(ActualizarCliente(getIt<ClientesRepository>())))
    ..registerFactoryParam<ClienteDetalleCubit, int, void>(
      (id, _) => ClienteDetalleCubit(
        id: id,
        obtener: ObtenerCliente(getIt<ClientesRepository>()),
        cambiarEstatus: CambiarEstatusCliente(getIt<ClientesRepository>()),
        abonarSaldo: AbonarSaldo(getIt<ClientesRepository>()),
      ),
    )
    // ------------------------------------------------------------ Navegacion
    ..registerLazySingleton<GoRouter>(
      () => crearRouter(
        getIt<SessionManager>(),
        FabricasCubits(
          login: () => getIt<LoginCubit>(),
          verificacion: (desafio) => getIt<VerificacionCubit>(param1: desafio),
          cerrarSesion: () => getIt<CerrarSesionCubit>(),
          registroCliente: () => getIt<RegistroClienteCubit>(),
          clientes: () => getIt<ClientesCubit>(),
          clienteDetalle: (id) => getIt<ClienteDetalleCubit>(param1: id),
          editarCliente: () => getIt<EditarClienteCubit>(),
          consultarCodigoPostal: ConsultarCodigoPostal(getIt<ClientesRepository>()).call,
          catalogo: () => getIt<CatalogoCubit>(),
          historial: () => getIt<HistorialCubit>(),
          compra: () => getIt<CompraCubit>(),
          nip: () => getIt<NipCubit>(),
        ),
      ),
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
