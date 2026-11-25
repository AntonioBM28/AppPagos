import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/features/clientes/domain/entities/cliente.dart';

import '../helpers/app_de_prueba.dart' as prueba;

void main() {
  testWidgets('calle limitada a 60 caracteres e informacion laboral con catalogos opcionales', (tester) async {
    final app = await prueba.abrirApp(tester);
    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();

    final calle = find.widgetWithText(TextFormField, 'Calle');
    await tester.ensureVisible(calle);
    await tester.enterText(calle, 'A' * 80);
    await tester.pump();
    expect(tester.widget<TextFormField>(calle).controller!.text, hasLength(60));
    expect(find.text('60/60'), findsOneWidget);

    // Ocupacion e ingreso son desplegables (no texto libre) y empiezan sin especificar
    expect(find.byType(DropdownButtonFormField<Ocupacion?>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<RangoIngreso?>), findsOneWidget);
    expect(find.text('Sin especificar'), findsNWidgets(2));
    expect(find.widgetWithText(TextFormField, 'Ingreso mensual'), findsNothing);

    await tester.ensureVisible(find.byType(DropdownButtonFormField<RangoIngreso?>));
    await tester.tap(find.byType(DropdownButtonFormField<RangoIngreso?>));
    await tester.pumpAndSettle();
    expect(find.text(r'$10,001 a $20,000'), findsWidgets);
    await tester.tap(find.text(r'$10,001 a $20,000').last);
    await tester.pumpAndSettle();
    expect(find.text('Sin especificar'), findsOneWidget);
    app.sesion.dispose();
  });
}
