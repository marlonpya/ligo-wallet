import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reglas de dependencia verificadas en CI (equivalente liviano a ArchUnit o
/// a los `module boundaries` de Gradle).
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('${Platform.pathSeparator}gen'));

  String relative(File file) => file.path.replaceAll(r'\', '/');

  test('solo bootstrap.dart importa los paquetes de datos', () {
    const dataPackages = [
      'package:wallet_api/',
      'package:wallet_data/',
      'package:wallet_storage/',
    ];

    final violations = [
      for (final file in dartFiles)
        if (!relative(file).endsWith('lib/bootstrap.dart'))
          for (final package in dataPackages)
            if (file.readAsStringSync().contains("import '$package"))
              '${relative(file)} importa $package',
    ];

    expect(violations, isEmpty);
  });

  test('los widgets no importan dio ni hacen HTTP', () {
    final violations = [
      for (final file in dartFiles)
        if (RegExp("import 'package:(dio|http|retrofit)/")
            .hasMatch(file.readAsStringSync()))
          relative(file),
    ];

    expect(violations, isEmpty);
  });

  test('ningún archivo usa print ni debugPrint', () {
    final violations = [
      for (final file in dartFiles)
        if (RegExp(r'\b(print|debugPrint)\(').hasMatch(file.readAsStringSync()))
          relative(file),
    ];

    expect(violations, isEmpty);
  });
}
