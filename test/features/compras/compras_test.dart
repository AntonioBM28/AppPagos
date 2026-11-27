import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/network/api_client.dart';
import 'package:pagosapp/core/network/interceptors/error_interceptor.dart';
import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/features/clientes/domain/entities/cliente.dart';
import 'package:pagosapp/features/compras/data/compras_repository_impl.dart';
import 'package:pagosapp/features/compras/domain/compra.dart';
import 'package:pagosapp/features/compras/presentation/compra_cubit.dart';
import 'package:pagosapp/features/compras/presentation/widgets/teclado_nip.dart';
import 'package:pagosapp/features/historial/domain/operacion.dart';

import '../../helpers/app_de_prueba.dart' as prueba;
import '../../helpers/fake_clientes_repository.dart';
import '../../helpers/fake_compras_repository.dart';
import '../../helpers/fake_http.dart';

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Captura un NIP con el teclado en pantalla.
Future<void> teclear(WidgetTester tester, String nip) async {
  for (final digito in nip.split('')) {
    final tecla = find.descendant(of: find.byType(TecladoNip), matching: find.text(digito));
    await tester.ensureVisible(tecla);
    await tester.tap(tecla);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

const solicitud = SolicitudCompra(
  numeroCuenta: '1000000009',
  idServicio: 79,
  idProducto: 200,
  monto: 100,
  destino: '5512345678',
);

void main() {
  group('Repositorio', () {
    test('la compra envia el token y la Idempotency-Key, y un rechazo (codigo 1) es un ticket', () async {
      final adapter = FakeAdapter(
        (_) async => respuestaJson(200, {
          'codigo': 1,
          'mensaje': 'Operación rechazada; el saldo fue liberado',
          'id': '9b0f2c1e-aaaa-bbbb-cccc-1234567890ab',
          'estado': 'RECHAZADA',
          'monto': 100.0,
          'codigoProveedor': 'GP-NODIS',
          'fechaCreacion': '2026-11-27T18:30:00Z',
          'motivo': 'El servicio de GestoPago no está disponible',
          'producto': r'Telcel $100',
          'servicio': 'Telcel',
          'numeroCuenta': '******0009',
          'saldoDisponible': 500.0,
          'nombreCliente': 'Jose Balderas',
          'upc': '123456789012345',
        }),
      );
      final repo = ComprasRepositoryImpl(ApiClient(dioDePrueba(adapter, interceptores: [const ErrorInterceptor()])));

      final ticket = (await repo.comprar(
        solicitud,
        const TokenDinamico(autorizacionId: 'aut-1', token: '48213907', vigencia: Duration(seconds: 60)),
        claveIdempotencia: 'clave-123456',
      ))
          .dataOrNull!;

      final peticion = adapter.peticiones.single;
      expect(peticion.path, '/transacciones');
      expect(peticion.headers['Idempotency-Key'], 'clave-123456');
      expect(peticion.data, {
        'numeroCuenta': '1000000009',
        'idServicio': 79,
        'idProducto': 200,
        'monto': 100.0,
        'destino': '5512345678',
        'autorizacionId': 'aut-1',
        'tokenDinamico': '48213907',
      });
      expect(ticket.estado, EstadoOperacion.rechazada);
      expect(ticket.cargoAplicado, 0);
      expect(ticket.motivo, contains('no está disponible'));
      expect(ticket.folioOperacion, '9B0F2C1E');
    });

    test('autorizar envia el NIP junto con los datos de la compra', () async {
      final adapter = FakeAdapter(
        (_) async => respuestaJson(200, {
          'codigo': 0,
          'mensaje': 'ok',
          'autorizacionId': 'aut-1',
          'tokenDinamico': '48213907',
          'vigenciaSegundos': 60,
        }),
      );
      final repo = ComprasRepositoryImpl(ApiClient(dioDePrueba(adapter, interceptores: [const ErrorInterceptor()])));

      final token = (await repo.autorizar(solicitud, '2580')).dataOrNull!;

      expect(adapter.peticiones.single.path, '/transacciones/autorizacion');
      expect((adapter.peticiones.single.data as Map)['nip'], '2580');
      expect(token.vigencia, const Duration(seconds: 60));
    });
  });

  group('Cubit', () {
    CompraCubit cubit(FakeComprasRepository repo) => CompraCubit(
          repositorio: repo,
          misCuentas: () async => Success(ClienteDetalle(
            cliente: clienteDePrueba(),
            cuentas: const [CuentaResumen(numeroCuenta: '1000000009', estatus: 'ACTIVA', saldo: 500)],
          )),
        );

    test('sin NIP pide crearlo; con token vencido regresa a confirmar el NIP', () async {
      final repo = FakeComprasRepository();
      final c = cubit(repo);
      await c.iniciar();
      c.continuar(solicitud);
      expect(c.state.paso, PasoCompra.crearNip);

      await c.crearNip('2580', '2580');
      expect(c.state.paso, PasoCompra.nip);

      await c.confirmarNip('2580');
      expect(c.state.paso, PasoCompra.token);

      c.tokenExpirado();
      expect(c.state.paso, PasoCompra.nip);
      expect(c.state.error, contains('expiró'));
      await c.close();
    });

    test('reintentar la compra usa la misma Idempotency-Key (no cobra dos veces)', () async {
      final repo = FakeComprasRepository(nip: '2580')..fallaCompra = const NetworkFailure();
      final c = cubit(repo);
      await c.iniciar();
      c.continuar(solicitud);
      await c.confirmarNip('2580');

      await c.autorizarPago();
      expect(c.state.paso, PasoCompra.token);
      repo.fallaCompra = null;
      await c.autorizarPago();

      expect(c.state.paso, PasoCompra.ticket);
      expect(repo.compras[0].$3, repo.compras[1].$3);
      await c.close();
    });
  });

  group('Pantallas', () {
    testWidgets('primera compra del cliente: crea su NIP, lo confirma, autoriza con token y ve el ticket rechazado',
        (tester) async {
      final compras = FakeComprasRepository();
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionCliente(), compras: compras);
      app.clientes.saldo = 500;

      await tocar(tester, find.text('Catálogo').last);
      await tocar(tester, find.text(r'Telcel $100'));
      await tocar(tester, find.widgetWithText(FilledButton, 'Comprar'));

      // Datos: cuenta con su saldo y telefono de 10 digitos
      expect(find.textContaining(r'Saldo disponible: $500.00'), findsOneWidget);
      await tocar(tester, find.text('Continuar'));
      expect(find.text('Escribe un teléfono de 10 dígitos'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Número de teléfono'), '5512345678');
      await tocar(tester, find.text('Continuar'));

      // Primera vez: crear el NIP (rechaza uno facil)
      expect(find.text('Crea tu NIP'), findsWidgets);
      await teclear(tester, '1111');
      expect(find.textContaining('muy fácil de adivinar'), findsOneWidget);
      await teclear(tester, '2580');
      expect(find.text('Confirma tu NIP'), findsOneWidget);
      await teclear(tester, '2580');
      expect(compras.nip, '2580');

      // Confirmar la operacion con el NIP (primero uno incorrecto)
      expect(find.text('Ingresa tu NIP'), findsOneWidget);
      await teclear(tester, '0000');
      expect(find.textContaining('NIP incorrecto'), findsOneWidget);
      await teclear(tester, '2580');

      // Token dinamico
      expect(find.text('Token dinámico generado'), findsOneWidget);
      // El token nunca se muestra, ni completo ni en partes
      expect(find.textContaining('48213907'), findsNothing);
      expect(find.textContaining('4821'), findsNothing);
      expect(find.textContaining('Vence en'), findsOneWidget);
      await tocar(tester, find.text('Autorizar pago'));

      // Ticket
      expect(compras.compras.single.$1.destino, '5512345678');
      // ...pero la app si lo envia al autorizar
      expect(compras.compras.single.$2.token, '48213907');
      expect(find.text('Operación rechazada'), findsOneWidget);
      expect(find.text('No se realizó ningún cargo a tu cuenta'), findsOneWidget);
      expect(find.text('Motivo del rechazo'), findsOneWidget);
      expect(find.text('9B0F2C1E'), findsOneWidget);
      expect(find.text('Cargo aplicado'), findsOneWidget);
      expect(find.text(r'$0.00'), findsOneWidget);
      expect(find.text('******0009'), findsOneWidget);

      await tocar(tester, find.text('Listo'));
      expect(find.text('2 producto(s)'), findsOneWidget);
      app.sesion.dispose();
    });

    testWidgets('sin saldo suficiente no deja continuar', (tester) async {
      final app = await prueba.abrirApp(
        tester,
        sesionRemota: prueba.sesionCliente(),
        compras: FakeComprasRepository(nip: '2580'),
      );
      app.clientes.saldo = 50;

      await tocar(tester, find.text('Catálogo').last);
      await tocar(tester, find.text(r'Telcel $100'));
      await tocar(tester, find.widgetWithText(FilledButton, 'Comprar'));

      expect(find.textContaining('Saldo insuficiente'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Número de teléfono'), '5512345678');
      await tocar(tester, find.text('Continuar'));
      expect(find.text('Ingresa tu NIP'), findsNothing);
      app.sesion.dispose();
    });

    testWidgets('el ejecutivo no puede comprar ni ve el NIP de transacciones', (tester) async {
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionEjecutivo());

      await tocar(tester, find.text('Catálogo').last);
      await tocar(tester, find.text(r'Telcel $100'));
      expect(find.text('Comprar'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tocar(tester, find.text('Perfil'));
      expect(find.text('NIP de transacciones'), findsNothing);
      app.sesion.dispose();
    });

    testWidgets('el cliente configura su NIP desde el perfil', (tester) async {
      final compras = FakeComprasRepository();
      final app = await prueba.abrirApp(tester, sesionRemota: prueba.sesionCliente(), compras: compras);

      await tocar(tester, find.text('Perfil'));
      await tocar(tester, find.text('NIP de transacciones'));
      await teclear(tester, '7391');
      await teclear(tester, '7391');

      expect(find.text('Tu NIP quedó configurado'), findsOneWidget);
      expect(compras.nip, '7391');
      app.sesion.dispose();
    });
  });
}
