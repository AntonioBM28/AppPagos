import '../../../../core/error/exceptions.dart';
import '../../domain/entities/desafio_verificacion.dart';

/// Conversion de la respuesta de POST /auth/login y /auth/reenviar-codigo.
abstract final class DesafioVerificacionModel {
  static DesafioVerificacion fromJson(Map<String, dynamic> json) {
    final id = json['desafioId'];
    final correo = json['correoEnmascarado'];
    final expira = json['expiraEnSegundos'];
    final reenviar = json['reenviarEnSegundos'];
    if (id is! String || correo is! String || expira is! num || reenviar is! num) {
      throw const InvalidResponseException();
    }
    return DesafioVerificacion(
      id: id,
      correoEnmascarado: correo,
      expiraEn: Duration(seconds: expira.toInt()),
      reenviarEn: Duration(seconds: reenviar.toInt()),
    );
  }
}
