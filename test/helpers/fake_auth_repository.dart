import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/core/security/session_data.dart';
import 'package:pagosapp/core/security/session_manager.dart';
import 'package:pagosapp/features/auth/domain/entities/credenciales.dart';
import 'package:pagosapp/features/auth/domain/entities/desafio_verificacion.dart';
import 'package:pagosapp/features/auth/domain/repositories/auth_repository.dart';

const desafioDePrueba = DesafioVerificacion(
  id: 'desafio-1',
  correoEnmascarado: 'an***@gmail.com',
  expiraEn: Duration(minutes: 5),
  reenviarEn: Duration(seconds: 60),
);

/// Repositorio en memoria: registra las llamadas y responde lo que indique la prueba.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.sesion});

  final SessionManager? sesion;
  final List<Credenciales> logins = [];
  final List<String> codigos = [];
  int reenvios = 0;
  int cierres = 0;

  Result<DesafioVerificacion> Function(Credenciales)? alIniciar;
  Result<void> Function(String codigo)? alVerificar;
  Result<DesafioVerificacion> Function()? alReenviar;

  @override
  Future<Result<DesafioVerificacion>> iniciarSesion(Credenciales credenciales) async {
    logins.add(credenciales);
    return alIniciar?.call(credenciales) ?? const Success(desafioDePrueba);
  }

  @override
  Future<Result<void>> verificarCodigo({required String desafioId, required String codigo}) async {
    codigos.add(codigo);
    final resultado = alVerificar?.call(codigo) ??
        (codigo == '123456' ? const Success<void>(null) : const ErrorResult<void>(ValidationFailure('Código incorrecto')));
    if (resultado.isSuccess) {
      await sesion?.iniciar(
        SessionData(
          usuario: 'antonio@gmail.com',
          rol: 'EJECUTIVO',
          expiracion: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
    }
    return resultado;
  }

  @override
  Future<Result<DesafioVerificacion>> reenviarCodigo(String desafioId) async {
    reenvios++;
    return alReenviar?.call() ?? const Success(desafioDePrueba);
  }

  @override
  Future<void> cerrarSesion() async {
    cierres++;
    await sesion?.cerrar();
  }
}
