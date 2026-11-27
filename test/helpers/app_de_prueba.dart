import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pagosapp/app.dart';
import 'package:pagosapp/core/router/app_router.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/core/security/web_session_store.dart';
import 'package:pagosapp/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pagosapp/features/auth/presentation/cubit/login_cubit.dart';
import 'package:pagosapp/features/auth/presentation/cubit/verificacion_cubit.dart';
import 'package:pagosapp/features/catalogo/domain/catalogo_repository.dart';
import 'package:pagosapp/features/catalogo/presentation/cubit/catalogo_cubit.dart';
import 'package:pagosapp/features/clientes/domain/usecases/clientes_usecases.dart';
import 'package:pagosapp/features/compras/presentation/compra_cubit.dart';
import 'package:pagosapp/features/compras/presentation/pages/nip_page.dart';
import 'package:pagosapp/features/historial/domain/operacion.dart';
import 'package:pagosapp/features/historial/presentation/historial_cubit.dart';
import 'package:pagosapp/features/clientes/presentation/cubit/clientes_cubits.dart';

import 'fake_auth_repository.dart';
import 'fake_catalogo_repository.dart';
import 'fake_compras_repository.dart';
import 'fake_historial_repository.dart';
import 'fake_clientes_repository.dart';

/// Sesiones de ejemplo.
SessionData sesionEjecutivo() => SessionData(
      usuario: 'antonio@gmail.com',
      rol: 'EJECUTIVO',
      expiracion: DateTime.now().add(const Duration(hours: 1)),
    );

SessionData sesionCliente() => SessionData(
      usuario: 'jose@mail.com',
      rol: 'CLIENTE',
      clienteId: 7,
      expiracion: DateTime.now().add(const Duration(hours: 1)),
    );

/// Todos los Cubits de la app con repositorios en memoria.
FabricasCubits fabricasDePrueba(
  FakeAuthRepository auth,
  FakeClientesRepository clientes, [
  FakeCatalogoRepository? catalogo,
  FakeHistorialRepository? historial,
  FakeComprasRepository? compras,
]) =>
    FabricasCubits(
      login: () => LoginCubit(IniciarSesion(auth)),
      verificacion: (desafio) => VerificacionCubit(
        desafio: desafio,
        verificarCodigo: VerificarCodigo(auth),
        reenviarCodigo: ReenviarCodigo(auth),
        tick: const Duration(hours: 1),
      ),
      cerrarSesion: () => CerrarSesionCubit(CerrarSesion(auth)),
      registroCliente: () => RegistroClienteCubit(RegistrarCliente(clientes)),
      clientes: () => ClientesCubit(ConsultarClientes(clientes)),
      clienteDetalle: (id) => ClienteDetalleCubit(
        id: id,
        obtener: ObtenerCliente(clientes),
        cambiarEstatus: CambiarEstatusCliente(clientes),
        abonarSaldo: AbonarSaldo(clientes),
      ),
      editarCliente: () => EditarClienteCubit(ActualizarCliente(clientes)),
      consultarCodigoPostal: clientes.consultarCodigoPostal,
      catalogo: () => CatalogoCubit(ConsultarCatalogo(catalogo ?? FakeCatalogoRepository())),
      historial: () => HistorialCubit(
        ConsultarHistorial(historial ?? FakeHistorialRepository(comoCliente: !(auth.sesion?.datos?.esEjecutivo ?? false))),
      ),
      compra: () => CompraCubit(
        repositorio: compras ?? FakeComprasRepository(),
        misCuentas: () => clientes.detalle(7),
      ),
      nip: () => NipCubit(compras ?? FakeComprasRepository()),
    );

/// Levanta la app completa con una sesion dada (o sin sesion) en el tamano indicado.
Future<({SessionManager sesion, FakeAuthRepository auth, FakeClientesRepository clientes})> abrirApp(
  WidgetTester tester, {
  SessionData? sesionRemota,
  Size tamano = const Size(390, 844),
  FakeComprasRepository? compras,
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
  final auth = FakeAuthRepository(sesion: sesion);
  final clientes = FakeClientesRepository();
  await tester.pumpWidget(
    PagosApp(router: crearRouter(sesion, fabricasDePrueba(auth, clientes, null, null, compras))),
  );
  await sesion.restaurar();
  await tester.pumpAndSettle();
  return (sesion: sesion, auth: auth, clientes: clientes);
}
