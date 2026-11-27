import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failures.dart';
import '../../../core/result/result.dart';
import '../../clientes/domain/entities/cliente.dart';
import '../domain/compra.dart';

/// Pasos de una compra, como en la banca en linea.
enum PasoCompra {
  /// Cuenta, telefono o referencia y monto.
  captura,

  /// Primera compra: el cliente define su NIP.
  crearNip,

  /// Confirma la operacion con su NIP.
  nip,

  /// Muestra el token dinamico y espera la autorizacion.
  token,

  procesando,

  /// Comprobante de la operacion.
  ticket,
}

class CompraState extends Equatable {
  const CompraState({
    this.paso = PasoCompra.captura,
    this.cuentas = const [],
    this.cargando = true,
    this.ocupado = false,
    this.nipConfigurado = false,
    this.solicitud,
    this.token,
    this.emitidoEn,
    this.ticket,
    this.error,
    this.aviso,
  });

  final PasoCompra paso;
  final List<CuentaResumen> cuentas;
  final bool cargando;
  final bool ocupado;
  final bool nipConfigurado;
  final SolicitudCompra? solicitud;
  final TokenDinamico? token;
  final DateTime? emitidoEn;
  final Ticket? ticket;
  final String? error;
  final String? aviso;

  List<CuentaResumen> get cuentasActivas => [for (final c in cuentas) if (c.activa) c];

  CompraState copyWith({
    PasoCompra? paso,
    List<CuentaResumen>? cuentas,
    bool? cargando,
    bool? ocupado,
    bool? nipConfigurado,
    SolicitudCompra? solicitud,
    TokenDinamico? token,
    DateTime? emitidoEn,
    Ticket? ticket,
    String? error,
    String? aviso,
  }) =>
      CompraState(
        paso: paso ?? this.paso,
        cuentas: cuentas ?? this.cuentas,
        cargando: cargando ?? this.cargando,
        ocupado: ocupado ?? this.ocupado,
        nipConfigurado: nipConfigurado ?? this.nipConfigurado,
        solicitud: solicitud ?? this.solicitud,
        token: token ?? this.token,
        emitidoEn: emitidoEn ?? this.emitidoEn,
        ticket: ticket ?? this.ticket,
        error: error,
        aviso: aviso,
      );

  @override
  List<Object?> get props =>
      [paso, cuentas, cargando, ocupado, nipConfigurado, solicitud, token, emitidoEn, ticket, error, aviso];
}

/// Flujo de compra: captura → (crear NIP) → NIP → token dinamico → ticket.
class CompraCubit extends Cubit<CompraState> {
  CompraCubit({
    required this._repositorio,
    required this._misCuentas,
    DateTime Function()? reloj,
  })  : _reloj = reloj ?? DateTime.now,
        super(const CompraState());

  final ComprasRepository _repositorio;
  final Future<Result<ClienteDetalle>> Function() _misCuentas;
  final DateTime Function() _reloj;
  String? _claveIdempotencia;

  /// Carga las cuentas del cliente (con su saldo) y si ya configuro su NIP.
  Future<void> iniciar() async {
    emit(state.copyWith(cargando: true));
    final (cuentas, nip) = (await _misCuentas(), await _repositorio.nipConfigurado());
    if (isClosed) return;
    switch ((cuentas, nip)) {
      case (Success(data: final detalle), Success(data: final configurado)):
        emit(state.copyWith(cuentas: detalle.cuentas, nipConfigurado: configurado, cargando: false));
      case (ErrorResult(:final failure), _) || (_, ErrorResult(:final failure)):
        emit(state.copyWith(cargando: false, error: failure.message));
    }
  }

  /// Termina la captura: la primera vez pide crear el NIP; despues, confirmarlo.
  void continuar(SolicitudCompra solicitud) {
    _claveIdempotencia = null;
    emit(state.copyWith(solicitud: solicitud, paso: state.nipConfigurado ? PasoCompra.nip : PasoCompra.crearNip));
  }

  Future<void> crearNip(String nip, String confirmacion) async {
    if (state.ocupado) return;
    emit(state.copyWith(ocupado: true));
    final resultado = await _repositorio.crearNip(nip, confirmacion);
    if (isClosed) return;
    resultado.fold(
      (_) => emit(state.copyWith(
        ocupado: false,
        nipConfigurado: true,
        paso: PasoCompra.nip,
        aviso: 'Tu NIP quedó configurado. Ingrésalo para confirmar la operación',
      )),
      (falla) => emit(state.copyWith(ocupado: false, error: falla.message)),
    );
  }

  /// Valida el NIP en el servidor y recibe el token dinamico.
  Future<void> confirmarNip(String nip) async {
    final solicitud = state.solicitud;
    if (state.ocupado || solicitud == null) return;
    emit(state.copyWith(ocupado: true));
    final resultado = await _repositorio.autorizar(solicitud, nip);
    if (isClosed) return;
    resultado.fold(
      (token) => emit(state.copyWith(ocupado: false, token: token, emitidoEn: _reloj(), paso: PasoCompra.token)),
      (falla) => emit(state.copyWith(ocupado: false, error: falla.message)),
    );
  }

  /// El token vencio sin usarse: hay que volver a confirmar con el NIP.
  void tokenExpirado() {
    if (state.paso != PasoCompra.token) return;
    emit(state.copyWith(paso: PasoCompra.nip, error: 'Tu token dinámico expiró. Ingresa tu NIP para generar otro'));
  }

  /// Ejecuta la compra con el token. El resultado (aprobada, pendiente o rechazada) es un ticket.
  Future<void> autorizarPago() async {
    final solicitud = state.solicitud;
    final token = state.token;
    if (state.ocupado || solicitud == null || token == null) return;
    // La misma clave en los reintentos evita cobrar dos veces si se pierde la respuesta
    _claveIdempotencia ??= const Uuid().v4();
    emit(state.copyWith(ocupado: true, paso: PasoCompra.procesando));
    final resultado = await _repositorio.comprar(solicitud, token, claveIdempotencia: _claveIdempotencia!);
    if (isClosed) return;
    switch (resultado) {
      case Success(data: final ticket):
        emit(state.copyWith(ocupado: false, ticket: ticket, paso: PasoCompra.ticket));
      case ErrorResult(failure: GoneFailure(:final message) || ConflictFailure(:final message)):
        // Token vencido, usado o de otra operacion: se confirma de nuevo con el NIP
        _claveIdempotencia = null;
        emit(state.copyWith(ocupado: false, paso: PasoCompra.nip, error: message));
      case ErrorResult(:final failure):
        emit(state.copyWith(ocupado: false, paso: PasoCompra.token, error: failure.message));
    }
  }

  /// Regresa a la captura para corregir datos (descarta el token).
  void corregirDatos() => emit(CompraState(
        cuentas: state.cuentas,
        cargando: false,
        nipConfigurado: state.nipConfigurado,
        solicitud: state.solicitud,
      ));
}
