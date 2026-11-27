import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/imagen_servicio.dart';
import '../../../historial/domain/operacion.dart';
import '../../domain/compra.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: r'$');
final _fecha = DateFormat("EEEE d 'de' MMMM 'de' y", 'es_MX');
final _hora = DateFormat('HH:mm:ss', 'es_MX');

/// Comprobante de una operacion, con aspecto de ticket: encabezado con el resultado, datos de la
/// operacion y de la cuenta, motivo del rechazo y folios para aclaraciones.
class TicketView extends StatelessWidget {
  const TicketView({required this.ticket, super.key});

  final Ticket ticket;

  ({Color fondo, Color texto, IconData icono, String titulo, String subtitulo}) _resultado(ColorScheme c) =>
      switch (ticket.estado) {
        EstadoOperacion.aprobada => (
            fondo: c.primary,
            texto: c.onPrimary,
            icono: Icons.check_circle_outline,
            titulo: 'Operación exitosa',
            subtitulo: 'Tu pago se aplicó correctamente',
          ),
        EstadoOperacion.rechazada => (
            fondo: c.error,
            texto: c.onError,
            icono: Icons.cancel_outlined,
            titulo: 'Operación rechazada',
            subtitulo: 'No se realizó ningún cargo a tu cuenta',
          ),
        _ => (
            fondo: c.tertiary,
            texto: c.onTertiary,
            icono: Icons.schedule,
            titulo: 'Operación en proceso',
            subtitulo: 'El monto está retenido mientras se confirma con el proveedor',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final r = _resultado(colores);
    final t = ticket;

    return Semantics(
      container: true,
      label: 'Comprobante de la operación',
      child: ClipPath(
        clipper: const _BordeTicket(),
        child: ColoredBox(
          color: colores.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ----- Encabezado con el resultado -----
              ColoredBox(
                color: r.fondo,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(r.icono, size: 56, color: r.texto),
                      const SizedBox(height: AppSpacing.sm),
                      Text(r.titulo, style: tema.textTheme.titleLarge?.copyWith(color: r.texto)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(r.subtitulo,
                          textAlign: TextAlign.center, style: tema.textTheme.bodyMedium?.copyWith(color: r.texto)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _moneda.format(t.monto),
                        style: tema.textTheme.displaySmall?.copyWith(
                          color: r.texto,
                          fontWeight: FontWeight.w600,
                          decoration: t.estado == EstadoOperacion.rechazada ? TextDecoration.lineThrough : null,
                          decorationColor: r.texto,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ----- Producto -----
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: colores.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: ImagenServicio(url: t.imagenUrl, tamano: 48),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.producto ?? 'Operación con GestoPago', style: tema.textTheme.titleMedium),
                              if (t.servicio != null)
                                Text(t.servicio!, style: tema.textTheme.bodySmall?.copyWith(color: colores.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (t.estado == EstadoOperacion.rechazada && t.motivo != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colores.errorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: colores.onErrorContainer),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Motivo del rechazo',
                                      style: tema.textTheme.labelLarge?.copyWith(color: colores.onErrorContainer)),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(t.motivo!, style: TextStyle(color: colores.onErrorContainer)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const _Separador(),
                    _Seccion('Operación', [
                      ('Fecha', _capitalizar(_fecha.format(t.fecha))),
                      ('Hora', _hora.format(t.fecha)),
                      ('Folio de operación', t.folioOperacion),
                      if (t.upc != null) ('Referencia GestoPago', t.upc!),
                      ('Estado', t.estado.etiqueta),
                      if (t.codigoRespuesta != null) ('Código de respuesta', t.codigoRespuesta!),
                      ('Autorización', t.numeroAutorizacion ?? '—'),
                      if (t.folio != null) ('Folio del proveedor', t.folio!),
                      if (t.pin != null) ('PIN', t.pin!),
                    ]),
                    const _Separador(),
                    _Seccion('Pago', [
                      if (t.referencia != null) ('Teléfono o referencia', t.referencia!),
                      if (t.nombreCliente != null) ('Titular', t.nombreCliente!),
                      if (t.numeroCuenta != null) ('Cuenta de cargo', t.numeroCuenta!),
                      ('Importe de la operación', _moneda.format(t.monto)),
                      ('Cargo aplicado', _moneda.format(t.cargoAplicado)),
                      if (t.saldoDisponible != null) ('Saldo disponible', _moneda.format(t.saldoDisponible)),
                    ]),
                    if (t.leyenda != null && t.leyenda!.trim().isNotEmpty) ...[
                      const _Separador(),
                      Text(t.leyenda!.trim(), style: tema.textTheme.bodySmall),
                    ],
                    const _Separador(),
                    ExcludeSemantics(child: SizedBox(height: 44, child: CustomPaint(painter: _CodigoBarras(t.id, colores.onSurface)))),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      t.id.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: tema.textTheme.labelSmall?.copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Conserva este comprobante. Para cualquier aclaración menciona tu folio de operación.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodySmall?.copyWith(color: colores.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: t.folioOperacion));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(content: Text('Folio copiado')));
                          }
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copiar folio'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalizar(String texto) => texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo, this.datos);

  final String titulo;
  final List<(String, String)> datos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titulo.toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: tema.colorScheme.primary)),
        const SizedBox(height: AppSpacing.sm),
        for (final (etiqueta, valor) in datos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(etiqueta, style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant))),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: SelectableText(
                    valor,
                    textAlign: TextAlign.end,
                    style: tema.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Linea punteada entre secciones, como en un ticket impreso.
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: SizedBox(
          height: 1,
          child: CustomPaint(painter: _Punteado(Theme.of(context).colorScheme.outlineVariant)),
        ),
      );
}

class _Punteado extends CustomPainter {
  const _Punteado(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), pincel);
    }
  }

  @override
  bool shouldRepaint(_Punteado anterior) => anterior.color != color;
}

/// Barras decorativas derivadas del folio (cada folio dibuja un patron distinto).
class _CodigoBarras extends CustomPainter {
  const _CodigoBarras(this.semilla, this.color);

  final String semilla;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()..color = color;
    final valores = semilla.codeUnits;
    var x = size.width * 0.1;
    var i = 0;
    while (x < size.width * 0.9) {
      final ancho = 1.0 + (valores[i % valores.length] % 3);
      if (i.isEven) canvas.drawRect(Rect.fromLTWH(x, 0, ancho, size.height), pincel);
      x += ancho + 1.5;
      i++;
    }
  }

  @override
  bool shouldRepaint(_CodigoBarras anterior) => anterior.semilla != semilla || anterior.color != color;
}

/// Borde dentado arriba y abajo, como un ticket recortado.
class _BordeTicket extends CustomClipper<Path> {
  const _BordeTicket();

  @override
  Path getClip(Size size) {
    const diente = 10.0;
    final path = Path()..moveTo(0, diente / 2);
    for (double x = 0; x < size.width; x += diente) {
      path.lineTo(x + diente / 2, 0);
      path.lineTo(x + diente, diente / 2);
    }
    path.lineTo(size.width, size.height - diente / 2);
    for (double x = size.width; x > 0; x -= diente) {
      path.lineTo(x - diente / 2, size.height);
      path.lineTo(x - diente, size.height - diente / 2);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_BordeTicket anterior) => false;
}
