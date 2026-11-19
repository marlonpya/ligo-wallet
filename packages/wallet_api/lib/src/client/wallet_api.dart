import 'package:wallet_api/src/models/auth_dtos.dart';
import 'package:wallet_api/src/models/movement_dto.dart';

/// Datasource remoto de la billetera.
///
/// Hay dos implementaciones: `DioWalletApi` (HTTP real) y `FakeWalletApi`
/// (backend simulado en memoria). Los repositorios no saben cuál reciben.
///
/// Todos los métodos lanzan únicamente `ApiException`.
abstract interface class WalletApi {
  /// `POST /auth/login`.
  Future<LoginResponseDto> login(LoginRequestDto request);

  /// `GET /movements`. Requiere token.
  Future<List<MovementDto>> getMovements();
}
