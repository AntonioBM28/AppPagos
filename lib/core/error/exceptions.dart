/// Excepciones de la capa data.
///
/// La jerarquia es sellada: cada tipo corresponde a una situacion concreta (sin
/// conexion, timeout o un codigo HTTP) y los repositorios las convierten en
/// [Failure] de forma exhaustiva.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Mensaje listo para mostrarse al usuario; nunca contiene detalles tecnicos.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No hay conexion con el servidor.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'Revisa tu conexión a internet']);
}

/// El servidor tardo demasiado en responder.
final class AppTimeoutException extends AppException {
  const AppTimeoutException([
    super.message = 'El servidor tardó demasiado en responder',
  ]);
}

/// La peticion fue cancelada por la propia app (por ejemplo, al salir de una pantalla).
final class RequestCancelledException extends AppException {
  const RequestCancelledException([super.message = 'La solicitud fue cancelada']);
}

/// 401: sin sesion, sesion invalida o expirada.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Tu sesión expiró o fue cerrada. Inicia sesión de nuevo',
  ]);
}

/// 403: el usuario no tiene permiso.
final class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'No tienes permiso para realizar esta operación',
  ]);
}

/// 404: el recurso no existe.
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'El recurso solicitado no existe']);
}

/// 400: datos invalidos, con el mensaje que envia la API.
final class ValidationException extends AppException {
  const ValidationException([super.message = 'Revisa los datos enviados']);
}

/// 409: conflicto con el estado actual (por ejemplo, un registro duplicado).
final class ConflictException extends AppException {
  const ConflictException([
    super.message = 'La operación entra en conflicto con información existente',
  ]);
}

/// 409 del login: el usuario ya tiene una sesion abierta en otro dispositivo.
final class SesionActivaException extends AppException {
  const SesionActivaException({
    required String message,
    required this.plataforma,
    this.iniciadaEn,
  }) : super(message);

  /// WEB o MOVIL.
  final String plataforma;
  final DateTime? iniciadaEn;
}

/// 422: regla de negocio (saldo insuficiente, compra rechazada...).
final class BusinessRuleException extends AppException {
  const BusinessRuleException([
    super.message = 'La operación no cumple las reglas del sistema',
  ]);
}

/// 410: el recurso ya no esta disponible (por ejemplo, un codigo de verificacion ya
/// usado o un desafio que ya no existe). No tiene caso reintentar.
final class GoneException extends AppException {
  const GoneException([super.message = 'Esta operación ya no está disponible']);
}

/// 413: el cuerpo de la peticion es demasiado grande.
final class PayloadTooLargeException extends AppException {
  const PayloadTooLargeException([
    super.message = 'La información enviada es demasiado grande',
  ]);
}

/// 429: demasiadas peticiones; [retryAfterSeconds] viene del header Retry-After.
final class TooManyRequestsException extends AppException {
  const TooManyRequestsException({
    String message = 'Demasiados intentos. Espera un momento e intenta de nuevo',
    this.retryAfterSeconds,
  }) : super(message);

  final int? retryAfterSeconds;
}

/// 5xx: falla del servidor o de GestoPago.
final class ServerException extends AppException {
  const ServerException([
    super.message = 'El servicio no está disponible, intenta más tarde',
  ]);
}

/// La respuesta no respeta el contrato de la API (falta el sobre `codigo`/`mensaje`).
final class InvalidResponseException extends AppException {
  const InvalidResponseException([
    super.message = 'La respuesta del servidor no tiene el formato esperado',
  ]);
}
