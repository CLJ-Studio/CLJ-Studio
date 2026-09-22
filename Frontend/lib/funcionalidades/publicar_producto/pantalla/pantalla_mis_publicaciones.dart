import 'package:flutter/material.dart';
import '../../../elementos_compartidos/imagenes/foto_producto.dart';
import '../../../elementos_compartidos/tarjetas_aplicacion/estilo_tarjeta_producto.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../mi_local/datos/repositorio_mi_local.dart';

/// Galería de todo lo que el estudiante tiene publicado en su local.
class PantallaMisPublicaciones extends StatefulWidget {
  const PantallaMisPublicaciones({super.key});

  @override
  State<PantallaMisPublicaciones> createState() =>
      _PantallaMisPublicacionesState();
}

class _PantallaMisPublicacionesState extends State<PantallaMisPublicaciones> {
  static const _repositorio = RepositorioMiLocal();

  late Future<List<ProductoMarketplace>> _publicaciones = _cargar();

  /// Todo lo publicado, tanto lo suelto como lo del negocio: son espacios
  /// distintos en la base, pero para quien publica es una sola lista.
  Future<List<ProductoMarketplace>> _cargar() =>
      _repositorio.cargarMisPublicaciones();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Mis publicaciones',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: FutureBuilder<List<ProductoMarketplace>>(
      future: _publicaciones,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MensajeCatalogo(
            mensaje: 'No se pudieron cargar tus publicaciones.',
            alReintentar: () => setState(() => _publicaciones = _cargar()),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: IndicadorCarga());
        }

        final publicaciones = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 50),
          child: ContenidoCentrado(
            anchoMaximo: 720,
            child: publicaciones.isEmpty
                ? const _EstadoVacio()
                : Column(
                    children: [
                      _Resumen(cantidad: publicaciones.length),
                      const SizedBox(height: 18),
                      for (final publicacion in publicaciones)
                        _TarjetaPublicacion(publicacion: publicacion),
                    ],
                  ),
          ),
        );
      },
    ),
  );
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.cantidad});
  final int cantidad;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 29,
          child: Icon(Icons.person_rounded, color: Color(0xFF474646)),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu perfil de ventas',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              Text(
                'Todo lo que compartiste.',
                style: TextStyle(color: Color(0xFF848381)),
              ),
            ],
          ),
        ),
        Text(
          '$cantidad',
          style: const TextStyle(
            color: Color(0xFF474646),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _TarjetaPublicacion extends StatelessWidget {
  const _TarjetaPublicacion({required this.publicacion});

  final ProductoMarketplace publicacion;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: EstiloTarjetaProducto.borde,
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .12),
            child: Text(
              publicacion.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            publicacion.nombre,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            publicacion.esServicio
                ? 'Servicio'
                : 'Producto · ${publicacion.stock} en stock',
          ),
          // Aqui conviven las dos clases de publicacion, asi que sin marcarlas
          // no hay forma de saber cual es cual ni por que una sale en el
          // catalogo del local y la otra no.
          trailing: _Origen(local: publicacion.local),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            borderRadius: EstiloTarjetaProducto.borde,
          ),
          // Antes 190 px de alto: la misma foto salia mas apaisada aqui que
          // en el catalogo, y al vendedor le costaba reconocer lo suyo.
          child: FotoProducto(
            url: publicacion.imagenUrl,
            // La tarjeta ocupa el ancho, con un tope de 720.
            anchoVisible: 720,
            alFallar: Center(
              child: Text(
                publicacion.emoji,
                style: const TextStyle(fontSize: 76),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bs ${publicacion.precio.toStringAsFixed(2)}',
                style: EstiloTarjetaProducto.precio(context),
              ),
              if (publicacion.descripcion.isNotEmpty) ...[
                const SizedBox(height: 7),
                // El color venia fijo en grafito, que en tema oscuro es el
                // mismo del fondo: el texto estaba ahi y no se leia.
                Text(
                  publicacion.descripcion,
                  style: EstiloTarjetaProducto.apoyo(context),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// De donde sale la publicacion: del local o del espacio personal.
class _Origen extends StatelessWidget {
  const _Origen({required this.local});

  final LocalUniversitario? local;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Sin local resuelto no se afirma nada: mejor no marcarla que marcarla mal.
    if (local == null) return const SizedBox.shrink();

    final delLocal = !local!.esPersonal;
    final color = delLocal
        ? tema.colorScheme.primary
        : tema.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            delLocal ? Icons.storefront_rounded : Icons.person_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            delLocal ? 'Tu local' : 'Personal',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 90),
    child: Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: .12),
            child: const Icon(
              Icons.grid_on_rounded,
              size: 46,
              color: Color(0xFF848381),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aún no publicaste nada',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tus productos y servicios aparecerán aquí.',
            style: TextStyle(color: Color(0xFF848381)),
          ),
        ],
      ),
    ),
  );
}
