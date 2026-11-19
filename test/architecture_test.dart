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

  // Código de la app y de los paquetes del workspace, sin código generado:
  // las reglas multiplataforma y de estado aplican a todas las capas.
  final workspaceFiles = [
    ...dartFiles,
    for (final package in Directory('packages').listSync())
      if (package is Directory && Directory('${package.path}/lib').existsSync())
        ...Directory('${package.path}/lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !f.path.endsWith('.g.dart')),
  ];

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

  test('ninguna capa importa dart:io ni dart:html (mismo código en web)', () {
    // `dart:io` no existe en web y `dart:html` solo en web. Lo que dependa de
    // la plataforma va detrás de un plugin (p. ej. flutter_secure_storage).
    final violations = [
      for (final file in workspaceFiles)
        if (RegExp("import 'dart:(io|html)'").hasMatch(file.readAsStringSync()))
          relative(file),
    ];

    expect(violations, isEmpty);
  });

  test('no hay estado global mutable (static ni variables top-level)', () {
    // El estado vive en los Blocs y llega por DI; un `static` mutable no
    // notifica a la UI, se comparte entre tests y sobrevive al logout.
    final mutableStatic = RegExp(
      r'^\s*static\s+(?!const\b|final\b)(?:late\s+)?[\w<>?,\[\] ]+?\s+\w+\s*(?:=(?!>)|;)',
      multiLine: true,
    );
    final mutableTopLevel = RegExp(r'^(?:late\s+)?var\s+\w+', multiLine: true);

    final violations = [
      for (final file in workspaceFiles)
        for (final match in [
          ...mutableStatic.allMatches(file.readAsStringSync()),
          ...mutableTopLevel.allMatches(file.readAsStringSync()),
        ])
          '${relative(file)}: ${match.group(0)!.trim()}',
    ];

    expect(violations, isEmpty);
  });
}
