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
import '../../../catalogo/domain/entities/producto.dart';
import '../../../clientes/domain/entities/cliente.dart';
import '../../domain/compra.dart';
import '../compra_cubit.dart';
import '../widgets/crear_nip_view.dart';
import '../widgets/teclado_nip.dart';
import '../widgets/ticket_view.dart';
import '../widgets/token_dinamico_view.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// Compra de un producto como una transaccion bancaria: datos → NIP → token dinamico → ticket.
class CompraPage extends StatefulWidget {
  const CompraPage({required this.producto, required this.onTerminar, this.onVerCompras, super.key});

  final Producto producto;
  final VoidCallback onTerminar;
  final VoidCallback? onVerCompras;

  @override
  State<CompraPage> createState() => _CompraPageState();
}

class _CompraPageState extends State<CompraPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<CompraCubit>().iniciar());
  }

  String _titulo(PasoCompra paso) => switch (paso) {
        PasoCompra.captura => widget.producto.precioFijo ? 'Comprar' : 'Pagar servicio',
        PasoCompra.crearNip => 'Crea tu NIP',
        PasoCompra.nip => 'Confirma con tu NIP',
        PasoCompra.token => 'Autoriza la operación',
        PasoCompra.procesando => 'Procesando',
        PasoCompra.ticket => 'Comprobante',
      };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompraCubit, CompraState>(
      builder: (context, estado) {
        final cubit = context.read<CompraCubit>();
        // En el ticket o mientras se procesa no se puede regresar a medias
        final bloqueado = estado.paso == PasoCompra.procesando || estado.paso == PasoCompra.ticket;
        return PopScope(
          canPop: !bloqueado,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_titulo(estado.paso)),
              automaticallyImplyLeading: !bloqueado,
            ),
            body: ContenidoCentrado(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(estado.paso), child: _paso(context, estado, cubit)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _paso(BuildContext context, CompraState estado, CompraCubit cubit) {
    final resumen = estado.solicitud == null ? null : _Resumen(producto: widget.producto, solicitud: estado.solicitud!);
    switch (estado.paso) {
      case PasoCompra.captura:
        if (estado.cargando) return const LoadingView(mensaje: 'Preparando tu operación');
        if (estado.cuentas.isEmpty && estado.error != null) {
          return ErrorView(mensaje: estado.error!, onReintentar: cubit.iniciar);
        }
        return _Captura(
          producto: widget.producto,
          cuentas: estado.cuentasActivas,
          inicial: estado.solicitud,
          onContinuar: cubit.continuar,
        );
      case PasoCompra.crearNip:
        return CrearNipView(
          error: estado.error,
          ocupado: estado.ocupado,
          onCrear: cubit.crearNip,
          explicacion: 'Para tu seguridad, antes de tu primera compra crea un NIP de 4 dígitos. '
              'Lo usarás para confirmar cada operación.',
        );
      case PasoCompra.nip:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?resumen,
            const SizedBox(height: AppSpacing.lg),
            TecladoNip(
              titulo: 'Ingresa tu NIP',
              descripcion: estado.aviso ?? 'Para confirmar la operación',
              error: estado.error,
              ocupado: estado.ocupado,
              alCompletar: cubit.confirmarNip,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: cubit.corregirDatos, child: const Text('Corregir datos')),
          ],
        );
      case PasoCompra.token:
        return TokenDinamicoView(
          token: estado.token!,
          emitidoEn: estado.emitidoEn!,
          resumen: resumen ?? const SizedBox.shrink(),
          error: estado.error,
          ocupado: estado.ocupado,
          alAutorizar: cubit.autorizarPago,
          alExpirar: cubit.tokenExpirado,
        );
      case PasoCompra.procesando:
        return const LoadingView(mensaje: 'Procesando tu operación con GestoPago');
      case PasoCompra.ticket:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TicketView(ticket: estado.ticket!),
            const SizedBox(height: AppSpacing.lg),
            AppButton(texto: 'Listo', icono: Icons.check, expandir: true, onPressed: widget.onTerminar),
            if (widget.onVerCompras != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                texto: 'Ver mis compras',
                variante: AppButtonVariante.texto,
                expandir: true,
                onPressed: widget.onVerCompras,
              ),
            ],
          ],
        );
    }
  }
}

/// Producto y monto que se esta autorizando.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.producto, required this.solicitud});

  final Producto producto;
  final SolicitudCompra solicitud;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final destino = solicitud.destino ?? solicitud.referencia;
    return Card(
      child: ListTile(
        leading: SizedBox.square(dimension: 40, child: ImagenServicio(url: producto.imagenUrl, tamano: 40)),
        title: Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([producto.servicio, ?destino].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(_moneda.format(solicitud.monto), style: tema.textTheme.titleMedium),
      ),
    );
  }
}

/// Paso 1: cuenta de cargo, telefono o referencia, y monto.
class _Captura extends StatefulWidget {
  const _Captura({required this.producto, required this.cuentas, required this.onContinuar, this.inicial});

  final Producto producto;
  final List<CuentaResumen> cuentas;
  final SolicitudCompra? inicial;
  final ValueChanged<SolicitudCompra> onContinuar;

  @override
  State<_Captura> createState() => _CapturaState();
}

class _CapturaState extends State<_Captura> {
  static const montoMaximo = 100000.0;

  final _formulario = GlobalKey<FormState>();
  late final _destino = TextEditingController(text: widget.inicial?.destino ?? '');
  late final _referencia = TextEditingController(text: widget.inicial?.referencia ?? '');
  late final _monto = TextEditingController(
    text: widget.inicial == null || widget.producto.precioFijo ? '' : widget.inicial!.monto.toStringAsFixed(2),
  );
  late CuentaResumen? _cuenta = widget.cuentas
          .where((c) => c.numeroCuenta == widget.inicial?.numeroCuenta)
          .firstOrNull ??
      widget.cuentas.firstOrNull;

  Producto get p => widget.producto;

  @override
  void dispose() {
    _destino.dispose();
    _referencia.dispose();
    _monto.dispose();
    super.dispose();
  }

  double? get _montoCapturado =>
      p.precioFijo ? p.precio : double.tryParse(_monto.text.replaceAll(',', '').trim());

  String? _validarMonto(String? _) {
    final monto = _montoCapturado;
    if (monto == null || monto <= 0) return 'Escribe el monto a pagar';
    if (monto > montoMaximo) return r'El monto máximo es de $100,000.00';
    return _validarSaldo(monto);
  }

  String? _validarSaldo(double monto) {
    final saldo = _cuenta?.saldo ?? 0;
    return monto > saldo ? 'Saldo insuficiente: tienes ${_moneda.format(saldo)}' : null;
  }

  String? _validarDestino(String? valor) {
    final texto = (valor ?? '').trim();
    if (p.destinoEsTelefono) {
      return RegExp(r'^[0-9]{10}$').hasMatch(texto) ? null : 'Escribe un teléfono de 10 dígitos';
    }
    return texto.isEmpty ? 'Escribe el número o destino' : null;
  }

  void _continuar() {
    final saldoValido = !p.precioFijo || _validarSaldo(p.precio) == null;
    if (!(_formulario.currentState?.validate() ?? false) || _cuenta == null || !saldoValido) {
      if (!saldoValido) setState(() {});
      return;
    }
    widget.onContinuar(SolicitudCompra(
      numeroCuenta: _cuenta!.numeroCuenta,
      idServicio: p.idServicio,
      idProducto: p.idProducto,
      monto: _montoCapturado!,
      destino: p.pideDestino ? _destino.text.trim() : null,
      referencia: p.pideDestino ? null : _referencia.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (!p.sePuedeComprar) {
      return const EmptyView(
        icono: Icons.block,
        titulo: 'Producto no disponible',
        mensaje: 'Este producto requiere un tipo de pago que la app todavía no maneja.',
      );
    }
    if (widget.cuentas.isEmpty) {
      return const EmptyView(
        icono: Icons.account_balance_wallet_outlined,
        titulo: 'Sin cuentas activas',
        mensaje: 'Necesitas una cuenta activa con saldo para comprar. Acude con tu ejecutivo.',
      );
    }
    final saldoInsuficiente = p.precioFijo ? _validarSaldo(p.precio) : null;
    return Form(
      key: _formulario,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  SizedBox.square(dimension: 64, child: ImagenServicio(url: p.imagenUrl, tamano: 64)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.servicio, style: tema.textTheme.labelMedium?.copyWith(color: tema.colorScheme.primary)),
                        Text(p.nombre, style: tema.textTheme.titleMedium),
                        if (p.precioFijo) Text(_moneda.format(p.precio), style: tema.textTheme.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.cuentas.length > 1)
            DropdownButtonFormField<CuentaResumen>(
              initialValue: _cuenta,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Cuenta de cargo', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
              items: [
                for (final c in widget.cuentas)
                  DropdownMenuItem(value: c, child: Text('${Ticket.enmascararCuenta(c.numeroCuenta)} · ${_moneda.format(c.saldo)}')),
              ],
              onChanged: (c) => setState(() => _cuenta = c),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text('Cuenta ${Ticket.enmascararCuenta(_cuenta!.numeroCuenta)}'),
                subtitle: Text('Saldo disponible: ${_moneda.format(_cuenta!.saldo)}'),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (p.pideDestino)
            TextFormField(
              controller: _destino,
              keyboardType: p.destinoEsTelefono ? TextInputType.phone : TextInputType.text,
              inputFormatters: p.destinoEsTelefono ? Formateadores.soloDigitos(10) : Formateadores.textoSeguro(30),
              decoration: InputDecoration(
                labelText: p.destinoEsTelefono ? 'Número de teléfono' : 'Número o destino',
                prefixIcon: Icon(p.destinoEsTelefono ? Icons.smartphone : Icons.tag),
                helperText: p.destinoEsTelefono ? '10 dígitos' : null,
              ),
              validator: _validarDestino,
            )
          else
            TextFormField(
              controller: _referencia,
              inputFormatters: Formateadores.textoSeguro(30),
              decoration: InputDecoration(
                labelText: p.pideReferencia ? 'Número de referencia o contrato' : 'Referencia (opcional)',
                prefixIcon: const Icon(Icons.receipt_long_outlined),
                helperText: 'Viene impresa en tu recibo',
              ),
              validator: (v) => p.pideReferencia && (v ?? '').trim().isEmpty ? 'Escribe la referencia de tu recibo' : null,
            ),
          if (!p.precioFijo) ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _monto,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: Formateadores.importe,
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                prefixText: r'$ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: _validarMonto,
            ),
          ],
          if (saldoInsuficiente != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(saldoInsuficiente, style: TextStyle(color: tema.colorScheme.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(texto: 'Continuar', icono: Icons.arrow_forward, expandir: true, onPressed: _continuar),
        ],
      ),
    );
  }
}
