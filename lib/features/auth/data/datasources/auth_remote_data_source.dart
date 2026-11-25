import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/security/device_id_provider.dart';
import '../../domain/entities/credenciales.dart';

/// Llamadas HTTP de autenticacion. Devuelve el cuerpo ya validado por [ApiClient] y
/// lanza [AppException] ante cualquier error.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required this._api,
    required this._dispositivo,
    required this._isWeb,
  });

  final ApiClient _api;
  final DeviceIdProvider _dispositivo;
  final bool _isWeb;

  /// WEB: el servidor entrega la sesion en una cookie HttpOnly. MOVIL: en el cuerpo.
  String get _plataforma => _isWeb ? 'WEB' : 'MOVIL';

  Future<Map<String, dynamic>> iniciarSesion(Credenciales credenciales) async {
    final respuesta = await _api.post(
      ApiEndpoints.login,
      body: {
        'correo': credenciales.correo,
        'password': credenciales.password,
        'plataforma': _plataforma,
        'dispositivo': await _dispositivo.obtener(),
        'cerrarSesionAnterior': credenciales.cerrarSesionAnterior,
      },
    );
    return respuesta.data;
  }

  Future<Map<String, dynamic>> verificarCodigo({
    required String desafioId,
    required String codigo,
  }) async {
    final respuesta = await _api.post(
      ApiEndpoints.verificarCodigo,
      body: {'desafioId': desafioId, 'codigo': codigo},
    );
    return respuesta.data;
  }

  Future<Map<String, dynamic>> reenviarCodigo(String desafioId) async {
    final respuesta = await _api.post(ApiEndpoints.reenviarCodigo, body: {'desafioId': desafioId});
    return respuesta.data;
  }

  Future<void> cerrarSesion() => _api.post(ApiEndpoints.logout);
}
