import 'package:equatable/equatable.dart';

import 'cliente.dart';

/// Lo que se captura en el formulario de cliente (alta o edicion). La CURP y el RFC
/// solo se envian en el alta: despues son inmutables.
class DatosCliente extends Equatable {
  const DatosCliente({
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
    required this.calle,
    required this.numeroExterior,
    required this.colonia,
    required this.codigoPostal,

    this.segundoNombre,
    this.ocupacion,
    this.empresa,
    this.rangoIngresoMensual,
    this.telefonoAlternativo,
    this.numeroInterior,
  });

  /// Para precargar el formulario de edicion.
  factory DatosCliente.desde(Cliente c) => DatosCliente(
        nombre: c.nombre,
        segundoNombre: c.segundoNombre,
        apellidoPaterno: c.apellidoPaterno,
        apellidoMaterno: c.apellidoMaterno,
        fechaNacimiento: c.fechaNacimiento,
        curp: c.curp,
        rfc: c.rfc,
        sexo: c.sexo,
        nacionalidad: c.nacionalidad,
        estadoCivil: c.estadoCivil,
        correo: c.correo,
        telefonoMovil: c.telefonoMovil,
        telefonoAlternativo: c.telefonoAlternativo,
        calle: c.domicilio.calle,
        numeroExterior: c.domicilio.numeroExterior,
        numeroInterior: c.domicilio.numeroInterior,
        colonia: c.domicilio.colonia,
        codigoPostal: c.domicilio.codigoPostal,
        ocupacion: c.ocupacion,
        empresa: c.empresa,
        rangoIngresoMensual: c.rangoIngresoMensual,
      );

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
  final String calle;
  final String numeroExterior;
  final String? numeroInterior;
  final String colonia;
  final String codigoPostal;
  final Ocupacion? ocupacion;
  final String? empresa;
  final RangoIngreso? rangoIngresoMensual;

  @override
  List<Object?> get props => [
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
        calle,
        numeroExterior,
        numeroInterior,
        colonia,
        codigoPostal,
        ocupacion,
        empresa,
        rangoIngresoMensual,
      ];
}
