import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Tipo monádico [Result] propio para representar éxito o fracaso en domain.
sealed class Result<T> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ErrorResult<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        ErrorResult<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        ErrorResult<T>(failure: final f) => f,
      };

  /// Pliega el resultado ejecutando [onSuccess] si fue exitoso o [onFailure] si falló.
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      ErrorResult<T>(failure: final f) => onFailure(f),
    };
  }
}

/// Resultado exitoso con datos de tipo [T].
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

/// Resultado fallido con un [Failure].
final class ErrorResult<T> extends Result<T> {
  final Failure failure;

  const ErrorResult(this.failure);

  @override
  List<Object?> get props => [failure];
}
