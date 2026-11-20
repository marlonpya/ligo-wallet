import 'package:equatable/equatable.dart';

/// Credenciales de una cuenta demo que el login puede sugerir.
///
/// Las provee el app shell (solo en el flavor `development`); la feature no
/// sabe de flavors ni del backend fake.
final class DemoCredentials extends Equatable {
  const new({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
