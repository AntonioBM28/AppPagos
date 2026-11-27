import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formateadores.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/imagen_servicio.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/producto.dart';
import '../cubit/catalogo_cubit.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

String _precio(Producto p) => p.montoVariable ? 'Monto variable' : _moneda.format(p.precio);

/// Catalogo de productos y servicios de GestoPago. No se puede modificar; el CLIENTE puede
/// comprar desde el detalle de un producto ([onComprar] es null para el EJECUTIVO).
class CatalogoPage extends StatefulWidget {
  const CatalogoPage({this.onComprar, super.key});

  final void Function(Producto producto)? onComprar;

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final _texto = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(context.read<CatalogoCubit>().buscar());
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  CatalogoCubit get _cubit => context.read<CatalogoCubit>();

  Future<void> _buscarTexto() => _cubit.buscar(_cubit.state.filtro.conTexto(_texto.text));

  Future<void> _abrirFiltros() async {
    final estado = _cubit.state;
    final filtro = await showModalBottomSheet<FiltroProductos>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PanelFiltros(
        filtro: estado.filtro.conTexto(_texto.text),
        servicios: estado.servicios,
        tipos: estado.tiposServicio,
      ),
    );
    if (filtro != null) await _cubit.buscar(filtro);
  }

  void _verProducto(Producto producto) => unawaited(
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (hoja) => _DetalleProducto(
            producto: producto,
            onComprar: widget.onComprar == null
                ? null
                : () {
                    Navigator.of(hoja).pop();
                    widget.onComprar!(producto);
                  },
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogoCubit, CatalogoState>(
      builder: (context, estado) {
        final activos = estado.filtro.filtrosActivos;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Catálogo'),
            actions: [
              IconButton(
                tooltip: activos == 0 ? 'Filtros' : 'Filtros ($activos activos)',
                icon: Badge(
                  isLabelVisible: activos > 0,
                  label: Text('$activos'),
                  child: const Icon(Icons.tune),
                ),
                onPressed: _abrirFiltros,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _cubit.buscar(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _centrado(_encabezado(estado))),
                ..._resultados(estado),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _centrado(Widget hijo) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
          child: hijo,
        ),
      );

  Widget _encabezado(CatalogoState estado) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _texto,
              inputFormatters: Formateadores.textoSeguro(60),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscarTexto(),
              decoration: InputDecoration(
                labelText: 'Buscar producto o servicio',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(tooltip: 'Buscar', icon: const Icon(Icons.arrow_forward), onPressed: _buscarTexto),
              ),
            ),
            if (estado.filtro.tieneCriterios) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: _chipsFiltros(estado),
              ),
            ],
          ],
        ),
      );

  List<Widget> _chipsFiltros(CatalogoState estado) {
    final f = estado.filtro;
    final servicio = estado.servicios.where((s) => s.idServicio == f.idServicio).firstOrNull;
    FiltroProductos sin({bool servicio = false, bool tipo = false, bool precio = false}) => FiltroProductos(
          texto: f.texto,
          idServicio: servicio ? null : f.idServicio,
          idCatTipoServicio: tipo ? null : f.idCatTipoServicio,
          precioMin: precio ? null : f.precioMin,
          precioMax: precio ? null : f.precioMax,
          orden: f.orden,
        );
    return [
      if (f.idServicio != null)
        InputChip(
          label: Text(servicio?.servicio ?? 'Servicio ${f.idServicio}'),
          onDeleted: () => _cubit.buscar(sin(servicio: true)),
        ),
      if (f.idCatTipoServicio != null)
        InputChip(label: Text('Tipo ${f.idCatTipoServicio}'), onDeleted: () => _cubit.buscar(sin(tipo: true))),
      if (f.precioMin != null || f.precioMax != null)
        InputChip(
          label: Text(_rango(f.precioMin, f.precioMax)),
          onDeleted: () => _cubit.buscar(sin(precio: true)),
        ),
      ActionChip(
        avatar: const Icon(Icons.clear_all, size: 18),
        label: const Text('Limpiar'),
        onPressed: () {
          _texto.clear();
          unawaited(_cubit.buscar(FiltroProductos(orden: f.orden)));
        },
      ),
    ];
  }

  static String _rango(double? min, double? max) => switch ((min, max)) {
        (final a?, final b?) => '${_moneda.format(a)} a ${_moneda.format(b)}',
        (final a?, null) => 'Desde ${_moneda.format(a)}',
        (null, final b?) => 'Hasta ${_moneda.format(b)}',
        _ => '',
      };

  List<Widget> _resultados(CatalogoState estado) {
    if (estado.cargando && estado.productos.isEmpty) {
      return const [SliverFillRemaining(hasScrollBody: false, child: LoadingView(mensaje: 'Cargando catálogo'))];
    }
    if (estado.error != null && estado.productos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(mensaje: estado.error!, onReintentar: () => _cubit.buscar()),
        ),
      ];
    }
    if (estado.productos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icono: Icons.search_off,
            titulo: 'Sin resultados',
            mensaje: estado.filtro.tieneCriterios
                ? 'Ningún producto coincide con los filtros.'
                : 'El catálogo todavía no tiene productos.',
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: _centrado(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text('${estado.total} producto(s)', style: Theme.of(context).textTheme.labelLarge),
                ),
                Text(estado.filtro.orden.etiqueta, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.md),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 250,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: estado.productos.length,
          itemBuilder: (context, i) => _TarjetaProducto(
            producto: estado.productos[i],
            onTap: () => _verProducto(estado.productos[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
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
        ),
      ),
    ];
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({required this.producto, required this.onTap});

  final Producto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 110,
              color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ImagenServicio(url: producto.imagenUrl, tamano: 80),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.servicio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.labelMedium?.copyWith(color: tema.colorScheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: Text(producto.nombre, maxLines: 3, overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.bodyMedium),
                    ),
                    Text(_precio(producto), style: tema.textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleProducto extends StatelessWidget {
  const _DetalleProducto({required this.producto, this.onComprar});

  final Producto producto;
  final VoidCallback? onComprar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final datos = <String, String>{
      'Servicio': producto.servicio,
      'Precio': _precio(producto),
      'Clave del producto': '${producto.idProducto}',
      'Clave del servicio': '${producto.idServicio}',
      if (producto.idCatTipoServicio != null) 'Tipo de servicio': '${producto.idCatTipoServicio}',
      if (producto.tipoReferencia != null) 'Tipo de referencia': producto.tipoReferencia!.toUpperCase(),
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 120, child: ImagenServicio(url: producto.imagenUrl, tamano: 120)),
            const SizedBox(height: AppSpacing.md),
            Text(producto.nombre, style: tema.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final dato in datos.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(dato.key, style: tema.textTheme.labelLarge)),
                    Expanded(child: SelectableText(dato.value, textAlign: TextAlign.end)),
                  ],
                ),
              ),
            if (producto.leyenda != null && producto.leyenda!.isNotEmpty) ...[
              const Divider(height: AppSpacing.lg),
              Text('Información', style: tema.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(producto.leyenda!, style: tema.textTheme.bodyMedium),
            ],
            if (onComprar != null) ...[
              const SizedBox(height: AppSpacing.lg),
              if (producto.sePuedeComprar)
                AppButton(
                  texto: producto.precioFijo ? 'Comprar' : 'Pagar servicio',
                  icono: Icons.shopping_cart_checkout,
                  expandir: true,
                  onPressed: onComprar,
                )
              else
                Text(
                  'Este producto requiere un tipo de pago que la app todavía no maneja.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Filtros combinables: servicio, tipo de servicio, rango de precio y orden.
class _PanelFiltros extends StatefulWidget {
  const _PanelFiltros({required this.filtro, required this.servicios, required this.tipos});

  final FiltroProductos filtro;
  final List<ServicioCatalogo> servicios;
  final List<int> tipos;

  @override
  State<_PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<_PanelFiltros> {
  final _formulario = GlobalKey<FormState>();
  late int? _servicio = widget.filtro.idServicio;
  late int? _tipo = widget.filtro.idCatTipoServicio;
  late OrdenProducto _orden = widget.filtro.orden;
  late final _min = TextEditingController(text: _texto(widget.filtro.precioMin));
  late final _max = TextEditingController(text: _texto(widget.filtro.precioMax));

  static String _texto(double? v) => v == null ? '' : v.toStringAsFixed(2);
  static double? _valor(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '').trim());

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  String? _validarMax(String? _) {
    final min = _valor(_min);
    final max = _valor(_max);
    return min != null && max != null && min > max ? 'Debe ser mayor o igual al mínimo' : null;
  }

  void _aplicar() {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(FiltroProductos(
      texto: widget.filtro.texto,
      idServicio: _servicio,
      idCatTipoServicio: _tipo,
      precioMin: _valor(_min),
      precioMax: _valor(_max),
      orden: _orden,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Form(
          key: _formulario,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                initialValue: _servicio,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Servicio', prefixIcon: Icon(Icons.storefront_outlined)),
                items: [
                  const DropdownMenuItem(child: Text('Todos')),
                  for (final s in widget.servicios)
                    DropdownMenuItem(
                      value: s.idServicio,
                      child: Row(
                        children: [
                          SizedBox.square(dimension: 24, child: ImagenServicio(url: s.imagenUrl, tamano: 24)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(s.servicio, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _servicio = v),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                initialValue: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de servicio', prefixIcon: Icon(Icons.category_outlined)),
                items: [
                  const DropdownMenuItem(child: Text('Todos')),
                  for (final t in widget.tipos) DropdownMenuItem(value: t, child: Text('Tipo $t')),
                ],
                onChanged: (v) => setState(() => _tipo = v),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: Formateadores.importe,
                      decoration: const InputDecoration(labelText: 'Precio mínimo', prefixText: r'$ '),
                      onChanged: (_) => _formulario.currentState?.validate(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _max,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: Formateadores.importe,
                      decoration: const InputDecoration(labelText: 'Precio máximo', prefixText: r'$ '),
                      validator: _validarMax,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<OrdenProducto>(
                initialValue: _orden,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ordenar por', prefixIcon: Icon(Icons.sort)),
                items: [for (final o in OrdenProducto.values) DropdownMenuItem(value: o, child: Text(o.etiqueta))],
                onChanged: (v) => setState(() => _orden = v ?? _orden),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      texto: 'Quitar filtros',
                      variante: AppButtonVariante.texto,
                      onPressed: () => Navigator.of(context).pop(FiltroProductos(texto: widget.filtro.texto)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppButton(texto: 'Aplicar', icono: Icons.check, onPressed: _aplicar)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
