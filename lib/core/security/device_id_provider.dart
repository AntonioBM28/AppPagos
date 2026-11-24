import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'mobile_session_store.dart';

/// Identificador de esta instalacion (UUID v4). Se usara para el control de sesion
/// unica: el servidor sabra desde que dispositivo esta abierta la sesion.
///
/// En movil se genera una vez y se guarda en el almacenamiento seguro. En web se
/// genera por pestana y vive en memoria (no se usa almacenamiento del navegador).
class DeviceIdProvider {
  DeviceIdProvider({required this._isWeb, FlutterSecureStorage? storage})
      : _storage = storage ?? MobileSessionStore.crearSecureStorage();

  final bool _isWeb;
  final FlutterSecureStorage _storage;
  String? _id;

  static const _key = 'dispositivo_id';

  Future<String> obtener() async {
    if (_id case final id?) return id;
    if (_isWeb) return _id = const Uuid().v4();

    final guardado = await _storage.read(key: _key);
    if (guardado != null && guardado.isNotEmpty) return _id = guardado;

    final nuevo = const Uuid().v4();
    await _storage.write(key: _key, value: nuevo);
    return _id = nuevo;
  }
}
