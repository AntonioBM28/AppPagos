import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/desafio_verificacion.dart';
import '../../domain/usecases/auth_usecases.dart';

class VerificacionState extends Equatable {
  const VerificacionState({
    required this.desafio,
    required this.segundosParaReenviar,
    required this.segundosParaExpirar,
    this.verificando = false,
    this.reenviando = false,
    this.error,
    this.aviso,
    this.debeReiniciar = false,
  });

  final DesafioVerificacion desafio;
  final int segundosParaReenviar;
  final int segundosParaExpirar;
  final bool verificando;
  final bool reenviando;
  final String? error;

  /// Mensaje informativo (por ejemplo, "Te enviamos un codigo nuevo").
  final String? aviso;

  /// El desafio ya no sirve (sin intentos o expirado): hay que volver al login.
  final bool debeReiniciar;

  bool get puedeReenviar => segundosParaReenviar == 0 && !reenviando && !debeReiniciar;
  bool get expirado => segundosParaExpirar == 0;
  bool get ocupado => verificando || reenviando;

  VerificacionState copyWith({
    DesafioVerificacion? desafio,
    int? segundosParaReenviar,
    int? segundosParaExpirar,
    bool? verificando,
    bool? reenviando,
    String? error,
    String? aviso,
    bool? debeReiniciar,
  }) =>
      VerificacionState(
        desafio: desafio ?? this.desafio,
        segundosParaReenviar: segundosParaReenviar ?? this.segundosParaReenviar,
        segundosParaExpirar: segundosParaExpirar ?? this.segundosParaExpirar,
        verificando: verificando ?? this.verificando,
        reenviando: reenviando ?? this.reenviando,
        error: error,
        aviso: aviso,
        debeReiniciar: debeReiniciar ?? this.debeReiniciar,
      );

  @override
  List<Object?> get props => [
        desafio,
        segundosParaReenviar,
        segundosParaExpirar,
        verificando,
        reenviando,
        error,
        aviso,
        debeReiniciar,
      ];
}

/// Segundo paso del login. El codigo se valida en el servidor; al tener exito, el
/// SessionManager abre la sesion y el router lleva al inicio.
class VerificacionCubit extends Cubit<VerificacionState> {
  VerificacionCubit({
    required DesafioVerificacion desafio,
    required this._verificarCodigo,
    required this._reenviarCodigo,
    Duration tick = const Duration(seconds: 1),
  }) : super(
          VerificacionState(
            desafio: desafio,
            segundosParaReenviar: desafio.reenviarEn.inSeconds,
            segundosParaExpirar: desafio.expiraEn.inSeconds,
          ),
        ) {
    _reloj = Timer.periodic(tick, (_) => _avanzar());
  }

  final VerificarCodigo _verificarCodigo;
  final ReenviarCodigo _reenviarCodigo;
  late final Timer _reloj;

  Future<void> verificar(String codigo) async {
    if (state.ocupado || state.debeReiniciar) return;
    emit(state.copyWith(verificando: true));

    final resultado = await _verificarCodigo(desafioId: state.desafio.id, codigo: codigo);
    if (isClosed) return;
    resultado.fold(
      (_) => emit(state.copyWith(verificando: false)),
      (falla) => emit(
        state.copyWith(
          verificando: false,
          error: falla.message,
          // Sin intentos (429) o desafio que ya no sirve (410): solo queda iniciar sesion de nuevo
          debeReiniciar: falla is TooManyRequestsFailure || falla is GoneFailure,
        ),
      ),
    );
  }

  Future<void> reenviar() async {
    if (!state.puedeReenviar || state.verificando) return;
    emit(state.copyWith(reenviando: true));

    final resultado = await _reenviarCodigo(state.desafio.id);
    if (isClosed) return;
    resultado.fold(
      (desafio) => emit(
        state.copyWith(
          desafio: desafio,
          reenviando: false,
          segundosParaReenviar: desafio.reenviarEn.inSeconds,
          segundosParaExpirar: desafio.expiraEn.inSeconds,
          aviso: 'Te enviamos un código nuevo a ${desafio.correoEnmascarado}',
        ),
      ),
      (falla) => emit(
        state.copyWith(
          reenviando: false,
          error: falla.message,
          segundosParaReenviar: falla is TooManyRequestsFailure ? falla.retryAfterSeconds : null,
          // 429 sin Retry-After: se agotaron los reenvios
          debeReiniciar: falla is GoneFailure ||
              (falla is TooManyRequestsFailure && falla.retryAfterSeconds == null),
        ),
      ),
    );
  }

  void _avanzar() {
    if (state.segundosParaReenviar == 0 && state.segundosParaExpirar == 0) return;
    emit(
      state.copyWith(
        segundosParaReenviar: _restar(state.segundosParaReenviar),
        segundosParaExpirar: _restar(state.segundosParaExpirar),
        error: state.error,
        aviso: state.aviso,
      ),
    );
  }

  static int _restar(int segundos) => segundos > 0 ? segundos - 1 : 0;

  @override
  Future<void> close() {
    _reloj.cancel();
    return super.close();
  }
}

/// Cierre de sesion desde el perfil.
class CerrarSesionCubit extends Cubit<bool> {
  CerrarSesionCubit(this._cerrarSesion) : super(false);

  final CerrarSesion _cerrarSesion;

  /// El estado es "cerrando". Al terminar, el router lleva al login.
  Future<void> cerrar() async {
    if (state) return;
    emit(true);
    await _cerrarSesion();
    if (!isClosed) emit(false);
  }
}
