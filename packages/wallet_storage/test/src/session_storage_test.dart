import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_storage/wallet_storage.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage;

void main() {
  const session = StoredSession(
    token: 'mock-jwt-token',
    userId: 'u_001',
    userName: 'Ronald Castillo',
  );

  late FlutterSecureStorage secureStorage;
  late SecureSessionStorage storage;

  setUp(() {
    secureStorage = _MockFlutterSecureStorage();
    storage = SecureSessionStorage(storage: secureStorage);
  });

  void stubRead(Map<String, String?> values) {
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((invocation) async {
          final key = invocation.namedArguments[#key] as String;
          return values[key];
        });
  }

  group('SecureSessionStorage', () {
    test('se puede crear con el almacenamiento por defecto', () {
      expect(SecureSessionStorage.new, returnsNormally);
    });

    group('read', () {
      test('devuelve la sesión cuando están todas las claves', () async {
        stubRead({
          'session.token': 'mock-jwt-token',
          'session.user_id': 'u_001',
          'session.user_name': 'Ronald Castillo',
        });

        expect(await storage.read(), session);
      });

      test('devuelve null si no hay sesión', () async {
        stubRead({});

        expect(await storage.read(), isNull);
      });

      test('devuelve null si la sesión está incompleta', () async {
        stubRead({'session.token': 'mock-jwt-token'});

        expect(await storage.read(), isNull);
      });

      test('envuelve errores de plataforma', () async {
        when(() => secureStorage.read(key: any(named: 'key')))
            .thenThrow(PlatformException(code: 'keystore'));

        expect(storage.read, throwsA(isA<SessionStorageException>()));
      });
    });

    group('write', () {
      test('guarda token, id y nombre', () async {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await storage.write(session);

        verify(
          () => secureStorage.write(
            key: 'session.token',
            value: 'mock-jwt-token',
          ),
        ).called(1);
        verify(
          () => secureStorage.write(key: 'session.user_id', value: 'u_001'),
        ).called(1);
        verify(
          () => secureStorage.write(
            key: 'session.user_name',
            value: 'Ronald Castillo',
          ),
        ).called(1);
      });

      test('envuelve errores de plataforma', () async {
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(PlatformException(code: 'keystore'));

        expect(
          () => storage.write(session),
          throwsA(isA<SessionStorageException>()),
        );
      });
    });

    group('clear', () {
      test('borra todas las claves de la sesión', () async {
        when(() => secureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        await storage.clear();

        for (final key in [
          'session.token',
          'session.user_id',
          'session.user_name',
        ]) {
          verify(() => secureStorage.delete(key: key)).called(1);
        }
      });

      test('envuelve errores de plataforma', () async {
        when(() => secureStorage.delete(key: any(named: 'key')))
            .thenThrow(PlatformException(code: 'keystore'));

        expect(storage.clear, throwsA(isA<SessionStorageException>()));
      });
    });
  });

  group('StoredSession', () {
    test('toString no expone el token', () {
      expect(session.toString(), isNot(contains('mock-jwt-token')));
      expect(session.toString(), contains('u_001'));
    });
  });

  group('SessionStorageException', () {
    test('toString incluye la causa', () {
      expect(
        const SessionStorageException('boom').toString(),
        'SessionStorageException(boom)',
      );
    });
  });
}
