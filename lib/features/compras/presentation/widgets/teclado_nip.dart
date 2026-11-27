import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';

/// Captura de un NIP de 4 digitos con teclado numerico propio (como un cajero): los digitos
/// nunca se muestran. Tambien acepta el teclado fisico. Al completar los 4 llama a [alCompletar].
class TecladoNip extends StatefulWidget {
  const TecladoNip({
    required this.titulo,
    required this.alCompletar,
    this.descripcion,
    this.error,
    this.ocupado = false,
    super.key,
  });

  static const longitud = 4;

  final String titulo;
  final String? descripcion;
  final String? error;
  final bool ocupado;
  final ValueChanged<String> alCompletar;

  @override
  State<TecladoNip> createState() => _TecladoNipState();
}

class _TecladoNipState extends State<TecladoNip> {
  String _nip = '';

  void _agregar(String digito) {
    if (widget.ocupado || _nip.length >= TecladoNip.longitud) return;
    setState(() => _nip += digito);
    if (_nip.length == TecladoNip.longitud) {
      final completo = _nip;
      // Se limpia en cuanto se envia: si el NIP es incorrecto se vuelve a capturar desde cero
      setState(() => _nip = '');
      widget.alCompletar(completo);
    }
  }

  void _borrar() {
    if (widget.ocupado || _nip.isEmpty) return;
    setState(() => _nip = _nip.substring(0, _nip.length - 1));
  }

  KeyEventResult _teclaFisica(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent) return KeyEventResult.ignored;
    final caracter = evento.character;
    if (caracter != null && RegExp(r'^[0-9]$').hasMatch(caracter)) {
      _agregar(caracter);
      return KeyEventResult.handled;
    }
    if (evento.logicalKey == LogicalKeyboardKey.backspace) {
      _borrar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    return Focus(
      autofocus: true,
      onKeyEvent: _teclaFisica,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 40, color: colores.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.titulo, style: tema.textTheme.titleLarge, textAlign: TextAlign.center),
          if (widget.descripcion != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(widget.descripcion!, style: tema.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: 'NIP: ${_nip.length} de ${TecladoNip.longitud} dígitos',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < TecladoNip.longitud; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _nip.length ? colores.primary : Colors.transparent,
                      border: Border.all(color: widget.error != null ? colores.error : colores.primary, width: 2),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: Center(
              child: widget.ocupado
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : widget.error == null
                      ? null
                      : Text(
                          widget.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colores.error),
                        ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              children: [
                for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) _Tecla(texto: d, alTocar: () => _agregar(d)),
                const SizedBox.shrink(),
                _Tecla(texto: '0', alTocar: () => _agregar('0')),
                _Tecla(icono: Icons.backspace_outlined, etiqueta: 'Borrar', alTocar: _borrar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tecla extends StatelessWidget {
  const _Tecla({required this.alTocar, this.texto, this.icono, this.etiqueta});

  final String? texto;
  final IconData? icono;
  final String? etiqueta;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: texto == null ? Colors.transparent : tema.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: alTocar,
        child: Center(
          child: texto != null
              ? Text(texto!, style: tema.textTheme.headlineSmall)
              : Icon(icono, semanticLabel: etiqueta),
        ),
      ),
    );
  }
}
