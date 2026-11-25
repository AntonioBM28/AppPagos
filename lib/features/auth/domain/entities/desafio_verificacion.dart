import 'package:equatable/equatable.dart';

/// Resultado del primer paso del login: la contrasena fue correcta y se envio un
/// codigo al correo. Todavia no hay sesion.
class DesafioVerificacion extends Equatable {
  const DesafioVerificacion({
    required this.id,
    required this.correoEnmascarado,
    required this.expiraEn,
    required this.reenviarEn,
  });

  /// Identificador que se envia junto con el codigo. No permite entrar por si solo.
  final String id;

  /// Correo al que se envio el codigo, parcialmente oculto (an***@gmail.com).
  final String correoEnmascarado;

  /// Tiempo de vida del codigo.
  final Duration expiraEn;

  /// Tiempo que falta para poder pedir otro codigo.
  final Duration reenviarEn;

  @override
  List<Object?> get props => [id, correoEnmascarado, expiraEn, reenviarEn];
}
