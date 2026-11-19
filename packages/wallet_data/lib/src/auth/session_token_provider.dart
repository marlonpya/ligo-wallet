import 'package:wallet_api/wallet_api.dart';
import 'package:wallet_storage/wallet_storage.dart';

/// Crea el [TokenProvider] que usa el datasource para firmar peticiones.
///
/// Lee del almacenamiento seguro en cada llamada (sin caché en memoria) para
/// que un logout o una expiración surtan efecto en la siguiente petición. Si
/// el almacenamiento falla, se comporta como "sin sesión".
TokenProvider sessionTokenProvider(SessionStorage storage) => () async {
  try {
    return (await storage.read())?.token;
  } on SessionStorageException {
    return null;
  }
};
