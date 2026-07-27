import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_catalogo.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
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

  /// Sin local no hay publicaciones: todo producto pertenece a uno.
  Future<List<ProductoMarketplace>> _cargar() async {
    final local = await _repositorio.cargarLocal();
    if (local == null) return const [];
    return _repositorio.cargarInventario(local.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFBFA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAFBFA),
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
          return const Center(child: CircularProgressIndicator());
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
      color: const Color(0xFFE8F2E9),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 29,
          backgroundColor: Colors.white,
          child: Icon(Icons.person_rounded, color: Color(0xFF5C8A63)),
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
                style: TextStyle(color: Color(0xFF6F7771)),
              ),
            ],
          ),
        ),
        Text(
          '$cantidad',
          style: const TextStyle(
            color: Color(0xFF5C8A63),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8EBE8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE7F2E8),
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
        ),
        Container(
          height: 190,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: switch (publicacion.imagenUrl) {
            final String url => Image.network(
              url,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  publicacion.emoji,
                  style: const TextStyle(fontSize: 76),
                ),
              ),
            ),
            _ => Center(
              child: Text(
                publicacion.emoji,
                style: const TextStyle(fontSize: 76),
              ),
            ),
          },
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bs ${publicacion.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF4F7956),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (publicacion.descripcion.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  publicacion.descripcion,
                  style: const TextStyle(
                    color: Color(0xFF555B57),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 90),
    child: Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFFE8F2E9),
            child: Icon(
              Icons.grid_on_rounded,
              size: 46,
              color: Color(0xFF6F9A76),
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
            style: TextStyle(color: Color(0xFF7B817D)),
          ),
        ],
      ),
    ),
  );
}
