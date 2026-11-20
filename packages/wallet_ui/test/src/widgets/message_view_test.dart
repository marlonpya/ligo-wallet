import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_ui/wallet_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, MessageView view) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));

  testWidgets('muestra ícono, título, mensaje y acción', (tester) async {
    var taps = 0;
    await pump(
      tester,
      MessageView(
        icon: Icons.search_off,
        title: 'Sin resultados',
        message: 'Prueba otra búsqueda',
        actionLabel: 'Limpiar',
        onAction: () => taps++,
      ),
    );

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('Sin resultados'), findsOneWidget);
    expect(find.text('Prueba otra búsqueda'), findsOneWidget);

    await tester.tap(find.text('Limpiar'));
    expect(taps, 1);
  });

  testWidgets('sin mensaje ni callback solo muestra el título', (tester) async {
    await pump(
      tester,
      const MessageView(
        icon: Icons.receipt_long_outlined,
        title: 'Sin movimientos',
        actionLabel: 'Sin callback',
      ),
    );

    expect(find.text('Sin movimientos'), findsOneWidget);
    // Una acción sin callback no se dibuja: no hay botones muertos.
    expect(find.text('Sin callback'), findsNothing);
  });
}
