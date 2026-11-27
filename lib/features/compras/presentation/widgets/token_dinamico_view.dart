import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/compra.dart';

/// Autorizacion con token dinamico: el token NO se muestra (la app lo usa sola al autorizar);
/// solo se ve su vigencia. Cuando llega a cero avisa con [alExpirar].
class TokenDinamicoView extends StatefulWidget {
  const TokenDinamicoView({
    required this.token,
    required this.emitidoEn,
    required this.resumen,
    required this.alAutorizar,
    required this.alExpirar,
    this.error,
    this.ocupado = false,
    this.reloj = DateTime.now,
    super.key,
  });

  final TokenDinamico token;
  final DateTime emitidoEn;

  /// Monto y producto que se autorizan.
  final Widget resumen;
  final Future<void> Function() alAutorizar;
  final VoidCallback alExpirar;
  final String? error;
  final bool ocupado;
  final DateTime Function() reloj;

  @override
  State<TokenDinamicoView> createState() => _TokenDinamicoViewState();
}

class _TokenDinamicoViewState extends State<TokenDinamicoView> {
  Timer? _timer;
  late Duration _restante = _calcular();

  Duration _calcular() {
    final restante = widget.token.vigencia - widget.reloj().difference(widget.emitidoEn);
    return restante.isNegative ? Duration.zero : restante;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _restante = _calcular());
      if (_restante == Duration.zero) {
        _timer?.cancel();
        widget.alExpirar();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final total = widget.token.vigencia.inSeconds;
    final segundos = _restante.inSeconds;
    final avance = total == 0 ? 0.0 : segundos / total;
    final urgente = segundos <= 10;

    // El token nunca se muestra: como el token movil integrado de las apps bancarias, la app lo
    // guarda en memoria y lo envia sola al autorizar.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.verified_user_outlined, size: 40, color: colores.primary),
        const SizedBox(height: AppSpacing.sm),
        Text('Operación lista para autorizar', style: tema.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tu NIP es correcto. Revisa los datos y autoriza el pago.',
          style: tema.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          color: colores.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, color: colores.onPrimaryContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Token dinámico generado',
                        style: tema.textTheme.titleMedium?.copyWith(color: colores.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Es de un solo uso y solo sirve para esta operación.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodySmall?.copyWith(color: colores.onPrimaryContainer),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        value: avance,
                        strokeWidth: 3,
                        color: urgente ? colores.error : colores.primary,
                        backgroundColor: colores.surface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Vence en $segundos s',
                      style: tema.textTheme.labelLarge?.copyWith(color: urgente ? colores.error : null),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        widget.resumen,
        if (widget.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(widget.error!, style: TextStyle(color: colores.error), textAlign: TextAlign.center),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          texto: 'Autorizar pago',
          icono: Icons.lock_open_outlined,
          expandir: true,
          cargando: widget.ocupado,
          onPressed: segundos == 0 ? null : widget.alAutorizar,
        ),
      ],
    );
  }
}
