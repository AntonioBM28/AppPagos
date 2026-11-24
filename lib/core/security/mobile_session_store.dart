import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session_data.dart';
import 'session_store.dart';

/// Android e iOS: guarda el token y los datos de sesion cifrados por el sistema
/// (Keystore con AES-GCM en Android, Keychain en iOS). Nunca guarda contrasenas.
class MobileSessionStore implements SessionStore {
  MobileSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? crearSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyToken = 'sesion_token';
  static const _keyDatos = 'sesion_datos';

  /// Opciones compartidas con [DeviceIdProvider]. En iOS el dato solo existe en este
  /// dispositivo (no viaja en respaldos de iCloud).
  static FlutterSecureStorage crearSecureStorage() => const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  @override
  Future<void> guardar({required SessionData datos, String? token}) async {
    if (token != null) await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyDatos, value: jsonEncode(datos.toJson()));
  }

  @override
  Future<String?> leerToken() => _storage.read(key: _keyToken);

  @override
  Future<SessionData?> leerDatos() async {
    final json = await _storage.read(key: _keyDatos);
    if (json == null) return null;
    try {
      return SessionData.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      // Datos corruptos o de una version anterior: se descartan.
      await borrar();
      return null;
    }
  }

  @override
  Future<void> borrar() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyDatos);
  }
}
