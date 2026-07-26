import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../logica/controlador_mis_publicaciones.dart';
import '../modelos/publicacion_usuario.dart';

/// Feed personal con todo lo publicado por el estudiante.
class PantallaMisPublicaciones extends StatelessWidget {
  const PantallaMisPublicaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ControladorMisPublicaciones.instancia;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFBFA),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mis publicaciones',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: controlador,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 50),
          child: ContenidoCentrado(
            anchoMaximo: 720,
            child: controlador.publicaciones.isEmpty
                ? const _EstadoVacio()
                : Column(
                    children: [
                      _Resumen(cantidad: controlador.cantidad),
                      const SizedBox(height: 18),
                      for (final publicacion in controlador.publicaciones)
                        _TarjetaPublicacion(
                          publicacion: publicacion,
                          alEliminar: () =>
                              controlador.eliminar(publicacion.id),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
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
  const _TarjetaPublicacion({
    required this.publicacion,
    required this.alEliminar,
  });

  final PublicacionUsuario publicacion;
  final VoidCallback alEliminar;

  IconData get icono => publicacion.tipo == 'Servicio'
      ? Icons.handyman_rounded
      : Icons.inventory_2_rounded;

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
            child: Icon(icono, color: const Color(0xFF5C8A63)),
          ),
          title: Text(
            publicacion.nombre,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text('${publicacion.tipo} · ${publicacion.categoria}'),
          trailing: IconButton(
            tooltip: 'Eliminar publicación',
            onPressed: alEliminar,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
        Container(
          height: 190,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icono, size: 76, color: const Color(0xFF7FA185)),
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
              const SizedBox(height: 7),
              Text(
                publicacion.descripcion,
                style: const TextStyle(color: Color(0xFF555B57), height: 1.4),
              ),
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
