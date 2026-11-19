import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ligo_wallet/features/auth/application/auth_use_cases.dart';
import 'package:wallet_domain/wallet_domain.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Estado global de sesión de la app. Lo escucha el router (guard) y la UI
/// para mostrar el aviso de sesión expirada.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  /// Crea el bloc con sus casos de uso.
  new({
    required this._restoreSession,
    required this._watchSession,
    required this._logout,
  }) : super(const SessionInitial()) {
    on<SessionStarted>(_onStarted);
    on<SessionLogoutRequested>(_onLogoutRequested);
  }

  final RestoreSessionUseCase _restoreSession;
  final WatchSessionUseCase _watchSession;
  final LogoutUseCase _logout;

  Future<void> _onStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionState.fromStatus(await _restoreSession()));
    // A partir de aquí el repositorio es la fuente de verdad: login, logout y
    // expiración por 401 llegan por este stream.
    await emit.forEach<SessionStatus>(
      _watchSession(),
      onData: SessionState.fromStatus,
    );
  }

  Future<void> _onLogoutRequested(
    SessionLogoutRequested event,
    Emitter<SessionState> emit,
  ) => _logout();
}
