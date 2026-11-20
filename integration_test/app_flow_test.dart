import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/bootstrap.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_storage/wallet_storage.dart';

/// Recorrido de punta a punta con la composición real del flavor
/// `development`: router, blocs, repositorios y el backend fake con su
/// latencia. Solo cambia el almacenamiento, para empezar sin sesión.
///
/// En un dispositivo: `flutter test integration_test -d <device>`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySessionStorage storage;

  setUp(() => storage = InMemorySessionStorage());

  Future<void> startApp(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      composeApp(AppEnvironment.development, storage: storage),
    );
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('login_emailField')),
      'demo@ligo.pe',
    );
    await tester.enterText(
      find.byKey(const Key('login_passwordField')),
      'ligo1234',
    );
    await tester.tap(find.byKey(const Key('login_submitButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('login, búsqueda, detalle y logout', (tester) async {
    await startApp(tester);

    // Credenciales inválidas: se queda en el login con el error.
    await tester.enterText(
      find.byKey(const Key('login_emailField')),
      'demo@ligo.pe',
    );
    await tester.enterText(
      find.byKey(const Key('login_passwordField')),
      'incorrecta',
    );
    await tester.tap(find.byKey(const Key('login_submitButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_failureMessage')), findsOneWidget);
    expect(storage.session, isNull);

    await login(tester);
    expect(find.byKey(const Key('movements_list')), findsOneWidget);
    expect(storage.session, isNotNull, reason: 'la sesión se guarda');

    // Búsqueda sin tildes ni mayúsculas.
    await tester.enterText(
      find.byKey(const Key('movements_searchField')),
      'SUELDO',
    );
    // pumpAndSettle no espera el debounce (no hay frames pendientes).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movementTile_mov_002')), findsOneWidget);
    expect(find.byKey(const Key('movementTile_mov_001')), findsNothing);

    await tester.tap(find.byKey(const Key('movementTile_mov_002')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movementDetail_amount')), findsOneWidget);
    expect(find.text('Abono de sueldo'), findsOneWidget);

    // material_ui tiene su propio BackButton (`pageBack` busca el de material).
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movements_list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logoutConfirmButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_submitButton')), findsOneWidget);
    expect(storage.session, isNull, reason: 'el logout borra la sesión');
  });

  testWidgets('la sesión guardada se restaura al reabrir', (tester) async {
    await startApp(tester);
    await login(tester);

    // Reabrir: un árbol nuevo sobre el mismo almacenamiento.
    await tester.pumpWidget(const SizedBox());
    await startApp(tester);

    expect(find.byKey(const Key('movements_list')), findsOneWidget);
  });
}

/// Almacenamiento en memoria con el mismo contrato que el seguro.
final class InMemorySessionStorage implements SessionStorage {
  StoredSession? session;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write(StoredSession session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}
