import '../../../../core/result/result.dart';
import '../entities/credenciales.dart';
import '../entities/desafio_verificacion.dart';

/// Contrato de autenticacion. La implementacion vive en data y habla con la API.
abstract interface class AuthRepository {
  /// Paso 1: valida la contrasena y pide el envio del codigo.
  /// Si hay una sesion en otro dispositivo devuelve [SesionActivaFailure].
  Future<Result<DesafioVerificacion>> iniciarSesion(Credenciales credenciales);

  /// Paso 2: valida el codigo y abre la sesion local.
  Future<Result<void>> verificarCodigo({required String desafioId, required String codigo});

  /// Envia un codigo nuevo para el mismo desafio.
  Future<Result<DesafioVerificacion>> reenviarCodigo(String desafioId);

  /// Cierra la sesion en el servidor y en el dispositivo.
  Future<void> cerrarSesion();
}
