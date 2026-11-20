import 'package:feature_auth/src/application/auth_use_cases.dart';
import 'package:feature_auth/src/presentation/login/bloc/login_bloc.dart';
import 'package:feature_auth/src/presentation/login/demo_credentials.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wallet_domain/wallet_domain.dart';
import 'package:wallet_l10n/wallet_l10n.dart';
import 'package:wallet_ui/wallet_ui.dart';

/// Ruta de login: crea el [LoginBloc] y monta la vista.
///
/// [demoCredentials] solo llega en el flavor `development`: la feature no
/// conoce los flavors, el app shell decide si mostrar la cuenta demo.
class LoginPage extends StatelessWidget {
  const new({super.key, this.demoCredentials});

  final DemoCredentials? demoCredentials;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LoginBloc(login: LoginUseCase(context.read<AuthRepository>())),
      child: LoginView(demoCredentials: demoCredentials),
    );
  }
}

/// Vista del formulario de login. Solo pinta estado y envía eventos.
class LoginView extends StatelessWidget {
  const new({super.key, this.demoCredentials});

  /// Cuenta demo a sugerir, o `null` para no mostrar la ayuda.
  final DemoCredentials? demoCredentials;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final demo = demoCredentials;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // En web/tablet el formulario no se estira a todo el ancho.
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loginTitle,
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginSubtitle,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const _EmailField(),
                    const SizedBox(height: 16),
                    const _PasswordField(),
                    const _FailureBanner(),
                    const SizedBox(height: 24),
                    const _SubmitButton(),
                    if (demo != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.demoCredentialsHint(demo.email, demo.password),
                        key: const Key('login_demoHint'),
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (error, enabled) = context
        .select<LoginBloc, (EmailValidationError?, bool)>(
          (bloc) => (
            bloc.state.showValidationErrors ? bloc.state.emailError : null,
            !bloc.state.isSubmitting,
          ),
        );

    return TextField(
      key: const Key('login_emailField'),
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: l10n.emailLabel,
        prefixIcon: const Icon(Icons.email_outlined),
        errorText: switch (error) {
          null => null,
          EmailValidationError.empty => l10n.emailEmptyError,
          EmailValidationError.invalidFormat => l10n.emailInvalidError,
        },
      ),
      onChanged: (value) =>
          context.read<LoginBloc>().add(LoginEmailChanged(value)),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const new();

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  // Mostrar u ocultar la contraseña es estado efímero de UI: no va al bloc.
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (error, enabled) = context
        .select<LoginBloc, (PasswordValidationError?, bool)>(
          (bloc) => (
            bloc.state.showValidationErrors ? bloc.state.passwordError : null,
            !bloc.state.isSubmitting,
          ),
        );

    return TextField(
      key: const Key('login_passwordField'),
      enabled: enabled,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: l10n.passwordLabel,
        prefixIcon: const Icon(Icons.lock_outline),
        errorText: switch (error) {
          null => null,
          PasswordValidationError.empty => l10n.passwordEmptyError,
        },
        suffixIcon: IconButton(
          tooltip: _obscured
              ? l10n.showPasswordTooltip
              : l10n.hidePasswordTooltip,
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      onChanged: (value) =>
          context.read<LoginBloc>().add(LoginPasswordChanged(value)),
      onSubmitted: (_) => context.read<LoginBloc>().add(const LoginSubmitted()),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final failure = context.select<LoginBloc, Failure?>(
      (bloc) => bloc.state.failure,
    );
    if (failure == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          failure.message(context.l10n),
          key: const Key('login_failureMessage'),
          style: TextStyle(color: colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<LoginBloc, bool>(
      (bloc) => bloc.state.isSubmitting,
    );

    return FilledButton(
      key: const Key('login_submitButton'),
      onPressed: isSubmitting
          ? null
          : () => context.read<LoginBloc>().add(const LoginSubmitted()),
      child: isSubmitting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(context.l10n.loginButton),
    );
  }
}
