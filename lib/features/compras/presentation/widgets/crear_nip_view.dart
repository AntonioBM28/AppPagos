import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import 'teclado_nip.dart';

/// Primera compra: el cliente define su NIP (dos veces para confirmarlo).
class CrearNipView extends StatefulWidget {
  const CrearNipView({required this.onCrear, required this.ocupado, this.error, this.explicacion, super.key});

  /// Texto que se muestra arriba del teclado.
  final String? explicacion;

  final Future<void> Function(String nip, String confirmacion) onCrear;
  final bool ocupado;
  final String? error;

  @override
  State<CrearNipView> createState() => CrearNipViewState();
}

class CrearNipViewState extends State<CrearNipView> {
  String? _primero;
  String? _errorLocal;

  /// Mismas reglas que el servidor: sin digitos repetidos ni consecutivos.
  static String? validar(String nip) {
    const secuencia = '0123456789';
    if (nip.split('').toSet().length == 1 ||
        secuencia.contains(nip) ||
        secuencia.split('').reversed.join().contains(nip)) {
      return 'Es muy fácil de adivinar: no uses dígitos repetidos ni consecutivos';
    }
    return null;
  }

  void _capturado(String nip) {
    if (_primero == null) {
      final error = validar(nip);
      setState(() {
        _errorLocal = error;
        if (error == null) _primero = nip;
      });
      return;
    }
    if (nip != _primero) {
      setState(() {
        _primero = null;
        _errorLocal = 'Los NIP no coinciden. Vuelve a crearlo';
      });
      return;
    }
    setState(() => _errorLocal = null);
    unawaited(widget.onCrear(_primero!, nip));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.explicacion != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(widget.explicacion!, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        TecladoNip(
          titulo: _primero == null ? 'Crea tu NIP' : 'Confirma tu NIP',
          descripcion: _primero == null ? 'Sin dígitos repetidos ni consecutivos' : 'Escríbelo otra vez',
          error: _errorLocal ?? widget.error,
          ocupado: widget.ocupado,
          alCompletar: _capturado,
        ),
      ],
    );
  }
}
