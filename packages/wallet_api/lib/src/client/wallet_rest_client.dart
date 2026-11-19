import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:wallet_api/src/interceptors/auth_interceptor.dart';
import 'package:wallet_api/src/models/auth_dtos.dart';
import 'package:wallet_api/src/models/movement_dto.dart';

part 'wallet_rest_client.g.dart';

/// Definición declarativa de los endpoints (equivalente a una interfaz de
/// Retrofit en Android). El código HTTP lo genera `retrofit_generator`.
@RestApi()
abstract class WalletRestClient {
  /// Crea el cliente sobre una instancia de [Dio] ya configurada.
  factory(Dio dio, {String? baseUrl}) = _WalletRestClient;

  /// `POST /auth/login`. No lleva token.
  @POST('/auth/login')
  @Extra({AuthInterceptor.requiresAuthKey: false})
  Future<LoginResponseDto> login(@Body() LoginRequestDto request);

  /// `GET /movements`.
  @GET('/movements')
  Future<List<MovementDto>> getMovements();
}
