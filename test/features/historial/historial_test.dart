import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/core/network/api_client.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';
import 'package:pagosapp/features/historial/data/historial_repository_impl.dart';
import 'package:pagosapp/features/historial/domain/operacion.dart';

import '../../helpers/app_de_prueba.dart' as prueba;
import '../../helpers/fake_http.dart';

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('el repositorio envia solo los filtros con valor y lee las operaciones', () async {
    final adapter = FakeAdapter(
      (_) async => respuestaJson(200, {
        'codigo': 0,
        'mensaje': 'Exito',
        'pagina': 0,
        'tamanio': 20,
        'totalElementos': 1,
        'totalPaginas': 1,
        'operaciones': [
          {
            'id': '9b0f',
            'fecha': '2026-11-20T16:30:00Z',
            'estado': 'APROBADA',
            'monto': 100.0,
            'producto': r'Telcel $100',
            'servicio': 'Telcel',
            'imagenUrl': 'https://img.test/79.png',
            'referencia': '******5678',
            'numeroCuenta': '1000000009',
            'clienteId': 7,
            'nombreCliente': 'Jose Balderas',
          },
        ],
      }),
    );
    final repo = HistorialRepositoryImpl(ApiClient(dioDePrueba(adapter, interceptores: [const ErrorInterceptor()])));

    final pagina = (await repo.consultar(FiltroOperaciones(
      nombreCliente: ' jose ',
      texto: '',
      estado: EstadoOperacion.aprobada,
      fechaDesde: DateTime(2026, 11, 1),
      fechaHasta: DateTime(2026, 11, 30),
    )))
        .dataOrNull!;

    expect(adapter.peticiones.single.path, '/transacciones/historial');
    expect(adapter.peticiones.single.data, {
      'nombreCliente': 'jose',
      'estado': 'APROBADA',
      'fechaDesde': '2026-11-01',
      'fechaHasta': '2026-11-30',
      'pagina': 0,
      'tamanio': 20,
    });
    final op = pagina.operaciones.single;
    expect(op.titulo, r'Telcel $100');
    expect(op.estado, EstadoOperacion.aprobada);
    expect(op.nombreCliente, 'Jose Balderas');
  });

  testWidgets('el ejecutivo ve "Operaciones" de todos los clientes y filtra por cliente y estado', (tester) async {
    final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionEjecutivo());

    expect(find.text('Historial'), findsNothing);
    expect(find.text('Mis compras'), findsNothing);
    await tocar(tester, find.text('Operaciones').last);

    expect(find.text('2 operación(es)'), findsOneWidget);
    expect(find.textContaining('Jose Balderas Martinez'), findsOneWidget);
    expect(find.textContaining('Maria Lopez Garcia'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Buscar por cliente'), 'maria');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('1 operación(es)'), findsOneWidget);
    expect(find.text('Agua Cancun'), findsOneWidget);

    await tocar(tester, find.byTooltip('Mostrar filtros'));
    await tester.enterText(find.widgetWithText(TextField, 'Buscar por cliente'), '');
    await tocar(tester, find.widgetWithText(ChoiceChip, 'Aprobada'));
    await tocar(tester, find.widgetWithText(FilledButton, 'Buscar'));
    expect(find.text(r'Telcel $100'), findsOneWidget);
    expect(find.text('Agua Cancun'), findsNothing);

    await tocar(tester, find.text(r'Telcel $100'));
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('AUT-123'), findsOneWidget);
    expect(find.text('******5678'), findsOneWidget);
    app.sesion.dispose();
  });

  testWidgets('el cliente ve "Mis compras" solo con sus operaciones', (tester) async {
    final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionCliente());

    expect(find.text('Operaciones'), findsNothing);
    await tocar(tester, find.text('Mis compras').last);

    expect(find.text('1 operación(es)'), findsOneWidget);
    expect(find.text(r'Telcel $100'), findsOneWidget);
    expect(find.text('Agua Cancun'), findsNothing);
    expect(find.widgetWithText(TextField, 'Buscar producto o servicio'), findsOneWidget);
    expect(find.textContaining('Maria Lopez'), findsNothing);

    await tocar(tester, find.text(r'Telcel $100'));
    expect(find.text('Cliente'), findsNothing);
    expect(find.text('Aprobada'), findsWidgets);
    app.sesion.dispose();
  });
}
