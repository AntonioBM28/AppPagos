import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/catalogo_repository.dart';
import '../../domain/entities/producto.dart';

class CatalogoState extends Equatable {
  const CatalogoState({
    this.filtro = const FiltroProductos(),
    this.productos = const [],
    this.servicios = const [],
    this.tiposServicio = const [],
    this.total = 0,
    this.hayMas = false,
    this.cargando = false,
    this.cargandoMas = false,
    this.error,
  });

  final FiltroProductos filtro;
  final List<Producto> productos;
  final List<ServicioCatalogo> servicios;
  final List<int> tiposServicio;
  final int total;
  final bool hayMas;
  final bool cargando;
  final bool cargandoMas;
  final String? error;

  CatalogoState copyWith({
    FiltroProductos? filtro,
    List<Producto>? productos,
    List<ServicioCatalogo>? servicios,
    List<int>? tiposServicio,
    int? total,
    bool? hayMas,
    bool? cargando,
    bool? cargandoMas,
    String? error,
  }) =>
      CatalogoState(
        filtro: filtro ?? this.filtro,
        productos: productos ?? this.productos,
        servicios: servicios ?? this.servicios,
        tiposServicio: tiposServicio ?? this.tiposServicio,
        total: total ?? this.total,
        hayMas: hayMas ?? this.hayMas,
        cargando: cargando ?? this.cargando,
        cargandoMas: cargandoMas ?? this.cargandoMas,
        error: error,
      );

  @override
  List<Object?> get props =>
      [filtro, productos, servicios, tiposServicio, total, hayMas, cargando, cargandoMas, error];
}

/// Consulta del catalogo (solo lectura) con filtros combinables y paginacion.
class CatalogoCubit extends Cubit<CatalogoState> {
  CatalogoCubit(this._consultar) : super(const CatalogoState());

  final ConsultarCatalogo _consultar;

  Future<void> buscar([FiltroProductos? filtro]) async {
    if (state.cargando) return;
    final nuevo = (filtro ?? state.filtro).enPagina(0);
    emit(state.copyWith(filtro: nuevo, cargando: true));
    final resultado = await _consultar(nuevo);
    if (isClosed) return;
    resultado.fold(
      (pagina) => emit(state.copyWith(
        productos: pagina.productos,
        servicios: pagina.servicios,
        tiposServicio: pagina.tiposServicio,
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
        productos: [...state.productos, ...pagina.productos],
        total: pagina.totalElementos,
        hayMas: pagina.hayMas,
        cargandoMas: false,
      )),
      (falla) => emit(state.copyWith(cargandoMas: false, error: falla.message)),
    );
  }
}
