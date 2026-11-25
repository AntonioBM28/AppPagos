import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/datos_cliente.dart';
import '../cubit/clientes_cubits.dart';
import '../widgets/formulario_cliente.dart';

/// Edicion de los datos de un cliente. Solo se envian los campos que cambiaron; la CURP
/// y el RFC se muestran bloqueados porque no se pueden modificar.
class EditarClientePage extends StatefulWidget {
  const EditarClientePage({
    required this.consultarCodigoPostal,
    required this.onGuardado,
    required this.onCancelar,
    super.key,
  });

  final Future<Result<InfoCodigoPostal>> Function(String) consultarCodigoPostal;
  final ValueChanged<ClienteDetalle> onGuardado;
  final VoidCallback onCancelar;

  @override
  State<EditarClientePage> createState() => _EditarClientePageState();
}

class _EditarClientePageState extends State<EditarClientePage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<ClienteDetalleCubit>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar datos'),
        leading: IconButton(tooltip: 'Cancelar', icon: const Icon(Icons.close), onPressed: widget.onCancelar),
      ),
      body: BlocBuilder<ClienteDetalleCubit, ClienteDetalleState>(
        builder: (context, detalle) => switch (detalle) {
          ClienteDetalleState(cargando: true, detalle: null) => const LoadingView(mensaje: 'Cargando datos'),
          ClienteDetalleState(detalle: null, :final error) => ErrorView(
              mensaje: error ?? 'No fue posible cargar los datos',
              onReintentar: context.read<ClienteDetalleCubit>().cargar,
            ),
          _ => _formulario(detalle.detalle!.cliente),
        },
      ),
    );
  }

  Widget _formulario(Cliente original) => BlocConsumer<EditarClienteCubit, FormularioClienteState>(
        listener: (context, estado) {
          if (estado.actualizado != null) {
            widget.onGuardado(estado.actualizado!);
          } else if (estado.error != null) {
            AppSnackbar.mostrar(context, estado.error!, tipo: TipoAviso.error);
          }
        },
        builder: (context, estado) => ContenidoCentrado(
          anchoMaximo: 920,
          child: FormularioCliente(
            inicial: DatosCliente.desde(original),
            esEdicion: true,
            consultarCodigoPostal: widget.consultarCodigoPostal,
            textoBoton: 'Guardar cambios',
            guardando: estado.guardando,
            onGuardar: (datos, _) => context.read<EditarClienteCubit>().guardar(original, datos),
          ),
        ),
      );
}
