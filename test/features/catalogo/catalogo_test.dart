import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/core/network/api_client.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';
import 'package:pagosapp/features/catalogo/data/catalogo_repository_impl.dart';
import 'package:pagosapp/features/catalogo/domain/entities/producto.dart';
import 'package:pagosapp/core/widgets/imagen_servicio.dart';

import '../../helpers/app_de_prueba.dart' as prueba;
import '../../helpers/fake_catalogo_repository.dart';
import '../../helpers/fake_http.dart';

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Repositorio', () {
    test('envia solo los filtros con valor y lee productos, servicios e imagen', () async {
      final adapter = FakeAdapter(
        (_) async => respuestaJson(200, {
          'codigo': 0,
          'mensaje': 'Exito',
          'pagina': 0,
          'tamanio': 20,
          'totalElementos': 1,
          'totalPaginas': 1,
          'productos': [
            {
              'idProducto': 200,
              'idServicio': 79,
              'idCatTipoServicio': 1,
              'nombre': r'Telcel $100',
              'servicio': 'Telcel',
              'precio': 100.0,
              'tipoReferencia': 'a',
              'leyenda': '  Recarga  ',
              'imagenUrl': 'https://img.test/79.png',
            },
          ],
          'servicios': [
            {'idServicio': 79, 'servicio': 'Telcel', 'imagenUrl': 'https://img.test/79.png'},
          ],
          'tiposServicio': [1, 10],
        }),
      );
      final repo = CatalogoRepositoryImpl(ApiClient(dioDePrueba(adapter, interceptores: [const ErrorInterceptor()])));

      final pagina = (await repo.consultar(
        const FiltroProductos(texto: ' tel ', idServicio: 79, precioMax: 500, orden: OrdenProducto.precioMenor),
      ))
          .dataOrNull!;

      expect(adapter.peticiones.single.path, '/productos/consulta');
      expect(adapter.peticiones.single.data, {
        'texto': 'tel',
        'idServicio': 79,
        'precioMax': 500.0,
        'orden': 'PRECIO_MENOR',
        'pagina': 0,
        'tamanio': 20,
      });
      expect(pagina.productos.single.imagenUrl, 'https://img.test/79.png');
      expect(pagina.productos.single.leyenda, 'Recarga');
      expect(pagina.servicios.single.servicio, 'Telcel');
      expect(pagina.tiposServicio, [1, 10]);
    });

    test('precio 0 es monto variable', () {
      expect(productosDePrueba[1].montoVariable, isTrue);
      expect(productosDePrueba[0].montoVariable, isFalse);
    });
  });

  group('Pantalla', () {
    testWidgets('el ejecutivo ve el catalogo con imagen, busca, filtra y abre el detalle sin poder modificar',
        (tester) async {
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionEjecutivo());

      await tocar(tester, find.text('Catálogo').last);

      expect(find.text('2 producto(s)'), findsOneWidget);
      expect(find.text(r'Telcel $100'), findsOneWidget);
      expect(find.text(r'$100.00'), findsOneWidget);
      expect(find.text('Monto variable'), findsOneWidget);
      expect(find.byType(ImagenServicio), findsNWidgets(2));

      // Busqueda por texto
      await tester.enterText(find.widgetWithText(TextField, 'Buscar producto o servicio'), 'agua');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('1 producto(s)'), findsOneWidget);
      expect(find.text('Agua Cancun'), findsOneWidget);

      // Filtro por servicio desde el panel
      await tester.enterText(find.widgetWithText(TextField, 'Buscar producto o servicio'), '');
      await tocar(tester, find.byTooltip('Filtros'));
      await tocar(tester, find.text('Todos').first);
      await tocar(tester, find.text('Telcel').last);
      await tocar(tester, find.text('Aplicar'));
      expect(find.text(r'Telcel $100'), findsOneWidget);
      expect(find.text('Agua Cancun'), findsNothing);
      expect(find.widgetWithText(InputChip, 'Telcel'), findsOneWidget);

      // Detalle de solo lectura
      await tocar(tester, find.text(r'Telcel $100'));
      expect(find.text('Recarga de tiempo aire'), findsOneWidget);
      expect(find.text('Clave del producto'), findsOneWidget);
      for (final accion in ['Editar', 'Eliminar', 'Guardar', 'Comprar']) {
        expect(find.textContaining(accion), findsNothing);
      }
      app.sesion.dispose();
    });

    testWidgets('el cliente tambien consulta el catalogo, filtra y ve el detalle (solo lectura)', (tester) async {
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionCliente());

      expect(find.text('Clientes'), findsNothing);
      await tocar(tester, find.text('Catálogo').last);

      expect(find.text('2 producto(s)'), findsOneWidget);
      expect(find.byType(ImagenServicio), findsNWidgets(2));

      await tocar(tester, find.byTooltip('Filtros'));
      await tocar(tester, find.text('Todos').first);
      await tocar(tester, find.text('AGUAKAN (Cancun)').last);
      await tocar(tester, find.text('Aplicar'));
      expect(find.text('Agua Cancun'), findsOneWidget);
      expect(find.text(r'Telcel $100'), findsNothing);

      await tocar(tester, find.text('Agua Cancun'));
      expect(find.text('Clave del producto'), findsOneWidget);
      for (final accion in ['Editar', 'Eliminar', 'Guardar']) {
        expect(find.textContaining(accion), findsNothing);
      }
      app.sesion.dispose();
    });
  });
}
