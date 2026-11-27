import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formateadores.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/imagen_servicio.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../compras/domain/compra.dart';
import '../../../compras/presentation/widgets/ticket_view.dart';
import '../../domain/operacion.dart';
import '../historial_cubit.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
final _fechaHora = DateFormat("d MMM y, HH:mm", 'es_MX');
final _fechaCorta = DateFormat('dd/MM/yyyy');

/// EJECUTIVO: "Operaciones", la bitacora de compras y pagos de todos los clientes.
/// CLIENTE: "Mis compras", su propio historial. Ambos son de solo lectura.
class HistorialPage extends StatefulWidget {
  const HistorialPage({required this.esEjecutivo, super.key});

  final bool esEjecutivo;

  static String titulo({required bool esEjecutivo}) => esEjecutivo ? 'Operaciones' : 'Mis compras';

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final _cliente = TextEditingController();
  final _texto = TextEditingController();
  EstadoOperacion? _estado;
  DateTimeRange? _fechas;
  bool _filtrosAbiertos = false;

  HistorialCubit get _cubit => context.read<HistorialCubit>();

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.buscar());
  }

  @override
  void dispose() {
    _cliente.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _buscar() => _cubit.buscar(FiltroOperaciones(
        nombreCliente: widget.esEjecutivo ? _cliente.text : null,
        texto: _texto.text,
        estado: _estado,
        fechaDesde: _fechas?.start,
        fechaHasta: _fechas?.end,
      ));

  Future<void> _limpiar() {
    _cliente.clear();
    _texto.clear();
    setState(() {
      _estado = null;
      _fechas = null;
    });
    return _cubit.buscar(const FiltroOperaciones());
  }

  Future<void> _elegirFechas() async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 5),
      lastDate: hoy,
      initialDateRange: _fechas,
      helpText: 'Periodo',
    );
    if (rango != null) setState(() => _fechas = rango);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = HistorialPage.titulo(esEjecutivo: widget.esEjecutivo);
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            tooltip: _filtrosAbiertos ? 'Ocultar filtros' : 'Mostrar filtros',
            icon: Icon(_filtrosAbiertos ? Icons.filter_alt_off_outlined : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _filtrosAbiertos = !_filtrosAbiertos),
          ),
        ],
      ),
      body: BlocBuilder<HistorialCubit, HistorialState>(
        builder: (context, estado) => RefreshIndicator(
          onRefresh: () => _cubit.buscar(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _centrado(Padding(padding: const EdgeInsets.all(AppSpacing.md), child: _filtros(estado)))),
              ..._resultados(estado),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centrado(Widget hijo) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
          child: hijo,
        ),
      );

  Widget _filtros(HistorialState estado) {
    final busqueda = TextField(
      controller: widget.esEjecutivo ? _cliente : _texto,
      inputFormatters: widget.esEjecutivo ? Formateadores.soloLetras : Formateadores.textoSeguro(60),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _buscar(),
      decoration: InputDecoration(
        labelText: widget.esEjecutivo ? 'Buscar por cliente' : 'Buscar producto o servicio',
        prefixIcon: Icon(widget.esEjecutivo ? Icons.person_search_outlined : Icons.search),
        suffixIcon: IconButton(tooltip: 'Buscar', icon: const Icon(Icons.arrow_forward), onPressed: _buscar),
      ),
    );
    if (!_filtrosAbiertos) return busqueda;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            busqueda,
            if (widget.esEjecutivo) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _texto,
                inputFormatters: Formateadores.textoSeguro(60),
                decoration: const InputDecoration(labelText: 'Producto o servicio', prefixIcon: Icon(Icons.storefront_outlined)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _elegirFechas,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(_fechas == null
                  ? 'Cualquier fecha'
                  : '${_fechaCorta.format(_fechas!.start)} – ${_fechaCorta.format(_fechas!.end)}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(label: const Text('Todas'), selected: _estado == null, onSelected: (_) => setState(() => _estado = null)),
                for (final e in EstadoOperacion.filtrables)
                  ChoiceChip(label: Text(e.etiqueta), selected: _estado == e, onSelected: (_) => setState(() => _estado = e)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: AppButton(texto: 'Limpiar', variante: AppButtonVariante.texto, onPressed: _limpiar)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppButton(texto: 'Buscar', icono: Icons.search, cargando: estado.cargando, onPressed: _buscar)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _resultados(HistorialState estado) {
    if (estado.cargando && estado.operaciones.isEmpty) {
      return const [SliverFillRemaining(hasScrollBody: false, child: LoadingView(mensaje: 'Cargando operaciones'))];
    }
    if (estado.error != null && estado.operaciones.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: ErrorView(mensaje: estado.error!, onReintentar: _buscar))];
    }
    if (estado.operaciones.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icono: Icons.receipt_long_outlined,
            titulo: 'Sin operaciones',
            mensaje: estado.filtro.tieneCriterios
                ? 'Ninguna operación coincide con los filtros.'
                : widget.esEjecutivo
                    ? 'Los clientes todavía no han realizado compras.'
                    : 'Aquí verás tus compras y pagos de servicios.',
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: _centrado(Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('${estado.total} operación(es)', style: Theme.of(context).textTheme.labelLarge),
        )),
      ),
      SliverList.builder(
        itemCount: estado.operaciones.length + 1,
        itemBuilder: (context, i) {
          if (i == estado.operaciones.length) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              child: Center(
                child: estado.hayMas
                    ? AppButton(
                        texto: 'Cargar más',
                        variante: AppButtonVariante.secundario,
                        cargando: estado.cargandoMas,
                        onPressed: _cubit.cargarMas,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          final operacion = estado.operaciones[i];
          return _centrado(Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: _TarjetaOperacion(
              operacion: operacion,
              mostrarCliente: widget.esEjecutivo,
              onTap: () => unawaited(showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => _DetalleOperacion(operacion: operacion, mostrarCliente: widget.esEjecutivo),
              )),
            ),
          ));
        },
      ),
    ];
  }
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.estado});

  final EstadoOperacion estado;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final (fondo, texto) = switch (estado) {
      EstadoOperacion.aprobada => (colores.primaryContainer, colores.onPrimaryContainer),
      EstadoOperacion.rechazada => (colores.errorContainer, colores.onErrorContainer),
      _ => (colores.tertiaryContainer, colores.onTertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(estado.etiqueta, style: TextStyle(color: texto, fontSize: 12)),
    );
  }
}

class _TarjetaOperacion extends StatelessWidget {
  const _TarjetaOperacion({required this.operacion, required this.mostrarCliente, required this.onTap});

  final Operacion operacion;
  final bool mostrarCliente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final o = operacion;
    final lineas = [
      if (mostrarCliente && o.nombreCliente != null) o.nombreCliente!,
      [o.servicio, _fechaHora.format(o.fecha)].whereType<String>().join(' · '),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox.square(dimension: 44, child: ImagenServicio(url: o.imagenUrl, tamano: 44)),
        title: Text(o.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(lineas.join('\n'), maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: lineas.length > 1,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_moneda.format(o.monto), style: tema.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            _EtiquetaEstado(estado: o.estado),
          ],
        ),
      ),
    );
  }
}

class _DetalleOperacion extends StatelessWidget {
  const _DetalleOperacion({required this.operacion, required this.mostrarCliente});

  final Operacion operacion;
  final bool mostrarCliente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final o = operacion;
    final datos = <String, String?>{
      if (mostrarCliente) 'Cliente': o.nombreCliente,
      'Servicio': o.servicio,
      'Monto': _moneda.format(o.monto),
      'Fecha': _fechaHora.format(o.fecha),
      'Teléfono o referencia': o.referencia,
      'Cuenta': o.numeroCuenta,
      'Autorización': o.numeroAutorizacion,
      'Folio': o.folio,
      'Resultado': o.detalle,
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 80, child: ImagenServicio(url: o.imagenUrl, tamano: 80)),
            const SizedBox(height: AppSpacing.md),
            Text(o.titulo, style: tema.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: _EtiquetaEstado(estado: o.estado)),
            const SizedBox(height: AppSpacing.md),
            for (final dato in datos.entries)
              if (dato.value != null && dato.value!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(dato.key, style: tema.textTheme.labelLarge)),
                      Expanded(child: SelectableText(dato.value!, textAlign: TextAlign.end)),
                    ],
                  ),
                ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              texto: 'Ver ticket',
              icono: Icons.receipt_long_outlined,
              variante: AppButtonVariante.secundario,
              expandir: true,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Comprobante')),
                  body: ContenidoCentrado(child: TicketView(ticket: Ticket.deOperacion(o))),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
