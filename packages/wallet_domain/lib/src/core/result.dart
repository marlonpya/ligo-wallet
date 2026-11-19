import 'package:equatable/equatable.dart';
import 'package:wallet_domain/src/core/failure.dart';

/// Resultado de una operación que puede fallar con un [Failure].
///
/// Los repositorios devuelven `Result` en lugar de lanzar excepciones, de modo
/// que el error forma parte del tipo y el compilador obliga a manejarlo
/// (equivalente a `Result<T>` de Kotlin o `Result<Success, Failure>` de Swift).
sealed class Result<T> extends Equatable {
  /// Constructor base para las subclases.
  const new();

  /// Atajo para crear un resultado exitoso.
  const factory ok(T value) = Ok<T>;

  /// Atajo para crear un resultado fallido.
  const factory err(Failure failure) = Err<T>;

  /// `true` si la operación terminó bien.
  bool get isOk => this is Ok<T>;

  /// Reduce el resultado a un único valor manejando ambos casos.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) => switch (this) {
    Ok(:final value) => onOk(value),
    Err(:final failure) => onErr(failure),
  };

  /// Transforma el valor exitoso y deja pasar el fallo sin cambios.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

/// Resultado exitoso que contiene [value].
final class Ok<T> extends Result<T> {
  /// Crea un resultado exitoso.
  const new(this.value);

  /// Valor producido por la operación.
  final T value;

  @override
  List<Object?> get props => [value];
}

/// Resultado fallido que contiene el [failure].
final class Err<T> extends Result<T> {
  /// Crea un resultado fallido.
  const new(this.failure);

  /// Motivo del fallo.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
