import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/network/api_client.dart';
import 'package:pagosapp/core/network/api_endpoints.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';
import 'package:pagosapp/features/clientes/data/repositories/clientes_repository_impl.dart';
import 'package:pagosapp/features/clientes/domain/cambios_cliente.dart';
import 'package:pagosapp/features/clientes/domain/entities/cliente.dart';
import 'package:pagosapp/features/clientes/domain/entities/datos_cliente.dart';

import '../../helpers/fake_clientes_repository.dart';
import '../../helpers/fake_http.dart';

Map<String, dynamic> clienteJson({bool activo = true}) => {
      'id': 7,
      'nombre': 'Jose',
      'segundoNombre': 'Antonio',
      'apellidoPaterno': 'Balderas',
      'apellidoMaterno': 'Martinez',
      'fechaNacimiento': '1990-05-12',
      'curp': 'BAMJ900512HGTLRS09',
      'rfc': 'BAMJ900512AB1',
      'sexo': 'H',
      'nacionalidad': 'MEX',
      'estadoCivil': 'SOLTERO',
      'correo': 'jose@mail.com',
      'telefonoMovil': '5512345678',
      'telefonoAlternativo': null,
      'domicilio': {
        'calle': 'Hidalgo',
        'numeroExterior': '10',
        'numeroInterior': null,
        'colonia': 'Centro',
        'codigoPostal': '37000',
        'municipio': 'León',
        'estado': 'Guanajuato',
        'pais': 'MEX',
      },
      'ocupacion': 'EMPLEADO_SECTOR_PRIVADO',
      'empresa': 'ACME',
      'rangoIngresoMensual': 'DE_20001_A_35000',
      'activo': activo,
    };

Map<String, dynamic> detalleJson({bool activo = true}) => {
      'codigo': 0,
      'mensaje': 'Exito',
      'cliente': clienteJson(activo: activo),
      'cuentas': [
        {'numeroCuenta': '1000000009', 'clienteId': 7, 'estatus': 'ACTIVA', 'saldo': 0},
      ],
    };

void main() {
  late FakeAdapter adapter;

  ClientesRepositoryImpl repositorio(Responder responder) {
    adapter = FakeAdapter(responder);
    return ClientesRepositoryImpl(ApiClient(dioDePrueba(adapter, interceptores: [const ErrorInterceptor()])));
  }

  test('registrar envia todos los datos y omite los opcionales vacios', () async {
    final repo = repositorio(
      (_) async => respuestaJson(201, {
        'codigo': 0,
        'mensaje': 'Cliente registrado',
        'cliente': clienteJson(),
        'cuenta': {'numeroCuenta': '1000000009', 'estatus': 'ACTIVA', 'saldo': 0},
        'usuario': 'jose@mail.com',
      }),
    );
    final datos = DatosCliente.desde(clienteDePrueba());

    final registro = (await repo.registrar(datos, password: 'Segura#2026')).dataOrNull!;

    expect(registro.numeroCuenta, '1000000009');
    final peticion = adapter.peticiones.single;
    final cuerpo = peticion.data as Map<String, dynamic>;
    expect(peticion.method, 'POST');
    expect(peticion.path, '/clientes');
    expect(cuerpo['fechaNacimiento'], '1990-05-12');
    expect(cuerpo['sexo'], 'H');
    expect(cuerpo['password'], 'Segura#2026');
    expect(cuerpo['ocupacion'], 'EMPLEADO_SECTOR_PRIVADO');
    expect(cuerpo['rangoIngresoMensual'], 'DE_20001_A_35000');
    expect(cuerpo.containsKey('ingresoMensual'), isFalse);
    expect(cuerpo.containsKey('telefonoAlternativo'), isFalse);
    expect((cuerpo['domicilio'] as Map).containsKey('numeroInterior'), isFalse);
  });

  test('un dato duplicado (409) devuelve el mensaje del servidor', () async {
    final repo = repositorio(
      (_) async => respuestaJson(409, {'codigo': 1, 'mensaje': 'Ya existe un cliente con esa CURP'}),
    );

    final falla = (await repo.registrar(DatosCliente.desde(clienteDePrueba()), password: 'x')).failureOrNull;

    expect(falla, const ConflictFailure('Ya existe un cliente con esa CURP'));
  });

  test('consultar combina solo los filtros con valor', () async {
    final repo = repositorio(
      (_) async => respuestaJson(200, {
        'codigo': 0,
        'mensaje': 'Exito',
        'pagina': 0,
        'tamanio': 20,
        'totalElementos': 1,
        'totalPaginas': 1,
        'clientes': [clienteJson()],
      }),
    );

    final pagina = (await repo.consultar(const FiltroClientes(nombre: ' Jo ', curp: '', activo: true))).dataOrNull!;

    expect(pagina.clientes.single.nombreCompleto, 'Jose Antonio Balderas Martinez');
    expect(adapter.peticiones.single.data, {'nombre': 'Jo', 'activo': true, 'pagina': 0, 'tamanio': 20});
  });

  test('actualizar envia por PATCH solo lo que cambio, nunca CURP ni RFC', () async {
    final repo = repositorio((_) async => respuestaJson(200, detalleJson()));
    final original = clienteDePrueba();
    final nuevos = DatosCliente(
      nombre: original.nombre,
      apellidoPaterno: original.apellidoPaterno,
      apellidoMaterno: original.apellidoMaterno,
      fechaNacimiento: original.fechaNacimiento,
      curp: original.curp,
      rfc: original.rfc,
      sexo: original.sexo,
      nacionalidad: original.nacionalidad,
      estadoCivil: EstadoCivil.casado,
      correo: original.correo,
      telefonoMovil: '5598765432',
      calle: original.domicilio.calle,
      numeroExterior: original.domicilio.numeroExterior,
      colonia: 'Obregón',
      codigoPostal: original.domicilio.codigoPostal,
      ocupacion: null,
      empresa: original.empresa,
      rangoIngresoMensual: RangoIngreso.de35001a50000,
    );

    await repo.actualizar(original, nuevos);

    final peticion = adapter.peticiones.single;
    expect(peticion.method, 'PATCH');
    expect(peticion.data, {
      'id': 7,
      'segundoNombre': '',
      'estadoCivil': 'CASADO',
      'telefonoMovil': '5598765432',
      // Dejar la ocupacion "sin especificar" la elimina; el ingreso cambia de rango
      'ocupacion': '',
      'rangoIngresoMensual': 'DE_35001_A_50000',
      'domicilio': {'colonia': 'Obregón'},
    });
  });

  test('sin cambios no llama al servidor', () async {
    final repo = repositorio((_) async => respuestaJson(200, detalleJson()));
    final original = clienteDePrueba();

    final falla = (await repo.actualizar(original, DatosCliente.desde(original))).failureOrNull;

    expect(falla, isA<ValidationFailure>());
    expect(adapter.peticiones, isEmpty);
  });

  test('dar de baja envia activo=false', () async {
    final repo = repositorio((_) async => respuestaJson(200, detalleJson(activo: false)));

    final detalle = (await repo.cambiarEstatus(7, activo: false)).dataOrNull!;

    expect(adapter.peticiones.single.data, {'id': 7, 'activo': false});
    expect(detalle.cliente.activo, isFalse);
  });

  test('el codigo postal se consulta una sola vez', () async {
    final repo = repositorio(
      (_) async => respuestaJson(200, {
        'codigo': 0,
        'mensaje': 'Exito',
        'codigoPostal': '37000',
        'estado': 'Guanajuato',
        'municipio': 'León',
        'colonias': ['Centro', 'Obregón'],
      }),
    );

    await repo.consultarCodigoPostal('37000');
    final info = (await repo.consultarCodigoPostal('37000')).dataOrNull!;

    expect(info.colonias, ['Centro', 'Obregón']);
    expect(adapter.peticiones, hasLength(1));
  });

  test('cambiar el codigo postal envia tambien la colonia para validarla', () {
    final original = clienteDePrueba();
    final base = DatosCliente.desde(original);
    final nuevos = DatosCliente(
      nombre: base.nombre,
      segundoNombre: base.segundoNombre,
      apellidoPaterno: base.apellidoPaterno,
      apellidoMaterno: base.apellidoMaterno,
      fechaNacimiento: base.fechaNacimiento,
      curp: base.curp,
      rfc: base.rfc,
      sexo: base.sexo,
      nacionalidad: base.nacionalidad,
      estadoCivil: base.estadoCivil,
      correo: base.correo,
      telefonoMovil: base.telefonoMovil,
      calle: base.calle,
      numeroExterior: base.numeroExterior,
      colonia: base.colonia,
      codigoPostal: '37100',
      ocupacion: base.ocupacion,
      empresa: base.empresa,
      rangoIngresoMensual: base.rangoIngresoMensual,
    );

    expect(CambiosCliente.calcular(original, nuevos), {
      'domicilio': {'codigoPostal': '37100', 'colonia': 'Centro'},
    });
  });

  test('POST /clientes es publico pero PATCH /clientes no', () {
    expect(ApiEndpoints.esPublica('/clientes', 'POST'), isTrue);
    expect(ApiEndpoints.esPublica('/clientes', 'PATCH'), isFalse);
    expect(ApiEndpoints.avisaExpiracion('/clientes', 'PATCH'), isTrue);
  });
}
