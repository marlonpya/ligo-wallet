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
            .where((f) => !f.path.endsWith('.g.dart'))
            .where((f) => !f.path.contains('${Platform.pathSeparator}gen')),
  ];

  /// Dependencias internas permitidas por paquete (el grafo de capas).
  ///
  /// Un paquete nuevo obliga a declarar aquí sus dependencias: así el grafo
  /// es una decisión explícita y revisable, no un efecto de agregar una línea
  /// al `pubspec.yaml`. Las features (`feature_*`) siguen una regla común.
  const allowedInternalDependencies = <String, Set<String>>{
    'wallet_domain': {},
    'wallet_api': {},
    'wallet_storage': {},
    'wallet_data': {'wallet_domain', 'wallet_api', 'wallet_storage'},
    'wallet_l10n': {},
    'wallet_ui': {'wallet_domain', 'wallet_l10n'},
  };
  const featureDependencies = {'wallet_domain', 'wallet_l10n', 'wallet_ui'};

  final packageNames = {
    for (final dir in Directory('packages').listSync().whereType<Directory>())
      dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
  };

  /// Paquetes del workspace que [package] declara en su `pubspec.yaml`.
  Set<String> internalDependenciesOf(String package) {
    final pubspec = File('packages/$package/pubspec.yaml').readAsStringSync();
    return {
      for (final match in RegExp(
        r'^  (\w+):\s*\n\s+path:',
        multiLine: true,
      ).allMatches(pubspec))
        match.group(1)!,
    }.intersection(packageNames);
  }

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

  group('grafo de paquetes', () {
    test('cada paquete solo depende de las capas permitidas', () {
      final violations = <String>[];
      for (final package in packageNames) {
        final allowed = package.startsWith('feature_')
            ? featureDependencies
            : allowedInternalDependencies[package];
        if (allowed == null) {
          violations.add('$package no está declarado en el grafo del test');
          continue;
        }
        for (final dependency in internalDependenciesOf(package)) {
          if (!allowed.contains(dependency)) {
            violations.add('$package no puede depender de $dependency');
          }
        }
      }

      expect(violations, isEmpty);
    });

    test('las features no conocen el router ni otras features', () {
      // La navegación y la composición entre features son del app shell
      // (lib/app): una feature recibe callbacks y widgets por parámetro.
      final violations = [
        for (final file in workspaceFiles)
          if (relative(file).contains('packages/feature_'))
            for (final match in RegExp(
              r"import 'package:(go_router|feature_\w+|ligo_wallet)/",
            ).allMatches(file.readAsStringSync()))
              if (!relative(file).contains('packages/${match.group(1)}/'))
                '${relative(file)} importa ${match.group(1)}',
      ];

      expect(violations, isEmpty);
    });
  });
}
