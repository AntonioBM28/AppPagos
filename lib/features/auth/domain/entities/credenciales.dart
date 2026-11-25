import 'package:equatable/equatable.dart';

/// Datos del primer paso del login. Solo viven en memoria mientras dura el flujo; la
/// contrasena nunca se guarda.
class Credenciales extends Equatable {
  const Credenciales({
    required this.correo,
    required this.password,
    this.cerrarSesionAnterior = false,
  });

  final String correo;
  final String password;

  /// El usuario acepto cerrar la sesion que tiene abierta en otro dispositivo.
  final bool cerrarSesionAnterior;

  Credenciales cerrandoSesionAnterior() =>
      Credenciales(correo: correo, password: password, cerrarSesionAnterior: true);

  /// La contrasena no forma parte de la igualdad ni de toString, para que nunca
  /// aparezca en logs o en mensajes de error de pruebas.
  @override
  List<Object?> get props => [correo, cerrarSesionAnterior];

  @override
  String toString() => 'Credenciales($correo, cerrarSesionAnterior: $cerrarSesionAnterior)';
}
