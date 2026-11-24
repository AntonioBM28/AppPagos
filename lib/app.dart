import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';

/// Raiz de la aplicacion.
class PagosApp extends StatelessWidget {
  const PagosApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PagosApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      routerConfig: router,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

/// Se muestra si la configuracion de compilacion es invalida (por ejemplo, falta
/// API_BASE_URL), en lugar de que la app falle sin explicacion.
class ConfiguracionInvalidaApp extends StatelessWidget {
  const ConfiguracionInvalidaApp({required this.mensaje, super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Configuración inválida: $mensaje',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
