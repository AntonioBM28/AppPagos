import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/verificar_codigo_page.dart';
import '../../features/catalogo/presentation/pages/catalogo_page.dart';
import '../../features/historial/presentation/pages/historial_page.dart';
import '../../features/inicio/presentation/pages/inicio_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../security/session_manager.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Crea el router. Se vuelve a evaluar el redirect cada vez que cambia la sesion.
GoRouter crearRouter(SessionManager sesion) {
  return GoRouter(
    initialLocation: AppRoutes.inicio,
    refreshListenable: sesion,
    redirect: (context, state) =>
        AppRoutes.redireccion(status: sesion.status, uri: state.uri),
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
          final expirada = sesion.motivoCierre == MotivoCierre.expirada;
          sesion.limpiarMotivoCierre();
          return LoginPage(sesionExpirada: expirada);
        },
      ),
      GoRoute(
        path: AppRoutes.verificarCodigo,
        builder: (context, state) => const VerificarCodigoPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          _rama(AppRoutes.inicio, const InicioPage()),
          _rama(AppRoutes.catalogo, const CatalogoPage()),
          _rama(AppRoutes.historial, const HistorialPage()),
          _rama(AppRoutes.perfil, const PerfilPage()),
        ],
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: EmptyView(
        icono: Icons.search_off,
        titulo: 'Página no encontrada',
        mensaje: 'La dirección que buscas no existe.',
      ),
    ),
  );
}

StatefulShellBranch _rama(String ruta, Widget pagina) => StatefulShellBranch(
      routes: [GoRoute(path: ruta, builder: (context, state) => pagina)],
    );
