import 'entities/cliente.dart';
import 'entities/datos_cliente.dart';

/// Calcula el cuerpo de PATCH /clientes: solo los campos que cambiaron.
///
/// La CURP y el RFC nunca se incluyen (son inmutables). En los opcionales, una cadena
/// vacia ("") le indica al servidor que elimine el valor.
abstract final class CambiosCliente {
  static Map<String, dynamic> calcular(Cliente original, DatosCliente nuevos) {
    final cambios = <String, dynamic>{};

    void comparar(String campo, Object? antes, Object? despues) {
      if (antes != despues) cambios[campo] = despues;
    }

    String opcional(String? valor) => valor?.trim() ?? '';

    comparar('nombre', original.nombre, nuevos.nombre);
    comparar('segundoNombre', opcional(original.segundoNombre), opcional(nuevos.segundoNombre));
    comparar('apellidoPaterno', original.apellidoPaterno, nuevos.apellidoPaterno);
    comparar('apellidoMaterno', original.apellidoMaterno, nuevos.apellidoMaterno);
    if (!_mismaFecha(original.fechaNacimiento, nuevos.fechaNacimiento)) {
      cambios['fechaNacimiento'] = fechaIso(nuevos.fechaNacimiento);
    }
    if (original.sexo != nuevos.sexo) cambios['sexo'] = nuevos.sexo.codigo;
    comparar('nacionalidad', original.nacionalidad, nuevos.nacionalidad);
    if (original.estadoCivil != nuevos.estadoCivil) cambios['estadoCivil'] = nuevos.estadoCivil.codigo;
    comparar('correo', original.correo, nuevos.correo);
    comparar('telefonoMovil', original.telefonoMovil, nuevos.telefonoMovil);
    comparar('telefonoAlternativo', opcional(original.telefonoAlternativo), opcional(nuevos.telefonoAlternativo));
    comparar('ocupacion', original.ocupacion?.codigo ?? '', nuevos.ocupacion?.codigo ?? '');
    comparar('empresa', opcional(original.empresa), opcional(nuevos.empresa));
    comparar('rangoIngresoMensual', original.rangoIngresoMensual?.codigo ?? '', nuevos.rangoIngresoMensual?.codigo ?? '');

    final d = original.domicilio;
    final domicilio = <String, dynamic>{};
    void compararDomicilio(String campo, Object? antes, Object? despues) {
      if (antes != despues) domicilio[campo] = despues;
    }

    compararDomicilio('calle', d.calle, nuevos.calle);
    compararDomicilio('numeroExterior', d.numeroExterior, nuevos.numeroExterior);
    compararDomicilio('numeroInterior', opcional(d.numeroInterior), opcional(nuevos.numeroInterior));
    compararDomicilio('codigoPostal', d.codigoPostal, nuevos.codigoPostal);
    compararDomicilio('colonia', d.colonia, nuevos.colonia);
    // Si cambia el codigo postal, el servidor exige la colonia para validarla con el nuevo codigo
    if (domicilio.containsKey('codigoPostal')) domicilio['colonia'] = nuevos.colonia;
    if (domicilio.isNotEmpty) cambios['domicilio'] = domicilio;

    return cambios;
  }

  static bool _mismaFecha(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String fechaIso(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
}
