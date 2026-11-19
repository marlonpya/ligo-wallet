import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:wallet_api/src/client/wallet_api.dart';
import 'package:wallet_api/src/exceptions/api_exception.dart';
import 'package:wallet_api/src/interceptors/auth_interceptor.dart';
import 'package:wallet_api/src/models/auth_dtos.dart';
import 'package:wallet_api/src/models/movement_dto.dart';

/// [WalletApi] sobre HTTP real con dio.
///
/// Se usa dio directamente, sin retrofit: con dos endpoints, la generación de
/// código no aporta claridad y suma un paso de build. Lo que sí aporta dio son
/// los interceptores (token), la cancelación y, a futuro, el certificate
/// pinning y la renovación de token con `QueuedInterceptor`.
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
    dio.interceptors.add(AuthInterceptor(tokenProvider));
    return DioWalletApi._(dio);
  }

  new _(this._dio);

  static const _loginPath = '/auth/login';
  static const _movementsPath = '/movements';

  /// Marca de petición pública: el login no debe llevar un token previo.
  static final Options _publicRequest = Options(
    extra: {AuthInterceptor.requiresAuthKey: false},
  );

  final Dio _dio;

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) => _guard(() async {
    final response = await _dio.post<Object?>(
      _loginPath,
      data: request.toJson(),
      options: _publicRequest,
    );
    return LoginResponseDto.fromJson(_asJsonObject(response.data));
  });

  @override
  Future<List<MovementDto>> getMovements() => _guard(() async {
    final response = await _dio.get<Object?>(_movementsPath);
    final data = response.data;
    if (data is! List<Object?>) throw const ApiMalformedResponseException();
    return data
        .map((item) => MovementDto.fromJson(_asJsonObject(item)))
        .toList(growable: false);
  });

  static Map<String, dynamic> _asJsonObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const ApiMalformedResponseException();
  }

  // Punto único de traducción de errores HTTP: garantiza que solo salgan
  // ApiException y trata cualquier fallo de parseo como contrato roto.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    } on ApiException {
      rethrow;
    } on Object {
      // CheckedFromJsonException, TypeError, FormatException...
      throw const ApiMalformedResponseException();
    }
  }
}
