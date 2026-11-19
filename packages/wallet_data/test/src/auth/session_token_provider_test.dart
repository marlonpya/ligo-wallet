import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_data/wallet_data.dart';
import 'package:wallet_storage/wallet_storage.dart';

class _MockSessionStorage extends Mock implements SessionStorage;

void main() {
  late SessionStorage storage;

  setUp(() => storage = _MockSessionStorage());

  group('sessionTokenProvider', () {
    test('devuelve el token guardado', () async {
      when(storage.read).thenAnswer(
        (_) async => const StoredSession(
          token: 'mock-jwt-token',
          userId: 'u_001',
          userName: 'Ronald',
        ),
      );

      expect(await sessionTokenProvider(storage)(), 'mock-jwt-token');
    });

    test('devuelve null si no hay sesión', () async {
      when(storage.read).thenAnswer((_) async => null);

      expect(await sessionTokenProvider(storage)(), isNull);
    });

    test('devuelve null si el almacenamiento falla', () async {
      when(storage.read).thenThrow(const SessionStorageException('boom'));

      expect(await sessionTokenProvider(storage)(), isNull);
    });

    test('lee el almacenamiento en cada llamada (sin caché)', () async {
      when(storage.read).thenAnswer((_) async => null);
      final provider = sessionTokenProvider(storage);

      await provider();
      await provider();

      verify(storage.read).called(2);
    });
  });
}
