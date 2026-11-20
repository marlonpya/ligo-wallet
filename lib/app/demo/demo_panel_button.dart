import 'package:feature_movements/feature_movements.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/app/demo/demo_scenario_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

/// Botón del panel de escenarios del backend fake (flavor `development`).
///
/// Es del app shell, no de la feature: los escenarios son una herramienta de
/// demo, no parte del listado. Se inyecta como acción de `MovementsPage`, que
/// lo construye debajo de su [MovementsBloc]; por eso puede recargarlo.
class DemoPanelButton extends StatelessWidget {
  const new({required this.demo, super.key});

  final DemoBackend demo;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('movements_demoPanelButton'),
      tooltip: context.l10n.demoPanelTooltip,
      icon: const Icon(Icons.science_outlined),
      onPressed: () async {
        final bloc = context.read<MovementsBloc>();
        final scenario = await showDemoScenarioSheet(
          context,
          demo.scenario.value,
        );
        if (scenario == null) return;
        demo.scenario.value = scenario;
        // Recarga completa para que se vea el skeleton con el nuevo escenario.
        bloc.add(const MovementsLoadRequested());
      },
    );
  }
}
