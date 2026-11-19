import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';
import 'package:wallet_api/wallet_api.dart';

void main() {
  group('LoginRequestDto', () {
    const request = LoginRequestDto(email: 'demo@ligo.pe', password: 'secret');

    test('serializa email y password', () {
      expect(request.toJson(), {'email': 'demo@ligo.pe', 'password': 'secret'});
    });

    test('toString no expone la contraseña', () {
      expect(request.toString(), isNot(contains('secret')));
    });
  });

  group('LoginResponseDto', () {
    test('se construye desde el JSON del contrato', () {
      final dto = LoginResponseDto.fromJson(const {
        'token': 'mock-jwt-token',
        'user': {'id': 'u_001', 'name': 'Ronald Castillo'},
      });

      expect(dto.token, 'mock-jwt-token');
      expect(dto.user.id, 'u_001');
      expect(dto.user.name, 'Ronald Castillo');
    });

    test('falla si falta el token', () {
      expect(
        () => LoginResponseDto.fromJson(const {
          'user': {'id': 'u_001', 'name': 'Ronald'},
        }),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('toString no expone el token', () {
      const dto = LoginResponseDto(
        token: 'mock-jwt-token',
        user: UserDto(id: 'u_001', name: 'Ronald'),
      );

      expect(dto.toString(), isNot(contains('mock-jwt-token')));
      expect(dto.toString(), contains('u_001'));
    });
  });

  group('MovementDto', () {
    const json = {
      'id': 'mov_001',
      'description': 'Pago QR',
      'amount': 25.50,
      'type': 'out',
      'status': 'completed',
    };

    test('se construye desde el JSON del contrato sin campos opcionales', () {
      final dto = MovementDto.fromJson(json);

      expect(dto.id, 'mov_001');
      expect(dto.description, 'Pago QR');
      expect(dto.amount, 25.50);
      expect(dto.type, 'out');
      expect(dto.status, 'completed');
      expect(dto.date, isNull);
      expect(dto.currency, isNull);
    });

    test('acepta montos enteros', () {
      expect(MovementDto.fromJson({...json, 'amount': 30}).amount, 30);
    });

    test('lee los campos opcionales cuando vienen', () {
      final dto = MovementDto.fromJson({
        ...json,
        'date': '2026-11-18T14:32:00Z',
        'currency': 'PEN',
      });

      expect(dto.date, '2026-11-18T14:32:00Z');
      expect(dto.currency, 'PEN');
    });

    test('falla si el monto no es numérico', () {
      expect(
        () => MovementDto.fromJson({...json, 'amount': '25.50'}),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('ida y vuelta por JSON conserva los datos', () {
      final dto = MovementDto.fromJson({...json, 'currency': 'PEN'});

      expect(MovementDto.fromJson(dto.toJson()).toJson(), dto.toJson());
    });
  });
}
