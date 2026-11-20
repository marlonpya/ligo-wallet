import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';
import 'package:wallet_ui/wallet_ui.dart';

void main() {
  const failures = <Failure>[
    NetworkFailure(),
    UnauthorizedFailure(),
    InvalidCredentialsFailure(),
    ServerFailure(statusCode: 503),
    NotFoundFailure(),
    DataFailure(),
    UnexpectedFailure(),
  ];

  for (final locale in AppLocalizations.supportedLocales) {
    group('FailureMessage ($locale)', () {
      late AppLocalizations l10n;

      setUp(() async {
        l10n = await AppLocalizations.delegate.load(locale);
      });

      test('cada fallo tiene un mensaje propio', () {
        final messages = failures.map((f) => f.message(l10n)).toSet();

        expect(messages, hasLength(failures.length));
      });

      test('ningún mensaje expone detalles técnicos', () {
        for (final failure in failures) {
          expect(failure.message(l10n), isNot(contains('503')));
          expect(failure.message(l10n), isNot(contains('Exception')));
        }
      });
    });
  }

  test('español traduce los mensajes', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));

    expect(const NetworkFailure().message(l10n), startsWith('Sin conexión'));
  });
}
