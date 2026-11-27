import 'package:pagosapp/core/error/failures.dart';
import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/features/compras/domain/compra.dart';
import 'package:pagosapp/features/historial/domain/operacion.dart';

/// Simula al servidor: NIP correcto 2580, token 48213907 y GestoPago fuera de servicio
/// (toda compra se rechaza sin cargo y devuelve su ticket).
class FakeComprasRepository implements ComprasRepository {
  FakeComprasRepository({this.nip});

  String? nip;
  int intentosFallidos = 0;
  final List<SolicitudCompra> autorizadas = [];
  final List<(SolicitudCompra, TokenDinamico, String)> compras = [];
  Failure? fallaCompra;

  @override
  Future<Result<bool>> nipConfigurado() async => Success(nip != null);

  @override
  Future<Result<void>> crearNip(String nip, String confirmacion) async {
    if (this.nip != null) return const ErrorResult(ConflictFailure('Ya tienes un NIP configurado'));
    this.nip = nip;
    return const Success(null);
  }

  @override
  Future<Result<void>> cambiarNip({required String actual, required String nuevo, required String confirmacion}) async {
    if (actual != nip) return const ErrorResult(ValidationFailure('NIP incorrecto. Te quedan 2 intentos'));
    nip = nuevo;
    return const Success(null);
  }

  @override
  Future<Result<TokenDinamico>> autorizar(SolicitudCompra compra, String nip) async {
    if (nip != this.nip) {
      intentosFallidos++;
      return ErrorResult(ValidationFailure('NIP incorrecto. Te quedan ${3 - intentosFallidos} intentos'));
    }
    autorizadas.add(compra);
    return const Success(TokenDinamico(autorizacionId: 'aut-1', token: '48213907', vigencia: Duration(seconds: 60)));
  }

  @override
  Future<Result<Ticket>> comprar(SolicitudCompra compra, TokenDinamico token, {required String claveIdempotencia}) async {
    compras.add((compra, token, claveIdempotencia));
    if (fallaCompra != null) return ErrorResult(fallaCompra!);
    return Success(Ticket(
      id: '9b0f2c1e-aaaa-bbbb-cccc-1234567890ab',
      estado: EstadoOperacion.rechazada,
      fecha: DateTime(2026, 11, 27, 12, 30),
      monto: compra.monto,
      motivo: 'El servicio de GestoPago no está disponible en este momento. No se realizó ningún cargo a tu cuenta',
      codigoRespuesta: 'GP-NODIS',
      producto: r'Telcel $100',
      servicio: 'Telcel',
      referencia: '******5678',
      numeroCuenta: '******0009',
      nombreCliente: 'Jose Balderas',
      saldoDisponible: 500,
      upc: '123456789012345',
    ));
  }
}
