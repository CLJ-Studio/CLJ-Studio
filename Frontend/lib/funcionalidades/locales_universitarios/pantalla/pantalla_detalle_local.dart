import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../carrito_compras/diseno/barra_resumen_carrito.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../visualizaciones/indicador_vistas.dart';
import '../../visualizaciones/servicio_visualizaciones.dart';
import '../diseno/encabezado_detalle_local.dart';
import '../diseno/lista_productos_local.dart';

/// Detalle navegable de un local con su catalogo real.
class PantallaDetalleLocal extends StatefulWidget {
  const PantallaDetalleLocal({required this.local, super.key});

  final LocalUniversitario local;

  @override
  State<PantallaDetalleLocal> createState() => _PantallaDetalleLocalState();
}

class _PantallaDetalleLocalState extends State<PantallaDetalleLocal> {
  late int _vistas = widget.local.vistas;
  // La pantalla carga su propio catalogo: evita traer los productos de todos
  // los locales por adelantado solo porque uno pueda abrirse.
  late final Future<List<ProductoMarketplace>> _productos =
      const RepositorioInicioMarketplace().obtenerProductos(widget.local.id);

  @override
  void initState() {
    super.initState();
    ServicioVisualizaciones.registrarLocal(widget.local.id).then((total) {
      if (mounted && total > 0) setState(() => _vistas = total);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.local.nombre)),
    bottomNavigationBar: BarraResumenCarrito(localId: widget.local.id),
    body: SingleChildScrollView(
      child: ContenidoCentrado(
        anchoMaximo: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                EncabezadoDetalleLocal(local: widget.local),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IndicadorVistas(total: _vistas),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: FutureBuilder<List<ProductoMarketplace>>(
                future: _productos,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _MensajeSimple(
                      'No se pudo cargar el catálogo de este local.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: IndicadorCarga()),
                    );
                  }

                  final productos = snapshot.data!;
                  return Column(
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
                        const _MensajeSimple(
                          'Este local publicará su catálogo próximamente.',
                        )
                      else
                        ListaProductosLocal(
                          productos: productos,
                          local: widget.local,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MensajeSimple extends StatelessWidget {
  const _MensajeSimple(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(texto, style: const TextStyle(color: Color(0xFF858585))),
  );
}
