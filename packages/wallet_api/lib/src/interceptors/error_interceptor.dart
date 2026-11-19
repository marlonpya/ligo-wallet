import 'package:dio/dio.dart';
import 'package:wallet_api/src/exceptions/api_exception.dart';

/// Punto único donde los errores de dio se convierten en [ApiException].
///
/// Deja la excepción tipada en `DioException.error`; `DioWalletApi` la
/// desenvuelve para que hacia arriba solo viaje [ApiException].
final class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: ApiException.fromDioException(err)));
  }
}
