// Not required for test files
// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';
import 'package:wallet_api/wallet_api.dart';

void main() {
  group('WalletApi', () {
    test('can be instantiated', () {
      expect(WalletApi(), isNotNull);
    });
  });
}
