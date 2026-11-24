import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';
import 'app_button.dart';

/// Indicador de carga centrado con texto opcional (anunciado a lectores de pantalla).
class LoadingView extends StatelessWidget {
  const LoadingView({this.mensaje, super.key});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: mensaje ?? 'Cargando',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (mensaje != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(mensaje!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensaje de error con boton para reintentar.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.mensaje, this.onReintentar, super.key});

  final String mensaje;
  final Future<void> Function()? onReintentar;

  @override
  Widget build(BuildContext context) {
    return _VistaDeEstado(
      icono: Icons.error_outline,
      colorIcono: Theme.of(context).colorScheme.error,
      titulo: 'Algo salió mal',
      mensaje: mensaje,
      accion: onReintentar == null
          ? null
          : AppButton(
              texto: 'Reintentar',
              icono: Icons.refresh,
              variante: AppButtonVariante.secundario,
              onPressed: onReintentar,
            ),
    );
  }
}

/// Estado vacio (por ejemplo, un historial sin compras).
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.titulo,
    this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.accion,
    super.key,
  });

  final String titulo;
  final String? mensaje;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return _VistaDeEstado(
      icono: icono,
      colorIcono: Theme.of(context).colorScheme.outline,
      titulo: titulo,
      mensaje: mensaje,
      accion: accion,
    );
  }
}

class _VistaDeEstado extends StatelessWidget {
  const _VistaDeEstado({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoFormulario),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(child: Icon(icono, size: 56, color: colorIcono)),
                const SizedBox(height: AppSpacing.md),
                Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
                if (mensaje != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(mensaje!, style: texto.bodyMedium, textAlign: TextAlign.center),
                ],
                if (accion != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  accion!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
