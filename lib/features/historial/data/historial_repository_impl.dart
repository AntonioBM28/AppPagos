import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../domain/operacion.dart';

class HistorialRepositoryImpl implements HistorialRepository {
  HistorialRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Result<PaginaOperaciones>> consultar(FiltroOperaciones filtro) async {
    try {
      final respuesta = await _api.post(ApiEndpoints.historial, body: cuerpo(filtro));
      return Success(pagina(respuesta.data));
    } on AppException catch (e) {
      return ErrorResult(Failure.fromException(e));
    }
  }

  static String _fecha(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

  static String? _texto(String? v) => v == null || v.trim().isEmpty ? null : v.trim();

  /// Solo se envian los filtros con valor; el servidor los combina (AND).
  static Map<String, dynamic> cuerpo(FiltroOperaciones f) => {
        'nombreCliente': ?_texto(f.nombreCliente),
        'texto': ?_texto(f.texto),
        'estado': ?f.estado?.codigo,
        'fechaDesde': ?(f.fechaDesde == null ? null : _fecha(f.fechaDesde!)),
        'fechaHasta': ?(f.fechaHasta == null ? null : _fecha(f.fechaHasta!)),
        'pagina': f.pagina,
        'tamanio': f.tamanio,
      };

  static PaginaOperaciones pagina(Map<String, dynamic> json) {
    try {
      return PaginaOperaciones(
        operaciones: [
          for (final o in json['operaciones'] as List<dynamic>? ?? const []) operacion(o as Map<String, dynamic>),
        ],
        pagina: json['pagina'] as int? ?? 0,
        totalPaginas: json['totalPaginas'] as int? ?? 0,
        totalElementos: (json['totalElementos'] as num?)?.toInt() ?? 0,
      );
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static Operacion operacion(Map<String, dynamic> o) => Operacion(
        id: o['id'] as String,
        fecha: DateTime.parse(o['fecha'] as String).toLocal(),
        estado: EstadoOperacion.deCodigo(o['estado'] as String?),
        monto: (o['monto'] as num).toDouble(),
        producto: o['producto'] as String?,
        servicio: o['servicio'] as String?,
        imagenUrl: o['imagenUrl'] as String?,
        referencia: o['referencia'] as String?,
        numeroCuenta: o['numeroCuenta'] as String?,
        numeroAutorizacion: o['numeroAutorizacion'] as String?,
        folio: o['folio'] as String?,
        detalle: o['detalle'] as String?,
        motivo: o['motivo'] as String?,
        codigoProveedor: o['codigoProveedor'] as String?,
        upc: o['upc'] as String?,
        clienteId: o['clienteId'] as int?,
        nombreCliente: o['nombreCliente'] as String?,
      );
}
