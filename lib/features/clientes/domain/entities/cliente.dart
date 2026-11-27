import 'package:equatable/equatable.dart';

enum Sexo {
  h('H', 'Hombre'),
  m('M', 'Mujer');

  const Sexo(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static Sexo? deCodigo(String? codigo) =>
      Sexo.values.where((s) => s.codigo == codigo).firstOrNull;
}

enum EstadoCivil {
  soltero('SOLTERO', 'Soltero(a)'),
  casado('CASADO', 'Casado(a)'),
  divorciado('DIVORCIADO', 'Divorciado(a)'),
  viudo('VIUDO', 'Viudo(a)'),
  unionLibre('UNION_LIBRE', 'Unión libre');

  const EstadoCivil(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoCivil? deCodigo(String? codigo) =>
      EstadoCivil.values.where((e) => e.codigo == codigo).firstOrNull;
}

/// Catalogo de ocupaciones (mismo que el backend).
enum Ocupacion {
  empleadoSectorPrivado('EMPLEADO_SECTOR_PRIVADO', 'Empleado(a) del sector privado'),
  servidorPublico('SERVIDOR_PUBLICO', 'Servidor(a) público(a)'),
  profesionistaIndependiente('PROFESIONISTA_INDEPENDIENTE', 'Profesionista independiente'),
  empresario('EMPRESARIO', 'Empresario(a)'),
  comerciante('COMERCIANTE', 'Comerciante'),
  trabajadorPorCuentaPropia('TRABAJADOR_POR_CUENTA_PROPIA', 'Trabajador(a) por cuenta propia'),
  oficioTecnico('OFICIO_TECNICO', 'Oficio o técnico(a)'),
  docente('DOCENTE', 'Docente'),
  profesionalDeLaSalud('PROFESIONAL_DE_LA_SALUD', 'Profesional de la salud'),
  fuerzasArmadasSeguridad('FUERZAS_ARMADAS_SEGURIDAD', 'Fuerzas armadas o seguridad'),
  agropecuario('AGROPECUARIO', 'Agricultura, ganadería o pesca'),
  estudiante('ESTUDIANTE', 'Estudiante'),
  hogar('HOGAR', 'Dedicado(a) al hogar'),
  jubiladoPensionado('JUBILADO_PENSIONADO', 'Jubilado(a) o pensionado(a)'),
  desempleado('DESEMPLEADO', 'Sin empleo'),
  otra('OTRA', 'Otra');

  const Ocupacion(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static Ocupacion? deCodigo(String? codigo) =>
      Ocupacion.values.where((o) => o.codigo == codigo).firstOrNull;
}

/// Tabulador de ingreso mensual: el cliente elige un rango, no escribe un monto.
enum RangoIngreso {
  hasta5000('HASTA_5000', r'Hasta $5,000'),
  de5001a10000('DE_5001_A_10000', r'$5,001 a $10,000'),
  de10001a20000('DE_10001_A_20000', r'$10,001 a $20,000'),
  de20001a35000('DE_20001_A_35000', r'$20,001 a $35,000'),
  de35001a50000('DE_35001_A_50000', r'$35,001 a $50,000'),
  de50001a100000('DE_50001_A_100000', r'$50,001 a $100,000'),
  masDe100000('MAS_DE_100000', r'Más de $100,000');

  const RangoIngreso(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static RangoIngreso? deCodigo(String? codigo) =>
      RangoIngreso.values.where((r) => r.codigo == codigo).firstOrNull;
}

class Domicilio extends Equatable {
  const Domicilio({
    required this.calle,
    required this.numeroExterior,
    required this.colonia,
    required this.codigoPostal,
    this.numeroInterior,
    this.municipio,
    this.estado,
  });

  final String calle;
  final String numeroExterior;
  final String? numeroInterior;
  final String colonia;
  final String codigoPostal;

  /// Los asigna el servidor a partir del codigo postal.
  final String? municipio;
  final String? estado;

  String get resumen {
    final interior = numeroInterior == null || numeroInterior!.isEmpty ? '' : ' int. $numeroInterior';
    return '$calle $numeroExterior$interior, $colonia, C.P. $codigoPostal'
        '${municipio == null ? '' : ', $municipio'}${estado == null ? '' : ', $estado'}';
  }

  @override
  List<Object?> get props => [calle, numeroExterior, numeroInterior, colonia, codigoPostal, municipio, estado];
}

/// Datos del cliente tal como los devuelve la API.
class Cliente extends Equatable {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.fechaNacimiento,
    required this.curp,
    required this.rfc,
    required this.sexo,
    required this.nacionalidad,
    required this.estadoCivil,
    required this.correo,
    required this.telefonoMovil,
    required this.domicilio,

    required this.activo,
    this.segundoNombre,
    this.ocupacion,
    this.empresa,
    this.rangoIngresoMensual,
    this.telefonoAlternativo,
  });

  final int id;
  final String nombre;
  final String? segundoNombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final DateTime fechaNacimiento;
  final String curp;
  final String rfc;
  final Sexo sexo;
  final String nacionalidad;
  final EstadoCivil estadoCivil;
  final String correo;
  final String telefonoMovil;
  final String? telefonoAlternativo;
  final Domicilio domicilio;
  final Ocupacion? ocupacion;
  final String? empresa;
  final RangoIngreso? rangoIngresoMensual;
  final bool activo;

  String get nombreCompleto => [nombre, segundoNombre, apellidoPaterno, apellidoMaterno]
      .where((parte) => parte != null && parte.isNotEmpty)
      .join(' ');

  @override
  List<Object?> get props => [
        id,
        nombre,
        segundoNombre,
        apellidoPaterno,
        apellidoMaterno,
        fechaNacimiento,
        curp,
        rfc,
        sexo,
        nacionalidad,
        estadoCivil,
        correo,
        telefonoMovil,
        telefonoAlternativo,
        domicilio,
        ocupacion,
        empresa,
        rangoIngresoMensual,
        activo,
      ];
}

class CuentaResumen extends Equatable {
  const CuentaResumen({required this.numeroCuenta, required this.estatus, required this.saldo});

  final String numeroCuenta;
  final String estatus;
  final double saldo;

  bool get activa => estatus == 'ACTIVA';

  @override
  List<Object?> get props => [numeroCuenta, estatus, saldo];
}

/// Resultado de abonar saldo a una cuenta.
class AbonoSaldo extends Equatable {
  const AbonoSaldo({required this.numeroCuenta, required this.monto, required this.saldo});

  final String numeroCuenta;
  final double monto;

  /// Saldo de la cuenta despues del abono.
  final double saldo;

  @override
  List<Object?> get props => [numeroCuenta, monto, saldo];
}

class ClienteDetalle extends Equatable {
  const ClienteDetalle({required this.cliente, required this.cuentas});

  final Cliente cliente;
  final List<CuentaResumen> cuentas;

  @override
  List<Object?> get props => [cliente, cuentas];
}

class PaginaClientes extends Equatable {
  const PaginaClientes({
    required this.clientes,
    required this.pagina,
    required this.totalPaginas,
    required this.totalElementos,
  });

  final List<Cliente> clientes;
  final int pagina;
  final int totalPaginas;
  final int totalElementos;

  bool get hayMas => pagina + 1 < totalPaginas;

  @override
  List<Object?> get props => [clientes, pagina, totalPaginas, totalElementos];
}

/// Criterios de busqueda combinables (todos opcionales).
class FiltroClientes extends Equatable {
  const FiltroClientes({
    this.nombre,
    this.apellidoPaterno,
    this.curp,
    this.rfc,
    this.correo,
    this.activo,
    this.pagina = 0,
    this.tamanio = 20,
  });

  /// Nombre o apellido que empieza con este texto.
  final String? nombre;
  final String? apellidoPaterno;
  final String? curp;
  final String? rfc;
  final String? correo;
  final bool? activo;
  final int pagina;
  final int tamanio;

  bool get tieneCriterios => [nombre, apellidoPaterno, curp, rfc, correo].any((v) => v != null && v.isNotEmpty) ||
      activo != null;

  FiltroClientes enPagina(int pagina) => FiltroClientes(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        curp: curp,
        rfc: rfc,
        correo: correo,
        activo: activo,
        pagina: pagina,
        tamanio: tamanio,
      );

  @override
  List<Object?> get props => [nombre, apellidoPaterno, curp, rfc, correo, activo, pagina, tamanio];
}

/// Informacion de un codigo postal: el estado y municipio los define el codigo, y la
/// colonia se elige de la lista.
class InfoCodigoPostal extends Equatable {
  const InfoCodigoPostal({
    required this.codigoPostal,
    required this.estado,
    required this.municipio,
    required this.colonias,
  });

  final String codigoPostal;
  final String estado;
  final String municipio;
  final List<String> colonias;

  @override
  List<Object?> get props => [codigoPostal, estado, municipio, colonias];
}

/// Resultado del registro.
class RegistroCliente extends Equatable {
  const RegistroCliente({required this.cliente, required this.numeroCuenta, required this.usuario});

  final Cliente cliente;
  final String numeroCuenta;
  final String usuario;

  @override
  List<Object?> get props => [cliente, numeroCuenta, usuario];
}
