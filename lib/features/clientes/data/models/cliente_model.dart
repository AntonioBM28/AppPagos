import '../../../../core/error/exceptions.dart';
import '../../domain/cambios_cliente.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/datos_cliente.dart';

/// Conversion entre el JSON de la API y las entidades de clientes. Si la respuesta no
/// trae lo esperado se lanza [InvalidResponseException] en lugar de fallar mas adelante.
abstract final class ClienteModel {
  static Cliente cliente(Object? json) {
    try {
      final m = json! as Map<String, dynamic>;
      final d = m['domicilio'] as Map<String, dynamic>;
      return Cliente(
        id: (m['id'] as num).toInt(),
        nombre: m['nombre'] as String,
        segundoNombre: m['segundoNombre'] as String?,
        apellidoPaterno: m['apellidoPaterno'] as String,
        apellidoMaterno: m['apellidoMaterno'] as String,
        fechaNacimiento: DateTime.parse(m['fechaNacimiento'] as String),
        curp: m['curp'] as String,
        rfc: m['rfc'] as String,
        sexo: Sexo.deCodigo(m['sexo'] as String?)!,
        nacionalidad: m['nacionalidad'] as String,
        estadoCivil: EstadoCivil.deCodigo(m['estadoCivil'] as String?)!,
        correo: m['correo'] as String,
        telefonoMovil: m['telefonoMovil'] as String,
        telefonoAlternativo: m['telefonoAlternativo'] as String?,
        domicilio: Domicilio(
          calle: d['calle'] as String,
          numeroExterior: d['numeroExterior'] as String,
          numeroInterior: d['numeroInterior'] as String?,
          colonia: d['colonia'] as String,
          codigoPostal: d['codigoPostal'] as String,
          municipio: d['municipio'] as String?,
          estado: d['estado'] as String?,
        ),
        ocupacion: Ocupacion.deCodigo(m['ocupacion'] as String?),
        empresa: m['empresa'] as String?,
        rangoIngresoMensual: RangoIngreso.deCodigo(m['rangoIngresoMensual'] as String?),
        activo: m['activo'] as bool? ?? true,
      );
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static ClienteDetalle detalle(Map<String, dynamic> json) {
    try {
      return ClienteDetalle(
        cliente: cliente(json['cliente']),
        cuentas: [
          for (final c in (json['cuentas'] as List<dynamic>? ?? const []))
            cuenta(c as Map<String, dynamic>),
        ],
      );
    } on InvalidResponseException {
      rethrow;
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static AbonoSaldo abono(Map<String, dynamic> json) {
    try {
      return AbonoSaldo(
        numeroCuenta: json['numeroCuenta'] as String,
        monto: (json['monto'] as num).toDouble(),
        saldo: (json['saldo'] as num).toDouble(),
      );
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static CuentaResumen cuenta(Map<String, dynamic> json) => CuentaResumen(
        numeroCuenta: json['numeroCuenta'] as String,
        estatus: json['estatus'] as String,
        saldo: (json['saldo'] as num).toDouble(),
      );

  static PaginaClientes pagina(Map<String, dynamic> json) {
    try {
      return PaginaClientes(
        clientes: [for (final c in json['clientes'] as List<dynamic>) cliente(c)],
        pagina: (json['pagina'] as num).toInt(),
        totalPaginas: (json['totalPaginas'] as num).toInt(),
        totalElementos: (json['totalElementos'] as num).toInt(),
      );
    } on InvalidResponseException {
      rethrow;
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static RegistroCliente registro(Map<String, dynamic> json) {
    try {
      return RegistroCliente(
        cliente: cliente(json['cliente']),
        numeroCuenta: (json['cuenta'] as Map<String, dynamic>)['numeroCuenta'] as String,
        usuario: json['usuario'] as String,
      );
    } on InvalidResponseException {
      rethrow;
    } on Object {
      throw const InvalidResponseException();
    }
  }

  static InfoCodigoPostal codigoPostal(Map<String, dynamic> json) {
    try {
      return InfoCodigoPostal(
        codigoPostal: json['codigoPostal'] as String,
        estado: json['estado'] as String,
        municipio: json['municipio'] as String,
        colonias: [for (final c in json['colonias'] as List<dynamic>) c as String],
      );
    } on Object {
      throw const InvalidResponseException();
    }
  }

  /// Cuerpo de POST /clientes. Los opcionales vacios no se envian.
  static Map<String, dynamic> alta(DatosCliente d, String password) => {
        'nombre': d.nombre,
        if (_conValor(d.segundoNombre)) 'segundoNombre': d.segundoNombre,
        'apellidoPaterno': d.apellidoPaterno,
        'apellidoMaterno': d.apellidoMaterno,
        'fechaNacimiento': CambiosCliente.fechaIso(d.fechaNacimiento),
        'curp': d.curp,
        'rfc': d.rfc,
        'sexo': d.sexo.codigo,
        'nacionalidad': d.nacionalidad,
        'estadoCivil': d.estadoCivil.codigo,
        'correo': d.correo,
        'telefonoMovil': d.telefonoMovil,
        if (_conValor(d.telefonoAlternativo)) 'telefonoAlternativo': d.telefonoAlternativo,
        'domicilio': {
          'calle': d.calle,
          'numeroExterior': d.numeroExterior,
          if (_conValor(d.numeroInterior)) 'numeroInterior': d.numeroInterior,
          'colonia': d.colonia,
          'codigoPostal': d.codigoPostal,
        },
        if (d.ocupacion != null) 'ocupacion': d.ocupacion!.codigo,
        if (_conValor(d.empresa)) 'empresa': d.empresa,
        if (d.rangoIngresoMensual != null) 'rangoIngresoMensual': d.rangoIngresoMensual!.codigo,
        'password': password,
      };

  static bool _conValor(String? valor) => valor != null && valor.trim().isNotEmpty;
}
