import 'package:feature_auth/src/presentation/session/session_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_l10n/wallet_l10n.dart';

/// Botón de cierre de sesión con confirmación.
class LogoutButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      key: const Key('logoutButton'),
      tooltip: l10n.logoutButton,
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.logoutConfirmTitle),
            content: Text(l10n.logoutConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                key: const Key('logoutConfirmButton'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.logoutButton),
              ),
            ],
          ),
        );
        if ((confirmed ?? false) && context.mounted) {
          context.read<SessionBloc>().add(const SessionLogoutRequested());
        }
      },
    );
  }
}
