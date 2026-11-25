import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/desafio_verificacion.dart';
import '../../domain/usecases/validaciones_auth.dart';
import '../cubit/login_cubit.dart';
import '../widgets/encabezado_auth.dart';

/// Paso 1 del inicio de sesion: correo y contrasena.
class LoginPage extends StatefulWidget {
  const LoginPage({required this.onCodigoEnviado, this.onCrearCuenta, this.avisoCierre, super.key});

  /// Navega a la verificacion del codigo.
  final ValueChanged<DesafioVerificacion> onCodigoEnviado;

  /// Lleva al autoregistro de clientes.
  final VoidCallback? onCrearCuenta;

  /// Explicacion de por que se cerro la sesion anterior (expiro, otro dispositivo...).
  final String? avisoCierre;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    TextInput.finishAutofillContext();
    await context.read<LoginCubit>().enviar(correo: _correo.text, password: _password.text);
  }

  Future<void> _escuchar(BuildContext context, LoginState estado) async {
    final cubit = context.read<LoginCubit>();
    switch (estado) {
      case LoginCodigoEnviado(:final desafio):
        _password.clear();
        cubit.reiniciar();
        widget.onCodigoEnviado(desafio);
      case LoginSesionActiva(:final sesion):
        final confirmado = await ConfirmDialog.mostrar(
          context,
          titulo: 'Tienes una sesión abierta',
          mensaje: _mensajeSesionActiva(sesion),
          textoConfirmar: 'Cerrar esa sesión',
          esDestructiva: true,
        );
        if (confirmado) {
          await cubit.cerrarSesionAnteriorYContinuar();
        } else {
          cubit.cancelarSesionActiva();
        }
      case LoginError(:final mensaje):
        if (context.mounted) AppSnackbar.mostrar(context, mensaje, tipo: TipoAviso.error);
      case LoginInicial() || LoginEnviando():
        break;
    }
  }

  static String _mensajeSesionActiva(SesionActivaFailure sesion) {
    final dispositivo = sesion.esMovil ? 'la app móvil' : 'la aplicación web';
    final desde = sesion.iniciadaEn == null
        ? ''
        : ' desde el ${DateFormat("d 'de' MMMM 'a las' H:mm", 'es_MX').format(sesion.iniciadaEn!)}';
    return 'Tu cuenta está abierta en $dispositivo$desde. Solo puedes tener una sesión a la vez.\n\n'
        'Si continúas, esa sesión se cerrará cuando confirmes el código que te enviaremos por correo.';
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ContenidoCentrado(
          anchoMaximo: AppSizes.anchoMaximoFormulario,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocConsumer<LoginCubit, LoginState>(
            listener: _escuchar,
            builder: (context, estado) {
              final enviando = estado is LoginEnviando;
              return Form(
                key: _formulario,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EncabezadoAuth(
                        icono: Icons.lock_outline,
                        titulo: 'Inicia sesión',
                        subtitulo: 'Usa tu correo y contraseña. Después te enviaremos un código para confirmar que eres tú.',
                      ),
                      if (widget.avisoCierre != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _AvisoCierre(mensaje: widget.avisoCierre!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        etiqueta: 'Correo electrónico',
                        controller: _correo,
                        icono: Icons.alternate_email,
                        teclado: TextInputType.emailAddress,
                        accion: TextInputAction.next,
                        autofill: const [AutofillHints.email, AutofillHints.username],
                        longitudMaxima: 100,
                        habilitado: !enviando,
                        validator: ValidacionesAuth.correo,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        etiqueta: 'Contraseña',
                        controller: _password,
                        icono: Icons.key_outlined,
                        esContrasena: true,
                        accion: TextInputAction.done,
                        autofill: const [AutofillHints.password],
                        longitudMaxima: 72,
                        habilitado: !enviando,
                        validator: ValidacionesAuth.password,
                        onSubmitted: (_) => _enviar(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        texto: 'Continuar',
                        icono: Icons.arrow_forward,
                        expandir: true,
                        cargando: enviando,
                        onPressed: _enviar,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Por seguridad, solo puedes tener una sesión abierta a la vez.',
                        style: texto.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.onCrearCuenta != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const Divider(),
                        const SizedBox(height: AppSpacing.sm),
                        Text('¿Todavía no tienes cuenta?', style: texto.bodyMedium, textAlign: TextAlign.center),
                        AppButton(
                          texto: 'Crear una cuenta',
                          icono: Icons.person_add_alt_1_outlined,
                          variante: AppButtonVariante.secundario,
                          expandir: true,
                          onPressed: enviando ? null : widget.onCrearCuenta,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AvisoCierre extends StatelessWidget {
  const _AvisoCierre({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Semantics(
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
                child: Text(mensaje, style: TextStyle(color: colores.onErrorContainer)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
