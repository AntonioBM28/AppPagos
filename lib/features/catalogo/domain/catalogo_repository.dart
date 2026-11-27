import '../../../core/result/result.dart';
import 'entities/producto.dart';

/// Catalogo de productos de GestoPago: solo consulta, no se puede modificar.
abstract interface class CatalogoRepository {
  Future<Result<PaginaProductos>> consultar(FiltroProductos filtro);
}

class ConsultarCatalogo {
  const ConsultarCatalogo(this._repositorio);
  final CatalogoRepository _repositorio;

  Future<Result<PaginaProductos>> call(FiltroProductos filtro) => _repositorio.consultar(filtro);
}
