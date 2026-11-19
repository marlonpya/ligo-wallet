import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligo_wallet/features/movements/presentation/list/bloc/movements_bloc.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Campo de búsqueda por descripción. El debounce lo aplica el bloc.
class MovementsSearchField extends StatefulWidget {
  const new({super.key});

  @override
  State<MovementsSearchField> createState() => _MovementsSearchFieldState();
}

class _MovementsSearchFieldState extends State<MovementsSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<MovementsBloc>().add(const MovementsSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Si la búsqueda se limpia desde fuera ("Limpiar filtros"), el texto del
    // campo debe acompañar al estado.
    return BlocListener<MovementsBloc, MovementsState>(
      listenWhen: (previous, current) =>
          previous.query.searchTerm != current.query.searchTerm &&
          current.query.searchTerm.isEmpty,
      listener: (_, _) => _controller.clear(),
      child: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) => TextField(
          key: const Key('movements_searchField'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clearSearchTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  ),
          ),
          onChanged: (term) =>
              context.read<MovementsBloc>().add(MovementsSearchChanged(term)),
        ),
      ),
    );
  }
}
