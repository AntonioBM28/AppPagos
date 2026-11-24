import 'package:equatable/equatable.dart';

import 'exceptions.dart';

/// Fallas que ve la capa domain. Cada una lleva un mensaje listo para el usuario.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  /// Convierte una [AppException] de la capa data en su [Failure]. Es exhaustivo:
  /// si se agrega una excepcion nueva, el compilador obliga a mapearla aqui.
  factory Failure.fromException(AppException exception) => switch (exception) {
        NetworkException(:final message) => NetworkFailure(message),
        AppTimeoutException(:final message) => TimeoutFailure(message),
        RequestCancelledException(:final message) => CancelledFailure(message),
        UnauthorizedException(:final message) => UnauthorizedFailure(message),
        ForbiddenException(:final message) => ForbiddenFailure(message),
        NotFoundException(:final message) => NotFoundFailure(message),
        ValidationException(:final message) => ValidationFailure(message),
        ConflictException(:final message) => ConflictFailure(message),
        BusinessRuleException(:final message) => BusinessRuleFailure(message),
        PayloadTooLargeException(:final message) => ValidationFailure(message),
        TooManyRequestsException(:final message, :final retryAfterSeconds) =>
          TooManyRequestsFailure(message, retryAfterSeconds: retryAfterSeconds),
        ServerException(:final message) => ServerFailure(message),
        InvalidResponseException(:final message) =>
          InvalidResponseFailure(message),
      };

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Revisa tu conexión a internet']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'El servidor tardó demasiado en responder']);
}

final class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'La solicitud fue cancelada']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Tu sesión expiró o fue cerrada. Inicia sesión de nuevo',
  ]);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'No tienes permiso para realizar esta operación',
  ]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'El recurso solicitado no existe']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Revisa los datos enviados']);
}

final class ConflictFailure extends Failure {
  const ConflictFailure([
    super.message = 'La operación entra en conflicto con información existente',
  ]);
}

final class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure([
    super.message = 'La operación no cumple las reglas del sistema',
  ]);
}

final class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure(super.message, {this.retryAfterSeconds});

  final int? retryAfterSeconds;

  @override
  List<Object?> get props => [message, retryAfterSeconds];
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'El servicio no está disponible, intenta más tarde',
  ]);
}

final class InvalidResponseFailure extends Failure {
  const InvalidResponseFailure([
    super.message = 'La respuesta del servidor no tiene el formato esperado',
  ]);
}

/// Error no previsto (por ejemplo, un bug al convertir datos). Nunca expone el detalle.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ocurrió un error inesperado']);
}
