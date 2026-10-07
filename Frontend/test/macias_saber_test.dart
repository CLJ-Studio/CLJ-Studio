import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/enciclopedia_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/lenguaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';

CerebroMacias _cerebro() => CerebroMacias(
  contexto: () => ContextoMacias(
    nombre: 'Juan',
    ahora: DateTime(2026, 10, 7, 15, 30),
    version: '1.0',
  ),
  azar: Random(3),
);

String _todo(RespuestaMacias respuesta) =>
    respuesta.burbujas.map((burbuja) => burbuja.texto).join('\n');

final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{20E3}]',
  unicode: true,
);

void main() {
  group('la enciclopedia esta bien escrita', () {
    test('cada nombre ya esta escrito como lo compara MacIAs', () {
      for (final (nombres, texto) in EnciclopediaMacias.entradas) {
        for (final nombre in nombres) {
          expect(
            LenguajeMacias.normalizar(nombre),
            nombre,
            reason: '"$nombre" ($texto)',
          );
        }
      }
    });

    test('sin emojis y con las negritas cerradas', () {
      for (final (_, texto) in EnciclopediaMacias.entradas) {
        expect(_emoji.hasMatch(texto), isFalse, reason: texto);
        expect('**'.allMatches(texto).length.isEven, isTrue, reason: texto);
      }
    });

    test('es grande de verdad', () {
      expect(EnciclopediaMacias.entradas.length, greaterThan(250));
    });
  });

  group('contesta lo que se pregunta', () {
    const casos = {
      'que es la fotosintesis': 'fotosíntesis',
      '¿Qué significa PIB?': 'PIB',
      'explicame la mitosis': 'mitosis',
      'definicion de inflacion': 'inflación',
      'hablame de la tabla periodica': '118',
      'que es el calor': 'energía',
      'que es un limite': 'función',
      'que es un algoritmo': 'pasos',
      'que es la api': 'maíz morado',
      'que son las neuronas': 'neuronas',
      'para que sirve la ram': 'memoria de trabajo',
      'que es la fotosintecis': 'fotosíntesis',
      'fotosintesis': 'fotosíntesis',
      'quien fue einstein': 'Einstein',
      'quien es jaime escalante': 'Escalante',
      'quien fue juana azurduy': 'Chuquisaca',
      'messi': 'Messi',
      'quien invento el telefono': 'Graham Bell',
      'quien creo whatsapp': 'Koum',
      'quien descubrio la penicilina': 'Fleming',
      'donde queda samaipata': 'Santa Cruz',
      'donde queda el salar de uyuni': 'Potosí',
      'simbolo del oro': '**Au**',
      'que elemento es fe': 'hierro',
      'numero atomico del carbono': 'número atómico 6',
      'que es el litio': 'Uyuni',
      'formula del area del circulo': 'π · r²',
      'como se calcula la velocidad': 'v = d / t',
      'formula de la energia cinetica': '½ · m · v²',
      'moneda de japon': 'yen',
      'que idioma se habla en brasil': 'portugués',
      'donde queda francia': 'Europa',
      'que es una salteña': 'empanada',
      'que es la diablada': 'Oruro',
      'que es el surazo': 'viento',
      'que es el majadito': 'charque',
    };
    for (final MapEntry(key: pregunta, value: esperado) in casos.entries) {
      test('"$pregunta"', () {
        final respuesta = _cerebro().escribir(pregunta);
        expect(
          _todo(respuesta),
          contains(esperado),
          reason: 'intención: ${respuesta.intencion ?? respuesta.temaId}',
        );
      });
    }
  });

  group('lo de la app sigue ganando en lo suyo', () {
    const casos = {
      'que es la app': 'que_es_app',
      'que es u market': 'que_es_app',
      'que es un local': 'que_es_local',
      'donde queda el local': 'donde_local',
      'que es el stock': 'stock',
      'que significa falta confirmar': 'estados',
      'que es una integral': 'c_integral',
      'que es un puntero': 'p_punteros',
      'que es la factorizacion': 'a_factorizacion',
      'cuantas publicaciones puedo hacer': 'limite_publicaciones',
    };
    for (final MapEntry(key: pregunta, value: tema) in casos.entries) {
      test('"$pregunta" → $tema', () {
        final respuesta = _cerebro().escribir(pregunta);
        expect(respuesta.temaId, tema, reason: _todo(respuesta));
      });
    }
  });
}
