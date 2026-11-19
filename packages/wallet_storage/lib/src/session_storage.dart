import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet_storage/src/stored_session.dart';

/// Error al leer o escribir en el almacenamiento seguro.
///
/// No incluye el valor guardado, solo la causa técnica para diagnóstico.
final class SessionStorageException implements Exception {
  /// Crea la excepción envolviendo el error original.
  const new(this.cause);

  /// Error de la plataforma que originó el fallo.
  final Object cause;

  @override
  String toString() => 'SessionStorageException($cause)';
}

/// Persistencia de la sesión del usuario.
///
/// Es una interfaz para poder sustituirla en tests sin tocar el canal de
/// plataforma.
abstract interface class SessionStorage {
  /// Lee la sesión guardada, o `null` si no hay una completa.
  ///
  /// Lanza [SessionStorageException] si la plataforma falla.
  Future<StoredSession?> read();

  /// Guarda la [session], reemplazando la anterior.
  ///
  /// Lanza [SessionStorageException] si la plataforma falla.
  Future<void> write(StoredSession session);

  /// Borra la sesión guardada. No falla si no había ninguna.
  ///
  /// Lanza [SessionStorageException] si la plataforma falla.
  Future<void> clear();
}

/// [SessionStorage] respaldado por Keychain (iOS) y Keystore (Android) vía
/// `flutter_secure_storage`.
///
/// En web, `flutter_secure_storage` cifra con WebCrypto pero guarda en
/// `localStorage`: no ofrece las garantías de hardware de móvil. Ver la
/// sección de seguridad del README.
final class SecureSessionStorage implements SessionStorage {
  /// Crea el almacenamiento. [storage] se inyecta para poder testearlo.
  new({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(iOptions: _iosOptions);

  // `unlocked_this_device`: el token solo se lee con el equipo desbloqueado y
  // no viaja en backups ni a otro dispositivo.
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  static const _tokenKey = 'session.token';
  static const _userIdKey = 'session.user_id';
  static const _userNameKey = 'session.user_name';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() => _guard(() async {
    final token = await _storage.read(key: _tokenKey);
    final userId = await _storage.read(key: _userIdKey);
    final userName = await _storage.read(key: _userNameKey);
    // Una sesión a medias (por ejemplo, una escritura interrumpida) no sirve.
    if (token == null || userId == null || userName == null) return null;
    return StoredSession(token: token, userId: userId, userName: userName);
  });

  @override
  Future<void> write(StoredSession session) => _guard(() async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userIdKey, value: session.userId);
    await _storage.write(key: _userNameKey, value: session.userName);
  });

  @override
  Future<void> clear() => _guard(() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Exception catch (error) {
      throw SessionStorageException(error);
    }
  }
}
