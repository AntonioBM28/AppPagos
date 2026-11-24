import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

enum TipoAviso { exito, error, informacion }

/// Avisos breves en la parte inferior de la pantalla.
abstract final class AppSnackbar {
  static void mostrar(
    BuildContext context,
    String mensaje, {
    TipoAviso tipo = TipoAviso.informacion,
  }) {
    final colores = Theme.of(context).colorScheme;
    final (icono, fondo, texto) = switch (tipo) {
      TipoAviso.exito => (Icons.check_circle_outline, AppColors.exito, Colors.white),
      TipoAviso.error => (Icons.error_outline, colores.error, colores.onError),
      TipoAviso.informacion =>
        (Icons.info_outline, colores.inverseSurface, colores.onInverseSurface),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: fondo,
          content: Row(
            children: [
              Icon(icono, color: texto),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(mensaje, style: TextStyle(color: texto))),
            ],
          ),
        ),
      );
  }
}

/// Dialogo de confirmacion. Devuelve true solo si el usuario confirma.
abstract final class ConfirmDialog {
  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Confirmar',
    String textoCancelar = 'Cancelar',
    bool esDestructiva = false,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colores = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(child: Text(mensaje)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(textoCancelar),
            ),
            FilledButton(
              style: esDestructiva
                  ? FilledButton.styleFrom(
                      backgroundColor: colores.error,
                      foregroundColor: colores.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );
    return confirmado ?? false;
  }
}
