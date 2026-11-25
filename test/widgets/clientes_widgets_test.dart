import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/app_de_prueba.dart' as prueba;

Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> escribir(WidgetTester tester, String etiqueta, String texto) async {
  await tester.ensureVisible(campo(etiqueta));
  await tester.enterText(campo(etiqueta), texto);
  await tester.pump();
}

String valorDe(WidgetTester tester, String etiqueta) =>
    tester.widget<TextFormField>(campo(etiqueta)).controller!.text;

void main() {
  group('Registro publico', () {
    testWidgets('desde el login se abre el formulario y valida antes de enviar', (tester) async {
      final app = await prueba.abrirApp(tester);

      await tocar(tester, find.text('Crear una cuenta'));
      expect(find.text('Crear cuenta'), findsOneWidget);

      // Los formateadores no dejan escribir caracteres invalidos
      await escribir(tester, 'Nombre', 'Jo5se#');
      expect(valorDe(tester, 'Nombre'), 'Jose');
      await escribir(tester, 'Teléfono móvil', '55ab1234567890');
      expect(valorDe(tester, 'Teléfono móvil'), '5512345678');

      await tocar(tester, find.text('Crear mi cuenta'));

      expect(find.text('Revisa los campos marcados en rojo'), findsOneWidget);
      expect(app.clientes.registrado, isNull);
      app.sesion.dispose();
    });
  });

  group('Ejecutivo', () {
    testWidgets('lista, detalle y baja logica con confirmacion', (tester) async {
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionEjecutivo());

      await tocar(tester, find.text('Clientes').last);
      expect(find.text('1 cliente(s)'), findsOneWidget);

      await tocar(tester, find.text('Jose Antonio Balderas Martinez'));
      expect(find.text('Activo'), findsOneWidget);

      await tocar(tester, find.widgetWithText(TextButton, 'Dar de baja'));
      expect(find.text('Dar de baja al cliente'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, 'Dar de baja'));

      expect(app.clientes.patches.single, {'id': 1, 'activo': false});
      expect(find.text('Reactivar cliente'), findsOneWidget);
      app.sesion.dispose();
    });

    testWidgets('editar bloquea CURP y RFC y envia solo lo que cambio', (tester) async {
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionEjecutivo());

      await tocar(tester, find.text('Clientes').last);
      await tocar(tester, find.text('Jose Antonio Balderas Martinez'));
      await tocar(tester, find.text('Editar datos'));

      expect(tester.widget<TextFormField>(campo('CURP')).enabled, isFalse);
      expect(tester.widget<TextFormField>(campo('RFC')).enabled, isFalse);

      await escribir(tester, 'Teléfono móvil', '5598765432');
      await tocar(tester, find.text('Guardar cambios'));

      expect(app.clientes.patches.single, {'id': 7, 'telefonoMovil': '5598765432'});
      app.sesion.dispose();
    });
  });

  group('Cliente', () {
    testWidgets('no ve la pestana Clientes pero si consulta sus datos', (tester) async {
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionCliente());

      expect(find.text('Clientes'), findsNothing);

      await tocar(tester, find.text('Perfil'));
      await tocar(tester, find.text('Mis datos'));

      expect(find.text('Jose Antonio Balderas Martinez'), findsOneWidget);
      expect(find.text('Editar datos'), findsOneWidget);
      expect(find.text('Dar de baja'), findsNothing);
      app.sesion.dispose();
    });
  });
}
