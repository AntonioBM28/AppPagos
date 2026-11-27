import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/breakpoints.dart';

class _Destino {
  const _Destino(this.rama, this.etiqueta, this.icono, this.iconoActivo, {this.soloEjecutivo = false});

  /// Indice de la rama en el StatefulShellRoute (ver app_router.dart).
  final int rama;
  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
  final bool soloEjecutivo;
}

/// La rama 3 cambia segun el rol: el EJECUTIVO no compra, ve la bitacora de operaciones
/// de los clientes; el CLIENTE ve su historial de compras.
List<_Destino> _destinos({required bool esEjecutivo}) => [
      const _Destino(0, 'Inicio', Icons.home_outlined, Icons.home),
      if (esEjecutivo) const _Destino(1, 'Clientes', Icons.groups_outlined, Icons.groups, soloEjecutivo: true),
      const _Destino(2, 'Catálogo', Icons.storefront_outlined, Icons.storefront),
      if (esEjecutivo)
        const _Destino(3, 'Operaciones', Icons.manage_search_outlined, Icons.manage_search)
      else
        const _Destino(3, 'Mis compras', Icons.receipt_long_outlined, Icons.receipt_long),
      const _Destino(4, 'Perfil', Icons.person_outline, Icons.person),
    ];

/// Estructura comun de las pantallas protegidas: barra inferior en pantallas
/// compactas y NavigationRail en pantallas anchas. La seccion Clientes solo aparece
/// para el EJECUTIVO.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, required this.esEjecutivo, super.key});

  final StatefulNavigationShell navigationShell;
  final bool esEjecutivo;

  List<_Destino> get _visibles => _destinos(esEjecutivo: esEjecutivo);

  void _irA(int posicion) {
    final rama = _visibles[posicion].rama;
    navigationShell.goBranch(
      rama,
      // Tocar la seccion activa regresa a su pantalla inicial.
      initialLocation: rama == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    final posicion = visibles.indexWhere((d) => d.rama == navigationShell.currentIndex);
    final indice = posicion < 0 ? 0 : posicion;
    final tamano = TamanoVentana.de(context);

    if (tamano == TamanoVentana.compacto) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: indice,
          onDestinationSelected: _irA,
          destinations: [
            for (final d in visibles)
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
              labelType: extendido ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              destinations: [
                for (final d in visibles)
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
