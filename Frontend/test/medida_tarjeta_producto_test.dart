import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/local_universitario.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/visualizaciones/indicador_vistas.dart';

/// TEMPORAL: mide cuanto ocupa de verdad el bloque de texto de la tarjeta a
/// distintas escalas de letra, para dejar de estimarlo a ojo.
const _local = LocalUniversitario(
  id: 'local-1',
  nombre: 'Doña Empanada',
  categoriaId: 'comida',
  categoria: 'Comida',
  descripcion: '',
  calificacion: 0,
  tiempoEstimado: '10 min',
  estaAbierto: true,
  costoEntrega: 0,
  emoji: '🥟',
  colorHexadecimal: 0xFFFFFFFF,
);

void main() {
  for (final escala in [1.0, 1.25, 1.5, 2.0]) {
    testWidgets('medida a escala $escala', (tester) async {
      const producto = ProductoMarketplace(
        id: 'p',
        localId: 'local-1',
        nombre: 'Empanada de carne cortada a cuchillo con papa',
        descripcion: 'Una descripción bastante larga que se recorta sola',
        precio: 12.5,
        emoji: '🥟',
        stock: 5,
        local: _local,
      );

      // El mismo bloque de texto de la tarjeta, sin altura impuesta.
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 154,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 11, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          producto.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.storefront_rounded, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _local.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Bs 12.50',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IndicadorVistas(
                              total: producto.vistas,
                              compacto: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final alto = tester.getSize(find.byType(Padding).at(0)).height;
      debugPrint('MEDIDA escala=$escala alto=$alto');
    });
  }
}
