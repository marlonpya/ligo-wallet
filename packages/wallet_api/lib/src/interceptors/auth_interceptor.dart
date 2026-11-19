import 'package:dio/dio.dart';

/// Devuelve el token actual, o `null` si no hay sesión.
typedef TokenProvider = Future<String?> Function();

/// Adjunta `Authorization: Bearer <token>` a las peticiones autenticadas
/// (equivalente a un `Interceptor` de OkHttp).
///
/// Las peticiones públicas (login) se marcan con
/// `extra[requiresAuthKey] = false` para no enviar un token viejo.
final class AuthInterceptor extends Interceptor {
  /// Crea el interceptor. El [TokenProvider] lee el token del almacenamiento
  /// seguro en cada petición, así un logout surte efecto de inmediato.
  new(this._tokenProvider);

  /// Clave de `RequestOptions.extra` para marcar peticiones públicas.
  static const requiresAuthKey = 'requiresAuth';

  final TokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra[requiresAuthKey] as bool? ?? true;
    if (requiresAuth) {
      final token = await _tokenProvider();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
