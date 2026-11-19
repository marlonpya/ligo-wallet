import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligo_wallet/features/auth/presentation/session/session_bloc.dart';
import 'package:ligo_wallet/features/auth/presentation/widgets/logout_button.dart';
import 'package:ligo_wallet/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Pantalla principal autenticada.
///
/// Por ahora solo saluda al usuario y permite cerrar sesión; el listado de
/// movimientos se agrega en el siguiente paso.
class MovementsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionBloc>().state;
    final name = session is SessionAuthenticated ? session.user.name : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.movementsTitle),
        actions: const [LogoutButton()],
      ),
      body: Center(
        child: Text(
          l10n.greeting(name),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
