import 'package:ligo_wallet/core/presentation/formatters.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';

/// Piezas visuales compartidas por la lista y el detalle de movimientos.

/// Color de ingresos: verde legible en tema claro y oscuro.
Color incomeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.green.shade300
    : Colors.green.shade800;

/// Ícono circular que indica la dirección del dinero.
class MovementTypeAvatar extends StatelessWidget {
  const new({required this.type, this.radius = 20, super.key});

  final MovementType type;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncome = type == MovementType.income;
    return CircleAvatar(
      radius: radius,
      backgroundColor: isIncome
          ? incomeColor(context).withValues(alpha: 0.15)
          : colorScheme.surfaceContainerHighest,
      child: Icon(
        isIncome ? Icons.south_west : Icons.north_east,
        size: radius,
        color: isIncome ? incomeColor(context) : colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Monto con signo y color según la dirección.
class MovementAmountText extends StatelessWidget {
  const new({required this.movement, this.style, super.key});

  final Movement movement;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium;
    return Text(
      Formatters.money(movement.signedAmount, signed: true),
      style: base?.copyWith(
        fontWeight: FontWeight.w600,
        color: movement.isIncome
            ? incomeColor(context)
            : Theme.of(context).colorScheme.onSurface,
        // Cifras de ancho fijo: los montos quedan alineados en la lista.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Etiqueta de estado. No se muestra para `completed` en la lista (es el
/// caso normal) salvo que se pida con [showCompleted].
class MovementStatusChip extends StatelessWidget {
  const new({required this.status, this.showCompleted = false, super.key});

  final MovementStatus status;
  final bool showCompleted;

  @override
  Widget build(BuildContext context) {
    if (status == MovementStatus.completed && !showCompleted) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      MovementStatus.completed => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      MovementStatus.pending => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      MovementStatus.failed => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      MovementStatus.unknown => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          status.label(context.l10n),
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

/// Textos localizados de los enums del dominio.
extension MovementStatusLabel on MovementStatus {
  /// Nombre visible del estado.
  String label(AppLocalizations l10n) => switch (this) {
    MovementStatus.completed => l10n.statusCompleted,
    MovementStatus.pending => l10n.statusPending,
    MovementStatus.failed => l10n.statusFailed,
    MovementStatus.unknown => l10n.statusUnknown,
  };
}

/// Nombre visible del tipo de movimiento.
extension MovementTypeLabel on MovementType {
  /// Nombre visible del tipo.
  String label(AppLocalizations l10n) => switch (this) {
    MovementType.income => l10n.typeIncome,
    MovementType.expense => l10n.typeExpense,
  };
}
