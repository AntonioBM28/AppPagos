import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/state_views.dart';

/// Marcador de posicion del inicio de sesion (el formulario llega en la Parte 2).
///
/// Ya muestra el aviso cuando la sesion se cerro por expiracion o por un 401.
class LoginPage extends StatelessWidget {
  const LoginPage({this.sesionExpirada = false, super.key});

  final bool sesionExpirada;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ContenidoCentrado(
          anchoMaximo: AppSizes.anchoMaximoFormulario,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (sesionExpirada)
                Semantics(
                  liveRegion: true,
                  child: Card(
                    color: colores.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock, color: colores.onErrorContainer),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Tu sesión expiró o fue cerrada. Inicia sesión de nuevo',
                              style: TextStyle(color: colores.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              const EmptyView(
                icono: Icons.lock_outline,
                titulo: 'Iniciar sesión',
                mensaje: 'Aquí ingresarás con tu correo y contraseña.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
