import 'package:feature_movements/src/application/movements_use_cases.dart';
import 'package:feature_movements/src/presentation/list/bloc/movements_bloc.dart';
import 'package:feature_movements/src/presentation/list/widgets/movement_tile.dart';
import 'package:feature_movements/src/presentation/list/widgets/movements_filter_bar.dart';
import 'package:feature_movements/src/presentation/list/widgets/movements_search_field.dart';
import 'package:feature_movements/src/presentation/list/widgets/movements_skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';
import 'package:wallet_ui/wallet_ui.dart';

/// Ruta del listado: crea el [MovementsBloc] y dispara la carga inicial.
///
/// La feature no conoce el router, la sesión ni los flavors: el app shell le
/// pasa a dónde navegar ([onMovementSelected]), el nombre a saludar
/// ([userName]) y las acciones extra de la barra ([actions], por ejemplo
/// logout). Las [actions] se construyen debajo del [MovementsBloc], así que
/// pueden leerlo.
class MovementsPage extends StatelessWidget {
  const new({
    required this.onMovementSelected,
    super.key,
    this.userName,
    this.actions = const [],
  });

  final ValueChanged<String> onMovementSelected;
  final String? userName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovementsBloc(
        getMovements: GetMovementsUseCase(context.read<MovementsRepository>()),
      )..add(const MovementsLoadRequested()),
      child: MovementsView(
        onMovementSelected: onMovementSelected,
        userName: userName,
        actions: actions,
      ),
    );
  }
}

/// Vista del listado: cabecera con búsqueda y filtro, y el contenido según
/// el estado (skeleton, error, vacío, sin resultados o lista).
class MovementsView extends StatelessWidget {
  const new({
    required this.onMovementSelected,
    super.key,
    this.userName,
    this.actions = const [],
  });

  /// Recibe el id del movimiento tocado.
  final ValueChanged<String> onMovementSelected;

  /// Nombre para el saludo; sin nombre no se saluda.
  final String? userName;

  /// Acciones extra de la barra, después de refrescar.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userName = this.userName;

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
          actions: [const _RefreshButton(), ...actions],
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
                        if (userName != null) ...[
                          Text(
                            l10n.greeting(userName),
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
                  Expanded(
                    child: _MovementsContent(
                      onMovementSelected: onMovementSelected,
                    ),
                  ),
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
  const new({required this.onMovementSelected});

  final ValueChanged<String> onMovementSelected;

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
              onTap: () => onMovementSelected(movement.id),
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
