import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/features/clientes/domain/validaciones_cliente.dart';

import '../helpers/app_de_prueba.dart' as prueba;

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('monto del abono: de 1 a 50,000 con maximo 2 decimales', () {
    expect(ValidacionesCliente.montoAbono('1500.50'), isNull);
    expect(ValidacionesCliente.montoAbono('50000'), isNull);
    expect(ValidacionesCliente.montoAbono(''), contains('Escribe'));
    expect(ValidacionesCliente.montoAbono('0.50'), contains('mínimo'));
    expect(ValidacionesCliente.montoAbono('50000.01'), contains('máximo'));
    expect(ValidacionesCliente.montoAbono('10.123'), contains('2 decimales'));
  });

  testWidgets('el ejecutivo abona saldo y ve el saldo nuevo', (tester) async {
    final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionEjecutivo());
    await tocar(tester, find.text('Clientes').last);
    await tocar(tester, find.text('Jose Antonio Balderas Martinez'));

    await tocar(tester, find.text('Abonar saldo'));
    expect(find.textContaining('Cuenta 1000000009'), findsOneWidget);

    // Valida antes de enviar
    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el monto a abonar'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Monto'), '60000');
    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();
    expect(find.text(r'El monto máximo por abono es de $50,000.00'), findsOneWidget);
    expect(app.clientes.abonos, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Monto'), '1500.50');
    await tester.enterText(find.widgetWithText(TextFormField, 'Concepto (opcional)'), 'Deposito en sucursal');
    await tester.tap(find.widgetWithText(FilledButton, 'Abonar'));
    await tester.pumpAndSettle();

    expect(app.clientes.abonos.single, (numeroCuenta: '1000000009', monto: 1500.5, concepto: 'Deposito en sucursal'));
    expect(find.textContaining('Saldo actual'), findsOneWidget);
    expect(find.textContaining(r'$1,500.50'), findsWidgets);
    app.sesion.dispose();
  });

  testWidgets('el cliente ve su saldo pero no puede abonarse', (tester) async {
    final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionCliente());
    await tocar(tester, find.text('Perfil'));
    await tocar(tester, find.text('Mis datos'));

    expect(find.text('Cuentas'), findsOneWidget);
    expect(find.text('Abonar saldo'), findsNothing);
    app.sesion.dispose();
  });
}
