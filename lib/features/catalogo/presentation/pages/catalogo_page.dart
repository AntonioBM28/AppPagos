import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/pagina_pendiente.dart';

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaPendiente(
      titulo: 'Catálogo',
      descripcion: 'Aquí podrás consultar los productos de GestoPago.',
      icono: Icons.storefront_outlined,
    );
  }
}
