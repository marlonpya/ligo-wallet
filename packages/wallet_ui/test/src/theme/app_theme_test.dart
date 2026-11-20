import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_ui/wallet_ui.dart';

void main() {
  test('el tema claro y el oscuro comparten semilla y Material 3', () {
    final light = AppTheme.light;
    final dark = AppTheme.dark;

    expect(light.useMaterial3, isTrue);
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.inputDecorationTheme.border, isA<OutlineInputBorder>());
  });
}
