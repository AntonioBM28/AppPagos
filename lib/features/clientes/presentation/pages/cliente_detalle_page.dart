import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/cliente.dart';
import '../cubit/clientes_cubits.dart';

/// Detalle de un cliente. El EJECUTIVO puede editarlo y darlo de baja o reactivarlo;
/// el propio cliente solo puede editar sus datos.
class ClienteDetallePage extends StatefulWidget {
  const ClienteDetallePage({
    required this.titulo,
    required this.onEditar,
    this.puedeCambiarEstatus = false,
    super.key,
  });

  final String titulo;

  /// Devuelve los datos actualizados cuando se guardaron cambios, o null si se cancelo.
  final Future<ClienteDetalle?> Function(int id) onEditar;
  final bool puedeCambiarEstatus;

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> {
  static final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
  static final _fecha = DateFormat("d 'de' MMMM 'de' y", 'es_MX');

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ClienteDetalleCubit>().cargar());
  }

  Future<void> _editar(Cliente cliente) async {
    final cubit = context.read<ClienteDetalleCubit>();
    final actualizado = await widget.onEditar(cliente.id);
    if (actualizado != null) cubit.actualizado(actualizado);
  }

  Future<void> _cambiarEstatus(Cliente cliente) async {
    final cubit = context.read<ClienteDetalleCubit>();
    final darDeBaja = cliente.activo;
    final confirmado = await ConfirmDialog.mostrar(
      context,
      titulo: darDeBaja ? 'Dar de baja al cliente' : 'Reactivar al cliente',
      mensaje: darDeBaja
          ? '${cliente.nombreCompleto} ya no podrá iniciar sesión y sus cuentas quedarán inactivas. '
              'Sus datos y su historial se conservan, y puedes reactivarlo después.'
          : '${cliente.nombreCompleto} podrá volver a iniciar sesión. Sus cuentas se reactivan por separado.',
      textoConfirmar: darDeBaja ? 'Dar de baja' : 'Reactivar',
      esDestructiva: darDeBaja,
    );
    if (confirmado) await cubit.cambiarEstatus(activo: !darDeBaja);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClienteDetalleCubit, ClienteDetalleState>(
      listener: (context, estado) {
        if (estado.aviso != null) AppSnackbar.mostrar(context, estado.aviso!, tipo: TipoAviso.exito);
        if (estado.error != null && estado.detalle != null) {
          AppSnackbar.mostrar(context, estado.error!, tipo: TipoAviso.error);
        }
      },
      builder: (context, estado) {
        final detalle = estado.detalle;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.titulo),
            actions: [
              if (detalle != null)
                IconButton(
                  tooltip: 'Editar datos',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editar(detalle.cliente),
                ),
            ],
          ),
          body: switch (estado) {
            ClienteDetalleState(cargando: true, detalle: null) => const LoadingView(mensaje: 'Cargando datos'),
            ClienteDetalleState(detalle: null, :final error) => ErrorView(
                mensaje: error ?? 'No fue posible cargar los datos',
                onReintentar: context.read<ClienteDetalleCubit>().cargar,
              ),
            _ => _contenido(detalle!, estado.cambiandoEstatus),
          },
        );
      },
    );
  }

  Widget _contenido(ClienteDetalle detalle, bool cambiandoEstatus) {
    final c = detalle.cliente;
    final texto = Theme.of(context).textTheme;
    return ContenidoCentrado(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(c.nombreCompleto, style: texto.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              Chip(
                avatar: Icon(c.activo ? Icons.check_circle : Icons.block, size: 18),
                label: Text(c.activo ? 'Activo' : 'De baja'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Grupo(titulo: 'Datos personales', datos: {
            'Fecha de nacimiento': _fecha.format(c.fechaNacimiento),
            'Sexo': c.sexo.etiqueta,
            'CURP': c.curp,
            'RFC': c.rfc,
            'Nacionalidad': c.nacionalidad,
            'Estado civil': c.estadoCivil.etiqueta,
          }),
          _Grupo(titulo: 'Contacto', datos: {
            'Correo': c.correo,
            'Teléfono móvil': c.telefonoMovil,
            if (c.telefonoAlternativo != null) 'Teléfono alternativo': c.telefonoAlternativo!,
          }),
          _Grupo(titulo: 'Domicilio', datos: {'Dirección': c.domicilio.resumen}),
          _Grupo(titulo: 'Información laboral', datos: {
            'Ocupación': c.ocupacion?.etiqueta ?? 'Sin especificar',
            'Empresa': c.empresa ?? 'Sin especificar',
            'Ingreso mensual': c.rangoIngresoMensual?.etiqueta ?? 'Sin especificar',
          }),
          _Grupo(titulo: 'Cuentas', datos: {
            for (final cuenta in detalle.cuentas)
              cuenta.numeroCuenta: '${_moneda.format(cuenta.saldo)} · ${cuenta.activa ? 'Activa' : 'Inactiva'}',
            if (detalle.cuentas.isEmpty) 'Sin cuentas': '',
          }),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            texto: 'Editar datos',
            icono: Icons.edit_outlined,
            variante: AppButtonVariante.secundario,
            expandir: true,
            onPressed: () => _editar(c),
          ),
          if (widget.puedeCambiarEstatus) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              texto: c.activo ? 'Dar de baja' : 'Reactivar cliente',
              icono: c.activo ? Icons.person_off_outlined : Icons.person_add_alt_1_outlined,
              variante: AppButtonVariante.texto,
              expandir: true,
              cargando: cambiandoEstatus,
              onPressed: () => unawaited(_cambiarEstatus(c)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.datos});

  final String titulo;
  final Map<String, String> datos;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(titulo, style: texto.titleMedium)),
              const SizedBox(height: AppSpacing.sm),
              for (final dato in datos.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dato.key, style: texto.labelMedium),
                      if (dato.value.isNotEmpty) SelectableText(dato.value, style: texto.bodyLarge),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
