import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/operacion.dart';

class HistorialState extends Equatable {
  const HistorialState({
    this.filtro = const FiltroOperaciones(),
    this.operaciones = const [],
    this.total = 0,
    this.hayMas = false,
    this.cargando = false,
    this.cargandoMas = false,
    this.error,
  });

  final FiltroOperaciones filtro;
  final List<Operacion> operaciones;
  final int total;
  final bool hayMas;
  final bool cargando;
  final bool cargandoMas;
  final String? error;

  HistorialState copyWith({
    FiltroOperaciones? filtro,
    List<Operacion>? operaciones,
    int? total,
    bool? hayMas,
    bool? cargando,
    bool? cargandoMas,
    String? error,
  }) =>
      HistorialState(
        filtro: filtro ?? this.filtro,
        operaciones: operaciones ?? this.operaciones,
        total: total ?? this.total,
        hayMas: hayMas ?? this.hayMas,
        cargando: cargando ?? this.cargando,
        cargandoMas: cargandoMas ?? this.cargandoMas,
        error: error,
      );

  @override
  List<Object?> get props => [filtro, operaciones, total, hayMas, cargando, cargandoMas, error];
}

/// Historial paginado: "Operaciones" del ejecutivo o "Mis compras" del cliente.
class HistorialCubit extends Cubit<HistorialState> {
  HistorialCubit(this._consultar) : super(const HistorialState());

  final ConsultarHistorial _consultar;

  Future<void> buscar([FiltroOperaciones? filtro]) async {
    if (state.cargando) return;
    final nuevo = (filtro ?? state.filtro).enPagina(0);
    emit(state.copyWith(filtro: nuevo, cargando: true));
    final resultado = await _consultar(nuevo);
    if (isClosed) return;
    resultado.fold(
      (pagina) => emit(state.copyWith(
        operaciones: pagina.operaciones,
        total: pagina.totalElementos,
        hayMas: pagina.hayMas,
        cargando: false,
      )),
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
      (pagina) => emit(state.copyWith(
        filtro: siguiente,
        operaciones: [...state.operaciones, ...pagina.operaciones],
        total: pagina.totalElementos,
        hayMas: pagina.hayMas,
        cargandoMas: false,
      )),
      (falla) => emit(state.copyWith(cargandoMas: false, error: falla.message)),
    );
  }
}
