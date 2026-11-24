import 'package:material_ui/material_ui.dart';

import 'state_views.dart';

/// Marcador de posicion para secciones que se construyen en partes siguientes.
/// No muestra datos simulados: solo indica que la seccion esta pendiente.
class PaginaPendiente extends StatelessWidget {
  const PaginaPendiente({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    super.key,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: EmptyView(icono: icono, titulo: titulo, mensaje: descripcion),
    );
  }
}
