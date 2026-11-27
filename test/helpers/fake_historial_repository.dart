import 'package:pagosapp/core/result/result.dart';
import 'package:pagosapp/features/historial/domain/operacion.dart';

final operacionesDePrueba = [
  Operacion(
    id: 'op-1',
    fecha: DateTime(2026, 11, 20, 10, 30),
    estado: EstadoOperacion.aprobada,
    monto: 100,
    producto: r'Telcel $100',
    servicio: 'Telcel',
    imagenUrl: 'https://img.test/79.png',
    referencia: '******5678',
    numeroCuenta: '1000000009',
    numeroAutorizacion: 'AUT-123',
    detalle: 'Operacion aprobada',
    clienteId: 7,
    nombreCliente: 'Jose Balderas Martinez',
  ),
  Operacion(
    id: 'op-2',
    fecha: DateTime(2026, 11, 21, 18, 5),
    estado: EstadoOperacion.rechazada,
    monto: 350.5,
    producto: 'Agua Cancun',
    servicio: 'AGUAKAN (Cancun)',
    detalle: 'Operacion rechazada; el saldo fue devuelto',
    clienteId: 8,
    nombreCliente: 'Maria Lopez Garcia',
  ),
];

/// Historial en memoria. Con [comoCliente] simula al servidor: solo devuelve las del cliente 7
/// y sin nombre de cliente.
class FakeHistorialRepository implements HistorialRepository {
  FakeHistorialRepository({this.comoCliente = false});

  bool comoCliente;
  final List<FiltroOperaciones> filtros = [];

  @override
  Future<Result<PaginaOperaciones>> consultar(FiltroOperaciones filtro) async {
    filtros.add(filtro);
    final nombre = filtro.nombreCliente?.toLowerCase();
    final lista = operacionesDePrueba
        .where((o) => !comoCliente || o.clienteId == 7)
        .where((o) => filtro.estado == null || o.estado == filtro.estado)
        .where((o) => nombre == null || nombre.isEmpty || (o.nombreCliente ?? '').toLowerCase().contains(nombre))
        .map((o) => comoCliente
            ? Operacion(
                id: o.id,
                fecha: o.fecha,
                estado: o.estado,
                monto: o.monto,
                producto: o.producto,
                servicio: o.servicio,
                imagenUrl: o.imagenUrl,
                referencia: o.referencia,
                numeroCuenta: o.numeroCuenta,
                numeroAutorizacion: o.numeroAutorizacion,
                detalle: o.detalle,
                clienteId: o.clienteId,
              )
            : o)
        .toList();
    return Success(PaginaOperaciones(operaciones: lista, pagina: 0, totalPaginas: 1, totalElementos: lista.length));
  }
}
