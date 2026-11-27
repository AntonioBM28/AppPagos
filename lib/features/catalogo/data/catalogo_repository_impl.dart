import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../domain/catalogo_repository.dart';
import '../domain/entities/producto.dart';

class CatalogoRepositoryImpl implements CatalogoRepository {
  CatalogoRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Result<PaginaProductos>> consultar(FiltroProductos filtro) async {
    try {
      final respuesta = await _api.post(ApiEndpoints.productosConsulta, body: cuerpo(filtro));
      return Success(pagina(respuesta.data));
    } on AppException catch (e) {
      return ErrorResult(Failure.fromException(e));
    }
  }

  /// Solo se envian los filtros con valor; el servidor los combina (AND).
  static Map<String, dynamic> cuerpo(FiltroProductos f) {
    final texto = f.texto?.trim();
    return {
      if (texto != null && texto.isNotEmpty) 'texto': texto,
      'idServicio': ?f.idServicio,
      'idCatTipoServicio': ?f.idCatTipoServicio,
      'precioMin': ?f.precioMin,
      'precioMax': ?f.precioMax,
      'orden': f.orden.codigo,
      'pagina': f.pagina,
      'tamanio': f.tamanio,
    };
  }

  static PaginaProductos pagina(Map<String, dynamic> json) {
    try {
      return PaginaProductos(
        productos: [
          for (final p in json['productos'] as List<dynamic>? ?? const []) producto(p as Map<String, dynamic>),
        ],
        pagina: json['pagina'] as int? ?? 0,
        totalPaginas: json['totalPaginas'] as int? ?? 0,
        totalElementos: (json['totalElementos'] as num?)?.toInt() ?? 0,
        servicios: [
          for (final s in json['servicios'] as List<dynamic>? ?? const [])
            ServicioCatalogo(
              idServicio: (s as Map<String, dynamic>)['idServicio'] as int,
              servicio: s['servicio'] as String,
              imagenUrl: s['imagenUrl'] as String?,
            ),
        ],
        tiposServicio: [for (final t in json['tiposServicio'] as List<dynamic>? ?? const []) t as int],
      );
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static Producto producto(Map<String, dynamic> p) => Producto(
        idProducto: p['idProducto'] as int,
        idServicio: p['idServicio'] as int,
        idCatTipoServicio: p['idCatTipoServicio'] as int?,
        tipoFront: p['tipoFront'] as int?,
        nombre: p['nombre'] as String? ?? '',
        servicio: p['servicio'] as String? ?? '',
        precio: (p['precio'] as num?)?.toDouble() ?? 0,
        tipoReferencia: p['tipoReferencia'] as String?,
        leyenda: (p['leyenda'] as String?)?.trim(),
        imagenUrl: p['imagenUrl'] as String?,
      );
}
