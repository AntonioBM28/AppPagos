import 'package:equatable/equatable.dart';

import '../../../core/result/result.dart';

enum EstadoOperacion {
  aprobada('APROBADA', 'Aprobada'),
  pendiente('PENDIENTE', 'Pendiente'),
  conciliacion('CONCILIACION', 'Por confirmar'),
  rechazada('RECHAZADA', 'Rechazada');

  const EstadoOperacion(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;

  static EstadoOperacion deCodigo(String? codigo) =>
      EstadoOperacion.values.where((e) => e.codigo == codigo).firstOrNull ?? EstadoOperacion.pendiente;

  /// Estados que se ofrecen en el filtro (PENDIENTE y CONCILIACION se muestran juntos como "Por confirmar").
  static const filtrables = [aprobada, conciliacion, rechazada];
}

/// Compra o pago de servicio realizado por un cliente.
class Operacion extends Equatable {
  const Operacion({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.monto,
    this.producto,
    this.servicio,
    this.imagenUrl,
    this.referencia,
    this.numeroCuenta,
    this.numeroAutorizacion,
    this.folio,
    this.detalle,
    this.motivo,
    this.codigoProveedor,
    this.upc,
    this.clienteId,
    this.nombreCliente,
  });

  final String id;
  final DateTime fecha;
  final EstadoOperacion estado;
  final double monto;
  final String? producto;
  final String? servicio;
  final String? imagenUrl;
  final String? referencia;
  final String? numeroCuenta;
  final String? numeroAutorizacion;
  final String? folio;
  final String? detalle;

  /// Por que se rechazo (solo en operaciones rechazadas).
  final String? motivo;
  final String? codigoProveedor;
  final String? upc;
  final int? clienteId;

  /// Solo viene en la consulta del ejecutivo.
  final String? nombreCliente;

  /// Las operaciones anteriores al registro del producto no tienen nombre.
  String get titulo => producto ?? 'Operación con GestoPago';

  @override
  List<Object?> get props => [id, fecha, estado, monto, producto, servicio, referencia, numeroAutorizacion, folio];
}

class FiltroOperaciones extends Equatable {
  const FiltroOperaciones({
    this.nombreCliente,
    this.texto,
    this.estado,
    this.fechaDesde,
    this.fechaHasta,
    this.pagina = 0,
    this.tamanio = 20,
  });

  final String? nombreCliente;
  final String? texto;
  final EstadoOperacion? estado;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final int pagina;
  final int tamanio;

  bool get tieneCriterios =>
      _conValor(nombreCliente) || _conValor(texto) || estado != null || fechaDesde != null || fechaHasta != null;

  static bool _conValor(String? v) => v != null && v.trim().isNotEmpty;

  FiltroOperaciones enPagina(int pagina) => FiltroOperaciones(
        nombreCliente: nombreCliente,
        texto: texto,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        pagina: pagina,
        tamanio: tamanio,
      );

  @override
  List<Object?> get props => [nombreCliente, texto, estado, fechaDesde, fechaHasta, pagina, tamanio];
}

class PaginaOperaciones extends Equatable {
  const PaginaOperaciones({
    required this.operaciones,
    required this.pagina,
    required this.totalPaginas,
    required this.totalElementos,
  });

  final List<Operacion> operaciones;
  final int pagina;
  final int totalPaginas;
  final int totalElementos;

  bool get hayMas => pagina + 1 < totalPaginas;

  @override
  List<Object?> get props => [operaciones, pagina, totalPaginas, totalElementos];
}

/// Historial de operaciones: el ejecutivo ve las de todos los clientes y el cliente solo las suyas
/// (lo decide el servidor con la sesion).
abstract interface class HistorialRepository {
  Future<Result<PaginaOperaciones>> consultar(FiltroOperaciones filtro);
}

class ConsultarHistorial {
  const ConsultarHistorial(this._repositorio);
  final HistorialRepository _repositorio;

  Future<Result<PaginaOperaciones>> call(FiltroOperaciones filtro) => _repositorio.consultar(filtro);
}
