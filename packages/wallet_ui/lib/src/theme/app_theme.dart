import 'package:material_ui/material_ui.dart';

/// Tema Material 3 de la app, claro y oscuro, generado desde un color semilla.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF6A1B9A);

  /// Tema claro.
  static ThemeData get light => _build(Brightness.light);

  /// Tema oscuro.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
