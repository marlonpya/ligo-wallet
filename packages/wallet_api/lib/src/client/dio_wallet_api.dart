import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:wallet_api/src/client/wallet_api.dart';
import 'package:wallet_api/src/client/wallet_rest_client.dart';
import 'package:wallet_api/src/exceptions/api_exception.dart';
import 'package:wallet_api/src/interceptors/auth_interceptor.dart';
import 'package:wallet_api/src/interceptors/error_interceptor.dart';
import 'package:wallet_api/src/models/auth_dtos.dart';
import 'package:wallet_api/src/models/movement_dto.dart';

/// [WalletApi] sobre HTTP real (dio + retrofit).
///
/// No agrega `LogInterceptor`: loguear peticiones expondría el header
/// `Authorization` y datos del usuario.
final class DioWalletApi implements WalletApi {
  /// Crea el cliente apuntando a `baseUrl`.
  ///
  /// `httpClientAdapter` solo se usa en tests para simular el servidor sin
  /// red; en la app se usa el adaptador por defecto de dio.
  factory({
    required String baseUrl,
    required TokenProvider tokenProvider,
    @visibleForTesting HttpClientAdapter? httpClientAdapter,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );
    if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter;
    // El orden importa: primero se adjunta el token y, al volver con error,
    // el ErrorInterceptor tipa la excepción.
    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider),
      ErrorInterceptor(),
    ]);
    return DioWalletApi._(WalletRestClient(dio));
  }

  new _(this._client);

  final WalletRestClient _client;

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) =>
      _guard(() => _client.login(request));

  @override
  Future<List<MovementDto>> getMovements() => _guard(_client.getMovements);

  // Garantiza que solo salgan ApiException: desenvuelve lo que dejó el
  // ErrorInterceptor y trata los fallos de parseo como contrato roto.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (exception) {
      final error = exception.error;
      throw error is ApiException
          ? error
          : ApiException.fromDioException(exception);
    } on ApiException {
      rethrow;
    } on Object {
      // CheckedFromJsonException, TypeError, FormatException...
      throw const ApiMalformedResponseException();
    }
  }
}
