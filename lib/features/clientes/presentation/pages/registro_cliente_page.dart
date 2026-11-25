import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/entities/cliente.dart';
import '../cubit/clientes_cubits.dart';
import '../widgets/formulario_cliente.dart';

/// Alta de cliente. La usa el propio cliente para crear su cuenta (sin sesion) y el
/// ejecutivo para dar de alta a un cliente.
class RegistroClientePage extends StatelessWidget {
  const RegistroClientePage({
    required this.consultarCodigoPostal,
    required this.onRegistrado,
    this.porEjecutivo = false,
    this.onCancelar,
    super.key,
  });

  final Future<Result<InfoCodigoPostal>> Function(String) consultarCodigoPostal;
  final ValueChanged<RegistroCliente> onRegistrado;
  final bool porEjecutivo;
  final VoidCallback? onCancelar;

  Future<void> _avisarRegistro(BuildContext context, RegistroCliente registro) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 40),
        title: Text(porEjecutivo ? 'Cliente registrado' : '¡Tu cuenta está lista!'),
        content: Text(
          porEjecutivo
              ? '${registro.cliente.nombreCompleto} quedó registrado con la cuenta ${registro.numeroCuenta}. '
                  'Puede iniciar sesión con ${registro.usuario}.'
              : 'Tu número de cuenta es ${registro.numeroCuenta}.\n\n'
                  'Inicia sesión con ${registro.usuario} y la contraseña que elegiste. '
                  'Te enviaremos un código a tu correo para confirmar que eres tú.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(porEjecutivo ? 'Ver cliente' : 'Iniciar sesión'),
          ),
        ],
      ),
    );
    onRegistrado(registro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(porEjecutivo ? 'Nuevo cliente' : 'Crear cuenta'),
        leading: onCancelar == null
            ? null
            : IconButton(tooltip: 'Volver', icon: const Icon(Icons.arrow_back), onPressed: onCancelar),
      ),
      body: SafeArea(
        child: BlocConsumer<RegistroClienteCubit, FormularioClienteState>(
          listener: (context, estado) {
            if (estado.registro != null) {
              _avisarRegistro(context, estado.registro!);
            } else if (estado.error != null) {
              AppSnackbar.mostrar(context, estado.error!, tipo: TipoAviso.error);
            }
          },
          builder: (context, estado) => ContenidoCentrado(
            anchoMaximo: 920,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!porEjecutivo) ...[
                  Text(
                    'Llena tus datos para abrir tu cuenta. Todos los campos son obligatorios, salvo los marcados '
                    'como opcionales.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                FormularioCliente(
                  consultarCodigoPostal: consultarCodigoPostal,
                  textoBoton: porEjecutivo ? 'Registrar cliente' : 'Crear mi cuenta',
                  guardando: estado.guardando,
                  onGuardar: (datos, password) =>
                      context.read<RegistroClienteCubit>().registrar(datos, password: password!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
