import 'package:equatable/equatable.dart';

/// Datos NO sensibles de la sesion activa. El token nunca forma parte de esta clase.
class SessionData extends Equatable {
  const SessionData({
    required this.usuario,
    required this.rol,
    required this.expiracion,
    this.clienteId,
  });

  /// Construye la sesion a partir de una respuesta del backend que incluye
  /// usuario, rol, clienteId y expiraEnSegundos (login y GET /auth/sesion).
  factory SessionData.fromApi(Map<String, dynamic> json, {DateTime? ahora}) {
    final usuario = json['usuario'];
    final rol = json['rol'];
    final segundos = json['expiraEnSegundos'];
    if (usuario is! String || rol is! String || segundos is! num) {
      throw const FormatException('Respuesta de sesion incompleta');
    }
    return SessionData(
      usuario: usuario,
      rol: rol,
      clienteId: (json['clienteId'] as num?)?.toInt(),
      expiracion: (ahora ?? DateTime.now()).add(Duration(seconds: segundos.toInt())),
    );
  }

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        usuario: json['usuario'] as String,
        rol: json['rol'] as String,
        clienteId: (json['clienteId'] as num?)?.toInt(),
        expiracion: DateTime.parse(json['expiracion'] as String),
      );

  final String usuario;

  /// CLIENTE o EJECUTIVO.
  final String rol;

  /// Nulo para un EJECUTIVO, que no es cliente.
  final int? clienteId;
  final DateTime expiracion;

  bool estaExpirada([DateTime? ahora]) =>
      !(ahora ?? DateTime.now()).isBefore(expiracion);

  bool get esEjecutivo => rol == 'EJECUTIVO';

  Map<String, dynamic> toJson() => {
        'usuario': usuario,
        'rol': rol,
        'clienteId': clienteId,
        'expiracion': expiracion.toIso8601String(),
      };

  @override
  List<Object?> get props => [usuario, rol, clienteId, expiracion];
}
