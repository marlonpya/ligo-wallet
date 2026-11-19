import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Panel del flavor `development` para forzar estados del backend fake
/// (carga lenta, vacío, errores, sesión expirada) durante la demo.
///
/// Devuelve el escenario elegido, o `null` si se cerró sin elegir.
Future<DemoScenario?> showDemoScenarioSheet(
  BuildContext context,
  DemoScenario current,
) {
  return showModalBottomSheet<DemoScenario>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(l10n.demoPanelTitle),
                subtitle: Text(l10n.demoPanelHint),
              ),
              const Divider(),
              for (final scenario in DemoScenario.values)
                ListTile(
                  key: Key('demoScenario_${scenario.name}'),
                  title: Text(scenario.label(l10n)),
                  trailing: scenario == current
                      ? const Icon(Icons.check)
                      : null,
                  selected: scenario == current,
                  onTap: () => Navigator.of(context).pop(scenario),
                ),
            ],
          ),
        ),
      );
    },
  );
}

extension on DemoScenario {
  String label(AppLocalizations l10n) => switch (this) {
    DemoScenario.normal => l10n.demoScenarioNormal,
    DemoScenario.slowNetwork => l10n.demoScenarioSlow,
    DemoScenario.empty => l10n.demoScenarioEmpty,
    DemoScenario.networkError => l10n.demoScenarioNetworkError,
    DemoScenario.serverError => l10n.demoScenarioServerError,
    DemoScenario.malformedResponse => l10n.demoScenarioMalformed,
    DemoScenario.sessionExpired => l10n.demoScenarioSessionExpired,
  };
}
