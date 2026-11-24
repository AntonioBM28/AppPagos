import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/pagina_pendiente.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaPendiente(
      titulo: 'Inicio',
      descripcion: 'Aquí verás el resumen de tus cuentas.',
      icono: Icons.home_outlined,
    );
  }
}
