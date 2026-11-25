import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/usecases/validaciones_auth.dart';
import '../cubit/verificacion_cubit.dart';
import '../widgets/encabezado_auth.dart';

/// Paso 2 del inicio de sesion: codigo de 6 digitos enviado por correo.
///
/// Al verificarse, el SessionManager abre la sesion y el router lleva al inicio.
class VerificarCodigoPage extends StatefulWidget {
  const VerificarCodigoPage({required this.onVolverAlLogin, super.key});

  final VoidCallback onVolverAlLogin;

  @override
  State<VerificarCodigoPage> createState() => _VerificarCodigoPageState();
}

class _VerificarCodigoPageState extends State<VerificarCodigoPage> {
  final _formulario = GlobalKey<FormState>();
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    await context.read<VerificacionCubit>().verificar(_codigo.text);
  }

  static String _reloj(int segundos) =>
      '${segundos ~/ 60}:${(segundos % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver al inicio de sesión',
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onVolverAlLogin,
        ),
      ),
      body: SafeArea(
        child: ContenidoCentrado(
          anchoMaximo: AppSizes.anchoMaximoFormulario,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocConsumer<VerificacionCubit, VerificacionState>(
            listenWhen: (anterior, actual) => actual.error != null && actual.error != anterior.error,
            listener: (context, estado) => _codigo.clear(),
            builder: (context, estado) {
              final bloqueado = estado.debeReiniciar || estado.expirado;
              return Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EncabezadoAuth(
                      icono: Icons.mark_email_read_outlined,
                      titulo: 'Verifica que eres tú',
                      subtitulo: 'Escribe el código de 6 dígitos que enviamos a '
                          '${estado.desafio.correoEnmascarado}.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (estado.error != null)
                      _Mensaje(texto: estado.error!, esError: true)
                    else if (estado.aviso != null)
                      _Mensaje(texto: estado.aviso!, esError: false),
                    AppTextField(
                      etiqueta: 'Código de verificación',
                      controller: _codigo,
                      icono: Icons.pin_outlined,
                      teclado: TextInputType.number,
                      accion: TextInputAction.done,
                      autofill: const [AutofillHints.oneTimeCode],
                      formatos: [FilteringTextInputFormatter.digitsOnly],
                      longitudMaxima: ValidacionesAuth.longitudCodigo,
                      habilitado: !estado.verificando && !bloqueado,
                      validator: ValidacionesAuth.codigo,
                      onSubmitted: (_) => _verificar(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      estado.expirado
                          ? 'El código expiró. Solicita uno nuevo.'
                          : 'El código vence en ${_reloj(estado.segundosParaExpirar)}.',
                      style: tema.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (estado.debeReiniciar)
                      AppButton(
                        texto: 'Iniciar sesión de nuevo',
                        icono: Icons.login,
                        expandir: true,
                        onPressed: widget.onVolverAlLogin,
                      )
                    else ...[
                      AppButton(
                        texto: 'Verificar',
                        icono: Icons.verified_user_outlined,
                        expandir: true,
                        cargando: estado.verificando,
                        onPressed: estado.expirado ? null : _verificar,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        texto: estado.segundosParaReenviar > 0
                            ? 'Reenviar código en ${_reloj(estado.segundosParaReenviar)}'
                            : 'Reenviar código',
                        icono: Icons.refresh,
                        variante: AppButtonVariante.texto,
                        expandir: true,
                        cargando: estado.reenviando,
                        onPressed: estado.puedeReenviar && !estado.verificando
                            ? context.read<VerificacionCubit>().reenviar
                            : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nunca compartas este código. Nadie de PagosApp te lo pedirá.',
                      style: tema.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.esError});

  final String texto;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final fondo = esError ? colores.errorContainer : colores.secondaryContainer;
    final frente = esError ? colores.onErrorContainer : colores.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Card(
          color: fondo,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(esError ? Icons.error_outline : Icons.info_outline, color: frente),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(texto, style: TextStyle(color: frente))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
