import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/app.dart';
import 'package:pagosapp/core/router/app_router.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/core/security/web_session_store.dart';
import 'package:pagosapp/core/theme/app_theme.dart';
import 'package:pagosapp/core/widgets/app_button.dart';

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
    Future<SessionManager> abrirApp(
      WidgetTester tester, {
      SessionData? sesionRemota,
      Size tamano = const Size(390, 844), // telefono
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = tamano;
      addTearDown(tester.view.reset);
      final sesion = SessionManager(
        store: WebSessionStore(),
        isWeb: true,
        consultarSesionRemota: () async => sesionRemota,
      );
      await tester.pumpWidget(PagosApp(router: crearRouter(sesion)));
      await sesion.restaurar();
      await tester.pumpAndSettle();
      return sesion;
    }

    testWidgets('sin sesion muestra el login', (tester) async {
      final sesion = await abrirApp(tester);

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
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
