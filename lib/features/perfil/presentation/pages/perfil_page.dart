import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/pagina_pendiente.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaPendiente(
      titulo: 'Perfil',
      descripcion: 'Aquí podrás consultar tus datos y cerrar sesión.',
      icono: Icons.person_outline,
    );
  }
}
