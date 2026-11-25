import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/core/theme/app_theme.dart';
import 'package:pagosapp/core/widgets/app_button.dart';
import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/result/result.dart';

import '../helpers/app_de_prueba.dart' as prueba;
import '../helpers/fake_auth_repository.dart';

Widget _envolver(Widget hijo) =>
    MaterialApp(theme: AppTheme.claro, home: Scaffold(body: Center(child: hijo)));

void main() {
  group('AppButton', () {
    testWidgets('ignora toques repetidos mientras la accion esta en curso', (tester) async {
      var llamadas = 0;
      final operacion = Completer<void>();
      await tester.pumpWidget(
        _envolver(
          AppButton(
            texto: 'Pagar',
            onPressed: () {
              llamadas++;
              return operacion.future;
            },
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      expect(llamadas, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      operacion.complete();
      await tester.pumpAndSettle();
      expect(find.text('Pagar'), findsOneWidget);
    });

    testWidgets('con cargando=true esta deshabilitado', (tester) async {
      var llamadas = 0;
      await tester.pumpWidget(
        _envolver(AppButton(texto: 'Pagar', cargando: true, onPressed: () => llamadas++)),
      );

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);

      expect(llamadas, 0);
    });
  });

  group('Navegacion protegida', () {
    late FakeAuthRepository repo;

    Future<SessionManager> abrirApp(
      WidgetTester tester, {
      SessionData? sesionRemota,
      Size tamano = const Size(390, 844), // telefono
    }) async {
      final app = await prueba.abrirApp(tester, sesionRemota: sesionRemota, tamano: tamano);
      repo = app.auth;
      return app.sesion;
    }

    testWidgets('sin sesion muestra el login', (tester) async {
      final sesion = await abrirApp(tester);

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      sesion.dispose();
    });

    testWidgets('flujo completo: contrasena, codigo e inicio', (tester) async {
      final sesion = await abrirApp(tester);

      // Validacion local antes de llamar al servidor
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('Escribe tu correo electrónico'), findsOneWidget);
      expect(repo.logins, isEmpty);

      await tester.enterText(find.byType(TextFormField).at(0), 'antonio@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Linux123!');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Verifica que eres tú'), findsOneWidget);
      expect(find.textContaining('an***@gmail.com'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '000000');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();
      expect(find.text('Código incorrecto'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(sesion.estaAutenticada, isTrue);
      sesion.dispose();
    });

    testWidgets('sesion en otro dispositivo: pide confirmacion antes de cerrarla', (tester) async {
      final sesion = await abrirApp(tester);
      repo.alIniciar = (c) => c.cerrarSesionAnterior
          ? const Success(desafioDePrueba)
          : const ErrorResult(SesionActivaFailure('Ya tienes una sesion activa', plataforma: 'MOVIL'));

      await tester.enterText(find.byType(TextFormField).at(0), 'antonio@gmail.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Linux123!');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Tienes una sesión abierta'), findsOneWidget);
      expect(find.textContaining('la app móvil'), findsOneWidget);

      await tester.tap(find.text('Cerrar esa sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Verifica que eres tú'), findsOneWidget);
      expect(repo.logins.last.cerrarSesionAnterior, isTrue);
      sesion.dispose();
    });

    testWidgets('el aviso del servidor explica por que se cerro la sesion', (tester) async {
      final sesion = await abrirApp(
        tester,
        sesionRemota: SessionData(
          usuario: 'cliente@mail.com',
          rol: 'CLIENTE',
          clienteId: 1,
          expiracion: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      sesion.notificarSesionExpirada('Tu sesion se cerro porque iniciaste sesion en otro dispositivo');
      await tester.pumpAndSettle();

      expect(find.text('Tu sesion se cerro porque iniciaste sesion en otro dispositivo'), findsOneWidget);
      sesion.dispose();
    });

    testWidgets('cerrar sesion desde el perfil pide confirmacion y vuelve al login', (tester) async {
      final sesion = await abrirApp(
        tester,
        sesionRemota: SessionData(
          usuario: 'cliente@mail.com',
          rol: 'CLIENTE',
          clienteId: 1,
          expiracion: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('cliente@mail.com'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(repo.cierres, 1);
      expect(find.text('Inicia sesión'), findsOneWidget);
      sesion.dispose();
    });

    testWidgets('con sesion muestra el inicio y la navegacion', (tester) async {
      final sesion = await abrirApp(
        tester,
        sesionRemota: SessionData(
          usuario: 'cliente@mail.com',
          rol: 'CLIENTE',
          clienteId: 1,
          expiracion: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Inicio'), findsWidgets);

      sesion.notificarSesionExpirada();
      await tester.pumpAndSettle();

      expect(find.text('Tu sesión expiró o fue cerrada. Inicia sesión de nuevo'), findsOneWidget);
      sesion.dispose();
    });

    testWidgets('en pantallas anchas usa NavigationRail', (tester) async {
      final sesion = await abrirApp(
        tester,
        tamano: const Size(1280, 800),
        sesionRemota: SessionData(
          usuario: 'cliente@mail.com',
          rol: 'CLIENTE',
          clienteId: 1,
          expiracion: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      sesion.dispose();
    });
  });
}
