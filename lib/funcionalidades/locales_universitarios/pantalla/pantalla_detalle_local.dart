import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../diseno/encabezado_detalle_local.dart';
import '../diseno/lista_productos_local.dart';

/// Detalle navegable de un local con productos de prueba.
class PantallaDetalleLocal extends StatelessWidget {
  const PantallaDetalleLocal({
    required this.local,
    required this.productos,
    super.key,
  });
  final LocalUniversitario local;
  final List<ProductoMarketplace> productos;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(local.nombre)),
    body: SingleChildScrollView(
      child: ContenidoCentrado(
        anchoMaximo: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EncabezadoDetalleLocal(local: local),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos disponibles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${productos.length} ${productos.length == 1 ? 'producto' : 'productos'} para elegir',
                    style: const TextStyle(color: Color(0xFF858585)),
                  ),
                  const SizedBox(height: 12),
                  if (productos.isEmpty)
                    const Text('Este local publicará su catálogo próximamente.')
                  else
                    ListaProductosLocal(productos: productos),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
