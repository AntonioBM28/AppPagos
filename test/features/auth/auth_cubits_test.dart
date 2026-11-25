import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/features/auth/domain/entities/credenciales.dart';
import 'package:pagosapp/features/auth/domain/entities/desafio_verificacion.dart';
import 'package:pagosapp/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pagosapp/features/auth/domain/usecases/validaciones_auth.dart';
import 'package:pagosapp/features/auth/presentation/cubit/login_cubit.dart';
import 'package:pagosapp/features/auth/presentation/cubit/verificacion_cubit.dart';

import '../../helpers/fake_auth_repository.dart';

const _sesionActiva = SesionActivaFailure('Ya tienes una sesion activa', plataforma: 'MOVIL');

void main() {
  group('ValidacionesAuth', () {
    test('correo', () {
      expect(ValidacionesAuth.correo(''), isNotNull);
      expect(ValidacionesAuth.correo('sin-arroba'), isNotNull);
      expect(ValidacionesAuth.correo('antonio@gmail.com'), isNull);
    });

    test('codigo de 6 digitos', () {
      expect(ValidacionesAuth.codigo('12345'), isNotNull);
      expect(ValidacionesAuth.codigo('12a456'), isNotNull);
      expect(ValidacionesAuth.codigo('123456'), isNull);
    });

    test('las credenciales no exponen la contrasena', () {
      const credenciales = Credenciales(correo: 'a@b.com', password: 'Linux123!');
      expect(credenciales.toString(), isNot(contains('Linux123!')));
    });
  });

  group('IniciarSesion', () {
    test('no llama al servidor con datos invalidos y normaliza el correo', () async {
      final repo = FakeAuthRepository();
      final iniciar = IniciarSesion(repo);

      final invalido = await iniciar(const Credenciales(correo: 'x', password: 'p'));
      await iniciar(const Credenciales(correo: '  Antonio@Gmail.COM ', password: 'p'));

      expect(invalido.failureOrNull, isA<ValidationFailure>());
      expect(repo.logins.single.correo, 'antonio@gmail.com');
    });
  });

  group('LoginCubit', () {
    late FakeAuthRepository repo;

    setUp(() => repo = FakeAuthRepository());

    blocTest<LoginCubit, LoginState>(
      'credenciales correctas: codigo enviado',
      build: () => LoginCubit(IniciarSesion(repo)),
      act: (cubit) => cubit.enviar(correo: 'antonio@gmail.com', password: 'Linux123!'),
      expect: () => [const LoginEnviando(), const LoginCodigoEnviado(desafioDePrueba)],
    );

    blocTest<LoginCubit, LoginState>(
      'error del servidor: muestra su mensaje',
      build: () {
        repo.alIniciar = (_) => const ErrorResult(UnauthorizedFailure('Correo o contrasena incorrectos'));
        return LoginCubit(IniciarSesion(repo));
      },
      act: (cubit) => cubit.enviar(correo: 'antonio@gmail.com', password: 'mala'),
      expect: () => [const LoginEnviando(), const LoginError('Correo o contrasena incorrectos')],
    );

    blocTest<LoginCubit, LoginState>(
      'sesion en otro dispositivo: pregunta y, al aceptar, reintenta cerrando la anterior',
      build: () {
        repo.alIniciar = (c) => c.cerrarSesionAnterior ? const Success(desafioDePrueba) : const ErrorResult(_sesionActiva);
        return LoginCubit(IniciarSesion(repo));
      },
      act: (cubit) async {
        await cubit.enviar(correo: 'antonio@gmail.com', password: 'Linux123!');
        await cubit.cerrarSesionAnteriorYContinuar();
      },
      expect: () => [
        const LoginEnviando(),
        const LoginSesionActiva(_sesionActiva),
        const LoginEnviando(),
        const LoginCodigoEnviado(desafioDePrueba),
      ],
      verify: (_) => expect(repo.logins.map((c) => c.cerrarSesionAnterior), [false, true]),
    );

    blocTest<LoginCubit, LoginState>(
      'cancelar la sesion activa olvida las credenciales',
      build: () {
        repo.alIniciar = (_) => const ErrorResult(_sesionActiva);
        return LoginCubit(IniciarSesion(repo));
      },
      act: (cubit) async {
        await cubit.enviar(correo: 'antonio@gmail.com', password: 'Linux123!');
        cubit.cancelarSesionActiva();
        await cubit.cerrarSesionAnteriorYContinuar();
      },
      expect: () => [const LoginEnviando(), const LoginSesionActiva(_sesionActiva), const LoginInicial()],
      verify: (_) => expect(repo.logins, hasLength(1)),
    );

    blocTest<LoginCubit, LoginState>(
      'un doble envio solo llama una vez al servidor',
      build: () => LoginCubit(IniciarSesion(repo)),
      act: (cubit) => Future.wait([
        cubit.enviar(correo: 'antonio@gmail.com', password: 'Linux123!'),
        cubit.enviar(correo: 'antonio@gmail.com', password: 'Linux123!'),
      ]),
      verify: (_) => expect(repo.logins, hasLength(1)),
    );
  });

  group('VerificacionCubit', () {
    late FakeAuthRepository repo;

    setUp(() => repo = FakeAuthRepository());

    VerificacionCubit crear({DesafioVerificacion desafio = desafioDePrueba, Duration tick = const Duration(hours: 1)}) =>
        VerificacionCubit(
          desafio: desafio,
          verificarCodigo: VerificarCodigo(repo),
          reenviarCodigo: ReenviarCodigo(repo),
          tick: tick,
        );

    test('codigo correcto: termina sin error', () async {
      final cubit = crear();
      await cubit.verificar('123456');
      expect(cubit.state.error, isNull);
      expect(cubit.state.verificando, isFalse);
      await cubit.close();
    });

    test('codigo incorrecto: muestra el error y permite reintentar', () async {
      final cubit = crear();
      await cubit.verificar('000000');
      expect(cubit.state.error, 'Código incorrecto');
      expect(cubit.state.debeReiniciar, isFalse);
      await cubit.close();
    });

    test('sin intentos (429) o codigo ya usado (410): hay que volver al login', () async {
      repo.alVerificar = (_) => const ErrorResult(TooManyRequestsFailure('Superaste los intentos'));
      final sinIntentos = crear();
      await sinIntentos.verificar('000000');

      repo.alVerificar = (_) => const ErrorResult(GoneFailure('Ya se utilizo'));
      final usado = crear();
      await usado.verificar('123456');

      expect(sinIntentos.state.debeReiniciar, isTrue);
      expect(usado.state.debeReiniciar, isTrue);
      await sinIntentos.verificar('123456');
      expect(repo.codigos, hasLength(2), reason: 'Bloqueado: no vuelve a llamar');
      await sinIntentos.close();
      await usado.close();
    });

    test('no permite reenviar antes de tiempo; despues reinicia los contadores', () async {
      final cubit = crear(
        desafio: const DesafioVerificacion(
          id: 'd',
          correoEnmascarado: 'an***@gmail.com',
          expiraEn: Duration(minutes: 5),
          reenviarEn: Duration.zero,
        ),
      );

      await cubit.reenviar();

      expect(repo.reenvios, 1);
      expect(cubit.state.segundosParaReenviar, 60);
      expect(cubit.state.aviso, contains('an***@gmail.com'));

      await cubit.reenviar();
      expect(repo.reenvios, 1, reason: 'Hay que esperar 60 segundos');
      await cubit.close();
    });

    test('el reloj descuenta los segundos', () async {
      final cubit = crear(tick: const Duration(milliseconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 55));
      expect(cubit.state.segundosParaReenviar, lessThan(60));
      expect(cubit.state.segundosParaExpirar, lessThan(300));
      await cubit.close();
    });
  });

  group('CerrarSesionCubit', () {
    test('cierra una sola vez aunque se toque dos veces', () async {
      final repo = FakeAuthRepository();
      final cubit = CerrarSesionCubit(CerrarSesion(repo));

      await Future.wait([cubit.cerrar(), cubit.cerrar()]);

      expect(repo.cierres, 1);
      await cubit.close();
    });
  });
}
