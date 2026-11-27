import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/compra.dart';
import '../widgets/crear_nip_view.dart';
import '../widgets/teclado_nip.dart';

class NipState extends Equatable {
  const NipState({this.cargando = true, this.configurado = false, this.ocupado = false, this.listo, this.error});

  final bool cargando;
  final bool configurado;
  final bool ocupado;

  /// Mensaje final cuando el NIP se configuro o cambio.
  final String? listo;
  final String? error;

  @override
  List<Object?> get props => [cargando, configurado, ocupado, listo, error];
}

/// Configurar el NIP por primera vez o cambiarlo (requiere el actual).
class NipCubit extends Cubit<NipState> {
  NipCubit(this._repositorio) : super(const NipState());

  final ComprasRepository _repositorio;

  Future<void> cargar() async {
    final resultado = await _repositorio.nipConfigurado();
    if (isClosed) return;
    resultado.fold(
      (configurado) => emit(NipState(cargando: false, configurado: configurado)),
      (falla) => emit(NipState(cargando: false, error: falla.message)),
    );
  }

  Future<void> crear(String nip, String confirmacion) =>
      _guardar(() => _repositorio.crearNip(nip, confirmacion), 'Tu NIP quedó configurado');

  Future<void> cambiar(String actual, String nuevo, String confirmacion) => _guardar(
        () => _repositorio.cambiarNip(actual: actual, nuevo: nuevo, confirmacion: confirmacion),
        'Tu NIP se actualizó',
      );

  Future<void> _guardar(Future<dynamic> Function() operacion, String exito) async {
    if (state.ocupado) return;
    emit(NipState(cargando: false, configurado: state.configurado, ocupado: true));
    final resultado = await operacion();
    if (isClosed) return;
    resultado.fold(
      (_) => emit(NipState(cargando: false, configurado: true, listo: exito)),
      (falla) => emit(NipState(cargando: false, configurado: state.configurado, error: falla.message)),
    );
  }
}

/// NIP de transacciones desde el perfil del cliente.
class NipPage extends StatefulWidget {
  const NipPage({required this.onTerminar, super.key});

  final VoidCallback onTerminar;

  @override
  State<NipPage> createState() => _NipPageState();
}

class _NipPageState extends State<NipPage> {
  String? _actual;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<NipCubit>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NipCubit, NipState>(
      builder: (context, estado) {
        final cubit = context.read<NipCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(estado.configurado ? 'Cambiar NIP' : 'Configurar NIP')),
          body: ContenidoCentrado(child: _contenido(estado, cubit)),
        );
      },
    );
  }

  Widget _contenido(NipState estado, NipCubit cubit) {
    if (estado.cargando) return const LoadingView(mensaje: 'Consultando tu NIP');
    if (estado.listo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.verified_user, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(estado.listo!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          AppButton(texto: 'Listo', expandir: true, onPressed: widget.onTerminar),
        ],
      );
    }
    if (!estado.configurado) {
      return CrearNipView(
        explicacion: 'Tu NIP de 4 dígitos confirma cada compra o pago de servicio. No lo compartas con nadie.',
        error: estado.error,
        ocupado: estado.ocupado,
        onCrear: cubit.crear,
      );
    }
    // Cambio: primero el NIP actual, luego el nuevo dos veces
    if (_actual == null) {
      return TecladoNip(
        titulo: 'Ingresa tu NIP actual',
        error: estado.error,
        ocupado: estado.ocupado,
        alCompletar: (nip) => setState(() => _actual = nip),
      );
    }
    return CrearNipView(
      explicacion: 'Ahora elige tu NIP nuevo.',
      error: estado.error,
      ocupado: estado.ocupado,
      onCrear: (nuevo, confirmacion) async {
        await cubit.cambiar(_actual!, nuevo, confirmacion);
        // Si el actual era incorrecto se vuelve a pedir desde el principio
        if (mounted && cubit.state.error != null) setState(() => _actual = null);
      },
    );
  }
}
