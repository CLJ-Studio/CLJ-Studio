import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/inicio_marketplace/modelos/producto_marketplace.dart';
import 'package:upsa_eat/funcionalidades/publicar_producto/diseno/selector_vigencia_publicacion.dart';
import 'package:upsa_eat/funcionalidades/publicar_producto/logica/vigencia_publicacion.dart';

/// Lunes 16 de noviembre de 2026, 14:37.
final ahora = DateTime(2026, 11, 16, 14, 37);

ProductoMarketplace producto({
  bool disponible = true,
  DateTime? venceEn,
  DateTime? vendidaEn,
}) => ProductoMarketplace(
  id: 'p',
  localId: 'l',
  nombre: 'Entrada',
  descripcion: '',
  precio: 50,
  emoji: '🎟️',
  stock: 1,
  disponible: disponible,
  venceEn: venceEn,
  vendidaEn: vendidaEn,
);

void main() {
  group('cuándo vence cada opción', () {
    test('sin fecha no vence, y en lo personal es "hasta que se venda"', () {
      const vigencia = SinFecha();
      expect(vigencia.venceEn(ahora), isNull);
      expect(
        vigencia.etiqueta(esPersonal: true, ahora: ahora),
        'Hasta que se venda',
      );
      expect(vigencia.etiqueta(esPersonal: false, ahora: ahora), 'Sin fecha');
      expect(VigenciaPublicacion.inicial, const SinFecha());
    });

    test('24 horas cuenta desde que se publica', () {
      const vigencia = UnDia();
      expect(vigencia.venceEn(ahora), DateTime(2026, 11, 17, 14, 37));
      expect(
        vigencia.explicacion(esPersonal: true, ahora: ahora),
        'Se deja de ver mañana a las 14:37.',
      );
    });

    test('hasta un día: hasta las 23:59 de ese día', () {
      final sabado = HastaDia(DateTime(2026, 11, 21, 9));
      expect(sabado.venceEn(ahora), DateTime(2026, 11, 21, 23, 59));
      expect(
        sabado.etiqueta(esPersonal: true, ahora: ahora),
        'Hasta el sábado 21 de noviembre',
      );
      expect(
        sabado.explicacion(esPersonal: true, ahora: ahora),
        'Se ve hasta las 23:59 del sábado 21 de noviembre.',
      );
      expect(
        HastaDia(ahora).explicacion(esPersonal: true, ahora: ahora),
        'Se ve hasta las 23:59 de hoy.',
      );
      expect(
        HastaDia(
          DateTime(2026, 11, 15),
        ).explicacion(esPersonal: true, ahora: ahora),
        'Esa fecha ya pasó: elige otra.',
      );
    });

    test('al editar, la fecha que ya tenía se conserva tal cual', () {
      final tenia = DateTime(2026, 11, 17, 14, 37, 12, 345);
      expect(VigenciaPublicacion.desde(null), const SinFecha());
      final desde = VigenciaPublicacion.desde(tenia);
      expect(desde.venceEn(ahora), tenia);
      // Igual a si misma: el dialogo sabe que no la tocaron y no la reenvia.
      expect(desde, VigenciaPublicacion.desde(tenia));
      expect(
        desde.etiqueta(esPersonal: true, ahora: ahora),
        'Hasta mañana a las 14:37',
      );
      expect(
        VigenciaPublicacion.desde(
          DateTime(2026, 11, 15, 23, 59),
        ).etiqueta(esPersonal: true, ahora: ahora),
        'Venció ayer',
      );
    });
  });

  group('cómo se dice una fecha', () {
    test('en largo', () {
      expect(
        textoHasta(DateTime(2026, 11, 16, 18, 30), ahora),
        'hoy a las 18:30',
      );
      expect(textoHasta(DateTime(2026, 11, 16, 23, 59), ahora), 'hoy');
      expect(textoHasta(DateTime(2026, 11, 17, 23, 59), ahora), 'mañana');
      expect(
        textoHasta(DateTime(2026, 11, 25, 10), ahora),
        'el miércoles 25 de noviembre a las 10:00',
      );
      expect(
        textoHasta(DateTime(2026, 12, 5, 23, 59), ahora),
        'el sábado 5 de diciembre',
      );
    });

    test('en corto, para la etiqueta de cada publicación', () {
      expect(
        textoHastaCorto(DateTime(2026, 11, 16, 18, 30), ahora),
        'hoy 18:30',
      );
      expect(textoHastaCorto(DateTime(2026, 11, 17, 23, 59), ahora), 'mañana');
      expect(
        textoHastaCorto(DateTime(2026, 11, 21, 23, 59), ahora),
        'sáb 21 nov',
      );
    });

    test('los días para elegir: de hoy a un mes, cruzando el fin de mes', () {
      final dias = diasParaElegir(ahora);
      expect(dias, hasLength(31));
      expect(dias.first, DateTime(2026, 11, 16));
      expect(dias[15], DateTime(2026, 12, 1));
      expect(nombreDia(dias[0], ahora), 'Hoy');
      expect(nombreDia(dias[1], ahora), 'Mañana');
      expect(nombreDia(dias[5], ahora), 'Sábado 21 de noviembre');
    });
  });

  group('el estado que ve quien la publicó', () {
    test('lee las fechas del servidor', () {
      final leido = ProductoMarketplace.desdeMapa({
        'id': 'p',
        'store_id': 'l',
        'name': 'Entrada',
        'price': 50,
        'is_available': false,
        'expires_at': '2026-11-21T03:59:00+00:00',
        'sold_at': null,
      });
      // 03:59 UTC es el sabado 23:59 en Bolivia; lo que importa es que
      // llegue como el mismo instante.
      expect(leido.venceEn!.toUtc(), DateTime.utc(2026, 11, 21, 3, 59));
      expect(leido.vendidaEn, isNull);
    });

    test('vendida, vencida, oculta, con fecha o sin nada', () {
      expect(
        estadoParaDueno(
          producto(disponible: false, vendidaEn: DateTime(2026, 11, 15)),
          ahora,
        ),
        'VENDIDA',
      );
      expect(
        estadoParaDueno(
          producto(disponible: false, venceEn: DateTime(2026, 11, 16, 10)),
          ahora,
        ),
        'VENCIDA',
      );
      expect(estadoParaDueno(producto(disponible: false), ahora), 'OCULTA');
      expect(
        estadoParaDueno(
          producto(venceEn: DateTime(2026, 11, 21, 23, 59)),
          ahora,
        ),
        'HASTA SÁB 21 NOV',
      );
      expect(estadoParaDueno(producto(), ahora), isNull);
    });

    test('solo una vencida o vendida pide volver a publicar', () {
      expect(
        producto(
          disponible: false,
          venceEn: DateTime(2026, 11, 1),
        ).necesitaVolverAPublicar,
        isTrue,
      );
      expect(
        producto(
          disponible: false,
          vendidaEn: DateTime(2026, 11, 1),
        ).necesitaVolverAPublicar,
        isTrue,
      );
      // Oculta a mano: se muestra con el boton de siempre.
      expect(producto(disponible: false).necesitaVolverAPublicar, isFalse);
      expect(producto().necesitaVolverAPublicar, isFalse);
    });
  });

  group('el selector', () {
    Future<List<VigenciaPublicacion>> montar(WidgetTester tester) async {
      final elegidas = <VigenciaPublicacion>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SelectorVigenciaPublicacion(
                vigencia: const SinFecha(),
                esPersonal: true,
                reloj: () => ahora,
                alCambiar: elegidas.add,
              ),
            ),
          ),
        ),
      );
      return elegidas;
    }

    testWidgets('elige 24 horas', (tester) async {
      final elegidas = await montar(tester);
      expect(find.text('Hasta que se venda'), findsOneWidget);
      expect(
        find.text('Sale sola cuando se entrega la última unidad.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Hasta que se venda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24 horas'));
      await tester.pumpAndSettle();

      expect(elegidas, [const UnDia()]);
    });

    testWidgets('elige un día de la lista, en español', (tester) async {
      final elegidas = await montar(tester);

      await tester.tap(find.text('Hasta que se venda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hasta una fecha…'));
      await tester.pumpAndSettle();

      expect(find.text('¿Hasta qué día se ve?'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      await tester.tap(find.text('Sábado 21 de noviembre'));
      await tester.pumpAndSettle();

      expect(elegidas, [HastaDia(DateTime(2026, 11, 21))]);
    });
  });
}
