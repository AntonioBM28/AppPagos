import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';

/// Encabezado comun de las pantallas de inicio de sesion.
class EncabezadoAuth extends StatelessWidget {
  const EncabezadoAuth({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        ExcludeSemantics(
          child: CircleAvatar(
            radius: 32,
            backgroundColor: tema.colorScheme.primaryContainer,
            child: Icon(icono, size: 32, color: tema.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(titulo, style: tema.textTheme.headlineSmall, textAlign: TextAlign.center),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitulo, style: tema.textTheme.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }
}
