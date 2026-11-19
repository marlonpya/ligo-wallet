import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

/// Cuerpo de `POST /auth/login`.
@JsonSerializable(createFactory: false)
final class LoginRequestDto {
  /// Crea el cuerpo de la petición.
  const new({required this.email, required this.password});

  /// Email del usuario.
  final String email;

  /// Contraseña en texto plano; solo viaja por HTTPS y nunca se persiste.
  final String password;

  /// Serializa a JSON.
  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);

  // Evita filtrar la contraseña si alguien imprime el objeto.
  @override
  String toString() => 'LoginRequestDto(email: $email, password: <redacted>)';
}

/// Respuesta de `POST /auth/login`.
@JsonSerializable(checked: true, createToJson: false)
final class LoginResponseDto {
  /// Crea la respuesta.
  const new({required this.token, required this.user});

  /// Construye desde JSON. Lanza si faltan campos o tienen otro tipo.
  factory fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  /// Token de acceso (JWT).
  final String token;

  /// Usuario autenticado.
  final UserDto user;

  @override
  String toString() => 'LoginResponseDto(user: $user, token: <redacted>)';
}

/// Usuario tal como lo devuelve la API.
@JsonSerializable(checked: true, createToJson: false)
final class UserDto {
  /// Crea el DTO.
  const new({required this.id, required this.name});

  /// Construye desde JSON. Lanza si faltan campos o tienen otro tipo.
  factory fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

  /// Id del usuario.
  final String id;

  /// Nombre para mostrar.
  final String name;

  @override
  String toString() => 'UserDto(id: $id)';
}
