/// Capa de dominio de la billetera: entidades, errores tipados, `Result` y
/// contratos de repositorio. Dart puro, sin dependencias de Flutter ni de
/// otros paquetes del repo.
library;

export 'src/auth/auth_repository.dart';
export 'src/auth/credentials_validator.dart';
export 'src/auth/session_status.dart';
export 'src/auth/user.dart';
export 'src/core/failure.dart';
export 'src/core/result.dart';
export 'src/movements/money.dart';
export 'src/movements/movement.dart';
export 'src/movements/movement_query.dart';
export 'src/movements/movements_repository.dart';
