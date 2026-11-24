import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/pagina_pendiente.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaPendiente(
      titulo: 'Historial',
      descripcion: 'Aquí verás tus compras exitosas.',
      icono: Icons.receipt_long_outlined,
    );
  }
}
