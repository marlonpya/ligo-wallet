// Not required for test files
// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';
import 'package:wallet_domain/wallet_domain.dart';

void main() {
  group('WalletDomain', () {
    test('can be instantiated', () {
      expect(WalletDomain(), isNotNull);
    });
  });
}
