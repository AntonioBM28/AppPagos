import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/security/session_data.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/cubit/verificacion_cubit.dart';

/// Datos de la sesion y cierre de sesion.
class PerfilPage extends StatelessWidget {
  const PerfilPage({required this.sesion, this.onMisDatos, this.onNip, super.key});

  final SessionData? sesion;

  /// Solo para el CLIENTE: abre sus datos para consultarlos y editarlos.
  final VoidCallback? onMisDatos;

  /// NIP de transacciones (solo CLIENTE).
  final VoidCallback? onNip;

  Future<void> _cerrarSesion(BuildContext context) async {
    final cubit = context.read<CerrarSesionCubit>();
    final confirmado = await ConfirmDialog.mostrar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres cerrar tu sesión en este dispositivo?',
      textoConfirmar: 'Cerrar sesión',
      esDestructiva: true,
    );
    if (confirmado) await cubit.cerrar();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final datos = sesion;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ContenidoCentrado(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (datos != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sesión activa', style: texto.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _Dato(icono: Icons.alternate_email, etiqueta: 'Usuario', valor: datos.usuario),
                      _Dato(
                        icono: Icons.badge_outlined,
                        etiqueta: 'Rol',
                        valor: datos.esEjecutivo ? 'Ejecutivo' : 'Cliente',
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (onMisDatos != null) ...[
              AppButton(
                texto: 'Mis datos',
                icono: Icons.badge_outlined,
                expandir: true,
                onPressed: onMisDatos,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (onNip != null) ...[
              AppButton(
                texto: 'NIP de transacciones',
                icono: Icons.pin_outlined,
                variante: AppButtonVariante.secundario,
                expandir: true,
                onPressed: onNip,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            BlocBuilder<CerrarSesionCubit, bool>(
              builder: (context, cerrando) => AppButton(
                texto: 'Cerrar sesión',
                icono: Icons.logout,
                variante: AppButtonVariante.secundario,
                expandir: true,
                cargando: cerrando,
                // Sin devolver el Future: el boton no debe mostrarse "procesando" mientras el
                // dialogo espera la confirmacion; el estado del Cubit lo indica al cerrar.
                onPressed: () => unawaited(_cerrarSesion(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.etiqueta, required this.valor});

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icono, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('$etiqueta: ', style: Theme.of(context).textTheme.labelLarge),
          Expanded(child: Text(valor, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
