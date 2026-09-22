import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/elementos_compartidos/tarjetas_aplicacion/estilo_tarjeta_producto.dart';

/// Cuanto mide de verdad el bloque de texto de la tarjeta del carrusel, que
/// es el que lleva ademas la fila de botones. El panel morado se dimensiona
/// con esa cuenta: si se queda corta, las tarjetas sobresalen del morado.
void main() {
  for (final escala in [1.0, 1.25, 1.5, 2.0]) {
    testWidgets('medida a escala $escala', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 164,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ASUS TUF Gaming F16',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: EstiloTarjetaProducto.nombre(context),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Bs 25000.00',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: EstiloTarjetaProducto.precio(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {},
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(30, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(
                                  Icons.favorite_border_rounded,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton.filled(
                                onPressed: () {},
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(30, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 20),
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
        ),
      );
      final alto = tester.getSize(find.byType(Padding).at(0)).height;
      debugPrint('MEDIDA carrusel escala=$escala alto=$alto');
    });
  }
}
