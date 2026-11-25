import '../../../../core/result/result.dart';
import '../entities/cliente.dart';
import '../entities/datos_cliente.dart';

abstract interface class ClientesRepository {
  /// Alta de cliente (autoregistro o por un ejecutivo). Crea tambien su cuenta y su usuario.
  Future<Result<RegistroCliente>> registrar(DatosCliente datos, {required String password});

  /// Busqueda paginada con filtros combinables (solo EJECUTIVO).
  Future<Result<PaginaClientes>> consultar(FiltroClientes filtro);

  Future<Result<ClienteDetalle>> detalle(int id);

  /// Envia solo los campos que cambiaron respecto a [original].
  Future<Result<ClienteDetalle>> actualizar(Cliente original, DatosCliente nuevos);

  /// Baja logica (false) o reactivacion (true). Solo EJECUTIVO.
  Future<Result<ClienteDetalle>> cambiarEstatus(int id, {required bool activo});

  Future<Result<InfoCodigoPostal>> consultarCodigoPostal(String codigoPostal);
}
