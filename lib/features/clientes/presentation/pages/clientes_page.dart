import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formateadores.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/cliente.dart';
import '../cubit/clientes_cubits.dart';

/// Lista de clientes del EJECUTIVO, con filtros combinables y paginacion.
class ClientesPage extends StatefulWidget {
  const ClientesPage({required this.onAbrir, required this.onNuevo, super.key});

  final ValueChanged<int> onAbrir;
  final VoidCallback onNuevo;

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _curp = TextEditingController();
  final _rfc = TextEditingController();
  final _correo = TextEditingController();
  bool? _activo;
  bool _filtrosAbiertos = false;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ClientesCubit>().buscar());
  }

  @override
  void dispose() {
    for (final c in [_nombre, _apellido, _curp, _rfc, _correo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscar() => context.read<ClientesCubit>().buscar(
        FiltroClientes(
          nombre: _nombre.text,
          apellidoPaterno: _apellido.text,
          curp: _curp.text,
          rfc: _rfc.text,
          correo: _correo.text,
          activo: _activo,
        ),
      );

  Future<void> _limpiar() {
    for (final c in [_nombre, _apellido, _curp, _rfc, _correo]) {
      c.clear();
    }
    setState(() => _activo = null);
    return context.read<ClientesCubit>().buscar(const FiltroClientes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: _filtrosAbiertos ? 'Ocultar filtros' : 'Mostrar filtros',
            icon: Icon(_filtrosAbiertos ? Icons.filter_alt_off_outlined : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _filtrosAbiertos = !_filtrosAbiertos),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNuevo,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente'),
      ),
      body: BlocBuilder<ClientesCubit, ClientesState>(
        builder: (context, estado) => RefreshIndicator(
          onRefresh: _buscar,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _filtros(estado),
                    ),
                  ),
                ),
              ),
              ..._resultados(estado),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtros(ClientesState estado) {
    final busquedaRapida = TextField(
      controller: _nombre,
      inputFormatters: Formateadores.soloLetras,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _buscar(),
      decoration: InputDecoration(
        labelText: 'Buscar por nombre',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(tooltip: 'Buscar', icon: const Icon(Icons.arrow_forward), onPressed: _buscar),
      ),
    );
    if (!_filtrosAbiertos) return busquedaRapida;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            busquedaRapida,
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _apellido,
              inputFormatters: Formateadores.soloLetras,
              decoration: const InputDecoration(labelText: 'Apellido paterno', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _curp,
              inputFormatters: Formateadores.claveMayusculas(18),
              decoration: const InputDecoration(labelText: 'CURP exacta', prefixIcon: Icon(Icons.fingerprint)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _rfc,
              inputFormatters: Formateadores.claveMayusculas(13),
              decoration: const InputDecoration(labelText: 'RFC exacto', prefixIcon: Icon(Icons.receipt_outlined)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _correo,
              inputFormatters: Formateadores.correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo exacto', prefixIcon: Icon(Icons.alternate_email)),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Todos')),
                ButtonSegment(value: true, label: Text('Activos')),
                ButtonSegment(value: false, label: Text('De baja')),
              ],
              selected: {_activo},
              onSelectionChanged: (s) => setState(() => _activo = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    texto: 'Limpiar',
                    variante: AppButtonVariante.texto,
                    onPressed: _limpiar,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(texto: 'Buscar', icono: Icons.search, cargando: estado.cargando, onPressed: _buscar),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _resultados(ClientesState estado) {
    if (estado.cargando && estado.clientes.isEmpty) {
      return const [SliverFillRemaining(hasScrollBody: false, child: LoadingView(mensaje: 'Buscando clientes'))];
    }
    if (estado.error != null && estado.clientes.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: ErrorView(mensaje: estado.error!, onReintentar: _buscar))];
    }
    if (estado.clientes.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icono: Icons.person_search_outlined,
            titulo: 'Sin resultados',
            mensaje: estado.filtro.tieneCriterios
                ? 'Ningún cliente coincide con los filtros.'
                : 'Todavía no hay clientes registrados.',
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('${estado.total} cliente(s)', style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ),
      ),
      SliverList.builder(
        itemCount: estado.clientes.length + 1,
        itemBuilder: (context, i) {
          if (i == estado.clientes.length) return _pie(estado);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: _TarjetaCliente(cliente: estado.clientes[i], onTap: () => widget.onAbrir(estado.clientes[i].id)),
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _pie(ClientesState estado) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        child: Center(
          child: estado.hayMas
              ? AppButton(
                  texto: 'Cargar más',
                  variante: AppButtonVariante.secundario,
                  cargando: estado.cargandoMas,
                  onPressed: context.read<ClientesCubit>().cargarMas,
                )
              : const SizedBox.shrink(),
        ),
      );
}

class _TarjetaCliente extends StatelessWidget {
  const _TarjetaCliente({required this.cliente, required this.onTap});

  final Cliente cliente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: cliente.activo ? colores.primaryContainer : colores.surfaceContainerHighest,
          child: Text(cliente.nombre.characters.first.toUpperCase()),
        ),
        title: Text(cliente.nombreCompleto, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${cliente.correo}\nCURP ${cliente.curp}', maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: cliente.activo ? const Icon(Icons.chevron_right) : const _Etiqueta(texto: 'De baja'),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colores.errorContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(texto, style: TextStyle(color: colores.onErrorContainer, fontSize: 12)),
    );
  }
}
