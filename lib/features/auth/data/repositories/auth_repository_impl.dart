import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/security/session_data.dart';
import '../../../../core/security/session_manager.dart';
import '../../domain/entities/credenciales.dart';
import '../../domain/entities/desafio_verificacion.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/desafio_verificacion_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remoto, required this._sesion});

  final AuthRemoteDataSource _remoto;
  final SessionManager _sesion;

  @override
  Future<Result<DesafioVerificacion>> iniciarSesion(Credenciales credenciales) =>
      _ejecutar(() async => DesafioVerificacionModel.fromJson(await _remoto.iniciarSesion(credenciales)));

  @override
  Future<Result<void>> verificarCodigo({required String desafioId, required String codigo}) =>
      _ejecutar(() async {
        final json = await _remoto.verificarCodigo(desafioId: desafioId, codigo: codigo);
        final SessionData datos;
        try {
          datos = SessionData.fromApi(json);
        } on FormatException {
          throw const InvalidResponseException();
        }
        // En movil el token viene en el cuerpo; en web viaja en la cookie y aqui es null
        await _sesion.iniciar(datos, token: json['token'] as String?);
      });

  @override
  Future<Result<DesafioVerificacion>> reenviarCodigo(String desafioId) =>
      _ejecutar(() async => DesafioVerificacionModel.fromJson(await _remoto.reenviarCodigo(desafioId)));

  /// Aunque el servidor no responda (sin red, sesion ya cerrada), la sesion local se
  /// borra: el usuario pidio salir.
  @override
  Future<void> cerrarSesion() async {
    try {
      await _remoto.cerrarSesion();
    } on AppException {
      // Se ignora a proposito; ver comentario del metodo
    } finally {
      await _sesion.cerrar();
    }
  }

  Future<Result<T>> _ejecutar<T>(Future<T> Function() operacion) async {
    try {
      return Success(await operacion());
    } on AppException catch (e) {
      return ErrorResult(Failure.fromException(e));
    }
  }
}
