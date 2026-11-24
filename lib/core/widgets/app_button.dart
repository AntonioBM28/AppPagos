import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

enum AppButtonVariante { primario, secundario, texto }

/// Boton de la app con proteccion contra toques repetidos.
///
/// Si [onPressed] devuelve un Future, el boton se bloquea y muestra un indicador
/// hasta que termine, asi un doble clic no dispara la accion dos veces (clave en
/// compras). [cargando] permite que el estado de un Cubit tambien lo bloquee.
class AppButton extends StatefulWidget {
  const AppButton({
    required this.texto,
    required this.onPressed,
    this.variante = AppButtonVariante.primario,
    this.icono,
    this.cargando = false,
    this.expandir = false,
    super.key,
  });

  final String texto;

  /// null deja el boton deshabilitado.
  final FutureOr<void> Function()? onPressed;
  final AppButtonVariante variante;
  final IconData? icono;
  final bool cargando;

  /// Ocupa todo el ancho disponible.
  final bool expandir;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _ejecutando = false;

  bool get _ocupado => widget.cargando || _ejecutando;

  Future<void> _alPresionar() async {
    if (_ocupado || widget.onPressed == null) return;
    final resultado = widget.onPressed!();
    if (resultado is! Future<void>) return;

    setState(() => _ejecutando = true);
    try {
      await resultado;
    } finally {
      if (mounted) setState(() => _ejecutando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onPressed != null && !_ocupado;
    final onPressed = habilitado ? _alPresionar : null;
    final contenido = _contenido(context);

    final boton = switch (widget.variante) {
      AppButtonVariante.primario =>
        FilledButton(onPressed: onPressed, child: contenido),
      AppButtonVariante.secundario =>
        OutlinedButton(onPressed: onPressed, child: contenido),
      AppButtonVariante.texto =>
        TextButton(onPressed: onPressed, child: contenido),
    };

    return Semantics(
      button: true,
      enabled: habilitado,
      label: _ocupado ? '${widget.texto}, procesando' : widget.texto,
      excludeSemantics: true,
      child: widget.expandir ? SizedBox(width: double.infinity, child: boton) : boton,
    );
  }

  Widget _contenido(BuildContext context) {
    if (_ocupado) {
      final color = widget.variante == AppButtonVariante.primario
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.primary;
      return SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    }
    if (widget.icono == null) return Text(widget.texto);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icono, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(widget.texto)),
      ],
    );
  }
}
