import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/features/movements/presentation/list/widgets/movement_tile.dart';
import 'package:ligo_wallet/features/movements/presentation/widgets/movement_visuals.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';

import '../../../helpers/helpers.dart';

void main() {
  testWidgets('cada estado tiene su etiqueta', (tester) async {
    await tester.pumpApp(
      const Column(
        children: [
          MovementStatusChip(status: MovementStatus.completed),
          MovementStatusChip(
            status: MovementStatus.completed,
            showCompleted: true,
          ),
          MovementStatusChip(status: MovementStatus.pending),
          MovementStatusChip(status: MovementStatus.failed),
          MovementStatusChip(status: MovementStatus.unknown),
        ],
      ),
    );

    // `completed` solo se ve cuando se pide explícitamente.
    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Fallido'), findsOneWidget);
    expect(find.text('Desconocido'), findsOneWidget);
  });

  testWidgets('en tema oscuro los ingresos usan un verde claro', (
    tester,
  ) async {
    late Color color;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: appSupportedLocales,
        home: Builder(
          builder: (context) {
            color = incomeColor(context);
            return MovementAmountText(movement: salary);
          },
        ),
      ),
    );

    expect(color, Colors.green.shade300);
    expect(find.text('+S/ 3,500.00'), findsOneWidget);
  });

  testWidgets('una fila sin fecha muestra solo el estado', (tester) async {
    await tester.pumpApp(
      Material(
        child: MovementTile(movement: pendingTransfer, onTap: () {}),
      ),
    );

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('−S/ 120.00'), findsOneWidget);
  });
}
