import '../../../../core/result/result.dart';
import '../entities/cliente.dart';
import '../entities/datos_cliente.dart';
import '../repositories/clientes_repository.dart';

class RegistrarCliente {
  const RegistrarCliente(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<RegistroCliente>> call(DatosCliente datos, {required String password}) =>
      _repositorio.registrar(datos, password: password);
}

class ConsultarClientes {
  const ConsultarClientes(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<PaginaClientes>> call(FiltroClientes filtro) => _repositorio.consultar(filtro);
}

class ObtenerCliente {
  const ObtenerCliente(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<ClienteDetalle>> call(int id) => _repositorio.detalle(id);
}

class ActualizarCliente {
  const ActualizarCliente(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<ClienteDetalle>> call(Cliente original, DatosCliente nuevos) =>
      _repositorio.actualizar(original, nuevos);
}

/// Baja logica (activo = false) o reactivacion. El servidor desactiva tambien las
/// cuentas y el usuario del cliente; no se borra nada.
class CambiarEstatusCliente {
  const CambiarEstatusCliente(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<ClienteDetalle>> call(int id, {required bool activo}) =>
      _repositorio.cambiarEstatus(id, activo: activo);
}

class AbonarSaldo {
  const AbonarSaldo(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<AbonoSaldo>> call(String numeroCuenta, {required double monto, String? concepto}) =>
      _repositorio.abonarSaldo(numeroCuenta, monto: monto, concepto: concepto);
}

class ConsultarCodigoPostal {
  const ConsultarCodigoPostal(this._repositorio);
  final ClientesRepository _repositorio;

  Future<Result<InfoCodigoPostal>> call(String codigoPostal) => _repositorio.consultarCodigoPostal(codigoPostal);
}
