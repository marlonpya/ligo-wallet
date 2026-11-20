import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:feature_auth/src/application/auth_use_cases.dart';
import 'package:wallet_domain/wallet_domain.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Formulario de login (patrón MVI: eventos de entrada, estado inmutable de
/// salida).
///
/// No navega: si el login sale bien, el repositorio emite `Authenticated` y el
/// guard del router lleva al usuario a la pantalla principal.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// Crea el bloc.
  new({required this._login}) : super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    // `droppable`: ignora toques repetidos en "Ingresar" mientras hay un
    // login en curso (evita peticiones duplicadas).
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final LoginUseCase _login;

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(email: event.email, status: LoginStatus.editing));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(password: event.password, status: LoginStatus.editing));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(showValidationErrors: true));
      return;
    }

    emit(state.copyWith(status: LoginStatus.submitting));
    final result = await _login(email: state.email, password: state.password);
    switch (result) {
      case Ok():
        emit(state.copyWith(status: LoginStatus.success));
      case Err(:final failure):
        emit(state.copyWith(status: LoginStatus.failure, failure: failure));
    }
  }
}
