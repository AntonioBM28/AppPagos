import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/domain/entities/desafio_verificacion.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/verificacion_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/verificar_codigo_page.dart';
import '../../features/catalogo/domain/entities/producto.dart';
import '../../features/catalogo/presentation/cubit/catalogo_cubit.dart';
import '../../features/catalogo/presentation/pages/catalogo_page.dart';
import '../../features/clientes/domain/entities/cliente.dart';
import '../../features/compras/presentation/compra_cubit.dart';
import '../../features/compras/presentation/pages/compra_page.dart';
import '../../features/compras/presentation/pages/nip_page.dart';
import '../../features/clientes/presentation/cubit/clientes_cubits.dart';
import '../../features/clientes/presentation/pages/cliente_detalle_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/clientes/presentation/pages/editar_cliente_page.dart';
import '../../features/clientes/presentation/pages/registro_cliente_page.dart';
import '../../features/historial/presentation/historial_cubit.dart';
import '../../features/historial/presentation/pages/historial_page.dart';
import '../../features/inicio/presentation/pages/inicio_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../result/result.dart';
import '../security/session_manager.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Fabricas de los Cubits que usan las pantallas. Se reciben desde fuera para que el
/// router no dependa del contenedor de dependencias y se pueda probar con dobles.
class FabricasCubits {
  const FabricasCubits({
    required this.login,
    required this.verificacion,
    required this.cerrarSesion,
    required this.registroCliente,
    required this.clientes,
    required this.clienteDetalle,
    required this.editarCliente,
    required this.consultarCodigoPostal,
    required this.catalogo,
    required this.historial,
    required this.compra,
    required this.nip,
  });

  final LoginCubit Function() login;
  final VerificacionCubit Function(DesafioVerificacion desafio) verificacion;
  final CerrarSesionCubit Function() cerrarSesion;
  final RegistroClienteCubit Function() registroCliente;
  final ClientesCubit Function() clientes;
  final ClienteDetalleCubit Function(int id) clienteDetalle;
  final EditarClienteCubit Function() editarCliente;
  final Future<Result<InfoCodigoPostal>> Function(String codigoPostal) consultarCodigoPostal;
  final CatalogoCubit Function() catalogo;
  final HistorialCubit Function() historial;
  final CompraCubit Function() compra;
  final NipCubit Function() nip;
}

/// Crea el router. Se vuelve a evaluar el redirect cada vez que cambia la sesion.
GoRouter crearRouter(SessionManager sesion, FabricasCubits cubits) {
  bool esEjecutivo() => sesion.datos?.esEjecutivo ?? false;

  Widget detalle(int id, {required String titulo, required String Function(int) rutaEditar, bool administrar = false}) =>
      BlocProvider(
        create: (_) => cubits.clienteDetalle(id),
        child: Builder(
          builder: (context) => ClienteDetallePage(
            titulo: titulo,
            puedeCambiarEstatus: administrar,
            onEditar: (id) => context.push<ClienteDetalle>(rutaEditar(id)),
          ),
        ),
      );

  Widget editar(int id) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => cubits.clienteDetalle(id)),
          BlocProvider(create: (_) => cubits.editarCliente()),
        ],
        child: Builder(
          builder: (context) => EditarClientePage(
            consultarCodigoPostal: cubits.consultarCodigoPostal,
            onGuardado: (detalle) => context.pop(detalle),
            onCancelar: () => context.pop(),
          ),
        ),
      );

  return GoRouter(
    initialLocation: AppRoutes.inicio,
    refreshListenable: sesion,
    redirect: (context, state) =>
        AppRoutes.redireccion(status: sesion.status, uri: state.uri, esEjecutivo: esEjecutivo()),
    routes: [
      GoRoute(
        path: AppRoutes.cargando,
        builder: (context, state) => const Scaffold(
          body: LoadingView(mensaje: 'Verificando tu sesión'),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final aviso = sesion.mensajeCierre;
          sesion.limpiarMotivoCierre();
          return BlocProvider(
            create: (_) => cubits.login(),
            child: LoginPage(
              avisoCierre: aviso,
              onCodigoEnviado: (desafio) => context.go(AppRoutes.verificarCodigo, extra: desafio),
              onCrearCuenta: () => context.go(AppRoutes.registro),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.verificarCodigo,
        // Sin desafio (por ejemplo, al recargar la pagina en web) se vuelve al login
        redirect: (context, state) => state.extra is DesafioVerificacion ? null : AppRoutes.login,
        builder: (context, state) => BlocProvider(
          create: (_) => cubits.verificacion(state.extra! as DesafioVerificacion),
          child: VerificarCodigoPage(onVolverAlLogin: () => context.go(AppRoutes.login)),
        ),
      ),
      // Autoregistro: el cliente crea su cuenta sin depender de un ejecutivo
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => BlocProvider(
          create: (_) => cubits.registroCliente(),
          child: RegistroClientePage(
            consultarCodigoPostal: cubits.consultarCodigoPostal,
            onRegistrado: (_) => context.go(AppRoutes.login),
            onCancelar: () => context.go(AppRoutes.login),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell, esEjecutivo: esEjecutivo()),
        // El orden de las ramas debe coincidir con _destinos en app_shell.dart
        branches: [
          _rama(AppRoutes.inicio, (_, _) => const InicioPage()),
          _rama(
            AppRoutes.clientes,
            (context, _) => BlocProvider(
              create: (_) => cubits.clientes(),
              child: ClientesPage(
                onAbrir: (id) => context.go(AppRoutes.clienteDetalle(id)),
                onNuevo: () => context.go(AppRoutes.clienteNuevo),
              ),
            ),
            rutas: [
              GoRoute(
                path: 'nuevo',
                builder: (context, state) => BlocProvider(
                  create: (_) => cubits.registroCliente(),
                  child: RegistroClientePage(
                    porEjecutivo: true,
                    consultarCodigoPostal: cubits.consultarCodigoPostal,
                    onRegistrado: (registro) => context.go(AppRoutes.clienteDetalle(registro.cliente.id)),
                    onCancelar: () => context.go(AppRoutes.clientes),
                  ),
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return id == null
                      ? const _NoEncontrado()
                      : detalle(id, titulo: 'Cliente', rutaEditar: AppRoutes.clienteEditar, administrar: true);
                },
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      return id == null ? const _NoEncontrado() : editar(id);
                    },
                  ),
                ],
              ),
            ],
          ),
          _rama(
            AppRoutes.catalogo,
            (context, _) => BlocProvider(
              create: (_) => cubits.catalogo(),
              // Solo el CLIENTE compra; el EJECUTIVO consulta el catalogo
              child: CatalogoPage(
                onComprar: esEjecutivo() ? null : (producto) => context.push(AppRoutes.compra, extra: producto),
              ),
            ),
            rutas: [
              GoRoute(
                path: 'comprar',
                // El producto viaja en extra; si se recarga la pagina se vuelve al catalogo
                redirect: (_, state) => state.extra is Producto ? null : AppRoutes.catalogo,
                builder: (context, state) => BlocProvider(
                  create: (_) => cubits.compra(),
                  child: CompraPage(
                    producto: state.extra! as Producto,
                    onTerminar: () => context.pop(),
                    onVerCompras: () => context.go(AppRoutes.historial),
                  ),
                ),
              ),
            ],
          ),
          _rama(
            AppRoutes.historial,
            (_, _) => BlocProvider(
              create: (_) => cubits.historial(),
              child: HistorialPage(esEjecutivo: esEjecutivo()),
            ),
          ),
          _rama(
            AppRoutes.perfil,
            (context, _) => BlocProvider(
              create: (_) => cubits.cerrarSesion(),
              child: PerfilPage(
                sesion: sesion.datos,
                onMisDatos: sesion.datos?.clienteId == null ? null : () => context.go(AppRoutes.misDatos),
                onNip: esEjecutivo() ? null : () => context.go(AppRoutes.nipTransacciones),
              ),
            ),
            rutas: [
              GoRoute(
                path: 'nip',
                builder: (context, state) => BlocProvider(
                  create: (_) => cubits.nip(),
                  child: NipPage(onTerminar: () => context.go(AppRoutes.perfil)),
                ),
              ),
              // Datos del propio cliente (el EJECUTIVO no es cliente y no la ve)
              GoRoute(
                path: 'datos',
                builder: (context, state) {
                  final id = sesion.datos?.clienteId;
                  return id == null
                      ? const _NoEncontrado()
                      : detalle(id, titulo: 'Mis datos', rutaEditar: (_) => '${AppRoutes.misDatos}/editar');
                },
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (context, state) {
                      final id = sesion.datos?.clienteId;
                      return id == null ? const _NoEncontrado() : editar(id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _NoEncontrado(),
  );
}

StatefulShellBranch _rama(
  String ruta,
  Widget Function(BuildContext context, GoRouterState state) pagina, {
  List<RouteBase> rutas = const [],
}) =>
    StatefulShellBranch(
      routes: [GoRoute(path: ruta, builder: pagina, routes: rutas)],
    );

class _NoEncontrado extends StatelessWidget {
  const _NoEncontrado();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: EmptyView(
          icono: Icons.search_off,
          titulo: 'Página no encontrada',
          mensaje: 'La dirección que buscas no existe.',
        ),
      );
}
