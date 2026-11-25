import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cliente.dart';
import '../../domain/entities/datos_cliente.dart';
import '../../domain/usecases/clientes_usecases.dart';

// =========================================================================== Lista

class ClientesState extends Equatable {
  const ClientesState({
    this.filtro = const FiltroClientes(),
    this.clientes = const [],
    this.total = 0,
    this.hayMas = false,
    this.cargando = false,
    this.cargandoMas = false,
    this.error,
  });

  final FiltroClientes filtro;
  final List<Cliente> clientes;
  final int total;
  final bool hayMas;
  final bool cargando;
  final bool cargandoMas;
  final String? error;

  ClientesState copyWith({
    FiltroClientes? filtro,
    List<Cliente>? clientes,
    int? total,
    bool? hayMas,
    bool? cargando,
    bool? cargandoMas,
    String? error,
  }) =>
      ClientesState(
        filtro: filtro ?? this.filtro,
        clientes: clientes ?? this.clientes,
        total: total ?? this.total,
        hayMas: hayMas ?? this.hayMas,
        cargando: cargando ?? this.cargando,
        cargandoMas: cargandoMas ?? this.cargandoMas,
        error: error,
      );

  @override
  List<Object?> get props => [filtro, clientes, total, hayMas, cargando, cargandoMas, error];
}

/// Busqueda paginada de clientes (EJECUTIVO). Una busqueda nueva reemplaza la lista y
/// "cargar mas" agrega la siguiente pagina; mientras hay una peticion en curso las demas
/// se ignoran.
class ClientesCubit extends Cubit<ClientesState> {
  ClientesCubit(this._consultar) : super(const ClientesState());

  final ConsultarClientes _consultar;

  Future<void> buscar([FiltroClientes? filtro]) async {
    if (state.cargando) return;
    final nuevo = (filtro ?? state.filtro).enPagina(0);
    emit(state.copyWith(filtro: nuevo, cargando: true));
    final resultado = await _consultar(nuevo);
    if (isClosed) return;
    resultado.fold(
      (pagina) => emit(
        state.copyWith(clientes: pagina.clientes, total: pagina.totalElementos, hayMas: pagina.hayMas, cargando: false),
      ),
      (falla) => emit(state.copyWith(cargando: false, error: falla.message)),
    );
  }

  Future<void> cargarMas() async {
    if (state.cargando || state.cargandoMas || !state.hayMas) return;
    final siguiente = state.filtro.enPagina(state.filtro.pagina + 1);
    emit(state.copyWith(cargandoMas: true));
    final resultado = await _consultar(siguiente);
    if (isClosed) return;
    resultado.fold(
      (pagina) => emit(
        state.copyWith(
          filtro: siguiente,
          clientes: [...state.clientes, ...pagina.clientes],
          total: pagina.totalElementos,
          hayMas: pagina.hayMas,
          cargandoMas: false,
        ),
      ),
      (falla) => emit(state.copyWith(cargandoMas: false, error: falla.message)),
    );
  }
}

// =========================================================================== Detalle

class ClienteDetalleState extends Equatable {
  const ClienteDetalleState({this.detalle, this.cargando = true, this.cambiandoEstatus = false, this.error, this.aviso});

  final ClienteDetalle? detalle;
  final bool cargando;
  final bool cambiandoEstatus;
  final String? error;
  final String? aviso;

  ClienteDetalleState copyWith({
    ClienteDetalle? detalle,
    bool? cargando,
    bool? cambiandoEstatus,
    String? error,
    String? aviso,
  }) =>
      ClienteDetalleState(
        detalle: detalle ?? this.detalle,
        cargando: cargando ?? this.cargando,
        cambiandoEstatus: cambiandoEstatus ?? this.cambiandoEstatus,
        error: error,
        aviso: aviso,
      );

  @override
  List<Object?> get props => [detalle, cargando, cambiandoEstatus, error, aviso];
}

class ClienteDetalleCubit extends Cubit<ClienteDetalleState> {
  ClienteDetalleCubit({required this.id, required this._obtener, required this._cambiarEstatus})
      : super(const ClienteDetalleState());

  final int id;
  final ObtenerCliente _obtener;
  final CambiarEstatusCliente _cambiarEstatus;

  Future<void> cargar() async {
    emit(state.copyWith(cargando: true));
    final resultado = await _obtener(id);
    if (isClosed) return;
    resultado.fold(
      (detalle) => emit(state.copyWith(detalle: detalle, cargando: false)),
      (falla) => emit(state.copyWith(cargando: false, error: falla.message)),
    );
  }

  /// Baja logica (activo = false) o reactivacion.
  Future<void> cambiarEstatus({required bool activo}) async {
    if (state.cambiandoEstatus) return;
    emit(state.copyWith(cambiandoEstatus: true));
    final resultado = await _cambiarEstatus(id, activo: activo);
    if (isClosed) return;
    resultado.fold(
      (detalle) => emit(
        state.copyWith(
          detalle: detalle,
          cambiandoEstatus: false,
          aviso: activo ? 'El cliente fue reactivado' : 'El cliente fue dado de baja',
        ),
      ),
      (falla) => emit(state.copyWith(cambiandoEstatus: false, error: falla.message)),
    );
  }

  /// Despues de editar, la pantalla de detalle muestra los datos nuevos sin consultar.
  void actualizado(ClienteDetalle detalle) => emit(state.copyWith(detalle: detalle, aviso: 'Datos actualizados'));
}

// =========================================================================== Formulario

/// Estado comun del alta y la edicion.
class FormularioClienteState extends Equatable {
  const FormularioClienteState({this.guardando = false, this.error, this.registro, this.actualizado});

  final bool guardando;
  final String? error;
  final RegistroCliente? registro;
  final ClienteDetalle? actualizado;

  @override
  List<Object?> get props => [guardando, error, registro, actualizado];
}

class RegistroClienteCubit extends Cubit<FormularioClienteState> {
  RegistroClienteCubit(this._registrar) : super(const FormularioClienteState());

  final RegistrarCliente _registrar;

  Future<void> registrar(DatosCliente datos, {required String password}) async {
    if (state.guardando) return;
    emit(const FormularioClienteState(guardando: true));
    final resultado = await _registrar(datos, password: password);
    if (isClosed) return;
    resultado.fold(
      (registro) => emit(FormularioClienteState(registro: registro)),
      (falla) => emit(FormularioClienteState(error: falla.message)),
    );
  }
}

class EditarClienteCubit extends Cubit<FormularioClienteState> {
  EditarClienteCubit(this._actualizar) : super(const FormularioClienteState());

  final ActualizarCliente _actualizar;

  Future<void> guardar(Cliente original, DatosCliente nuevos) async {
    if (state.guardando) return;
    emit(const FormularioClienteState(guardando: true));
    final resultado = await _actualizar(original, nuevos);
    if (isClosed) return;
    resultado.fold(
      (detalle) => emit(FormularioClienteState(actualizado: detalle)),
      (falla) => emit(FormularioClienteState(error: falla.message)),
    );
  }
}
