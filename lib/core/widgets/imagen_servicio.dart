import 'package:material_ui/material_ui.dart';

/// Imagen del servicio. GestoPago no envia cabeceras CORS, por eso en web se dibuja con un
/// elemento <img> del navegador; si el servicio no tiene imagen se muestra un icono.
class ImagenServicio extends StatelessWidget {
  const ImagenServicio({required this.url, this.tamano = 48, super.key});

  final String? url;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final sinImagen = Icon(Icons.storefront_outlined, size: tamano * 0.6, color: colores.onSurfaceVariant);
    if (url == null) return Center(child: sinImagen);
    return Image.network(
      url!,
      fit: BoxFit.contain,
      semanticLabel: 'Logotipo del servicio',
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => Center(child: sinImagen),
      loadingBuilder: (context, hijo, progreso) => progreso == null
          ? hijo
          : const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}
