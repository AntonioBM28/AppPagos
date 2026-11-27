import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/features/clientes/domain/cambios_cliente.dart';
import 'package:pagosapp/features/clientes/domain/entities/cliente.dart';
import 'package:pagosapp/features/clientes/domain/entities/datos_cliente.dart';
import 'package:pagosapp/features/clientes/domain/repositories/clientes_repository.dart';

/// Cliente valido de ejemplo: CURP, RFC, fecha y sexo coinciden entre si.
Cliente clienteDePrueba({int id = 7, bool activo = true}) => Cliente(
      id: id,
      nombre: 'Jose',
      segundoNombre: 'Antonio',
      apellidoPaterno: 'Balderas',
      apellidoMaterno: 'Martinez',
      fechaNacimiento: DateTime(1990, 5, 12),
      curp: 'BAMJ900512HGTLRS09',
      rfc: 'BAMJ900512AB1',
      sexo: Sexo.h,
      nacionalidad: 'MEX',
      estadoCivil: EstadoCivil.soltero,
      correo: 'jose@mail.com',
      telefonoMovil: '5512345678',
      domicilio: const Domicilio(
        calle: 'Hidalgo',
        numeroExterior: '10',
        colonia: 'Centro',
        codigoPostal: '37000',
        municipio: 'León',
        estado: 'Guanajuato',
      ),
      ocupacion: Ocupacion.empleadoSectorPrivado,
      empresa: 'ACME',
      rangoIngresoMensual: RangoIngreso.de20001a35000,
      activo: activo,
    );

const infoCpDePrueba = InfoCodigoPostal(
  codigoPostal: '37000',
  estado: 'Guanajuato',
  municipio: 'León',
  colonias: ['Centro', 'Obregón'],
);

/// Repositorio en memoria para pruebas de Cubits y pantallas.
class FakeClientesRepository implements ClientesRepository {
  final List<Map<String, dynamic>> patches = [];
  final List<FiltroClientes> filtros = [];
  DatosCliente? registrado;
  String? passwordRegistrado;
  Failure? fallaRegistro;
  Cliente cliente = clienteDePrueba();
  int totalClientes = 1;

  @override
  Future<Result<RegistroCliente>> registrar(DatosCliente datos, {required String password}) async {
    registrado = datos;
    passwordRegistrado = password;
    if (fallaRegistro != null) return ErrorResult(fallaRegistro!);
    return Success(RegistroCliente(cliente: cliente, numeroCuenta: '1000000009', usuario: datos.correo));
  }

  @override
  Future<Result<PaginaClientes>> consultar(FiltroClientes filtro) async {
    filtros.add(filtro);
    final paginas = (totalClientes / filtro.tamanio).ceil();
    final desde = filtro.pagina * filtro.tamanio;
    final cuantos = (totalClientes - desde).clamp(0, filtro.tamanio);
    return Success(
      PaginaClientes(
        clientes: [for (var i = 0; i < cuantos; i++) clienteDePrueba(id: desde + i + 1)],
        pagina: filtro.pagina,
        totalPaginas: paginas,
        totalElementos: totalClientes,
      ),
    );
  }

  @override
  Future<Result<ClienteDetalle>> detalle(int id) async =>
      Success(ClienteDetalle(
        cliente: cliente,
        cuentas: [CuentaResumen(numeroCuenta: '1000000009', estatus: cliente.activo ? 'ACTIVA' : 'INACTIVA', saldo: saldo)],
      ));

  @override
  Future<Result<ClienteDetalle>> actualizar(Cliente original, DatosCliente nuevos) async {
    final cambios = CambiosCliente.calcular(original, nuevos);
    if (cambios.isEmpty) return const ErrorResult(ValidationFailure('No modificaste ningún dato'));
    patches.add({'id': original.id, ...cambios});
    return detalle(original.id);
  }

  @override
  Future<Result<ClienteDetalle>> cambiarEstatus(int id, {required bool activo}) async {
    patches.add({'id': id, 'activo': activo});
    cliente = clienteDePrueba(id: id, activo: activo);
    return detalle(id);
  }

  final List<({String numeroCuenta, double monto, String? concepto})> abonos = [];
  double saldo = 0;

  @override
  Future<Result<AbonoSaldo>> abonarSaldo(String numeroCuenta, {required double monto, String? concepto}) async {
    abonos.add((numeroCuenta: numeroCuenta, monto: monto, concepto: concepto));
    saldo += monto;
    return Success(AbonoSaldo(numeroCuenta: numeroCuenta, monto: monto, saldo: saldo));
  }

  @override
  Future<Result<InfoCodigoPostal>> consultarCodigoPostal(String codigoPostal) async => codigoPostal == '37000'
      ? const Success(infoCpDePrueba)
      : const ErrorResult(NotFoundFailure('El codigo postal no existe'));
}
