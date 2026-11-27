import 'package:equatable/equatable.dart';

import '../../../core/result/result.dart';
import '../../historial/domain/operacion.dart';

/// Datos de una compra. El token dinamico queda ligado a estos datos: si cambian, hay que
/// volver a confirmar con el NIP.
class SolicitudCompra extends Equatable {
  const SolicitudCompra({
    required this.numeroCuenta,
    required this.idServicio,
    required this.idProducto,
    required this.monto,
    this.destino,
    this.referencia,
  });

  final String numeroCuenta;
  final int idServicio;
  final int idProducto;
  final double monto;
  final String? destino;
  final String? referencia;

  @override
  List<Object?> get props => [numeroCuenta, idServicio, idProducto, monto, destino, referencia];
}

/// Token dinamico de un solo uso que autoriza una compra concreta.
class TokenDinamico extends Equatable {
  const TokenDinamico({required this.autorizacionId, required this.token, required this.vigencia});

  final String autorizacionId;
  /// Uso interno: nunca se muestra en pantalla.
  final String token;
  final Duration vigencia;

  @override
  List<Object?> get props => [autorizacionId, token, vigencia];
}

/// Comprobante de una operacion (aprobada, pendiente o rechazada).
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.estado,
    required this.fecha,
    required this.monto,
    this.mensaje,
    this.motivo,
    this.codigoRespuesta,
    this.producto,
    this.servicio,
    this.imagenUrl,
    this.referencia,
    this.numeroCuenta,
    this.nombreCliente,
    this.saldoDisponible,
    this.numeroAutorizacion,
    this.folio,
    this.pin,
    this.leyenda,
    this.upc,
  });

  final String id;
  final EstadoOperacion estado;
  final DateTime fecha;
  final double monto;
  final String? mensaje;
  final String? motivo;
  final String? codigoRespuesta;
  final String? producto;
  final String? servicio;
  final String? imagenUrl;
  final String? referencia;
  final String? numeroCuenta;
  final String? nombreCliente;
  final double? saldoDisponible;
  final String? numeroAutorizacion;
  final String? folio;
  final String? pin;
  final String? leyenda;
  final String? upc;

  /// Folio corto para mostrar y dictar (primeros 8 caracteres del id).
  String get folioOperacion {
    final limpio = id.replaceAll('-', '').toUpperCase();
    return limpio.length <= 8 ? limpio : limpio.substring(0, 8);
  }

  /// En una operacion rechazada no se cobra; en una pendiente el monto queda retenido.
  double get cargoAplicado => estado == EstadoOperacion.rechazada ? 0 : monto;

  /// Ticket a partir de una operacion del historial.
  factory Ticket.deOperacion(Operacion o) => Ticket(
        id: o.id,
        estado: o.estado,
        fecha: o.fecha,
        monto: o.monto,
        mensaje: o.detalle,
        motivo: o.motivo,
        codigoRespuesta: o.codigoProveedor,
        producto: o.producto,
        servicio: o.servicio,
        imagenUrl: o.imagenUrl,
        referencia: o.referencia,
        numeroCuenta: o.numeroCuenta == null ? null : enmascararCuenta(o.numeroCuenta!),
        nombreCliente: o.nombreCliente,
        numeroAutorizacion: o.numeroAutorizacion,
        folio: o.folio,
        upc: o.upc,
      );

  static String enmascararCuenta(String cuenta) =>
      cuenta.length <= 4 ? cuenta : '${'*' * (cuenta.length - 4)}${cuenta.substring(cuenta.length - 4)}';

  @override
  List<Object?> get props => [id, estado, fecha, monto, motivo, numeroAutorizacion];
}

abstract interface class ComprasRepository {
  /// true si el cliente ya configuro su NIP de transacciones.
  Future<Result<bool>> nipConfigurado();

  Future<Result<void>> crearNip(String nip, String confirmacion);

  Future<Result<void>> cambiarNip({required String actual, required String nuevo, required String confirmacion});

  /// Paso 1: valida la compra y el NIP; devuelve el token dinamico.
  Future<Result<TokenDinamico>> autorizar(SolicitudCompra compra, String nip);

  /// Paso 2: ejecuta la compra con el token. Una operacion rechazada tambien es un resultado
  /// (con su ticket), no un error.
  Future<Result<Ticket>> comprar(SolicitudCompra compra, TokenDinamico token, {required String claveIdempotencia});
}
