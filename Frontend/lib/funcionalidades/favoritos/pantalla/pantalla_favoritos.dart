import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../locales_universitarios/diseno/lista_productos_local.dart';
import '../logica/controlador_favoritos.dart';

/// Reúne todos los productos marcados con corazón.
class PantallaFavoritos extends StatelessWidget {
  const PantallaFavoritos({super.key});

  @override
  Widget build(BuildContext context) {
    final controlador = ControladorFavoritos.instancia;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Favoritos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: controlador,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          child: ContenidoCentrado(
            anchoMaximo: 900,
            child: controlador.productos.isEmpty
                ? const _FavoritosVacios()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${controlador.cantidad} ${controlador.cantidad == 1 ? 'producto guardado' : 'productos guardados'}',
                        style: const TextStyle(
                          color: Color(0xFF7B817D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListaProductosLocal(productos: controlador.productos),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FavoritosVacios extends StatelessWidget {
  const _FavoritosVacios();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 90),
    child: Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Todavía no tienes favoritos',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa el corazón de un producto para guardarlo aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7B817D)),
          ),
        ],
      ),
    ),
  );
}
