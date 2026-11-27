import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../../historial/domain/operacion.dart';
import '../domain/compra.dart';

class ComprasRepositoryImpl implements ComprasRepository {
  ComprasRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Result<bool>> nipConfigurado() =>
      _ejecutar(() async => (await _api.get(ApiEndpoints.nip)).data['configurado'] == true);

  @override
  Future<Result<void>> crearNip(String nip, String confirmacion) =>
      _ejecutar(() => _api.post(ApiEndpoints.nip, body: {'nip': nip, 'confirmacion': confirmacion}));

  @override
  Future<Result<void>> cambiarNip({required String actual, required String nuevo, required String confirmacion}) =>
      _ejecutar(
        () => _api.patch(ApiEndpoints.nip, body: {'nipActual': actual, 'nip': nuevo, 'confirmacion': confirmacion}),
      );

  @override
  Future<Result<TokenDinamico>> autorizar(SolicitudCompra compra, String nip) => _ejecutar(() async {
        final data = (await _api.post(ApiEndpoints.autorizacionCompra, body: {...cuerpo(compra), 'nip': nip})).data;
        try {
          return TokenDinamico(
            autorizacionId: data['autorizacionId'] as String,
            token: data['tokenDinamico'] as String,
            vigencia: Duration(seconds: (data['vigenciaSegundos'] as num).toInt()),
          );
        } on Object {
          throw const InvalidResponseException();
        }
      });

  @override
  Future<Result<Ticket>> comprar(SolicitudCompra compra, TokenDinamico token, {required String claveIdempotencia}) =>
      _ejecutar(() async {
        final respuesta = await _api.post(
          ApiEndpoints.transacciones,
          headers: {'Idempotency-Key': claveIdempotencia},
          body: {...cuerpo(compra), 'autorizacionId': token.autorizacionId, 'tokenDinamico': token.token},
          aceptarRechazo: true,
        );
        return ticket(respuesta.data);
      });

  static Map<String, dynamic> cuerpo(SolicitudCompra c) => {
        'numeroCuenta': c.numeroCuenta,
        'idServicio': c.idServicio,
        'idProducto': c.idProducto,
        'monto': c.monto,
        if (c.destino != null && c.destino!.isNotEmpty) 'destino': c.destino,
        if (c.referencia != null && c.referencia!.isNotEmpty) 'referencia': c.referencia,
      };

  static Ticket ticket(Map<String, dynamic> t) {
    try {
      return Ticket(
        id: t['id'] as String,
        estado: EstadoOperacion.deCodigo(t['estado'] as String?),
        fecha: DateTime.parse(t['fechaCreacion'] as String).toLocal(),
        monto: (t['monto'] as num).toDouble(),
        mensaje: t['mensaje'] as String?,
        motivo: t['motivo'] as String?,
        codigoRespuesta: t['codigoProveedor'] as String?,
        producto: t['producto'] as String?,
        servicio: t['servicio'] as String?,
        imagenUrl: t['imagenUrl'] as String?,
        referencia: t['referencia'] as String?,
        numeroCuenta: t['numeroCuenta'] as String?,
        nombreCliente: t['nombreCliente'] as String?,
        saldoDisponible: (t['saldoDisponible'] as num?)?.toDouble(),
        numeroAutorizacion: t['numeroAutorizacion'] as String?,
        folio: t['folio'] as String?,
        pin: t['pin'] as String?,
        leyenda: t['leyenda'] as String?,
        upc: t['upc'] as String?,
      );
    } on Object {
      throw const InvalidResponseException();
    }
  }

  Future<Result<T>> _ejecutar<T>(Future<T> Function() operacion) async {
    try {
      return Success(await operacion());
    } on AppException catch (e) {
      return ErrorResult(Failure.fromException(e));
    }
  }
}
