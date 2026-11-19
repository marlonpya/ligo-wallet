import 'package:wallet_api/src/client/wallet_api.dart';
import 'package:wallet_api/src/exceptions/api_exception.dart';
import 'package:wallet_api/src/fake/fake_backend_config.dart';
import 'package:wallet_api/src/fake/fake_movements.dart';
import 'package:wallet_api/src/interceptors/auth_interceptor.dart';
import 'package:wallet_api/src/models/auth_dtos.dart';
import 'package:wallet_api/src/models/movement_dto.dart';

/// Backend simulado en memoria que respeta el contrato de la API.
///
/// Se sustituye a nivel de datasource (no de repositorio): así el flavor
/// `development` ejercita el repositorio real, el almacenamiento seguro y el
/// manejo de 401, igual que producción. Valida el token como lo haría el
/// servidor.
final class FakeWalletApi implements WalletApi {
  /// Crea el backend fake. `tokenProvider` lee el token guardado, igual que el
  /// `AuthInterceptor` del cliente real.
  new({required this._tokenProvider, FakeBackendConfig? config})
    : config = config ?? FakeBackendConfig();

  /// Email de la cuenta de prueba.
  static const demoEmail = 'demo@ligo.pe';

  /// Contraseña de la cuenta de prueba.
  static const demoPassword = 'ligo1234';

  /// Token que emite el backend fake (el del contrato).
  static const issuedToken = 'mock-jwt-token';

  /// Configuración modificable en caliente.
  final FakeBackendConfig config;

  final TokenProvider _tokenProvider;

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    await _simulateNetwork();
    final isValid =
        request.email.trim().toLowerCase() == demoEmail &&
        request.password == demoPassword;
    if (!isValid) throw const ApiUnauthorizedException();
    // Un login nuevo emite un token válido: la sesión deja de estar expirada.
    config.sessionExpired = false;
    return const LoginResponseDto(
      token: issuedToken,
      user: UserDto(id: 'u_001', name: 'Ronald Castillo'),
    );
  }

  @override
  Future<List<MovementDto>> getMovements() async {
    await _simulateNetwork();
    await _authorize();
    if (config.emptyMovements) return const [];
    return fakeMovements;
  }

  Future<void> _simulateNetwork() async {
    if (config.latency > Duration.zero) {
      await Future<void>.delayed(config.latency);
    }
    switch (config.failureMode) {
      case FakeFailureMode.none:
        return;
      case FakeFailureMode.network:
        throw const ApiNetworkException();
      case FakeFailureMode.server:
        throw const ApiServerException(statusCode: 500);
      case FakeFailureMode.malformed:
        throw const ApiMalformedResponseException();
    }
  }

  Future<void> _authorize() async {
    final token = await _tokenProvider();
    if (token != issuedToken || config.sessionExpired) {
      throw const ApiUnauthorizedException();
    }
  }
}
