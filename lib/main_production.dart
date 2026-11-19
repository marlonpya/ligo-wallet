import 'package:ligo_wallet/app/app.dart';
import 'package:ligo_wallet/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
