/// Datasource HTTP de la billetera: contrato `WalletApi`, cliente real
/// (dio), backend fake, DTOs y excepciones tipadas.
library;

export 'src/client/dio_wallet_api.dart';
export 'src/client/wallet_api.dart';
export 'src/exceptions/api_exception.dart';
export 'src/fake/fake_backend_config.dart';
export 'src/fake/fake_movements.dart';
export 'src/fake/fake_wallet_api.dart';
export 'src/interceptors/auth_interceptor.dart' show TokenProvider;
export 'src/models/auth_dtos.dart';
export 'src/models/movement_dto.dart';
