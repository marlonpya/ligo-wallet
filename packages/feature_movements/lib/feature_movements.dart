/// Feature de movimientos: listado (búsqueda, filtros, refresco) y detalle.
///
/// La navegación, el saludo y las acciones extra llegan por parámetros desde
/// el app shell; la feature no conoce el router, la sesión ni otras
/// features. Lee `MovementsRepository` (de `wallet_domain`) del contexto.
library;

export 'src/presentation/detail/view/movement_detail_page.dart';
export 'src/presentation/list/bloc/movements_bloc.dart';
export 'src/presentation/list/view/movements_page.dart';
