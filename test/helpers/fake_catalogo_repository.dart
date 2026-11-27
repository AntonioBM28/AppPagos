import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/features/catalogo/domain/catalogo_repository.dart';
import 'package:pagosapp/features/catalogo/domain/entities/producto.dart';

const productosDePrueba = [
  Producto(
    idProducto: 200,
    idServicio: 79,
    idCatTipoServicio: 1,
    tipoFront: 1,
    nombre: r'Telcel $100',
    servicio: 'Telcel',
    precio: 100,
    tipoReferencia: 'a',
    leyenda: 'Recarga de tiempo aire',
    imagenUrl: 'https://img.test/79.png',
  ),
  Producto(
    idProducto: 185,
    idServicio: 56,
    idCatTipoServicio: 15,
    tipoFront: 2,
    tipoReferencia: 'c',
    nombre: 'Agua Cancun',
    servicio: 'AGUAKAN (Cancun)',
    precio: 0,
    imagenUrl: 'https://img.test/56.png',
  ),
];

/// Catalogo en memoria: filtra por texto y servicio como lo haria el servidor.
class FakeCatalogoRepository implements CatalogoRepository {
  final List<FiltroProductos> filtros = [];

  @override
  Future<Result<PaginaProductos>> consultar(FiltroProductos filtro) async {
    filtros.add(filtro);
    final texto = filtro.texto?.toLowerCase();
    final productos = productosDePrueba
        .where((p) => texto == null || '${p.nombre} ${p.servicio}'.toLowerCase().contains(texto))
        .where((p) => filtro.idServicio == null || p.idServicio == filtro.idServicio)
        .toList();
    return Success(PaginaProductos(
      productos: productos,
      pagina: 0,
      totalPaginas: 1,
      totalElementos: productos.length,
      servicios: const [
        ServicioCatalogo(idServicio: 56, servicio: 'AGUAKAN (Cancun)'),
        ServicioCatalogo(idServicio: 79, servicio: 'Telcel'),
      ],
      tiposServicio: const [1, 15],
    ));
  }
}
