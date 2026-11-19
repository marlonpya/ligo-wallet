// Not required for test files
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_storage/wallet_storage.dart';

void main() {
  group('WalletStorage', () {
    test('can be instantiated', () {
      expect(WalletStorage(), isNotNull);
    });
  });
}
