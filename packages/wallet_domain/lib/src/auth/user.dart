import 'package:equatable/equatable.dart';

/// Usuario autenticado.
final class User extends Equatable {
  /// Crea un usuario.
  const new({required this.id, required this.name});

  /// Identificador del usuario (por ejemplo `u_001`).
  final String id;

  /// Nombre para mostrar.
  final String name;

  @override
  List<Object?> get props => [id, name];
}
