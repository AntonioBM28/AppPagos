import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/pagina_pendiente.dart';

class VerificarCodigoPage extends StatelessWidget {
  const VerificarCodigoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaginaPendiente(
      titulo: 'Verificar código',
      descripcion: 'Aquí ingresarás el código de verificación que te enviaremos por correo.',
      icono: Icons.mark_email_read_outlined,
    );
  }
}
