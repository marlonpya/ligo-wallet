/// Design system de la billetera: tema, widgets compartidos, formatos de
/// montos y fechas, y el mensaje de cada `Failure`.
///
/// No conoce features ni datos: solo `wallet_domain` (tipos que muestra) y
/// `wallet_l10n` (textos).
library;

export 'src/failure_message.dart';
export 'src/formatters.dart';
export 'src/theme/app_theme.dart';
export 'src/widgets/message_view.dart';
