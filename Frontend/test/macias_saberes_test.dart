import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/bienestar_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conversacion_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/enciclopedia_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/lenguaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/trivia_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';

CerebroMacias _cerebro({int sorteo = 0}) => CerebroMacias(
  contexto: () => ContextoMacias(
    nombre: 'Juan',
    ahora: DateTime(2026, 10, 7, 15, 30),
    version: '1.0',
    sorteo: sorteo,
  ),
  azar: Random(11),
);

String _todo(RespuestaMacias respuesta) =>
    respuesta.burbujas.map((burbuja) => burbuja.texto).join('\n');

final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{20E3}]',
  unicode: true,
);

void _contiene(Map<String, String> casos) {
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
}

void _intencion(Map<String, String> casos) {
  for (final MapEntry(key: pregunta, value: esperada) in casos.entries) {
    test('"$pregunta" → $esperada', () {
      final respuesta = _cerebro().escribir(pregunta);
      expect(respuesta.intencion, esperada, reason: _todo(respuesta));
    });
  }
}

void main() {
  group('filosofía, psicología e historia', () {
    _contiene(const {
      'que es el estoicismo': 'Séneca',
      'que es el existencialismo': 'Sartre',
      'que es el nihilismo': 'Nietzsche',
      'que es el mito de la caverna': 'Platón',
      'dilema del tranvia': 'palanca',
      'que es una falacia': 'ad hominem',
      'que es la autoestima': 'valoras',
      'que es el sindrome del impostor': 'descubrir',
      'que es el burnout': 'agotamiento',
      'que es el efecto dunning kruger': 'sobreestimar',
      'piramide de maslow': 'autorrealización',
      'que es el gaslighting': 'manipulación',
      'que es el ghosting': 'desaparece',
      'que es la tecnica feynman': 'niño',
      'que es la repeticion espaciada': 'intervalos',
      'que fue la guerra fria': 'Unión Soviética',
      'quienes fueron los incas': 'Cusco',
      'que es el renacimiento': 'Leonardo',
      'que es la oferta y la demanda': 'precio sube',
      'quien fue socrates': 'cicuta',
      'quien fue freud': 'psicoanálisis',
      'quien fue frida kahlo': 'autorretratos',
      'quien fue kant': 'imperativo categórico',
      'quien fue mandela': 'apartheid',
    });

    test('"¿y el existencialismo?" sigue la charla', () {
      final cerebro = _cerebro();
      cerebro.escribir('que es el estoicismo');
      expect(
        _todo(cerebro.escribir('y el existencialismo')),
        contains('Sartre'),
      );
    });
  });

  group('frases, refranes y fábulas', () {
    _intencion(const {
      'dame una frase celebre': 'saber:frase',
      'dime una frase': 'saber:frase',
      'frase de seneca': 'saber:frase',
      'que dijo einstein': 'saber:frase',
      'dime un refran': 'saber:refran',
      'un dicho popular': 'saber:refran',
      'cuentame una fabula': 'charla:cuento',
      'cuentame un cuento': 'charla:cuento',
    });

    test('la frase de alguien es suya', () {
      expect(_todo(_cerebro().escribir('frase de seneca')), contains('Séneca'));
    });

    test('se explica el refrán que se pregunta', () {
      expect(
        _todo(
          _cerebro().escribir(
            'que significa camaron que se duerme se lo lleva la corriente',
          ),
        ),
        contains('oportunidad'),
      );
    });

    test('"otra" después de una fábula es otra fábula', () {
      final cerebro = _cerebro();
      final primera = _todo(cerebro.escribir('cuentame una fabula'));
      final otra = cerebro.escribir('otra');
      expect(otra.intencion, 'charla:cuento');
      expect(_todo(otra), isNot(primera));
    });
  });

  group('trivia', () {
    test('cada pregunta tiene tres opciones y una correcta', () {
      expect(TriviaMacias.preguntas.length, greaterThanOrEqualTo(40));
      for (final (pregunta, opciones, correcta, explicacion)
          in TriviaMacias.preguntas) {
        expect(opciones, hasLength(3), reason: pregunta);
        expect(correcta, inInclusiveRange(0, 2), reason: pregunta);
        expect(explicacion, isNotEmpty, reason: pregunta);
      }
    });

    test('se contesta con la letra', () {
      final cerebro = _cerebro();
      final pregunta = cerebro.escribir('trivia');
      expect(pregunta.intencion, 'juego:trivia');
      final espera = cerebro.espera! as EsperaTrivia;
      final letra = 'abc'[espera.correcta];
      final resultado = cerebro.escribir(letra);
      expect(_todo(resultado), isNot(contains('Casi')));
      expect(_todo(resultado), contains('¿Otra?'));
    });

    test('se contesta tocando una opción', () {
      final cerebro = _cerebro();
      final pregunta = cerebro.escribir('juguemos trivia');
      final espera = cerebro.espera! as EsperaTrivia;
      final mala = pregunta.burbujas.last.opciones[(espera.correcta + 1) % 3];
      final resultado = cerebro.elegir(mala);
      expect(_todo(resultado), contains('Casi'));
    });

    test('se contesta escribiendo la respuesta', () {
      final cerebro = _cerebro();
      cerebro.escribir('preguntame algo');
      final espera = cerebro.espera! as EsperaTrivia;
      final resultado = cerebro.escribir(
        'creo que es ${LenguajeMacias.normalizar(espera.opciones[espera.correcta])}',
      );
      expect(_todo(resultado), isNot(contains('Casi')));
    });

    test('"me rindo" la revela y "sí" trae otra', () {
      final cerebro = _cerebro();
      cerebro.escribir('trivia');
      final revelada = cerebro.escribir('me rindo');
      expect(_todo(revelada), startsWith('Era la'));
      expect(cerebro.escribir('si').intencion, 'juego:trivia');
    });

    test('está en el menú de juegos', () {
      final juegos = _cerebro().escribir('juguemos');
      expect(
        juegos.burbujas.last.opciones.map((o) => o.texto),
        contains('Trivia'),
      );
    });
  });

  group('ortografía', () {
    _contiene(const {
      'hay ahi o ay': '**Ahí**',
      'a ver o haber': 'veamos',
      'diferencia entre porque y por que': '**Por qué**',
      'cuando se usa sino': 'contraponer',
      'como se escribe hay': '**Hay**',
      'echo o hecho': 'echar',
      'como se escribe examen': 'sin tilde',
      'lleva tilde exito': 'éxito',
      'reglas de acentuacion': 'Esdrújulas',
      'b o v': 'cantaba',
      'solo lleva tilde': '2010',
    });

    test('lo que no es una duda de escritura sigue de largo', () {
      for (final frase in const [
        'ah ya veo',
        'hay alguien',
        'a ver',
        'ahi nos vemos',
      ]) {
        expect(
          _cerebro().escribir(frase).intencion,
          isNot('saber:ortografia'),
          reason: frase,
        );
      }
    });
  });

  group('consejos de vida y estudio', () {
    _intencion(const {
      'como subir mi autoestima': 'consejo:autoestima',
      'como calmar la ansiedad': 'consejo:ansiedad',
      'como dejar el celular': 'consejo:celular',
      'como ser mas disciplinado': 'consejo:disciplina',
      'como priorizar': 'consejo:priorizar',
      'como decir que no': 'consejo:limites',
      'como superar a mi ex': 'consejo:ex',
      'como pedir perdon': 'consejo:perdon',
      'como dormir mejor': 'consejo:dormir',
      'no se que decidir': 'consejo:decidir',
      'como controlar mi enojo': 'consejo:enojo',
      'soy muy celoso': 'consejo:celos',
      'que hago con mi vida': 'consejo:proposito',
      'como tomar apuntes': 'consejo:estudio',
      'mapa mental': 'consejo:estudio',
      'como hacer un resumen': 'consejo:estudio',
      'examen de opcion multiple': 'consejo:estudio',
      'como aprender ingles': 'consejo:estudio',
      'como preparo mi examen': 'consejo:estudio',
      'soy malo en matematicas': 'consejo:matematicas',
      'que lleva un cv': 'consejo:cv',
      'me queme con aceite caliente': 'consejo:salud',
      'tengo gripe': 'consejo:salud',
      'tengo chaqui': 'consejo:salud',
    });

    test(
      'bien escritos: nombres normalizados, sin emojis, negritas cerradas',
      () {
        for (final (claves, texto) in BienestarMacias.entradas) {
          for (final clave in claves) {
            expect(LenguajeMacias.normalizar(clave), clave, reason: clave);
          }
          expect(_emoji.hasMatch(texto), isFalse, reason: texto);
          expect('**'.allMatches(texto).length.isEven, isTrue, reason: texto);
        }
      },
    );

    test('un saludo adelante no lo tapa', () {
      final respuesta = _cerebro().escribir('hola, como subo mi autoestima');
      expect(respuesta.intencion, 'consejo:autoestima');
      expect(_todo(respuesta), startsWith('¡Hola, Juan!'));
    });
  });

  group('sobre MacIAs', () {
    _contiene(const {
      'la ia nos va a reemplazar': 'chistes malos',
      'tienes conciencia': 'conciencia',
      'duermes': '24/7',
      'tienes instagram': 'No tengo redes',
      'cuando es tu cumpleanos': '2026',
      'sabes de filosofia': 'estoicismo',
      'sabes cocinar': 'recetas',
      'que sabes hacer': 'filosofía',
    });
  });

  group('platos y recetas', () {
    test('lo que es un plato ofrece su receta, y "sí" la trae', () {
      final cerebro = _cerebro();
      final plato = cerebro.escribir('que es el majadito');
      expect(_todo(plato), contains('¿Te paso la receta?'));
      expect(
        plato.burbujas.last.opciones.map((o) => o.texto),
        contains('Ver la receta'),
      );
      final receta = cerebro.escribir('si');
      expect(receta.intencion, 'saber:receta');
      expect(_todo(receta), contains('**Paso a paso**'));
    });

    test('un plato suelto que solo es receta, trae la receta', () {
      expect(_cerebro().escribir('nuggets').intencion, 'saber:receta');
      expect(_cerebro().escribir('lentejas').intencion, 'saber:receta');
    });

    test('con un ingrediente que ninguna receta usa, lo dice', () {
      expect(
        _todo(_cerebro().escribir('que puedo hacer con frejoles')),
        contains('todavía no tengo recetas'),
      );
    });
  });

  group('no se mete donde no va', () {
    test('"me siento solo" no es una comida favorita', () {
      final cerebro = _cerebro();
      cerebro.escribir('cual es tu comida favorita');
      final respuesta = cerebro.escribir('me siento solo');
      expect(respuesta.intencion, isNot('memoria:favorito'));
    });

    test('"los precios" no es un piropo', () {
      expect(
        _cerebro().escribir('los precios').intencion,
        isNot('charla:elogio'),
      );
    });

    test('lo que habla de comprar o vender es de la app', () {
      for (final frase in const [
        'como me calmo si el vendedor no responde',
        'puedo vender una olla a presion',
        'me vendieron pan viejo',
        'como priorizo mis pedidos',
        'como decido el precio',
      ]) {
        final intencion = _cerebro().escribir(frase).intencion ?? '';
        expect(intencion, isNot(startsWith('consejo:')), reason: frase);
        expect(intencion, isNot('saber:cocina'), reason: frase);
      }
    });

    _intencion(const {
      'receta para vender': 'saber:recetas',
      'tengo pollo': 'saber:recetas',
      'me quedan dos papas y un huevo': 'saber:recetas',
      'pan duro': 'saber:cocina',
      'como me calmo': 'consejo:ansiedad',
    });
  });

  group('la enciclopedia creció', () {
    test('es grande de verdad', () {
      expect(EnciclopediaMacias.entradas.length, greaterThan(450));
    });
  });

  group('la app sigue ganando en lo suyo', () {
    const casos = {
      'que es la app': 'que_es_app',
      'como publico algo': 'como_publicar',
      'que significa falta confirmar': 'estados',
      'como pago': 'faq_pago',
    };
    for (final MapEntry(key: pregunta, value: tema) in casos.entries) {
      test('"$pregunta" → $tema', () {
        final respuesta = _cerebro().escribir(pregunta);
        expect(respuesta.temaId, tema, reason: _todo(respuesta));
      });
    }
  });
}
