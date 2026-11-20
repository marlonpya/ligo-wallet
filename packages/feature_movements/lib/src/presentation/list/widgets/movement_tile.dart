import 'package:feature_movements/src/presentation/widgets/movement_visuals.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_ui/wallet_ui.dart';

/// Fila de un movimiento en el listado.
class MovementTile extends StatelessWidget {
  const new({required this.movement, required this.onTap, super.key});

  final Movement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = movement.date;
    return ListTile(
      key: Key('movementTile_${movement.id}'),
      onTap: onTap,
      leading: MovementTypeAvatar(type: movement.type),
      title: Text(
        movement.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (date != null)
            Flexible(child: Text(Formatters.shortDate(date, locale))),
          if (date != null && movement.status != MovementStatus.completed)
            const SizedBox(width: 8),
          MovementStatusChip(status: movement.status),
        ],
      ),
      trailing: MovementAmountText(movement: movement),
    );
  }
}
