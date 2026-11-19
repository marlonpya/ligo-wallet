import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligo_wallet/features/movements/presentation/list/bloc/movements_bloc.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Filtro Todos / Ingresos / Salidas (SegmentedButton de Material 3).
class MovementsFilterBar extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = context.select<MovementsBloc, MovementFilter>(
      (bloc) => bloc.state.query.filter,
    );

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<MovementFilter>(
        key: const Key('movements_filterBar'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: MovementFilter.all, label: Text(l10n.filterAll)),
          ButtonSegment(
            value: MovementFilter.income,
            label: Text(l10n.filterIncome),
          ),
          ButtonSegment(
            value: MovementFilter.expense,
            label: Text(l10n.filterExpense),
          ),
        ],
        selected: {filter},
        onSelectionChanged: (selection) => context.read<MovementsBloc>().add(
          MovementsFilterChanged(selection.single),
        ),
      ),
    );
  }
}
