import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/credenciales.dart';
import '../../domain/entities/desafio_verificacion.dart';
import '../../domain/usecases/auth_usecases.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

final class LoginInicial extends LoginState {
  const LoginInicial();
}

final class LoginEnviando extends LoginState {
  const LoginEnviando();
}

/// La contrasena fue correcta y se envio el codigo: hay que ir a la verificacion.
final class LoginCodigoEnviado extends LoginState {
  const LoginCodigoEnviado(this.desafio);

  final DesafioVerificacion desafio;

  @override
  List<Object?> get props => [desafio];
}

/// Hay una sesion abierta en otro dispositivo: hay que preguntar si se cierra.
final class LoginSesionActiva extends LoginState {
  const LoginSesionActiva(this.sesion);

  final SesionActivaFailure sesion;

  @override
  List<Object?> get props => [sesion];
}

final class LoginError extends LoginState {
  const LoginError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}

/// Primer paso del login. Las credenciales solo se conservan en memoria mientras el
/// usuario decide si cierra la sesion del otro dispositivo.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._iniciarSesion) : super(const LoginInicial());

  final IniciarSesion _iniciarSesion;
  Credenciales? _pendientes;

  Future<void> enviar({required String correo, required String password}) =>
      _enviar(Credenciales(correo: correo, password: password));

  /// El usuario acepto cerrar la sesion del otro dispositivo.
  Future<void> cerrarSesionAnteriorYContinuar() async {
    final pendientes = _pendientes;
    if (pendientes == null) return;
    await _enviar(pendientes.cerrandoSesionAnterior());
  }

  void cancelarSesionActiva() {
    _pendientes = null;
    emit(const LoginInicial());
  }

  /// Despues de navegar a la verificacion, el formulario vuelve a su estado inicial.
  void reiniciar() => emit(const LoginInicial());

  Future<void> _enviar(Credenciales credenciales) async {
    // Control de operaciones simultaneas: un segundo envio se ignora
    if (state is LoginEnviando) return;
    emit(const LoginEnviando());

    final resultado = await _iniciarSesion(credenciales);
    if (isClosed) return;
    resultado.fold(
      (desafio) {
        _pendientes = null;
        emit(LoginCodigoEnviado(desafio));
      },
      (falla) {
        if (falla is SesionActivaFailure) {
          _pendientes = credenciales;
          emit(LoginSesionActiva(falla));
        } else {
          _pendientes = null;
          emit(LoginError(falla.message));
        }
      },
    );
  }
}
