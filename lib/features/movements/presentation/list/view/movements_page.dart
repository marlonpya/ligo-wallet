import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ligo_wallet/app/config/app_config.dart';
import 'package:ligo_wallet/app/router/app_router.dart';
import 'package:ligo_wallet/core/presentation/failure_message.dart';
import 'package:ligo_wallet/core/presentation/widgets/message_view.dart';
import 'package:ligo_wallet/features/auth/presentation/session/session_bloc.dart';
import 'package:ligo_wallet/features/auth/presentation/widgets/logout_button.dart';
import 'package:ligo_wallet/features/movements/application/movements_use_cases.dart';
import 'package:ligo_wallet/features/movements/presentation/list/bloc/movements_bloc.dart';
import 'package:ligo_wallet/features/movements/presentation/list/widgets/demo_scenario_sheet.dart';
import 'package:ligo_wallet/features/movements/presentation/list/widgets/movement_tile.dart';
import 'package:ligo_wallet/features/movements/presentation/list/widgets/movements_filter_bar.dart';
import 'package:ligo_wallet/features/movements/presentation/list/widgets/movements_search_field.dart';
import 'package:ligo_wallet/features/movements/presentation/list/widgets/movements_skeleton.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Ruta del listado: crea el [MovementsBloc] y dispara la carga inicial.
class MovementsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovementsBloc(
        getMovements: GetMovementsUseCase(context.read<MovementsRepository>()),
      )..add(const MovementsLoadRequested()),
      child: const MovementsView(),
    );
  }
}

/// Vista del listado: cabecera con búsqueda y filtro, y el contenido según
/// el estado (skeleton, error, vacío, sin resultados o lista).
class MovementsView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionBloc>().state;
    final demo = context.read<AppConfig>().demoBackend;

    return BlocListener<MovementsBloc, MovementsState>(
      // Refresco fallido con datos visibles: se avisa sin perder la lista.
      listenWhen: (previous, current) =>
          current.hasData &&
          current.failure != null &&
          previous.failure != current.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.refreshFailedMessage(state.failure!.message(l10n)),
              ),
            ),
          );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.movementsTitle),
          actions: [
            const _RefreshButton(),
            if (demo != null) _DemoPanelButton(demo: demo),
            const LogoutButton(),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              // En web/tablet el listado no se estira a todo el ancho.
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (session is SessionAuthenticated) ...[
                          Text(
                            l10n.greeting(session.user.name),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                        ],
                        const MovementsSearchField(),
                        const SizedBox(height: 12),
                        const MovementsFilterBar(),
                      ],
                    ),
                  ),
                  const Expanded(child: _MovementsContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MovementsContent extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<MovementsBloc>().state;
    final bloc = context.read<MovementsBloc>();

    switch (state.status) {
      case MovementsStatus.initial:
      case MovementsStatus.loading:
        return const MovementsSkeleton();
      case MovementsStatus.failure:
        return MessageView(
          key: const Key('movements_errorView'),
          icon: Icons.cloud_off_outlined,
          title: l10n.errorTitle,
          message: state.failure?.message(l10n),
          actionLabel: l10n.retryButton,
          onAction: () => bloc.add(const MovementsLoadRequested()),
        );
      case MovementsStatus.success:
        break;
    }

    final Widget child;
    if (state.isEmpty) {
      child = MessageView(
        key: const Key('movements_emptyView'),
        icon: Icons.receipt_long_outlined,
        title: l10n.emptyMovementsTitle,
        message: l10n.emptyMovementsMessage,
      );
    } else if (state.hasNoResults) {
      child = MessageView(
        key: const Key('movements_noResultsView'),
        icon: Icons.search_off,
        title: l10n.noResultsTitle,
        message: l10n.noResultsMessage,
        actionLabel: l10n.clearFiltersButton,
        onAction: () => bloc.add(const MovementsQueryCleared()),
      );
    } else {
      final movements = state.visibleMovements;
      return RefreshIndicator(
        onRefresh: () => _refresh(bloc),
        child: ListView.separated(
          key: const Key('movements_list'),
          // Siempre desplazable para que el pull to refresh funcione aunque
          // la lista sea corta.
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: movements.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final movement = movements[index];
            return MovementTile(
              movement: movement,
              // `go` (no `push`) para que la URL refleje el detalle en web y
              // se pueda recargar o compartir; la ruta anidada mantiene el
              // listado debajo para volver.
              onTap: () => context.go(AppRoutes.movementDetail(movement.id)),
            );
          },
        ),
      );
    }

    // Vacío y sin resultados también admiten pull to refresh.
    return RefreshIndicator(
      onRefresh: () => _refresh(bloc),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Dispara el refresco y espera a que termine (el `RefreshIndicator` gira
/// hasta que se completa este future).
Future<void> _refresh(MovementsBloc bloc) async {
  bloc.add(const MovementsRefreshRequested());
  await bloc.stream.firstWhere(
    (state) => !state.isRefreshing && state.status != MovementsStatus.loading,
    // Si el bloc se cierra antes (por ejemplo, la sesión expiró y se salió de
    // la pantalla), el indicador termina igual en lugar de lanzar un error.
    orElse: () => bloc.state,
  );
}

/// Botón de refrescar: alternativa al gesto en web y escritorio, y acceso
/// por teclado.
class _RefreshButton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final busy = context.select<MovementsBloc, bool>(
      (bloc) =>
          bloc.state.isRefreshing ||
          bloc.state.status == MovementsStatus.loading,
    );
    return IconButton(
      key: const Key('movements_refreshButton'),
      tooltip: context.l10n.refreshTooltip,
      icon: const Icon(Icons.refresh),
      onPressed: busy
          ? null
          : () => context.read<MovementsBloc>().add(
              const MovementsRefreshRequested(),
            ),
    );
  }
}

class _DemoPanelButton extends StatelessWidget {
  const new({required this.demo});

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
