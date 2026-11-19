import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ligo_wallet/app/router/app_router.dart';
import 'package:ligo_wallet/core/presentation/failure_message.dart';
import 'package:ligo_wallet/core/presentation/formatters.dart';
import 'package:ligo_wallet/core/presentation/widgets/message_view.dart';
import 'package:ligo_wallet/features/movements/application/movements_use_cases.dart';
import 'package:ligo_wallet/features/movements/presentation/detail/cubit/movement_detail_cubit.dart';
import 'package:ligo_wallet/features/movements/presentation/widgets/movement_visuals.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Ruta de detalle `/movements/:id`.
class MovementDetailPage extends StatelessWidget {
  const new({required this.movementId, super.key});

  final String movementId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = MovementDetailCubit(
          getMovementById: GetMovementByIdUseCase(
            context.read<MovementsRepository>(),
          ),
          movementId: movementId,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const MovementDetailView(),
    );
  }
}

/// Vista del detalle según el estado del cubit.
class MovementDetailView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<MovementDetailCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.movementDetailTitle)),
      body: switch (state) {
        MovementDetailLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        MovementDetailFailure(failure: NotFoundFailure()) => MessageView(
          key: const Key('movementDetail_notFound'),
          icon: Icons.search_off,
          title: l10n.detailNotFoundTitle,
          actionLabel: l10n.backButton,
          onAction: () => context.go(AppRoutes.movements),
        ),
        MovementDetailFailure(:final failure) => MessageView(
          key: const Key('movementDetail_error'),
          icon: Icons.cloud_off_outlined,
          title: failure.message(l10n),
          actionLabel: l10n.retryButton,
          onAction: context.read<MovementDetailCubit>().load,
        ),
        MovementDetailLoaded(:final movement) => _MovementDetailContent(
          movement: movement,
        ),
      },
    );
  }
}

class _MovementDetailContent extends StatelessWidget {
  const new({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = movement.date;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(child: MovementTypeAvatar(type: movement.type, radius: 32)),
            const SizedBox(height: 16),
            Center(
              child: MovementAmountText(
                key: const Key('movementDetail_amount'),
                movement: movement,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movement.description,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(
              child: MovementStatusChip(
                status: movement.status,
                showCompleted: true,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _DetailRow(
                    label: l10n.detailType,
                    value: movement.type.label(l10n),
                  ),
                  _DetailRow(
                    label: l10n.detailStatus,
                    value: movement.status.label(l10n),
                  ),
                  _DetailRow(
                    label: l10n.detailDate,
                    value: date == null
                        ? l10n.detailDateUnavailable
                        : Formatters.longDateTime(date, locale),
                  ),
                  _DetailRow(
                    label: l10n.detailCurrency,
                    value: movement.amount.currency,
                  ),
                  _DetailRow(
                    label: l10n.detailId,
                    value: movement.id,
                    selectable: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;

  /// El id de operación se puede copiar (útil para soporte).
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    // M3 aplica `labelSmall` al `trailing` de ListTile; aquí el valor es
    // tan importante como la etiqueta.
    final style = Theme.of(context).textTheme.bodyMedium;
    return ListTile(
      title: Text(label),
      trailing: selectable
          ? SelectableText(value, style: style)
          : Text(value, style: style),
    );
  }
}
