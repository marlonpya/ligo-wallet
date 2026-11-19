import 'package:material_ui/material_ui.dart';

/// Pantalla mínima mientras se lee la sesión del almacenamiento seguro.
class SplashPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
