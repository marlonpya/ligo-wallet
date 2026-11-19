import 'package:equatable/equatable.dart';
import 'package:wallet_domain/src/movements/movement.dart';

/// Filtro por tipo que ofrece la pantalla: Todos / Ingresos / Salidas.
enum MovementFilter {
  /// Todos los movimientos.
  all,

  /// Solo ingresos.
  income,

  /// Solo salidas.
  expense;

  /// `true` si [movement] pasa este filtro.
  bool accepts(Movement movement) => switch (this) {
    MovementFilter.all => true,
    MovementFilter.income => movement.type == MovementType.income,
    MovementFilter.expense => movement.type == MovementType.expense,
  };
}

/// Criterio combinado de búsqueda por descripción y filtro por tipo.
///
/// Vive en el dominio para que la regla de "qué movimientos se muestran" no
/// quede en un widget y se pueda testear sin Flutter.
final class MovementQuery extends Equatable {
  /// Crea una consulta. Por defecto no filtra nada.
  const new({this.searchTerm = '', this.filter = MovementFilter.all});

  /// Texto a buscar en la descripción.
  final String searchTerm;

  /// Filtro por tipo de movimiento.
  final MovementFilter filter;

  /// `true` si la consulta no restringe resultados.
  bool get isEmpty =>
      _normalize(searchTerm).isEmpty && filter == MovementFilter.all;

  /// `true` si [movement] cumple el filtro y la búsqueda.
  ///
  /// La búsqueda ignora mayúsculas, tildes y espacios extra, porque el usuario
  /// suele escribir "credito" esperando encontrar "Abono de crédito".
  bool matches(Movement movement) {
    if (!filter.accepts(movement)) return false;
    final term = _normalize(searchTerm);
    if (term.isEmpty) return true;
    return _normalize(movement.description).contains(term);
  }

  /// Devuelve los movimientos que cumplen la consulta, en el mismo orden.
  List<Movement> apply(Iterable<Movement> movements) =>
      movements.where(matches).toList(growable: false);

  /// Copia con los campos indicados reemplazados.
  MovementQuery copyWith({String? searchTerm, MovementFilter? filter}) =>
      MovementQuery(
        searchTerm: searchTerm ?? this.searchTerm,
        filter: filter ?? this.filter,
      );

  static const Map<String, String> _diacritics = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
  };

  static final RegExp _whitespace = RegExp(r'\s+');

  // Minúsculas, sin tildes y con espacios colapsados. La ñ se conserva porque
  // en español es una letra distinta.
  static String _normalize(String input) {
    final lower = input.trim().toLowerCase().replaceAll(_whitespace, ' ');
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_diacritics[char] ?? char);
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [searchTerm, filter];
}
