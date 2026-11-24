import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/breakpoints.dart';

class _Destino {
  const _Destino(this.etiqueta, this.icono, this.iconoActivo);

  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
}

const _destinos = [
  _Destino('Inicio', Icons.home_outlined, Icons.home),
  _Destino('Catálogo', Icons.storefront_outlined, Icons.storefront),
  _Destino('Historial', Icons.receipt_long_outlined, Icons.receipt_long),
  _Destino('Perfil', Icons.person_outline, Icons.person),
];

/// Estructura comun de las pantallas protegidas: barra inferior en pantallas
/// compactas y NavigationRail en pantallas anchas.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _irA(int indice) => navigationShell.goBranch(
        indice,
        // Tocar la seccion activa regresa a su pantalla inicial.
        initialLocation: indice == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final tamano = TamanoVentana.de(context);
    final indice = navigationShell.currentIndex;

    if (tamano == TamanoVentana.compacto) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: indice,
          onDestinationSelected: _irA,
          destinations: [
            for (final d in _destinos)
              NavigationDestination(
                icon: Icon(d.icono),
                selectedIcon: Icon(d.iconoActivo),
                label: d.etiqueta,
              ),
          ],
        ),
      );
    }

    final extendido = tamano == TamanoVentana.expandido;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: indice,
              onDestinationSelected: _irA,
              extended: extendido,
              labelType: extendido
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinos)
                  NavigationRailDestination(
                    icon: Icon(d.icono),
                    selectedIcon: Icon(d.iconoActivo),
                    label: Text(d.etiqueta),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
