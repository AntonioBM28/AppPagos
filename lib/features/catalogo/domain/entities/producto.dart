import 'package:equatable/equatable.dart';

/// Producto o servicio del catalogo de GestoPago (solo lectura).
class Producto extends Equatable {
  const Producto({
    required this.idProducto,
    required this.idServicio,
    required this.nombre,
    required this.servicio,
    required this.precio,
    this.idCatTipoServicio,
    this.tipoFront,
    this.tipoReferencia,
    this.leyenda,
    this.imagenUrl,
  });

  final int idProducto;
  final int idServicio;
  final int? idCatTipoServicio;

  /// 1: precio fijo con telefono o destino (recargas); 2: pago con monto y referencia (servicios).
  final int? tipoFront;
  final String nombre;
  final String servicio;
  final double precio;
  final String? tipoReferencia;
  final String? leyenda;

  /// Imagen del servicio publicada por GestoPago; algunos servicios no tienen imagen.
  final String? imagenUrl;

  /// En GestoPago, precio 0 indica que el monto lo captura el cliente (por ejemplo, pago de un recibo).
  bool get montoVariable => precio <= 0;

  @override
  List<Object?> get props =>
      [idProducto, idServicio, idCatTipoServicio, nombre, servicio, precio, tipoReferencia, leyenda, imagenUrl];
}

/// Servicio (proveedor) disponible en el catalogo, para el filtro por servicio.
class ServicioCatalogo extends Equatable {
  const ServicioCatalogo({required this.idServicio, required this.servicio, this.imagenUrl});

  final int idServicio;
  final String servicio;
  final String? imagenUrl;

  @override
  List<Object?> get props => [idServicio, servicio, imagenUrl];
}

enum OrdenProducto {
  nombre('NOMBRE', 'Nombre'),
  precioMenor('PRECIO_MENOR', 'Precio: menor a mayor'),
  precioMayor('PRECIO_MAYOR', 'Precio: mayor a menor');

  const OrdenProducto(this.codigo, this.etiqueta);

  final String codigo;
  final String etiqueta;
}

/// Filtros combinables de la consulta del catalogo.
class FiltroProductos extends Equatable {
  const FiltroProductos({
    this.texto,
    this.idServicio,
    this.idCatTipoServicio,
    this.precioMin,
    this.precioMax,
    this.orden = OrdenProducto.nombre,
    this.pagina = 0,
    this.tamanio = 20,
  });

  final String? texto;
  final int? idServicio;
  final int? idCatTipoServicio;
  final double? precioMin;
  final double? precioMax;
  final OrdenProducto orden;
  final int pagina;
  final int tamanio;

  bool get tieneCriterios =>
      (texto != null && texto!.trim().isNotEmpty) ||
      idServicio != null ||
      idCatTipoServicio != null ||
      precioMin != null ||
      precioMax != null;

  /// Cuantos filtros (sin contar el texto ni el orden) estan aplicados.
  int get filtrosActivos =>
      [idServicio, idCatTipoServicio, precioMin, precioMax].where((f) => f != null).length;

  FiltroProductos enPagina(int pagina) => FiltroProductos(
        texto: texto,
        idServicio: idServicio,
        idCatTipoServicio: idCatTipoServicio,
        precioMin: precioMin,
        precioMax: precioMax,
        orden: orden,
        pagina: pagina,
        tamanio: tamanio,
      );

  FiltroProductos conTexto(String? texto) => FiltroProductos(
        texto: texto,
        idServicio: idServicio,
        idCatTipoServicio: idCatTipoServicio,
        precioMin: precioMin,
        precioMax: precioMax,
        orden: orden,
        tamanio: tamanio,
      );

  @override
  List<Object?> get props => [texto, idServicio, idCatTipoServicio, precioMin, precioMax, orden, pagina, tamanio];
}

class PaginaProductos extends Equatable {
  const PaginaProductos({
    required this.productos,
    required this.pagina,
    required this.totalPaginas,
    required this.totalElementos,
    this.servicios = const [],
    this.tiposServicio = const [],
  });

  final List<Producto> productos;
  final int pagina;
  final int totalPaginas;
  final int totalElementos;

  /// Opciones para los filtros (todo el catalogo, no solo esta pagina).
  final List<ServicioCatalogo> servicios;
  final List<int> tiposServicio;

  bool get hayMas => pagina + 1 < totalPaginas;

  @override
  List<Object?> get props => [productos, pagina, totalPaginas, totalElementos, servicios, tiposServicio];
}

/// Que pide la compra de un producto (las mismas reglas que valida el servidor).
extension ReglasCompra on Producto {
  /// La app solo maneja los flujos 1 (precio fijo) y 2 (pago de servicio con monto).
  bool get sePuedeComprar => tipoFront == 1 || tipoFront == 2;

  bool get precioFijo => tipoFront == 1;

  /// Recargas: el destino es un telefono de 10 digitos.
  bool get destinoEsTelefono => tipoFront == 1 && (tipoReferencia ?? '').toLowerCase() == 'a';

  bool get pideDestino => tipoFront == 1;

  /// Pagos de servicio con referencia obligatoria (numero de contrato, recibo...).
  bool get pideReferencia {
    final tipo = (tipoReferencia ?? '').toLowerCase();
    return tipoFront == 2 && (tipo.contains('b') || tipo.contains('c'));
  }
}
