import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/credenciales.dart';
import '../entities/desafio_verificacion.dart';
import '../repositories/auth_repository.dart';
import 'validaciones_auth.dart';

/// Paso 1 del login. Valida la entrada antes de llamar al servidor.
class IniciarSesion {
  const IniciarSesion(this._repositorio);

  final AuthRepository _repositorio;

  Future<Result<DesafioVerificacion>> call(Credenciales credenciales) async {
    final error = ValidacionesAuth.correo(credenciales.correo) ??
        ValidacionesAuth.password(credenciales.password);
    if (error != null) return ErrorResult(ValidationFailure(error));

    return _repositorio.iniciarSesion(
      Credenciales(
        correo: credenciales.correo.trim().toLowerCase(),
        password: credenciales.password,
        cerrarSesionAnterior: credenciales.cerrarSesionAnterior,
      ),
    );
  }
}

/// Paso 2 del login: el codigo se valida en el servidor, nunca en la app.
class VerificarCodigo {
  const VerificarCodigo(this._repositorio);

  final AuthRepository _repositorio;

  Future<Result<void>> call({required String desafioId, required String codigo}) async {
    final error = ValidacionesAuth.codigo(codigo);
    if (error != null) return ErrorResult(ValidationFailure(error));
    return _repositorio.verificarCodigo(desafioId: desafioId, codigo: codigo.trim());
  }
}

class ReenviarCodigo {
  const ReenviarCodigo(this._repositorio);

  final AuthRepository _repositorio;

  Future<Result<DesafioVerificacion>> call(String desafioId) => _repositorio.reenviarCodigo(desafioId);
}

class CerrarSesion {
  const CerrarSesion(this._repositorio);

  final AuthRepository _repositorio;

  Future<void> call() => _repositorio.cerrarSesion();
}
