import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/result/result.dart';
import '../../domain/cambios_cliente.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/datos_cliente.dart';
import '../../domain/repositories/clientes_repository.dart';
import '../models/cliente_model.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  ClientesRepositoryImpl(this._api);

  final ApiClient _api;

  /// Evita repetir la consulta de un mismo codigo postal mientras la app esta abierta.
  final Map<String, InfoCodigoPostal> _codigosPostales = {};

  @override
  Future<Result<RegistroCliente>> registrar(DatosCliente datos, {required String password}) => _ejecutar(
        () async => ClienteModel.registro(
          (await _api.post(ApiEndpoints.clientes, body: ClienteModel.alta(datos, password))).data,
        ),
      );

  @override
  Future<Result<PaginaClientes>> consultar(FiltroClientes filtro) => _ejecutar(
        () async => ClienteModel.pagina(
          (await _api.post(ApiEndpoints.clientesConsulta, body: _filtro(filtro))).data,
        ),
      );

  @override
  Future<Result<ClienteDetalle>> detalle(int id) => _ejecutar(
        () async => ClienteModel.detalle((await _api.post(ApiEndpoints.clientesDetalle, body: {'id': id})).data),
      );

  @override
  Future<Result<ClienteDetalle>> actualizar(Cliente original, DatosCliente nuevos) {
    final cambios = CambiosCliente.calcular(original, nuevos);
    if (cambios.isEmpty) {
      return Future.value(const ErrorResult(ValidationFailure('No modificaste ningún dato')));
    }
    return _patch({'id': original.id, ...cambios});
  }

  @override
  Future<Result<ClienteDetalle>> cambiarEstatus(int id, {required bool activo}) =>
      _patch({'id': id, 'activo': activo});

  @override
  Future<Result<InfoCodigoPostal>> consultarCodigoPostal(String codigoPostal) async {
    final guardado = _codigosPostales[codigoPostal];
    if (guardado != null) return Success(guardado);
    final resultado = await _ejecutar(
      () async => ClienteModel.codigoPostal(
        (await _api.post(ApiEndpoints.codigosPostales, body: {'codigoPostal': codigoPostal})).data,
      ),
    );
    if (resultado case Success(:final data)) _codigosPostales[codigoPostal] = data;
    return resultado;
  }

  Future<Result<ClienteDetalle>> _patch(Map<String, dynamic> cuerpo) => _ejecutar(
        () async => ClienteModel.detalle((await _api.patch(ApiEndpoints.clientes, body: cuerpo)).data),
      );

  /// Solo se envian los criterios con valor; el servidor los combina (AND).
  static Map<String, dynamic> _filtro(FiltroClientes f) {
    String? valor(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    return {
      'nombre': ?valor(f.nombre),
      'apellidoPaterno': ?valor(f.apellidoPaterno),
      'curp': ?valor(f.curp),
      'rfc': ?valor(f.rfc),
      'correo': ?valor(f.correo),
      'activo': ?f.activo,
      'pagina': f.pagina,
      'tamanio': f.tamanio,
    };
  }

  Future<Result<T>> _ejecutar<T>(Future<T> Function() operacion) async {
    try {
      return Success(await operacion());
    } on AppException catch (e) {
      return ErrorResult(Failure.fromException(e));
    }
  }
}
