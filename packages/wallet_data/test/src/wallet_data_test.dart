// Not required for test files
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_data/wallet_data.dart';

void main() {
  group('WalletData', () {
    test('can be instantiated', () {
      expect(WalletData(), isNotNull);
    });
  });
}
