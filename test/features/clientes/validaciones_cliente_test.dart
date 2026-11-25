import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/utils/formateadores.dart';
import 'package:pagosapp/features/clientes/domain/entities/cliente.dart';
import 'package:pagosapp/features/clientes/domain/validaciones_cliente.dart';

/// Aplica los formateadores como si el usuario escribiera [texto].
String escribir(List<TextInputFormatter> formateadores, String texto) {
  var valor = TextEditingValue.empty;
  for (final caracter in texto.split('')) {
    final nuevo = TextEditingValue(
      text: valor.text + caracter,
      selection: TextSelection.collapsed(offset: valor.text.length + 1),
    );
    valor = formateadores.fold(nuevo, (v, f) => f.formatEditUpdate(valor, v));
  }
  return valor.text;
}

void main() {
  group('Nombres: solo letras', () {
    test('acepta letras con acentos y espacios entre palabras', () {
      expect(ValidacionesCliente.nombre('María José', campo: 'El nombre'), isNull);
      expect(ValidacionesCliente.nombre('Núñez', campo: 'El apellido'), isNull);
    });

    test('rechaza numeros, simbolos, vacios y longitudes invalidas', () {
      expect(ValidacionesCliente.nombre('Jose2', campo: 'El nombre'), contains('solo admite letras'));
      expect(ValidacionesCliente.nombre('Jose!', campo: 'El nombre'), contains('solo admite letras'));
      expect(ValidacionesCliente.nombre('', campo: 'El nombre'), 'El nombre es obligatorio');
      expect(ValidacionesCliente.nombre('J', campo: 'El nombre'), contains('entre 2 y 50'));
      expect(ValidacionesCliente.nombre('a' * 51, campo: 'El nombre'), contains('entre 2 y 50'));
    });

    test('el segundo nombre es opcional', () {
      expect(ValidacionesCliente.nombreOpcional('', campo: 'El segundo nombre'), isNull);
      expect(ValidacionesCliente.nombreOpcional('A1', campo: 'El segundo nombre'), isNotNull);
    });

    test('el formateador impide escribir numeros y simbolos', () {
      expect(escribir(Formateadores.soloLetras, 'Jo5se#'), 'Jose');
    });
  });

  group('Telefonos: 10 digitos', () {
    test('exactamente 10 digitos', () {
      expect(ValidacionesCliente.telefono('5512345678', campo: 'El teléfono'), isNull);
      expect(ValidacionesCliente.telefono('551234567', campo: 'El teléfono'), contains('10 dígitos'));
      expect(ValidacionesCliente.telefono('55123456ab', campo: 'El teléfono'), contains('10 dígitos'));
      expect(ValidacionesCliente.telefonoOpcional('', campo: 'El teléfono'), isNull);
    });

    test('el formateador no deja escribir letras ni mas de 10 digitos', () {
      expect(escribir(Formateadores.soloDigitos(10), '55a12-345678999'), '5512345678');
    });
  });

  group('CURP y RFC', () {
    final fecha = DateTime(1990, 5, 12);

    test('CURP valida y congruente con fecha y sexo', () {
      expect(ValidacionesCliente.curp('BAMJ900512HGTLRS09', fechaNacimiento: fecha, sexo: Sexo.h), isNull);
    });

    test('CURP con formato invalido o que no coincide', () {
      expect(ValidacionesCliente.curp('BAMJ900512'), contains('18 caracteres'));
      expect(ValidacionesCliente.curp('BAMJ900512HXXLRS09'), contains('formato'));
      expect(
        ValidacionesCliente.curp('BAMJ900512HGTLRS09', fechaNacimiento: DateTime(1991, 5, 12)),
        contains('fecha'),
      );
      expect(ValidacionesCliente.curp('BAMJ900512HGTLRS09', sexo: Sexo.m), contains('sexo'));
    });

    test('RFC valido y que comparte los primeros 10 caracteres con la CURP', () {
      expect(ValidacionesCliente.rfc('BAMJ900512AB1', curp: 'BAMJ900512HGTLRS09'), isNull);
      expect(ValidacionesCliente.rfc('BAMJ900512AB'), contains('13 caracteres'));
      expect(ValidacionesCliente.rfc('XAMJ900512AB1', curp: 'BAMJ900512HGTLRS09'), contains('coincidir'));
    });

    test('el formateador convierte a mayusculas y limita la longitud', () {
      expect(escribir(Formateadores.claveMayusculas(18), 'bamj900512hgtlrs09extra'), 'BAMJ900512HGTLRS09');
    });
  });

  group('Fecha de nacimiento', () {
    final hoy = DateTime(2026, 11, 24);

    test('debe ser mayor de edad', () {
      expect(ValidacionesCliente.fechaNacimiento(DateTime(2008, 11, 24), hoy: hoy), isNull);
      expect(ValidacionesCliente.fechaNacimiento(DateTime(2008, 11, 25), hoy: hoy), contains('mayor de edad'));
      expect(ValidacionesCliente.fechaNacimiento(DateTime(2027, 1, 1), hoy: hoy), contains('futura'));
      expect(ValidacionesCliente.fechaNacimiento(null), contains('obligatoria'));
    });
  });

  group('Otros campos', () {
    test('correo', () {
      expect(ValidacionesCliente.correo('jose@mail.com'), isNull);
      expect(ValidacionesCliente.correo('jose@mail'), contains('válido'));
    });

    test('codigo postal de 5 digitos', () {
      expect(ValidacionesCliente.codigoPostal('37000'), isNull);
      expect(ValidacionesCliente.codigoPostal('3700'), contains('5 dígitos'));
    });

    test('nacionalidad de 3 letras', () {
      expect(ValidacionesCliente.nacionalidad('MEX'), isNull);
      expect(ValidacionesCliente.nacionalidad('MX'), contains('3 letras'));
    });

    test('texto seguro: sin caracteres que permitan HTML o scripts', () {
      expect(ValidacionesCliente.texto('Av. Juárez #10-B', campo: 'La calle', maximo: 100), isNull);
      expect(ValidacionesCliente.texto('<script>', campo: 'La calle', maximo: 100), contains('solo admite'));
      expect(ValidacionesCliente.texto('', campo: 'El número interior', maximo: 10, obligatorio: false), isNull);
    });

    test('empresa opcional', () {
      expect(ValidacionesCliente.texto('', campo: 'La empresa', maximo: 100, obligatorio: false), isNull);
      expect(ValidacionesCliente.texto('A' * 101, campo: 'La empresa', maximo: 100, obligatorio: false), contains('100'));
    });

    test('contrasena con la misma politica que el servidor', () {
      expect(ValidacionesCliente.password('Segura#2026'), isNull);
      expect(ValidacionesCliente.password('segura2026'), allOf(contains('mayúscula'), contains('especial')));
      expect(ValidacionesCliente.confirmarPassword('Otra#2026', 'Segura#2026'), contains('no coinciden'));
    });
  });
}
