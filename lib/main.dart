import 'dart:async';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/security/session_manager.dart';
import 'injection.dart';

void main() {
  // En web usa URLs limpias (/historial en lugar de /#/historial). El servidor debe
  // responder index.html en cualquier ruta de la app. En movil no hace nada.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppConfig.validate();
  } on StateError catch (e) {
    runApp(ConfiguracionInvalidaApp(mensaje: e.message));
    return;
  }

  configurarDependencias();
  // La app arranca en /cargando y el router decide a donde ir cuando termina.
  unawaited(getIt<SessionManager>().restaurar());
  runApp(PagosApp(router: getIt<GoRouter>()));
}
