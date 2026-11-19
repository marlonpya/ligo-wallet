import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Skeleton del listado: filas con la forma de `MovementTile` que pulsan
/// mientras se cargan los datos (sin dependencias externas de shimmer).
class MovementsSkeleton extends StatefulWidget {
  const new({this.itemCount = 8, super.key});

  final int itemCount;

  @override
  State<MovementsSkeleton> createState() => _MovementsSkeletonState();
}

class _MovementsSkeletonState extends State<MovementsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingMovements,
      liveRegion: true,
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
          child: ListView.builder(
            key: const Key('movementsSkeleton'),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.itemCount,
            itemBuilder: (context, _) => const _SkeletonTile(),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return ListTile(
      leading: CircleAvatar(backgroundColor: color),
      title: Align(alignment: Alignment.centerLeft, child: bar(160, 14)),
      subtitle: Align(alignment: Alignment.centerLeft, child: bar(90, 12)),
      trailing: bar(72, 16),
    );
  }
}
