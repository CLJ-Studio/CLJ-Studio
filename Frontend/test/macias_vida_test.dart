import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/charla_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/lenguaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/memoria_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';

/// Un miercoles a media tarde, como en las otras pruebas.
final _hoy = DateTime(2026, 10, 7, 15, 30);

CerebroMacias _cerebro({DateTime? ahora, MemoriaMacias? memoria}) =>
    CerebroMacias(
      contexto: () =>
          ContextoMacias(nombre: 'Juan', ahora: ahora ?? _hoy, version: '1.0'),
      memoria: memoria,
      azar: Random(5),
    );

String _todo(RespuestaMacias respuesta) =>
    respuesta.burbujas.map((burbuja) => burbuja.texto).join('\n');

void _cadaUno(Map<String, String> casos, {bool porTema = false}) {
  for (final MapEntry(key: mensaje, value: esperado) in casos.entries) {
    test('"$mensaje" → $esperado', () {
      final respuesta = _cerebro().escribir(mensaje);
      expect(
        porTema ? respuesta.temaId : respuesta.intencion,
        esperado,
        reason: _todo(respuesta),
      );
    });
  }
}

void main() {
  group('la U, los profes y la carrera', () {
    _cadaUno(const {
      'cuando son las vacaciones': 'universidad:tramite',
      'cuando empiezan las clases': 'universidad:tramite',
      'como me inscribo a las materias': 'universidad:tramite',
      'cuanto cuesta la mensualidad': 'universidad:tramite',
      'como saco mi carnet': 'universidad:tramite',
      'donde veo mis notas': 'universidad:tramite',
      'hay becas en la upsa': 'universidad:tramite',
      'como me titulo': 'universidad:tramite',
      'como retiro una materia': 'universidad:tramite',
      'el wifi de la u no sirve': 'universidad:tramite',
      'a que hora abre la biblioteca': 'universidad:tramite',
      'donde queda el bloque a': 'universidad:campus',
      'donde esta la cafeteria': 'universidad:campus',
      'como llego a la upsa': 'universidad:campus',
      'el profe de calculo me odia': 'universidad:profe',
      'no entiendo a mi profe': 'universidad:profe',
      'el ingeniero es muy exigente': 'universidad:profe',
      'llegue tarde a clases': 'universidad:tarde',
      'me quede dormido y perdi el examen': 'universidad:tarde',
      'cuanto gana un ingeniero': 'universidad:carrera',
      'vale la pena estudiar sistemas': 'universidad:carrera',
      'que tal es la carrera de derecho': 'universidad:carrera',
      'que carrera me recomiendas': 'universidad:carrera',
      'me quiero cambiar de carrera': 'universidad:carrera',
      'donde puedo estudiar en el campus': 'universidad:estudiar',
    });

    test('no inventa precios ni fechas de la U', () {
      for (final pregunta in [
        'cuanto cuesta la mensualidad',
        'cuando son las vacaciones',
        'cuanto gana un ingeniero',
      ]) {
        final texto = _todo(_cerebro().escribir(pregunta));
        expect(texto, isNot(matches(RegExp(r'\d'))), reason: texto);
      }
    });

    test('cuenta de que va la carrera que se nombra', () {
      final texto = _todo(
        _cerebro().escribir('vale la pena estudiar sistemas'),
      );
      expect(texto, contains('Ingeniería de Sistemas'));
    });

    test('"¿qué tal es la carrera?" no es un saludo', () {
      final texto = _todo(
        _cerebro().escribir('que tal es la carrera de derecho'),
      );
      expect(texto, isNot(startsWith('¡Hola')));
      expect(texto, contains('Derecho'));
    });
  });

  group('lo de la app que faltaba', () {
    _cadaUno(const {
      'hay modo oscuro': 'app_tema_oscuro',
      'como cambio el idioma': 'app_idioma',
      'la app esta en ingles': 'app_idioma',
      'la app pesa mucho': 'app_peso',
      'funciona sin internet': 'app_sin_internet',
      'hacen delivery': 'app_delivery',
      'hay descuentos': 'app_descuentos',
      'puedo dejar una reseña': 'app_resenas',
      'el vendedor me estafo': 'app_problema_pedido',
      'me robaron mi pedido': 'app_problema_pedido',
      'puedo vender ropa usada': 'app_permitido',
      'puedo vender cerveza': 'app_prohibido',
      'por que no aparece mi publicacion': 'app_no_aparece',
      'borre mi publicacion sin querer': 'app_borre_sin_querer',
      'como bloqueo a alguien': 'app_bloquear',
      'cuantos usuarios tiene la app': 'app_usuarios',
      'en que esta hecha la app': 'app_como_se_hizo',
      'cuanto cuesta hacer una app': 'app_como_se_hizo',
      'cuanto ganan con la app': 'app_ganancias',
      'puedo trabajar con ustedes': 'app_equipo',
      'quien es el dueño de la app': 'oficial',
      'como reporto una publicacion': 'faq_reportar',
      'nadie me responde en la app': 'no_responde_vendedor',
      'como cambio el precio': 'editar_publicacion',
      'como borro mi cuenta': 'borrar_cuenta',
      'como puedo vender': 'como_publicar',
      'que puedo vender': 'ideas_vender',
      'que hay de nuevo en la app': 'version',
    }, porTema: true);

    test('reportar dice donde esta el boton', () {
      final texto = _todo(_cerebro().escribir('como reporto una publicacion'));
      expect(texto, contains('banderita'));
    });
  });

  group('charla nueva', () {
    _cadaUno(const {
      'feliz navidad': 'charla:fiestas',
      'me voy a almorzar': 'charla:voy_a',
      'ya volvi': 'charla:volvi',
      'me extrañaste': 'charla:volvi',
      'dime un piropo': 'charla:piropo',
      'me invitas un cafe': 'charla:invitacion',
      'vamos a la cafeteria': 'charla:invitacion',
      'me prestas plata': 'charla:plata',
      'ese no me dio risa': 'charla:chiste_malo',
      'tengo miedo': 'charla:miedo',
      'me siento feo': 'charla:autoestima',
      'ya termine mis examenes': 'charla:libre',
      'esta lloviendo': 'charla:lluvia',
      'como me veo': 'charla:como_me_veo',
      'eres feo': 'charla:insulto',
      'eres el mejor bot del mundo': 'charla:elogio',
      'te voy a extrañar': 'charla:despedida',
      'que hay de nuevo': 'charla:como_estas',
      'aprobe calculo': 'charla:aprobe',
      'oye y tu que estudias': 'charla:macias',
      'cuentame tu vida': 'charla:macias',
      'eres de oriente o blooming': 'charla:macias',
      'puedes mandar fotos': 'charla:macias',
      'puedes buscar en google': 'charla:macias',
      'hablas quechua': 'charla:macias',
      'tienes hambre': 'charla:macias',
      'quiero helado': 'charla:antojo',
      'donde venden las mejores salteñas': 'charla:antojo',
      'que hago este finde': 'charla:consejo',
      'como hago una tesis': 'charla:consejo',
      'como hablo en publico': 'charla:consejo',
      'como hago un cv': 'charla:consejo',
      'como aprendo a programar': 'charla:consejo',
      'quiero hacer amigos': 'charla:consejo',
      'que es mejor python o c++': 'charla:opinion',
      'me ayudas con un proyecto': 'charla:tarea',
      'mmm': 'charla:acuerdo',
    });

    test('en el clasico cruceño no elige', () {
      final texto = _todo(_cerebro().escribir('prefieres oriente o blooming'));
      expect(texto, contains('neutral'));
    });

    test('compara lenguajes de verdad', () {
      final texto = _todo(_cerebro().escribir('cual es mejor java o python'));
      expect(texto, contains('**Java**'));
      expect(texto, contains('**Python**'));
    });

    test('"me prestas plata" no es lo mismo que "estoy yesca"', () {
      expect(
        _todo(_cerebro().escribir('me prestas plata')),
        contains('No tengo billetera'),
      );
      expect(
        _todo(_cerebro().escribir('estoy yesca')),
        isNot(contains('billetera')),
      );
    });
  });

  group('fiestas segun la fecha', () {
    test('en Navidad se saluda', () {
      final texto = _todo(
        _cerebro(ahora: DateTime(2026, 12, 25, 10)).escribir('feliz navidad'),
      );
      expect(texto, contains('Feliz Navidad, Juan'));
    });

    test('en octubre, se adelanto', () {
      expect(
        _todo(_cerebro().escribir('feliz navidad')),
        contains('te adelantaste'),
      );
    });

    test('el 1 de enero, feliz año', () {
      final texto = _todo(
        _cerebro(ahora: DateTime(2027, 1, 1, 12)).escribir('feliz año nuevo'),
      );
      expect(texto, contains('Feliz año nuevo'));
    });

    test('el Dia del Estudiante ya paso', () {
      expect(
        _todo(_cerebro().escribir('feliz dia del estudiante')),
        contains('ya pasó'),
      );
    });

    test('si el cumpleaños es de quien escribe, se lo dice', () {
      final memoria = MemoriaMacias()
        ..cumpleMes = 10
        ..cumpleDia = 7;
      final texto = _todo(
        _cerebro(memoria: memoria).escribir('feliz cumpleaños'),
      );
      expect(texto, contains('el del cumpleaños eres tú'));
    });
  });

  group('ejercicios de C++', () {
    const casos = {
      'factorial en c++': '**Factorial** en C++',
      'programa para saber si un numero es primo en c++': 'esPrimo',
      'como sumo dos numeros en c++': 'a + b',
      'fibonacci en c++': 'siguiente',
      'ordenar un arreglo en c++': 'burbuja',
      'como hago la tabla de multiplicar en c++': 'n * i',
      'codigo para invertir un numero': 'invertido',
      'como hago una calculadora en c++': "case '+'",
    };
    for (final MapEntry(key: pregunta, value: esperado) in casos.entries) {
      test('"$pregunta"', () {
        final respuesta = _cerebro().escribir(pregunta);
        expect(respuesta.intencion, 'estudio:ejercicio');
        expect(_todo(respuesta), contains('```'));
        expect(_todo(respuesta), contains(esperado));
      });
    }

    test('sin hablar de programar, no hay codigo', () {
      for (final pregunta in [
        'como sumo dos numeros',
        'mi primo programa en c',
      ]) {
        expect(
          _cerebro().escribir(pregunta).intencion,
          isNot('estudio:ejercicio'),
          reason: pregunta,
        );
      }
    });
  });

  group('utilidades', () {
    const casos = {
      'que hora es en japon': '4:30',
      'que hora es en españa': '21:30',
      'que hora es en nueva york': 'misma hora',
      'cuantos metros tiene un kilometro': '1000 metros',
      'cuantos gramos tiene un kilo': '1000 gramos',
      '100 dolares a 6,96': '696 Bs',
      'convierte 100 dolares a bolivianos': 'No tengo el tipo de cambio',
      'a cuanto esta el dolar': 'No tengo el tipo de cambio',
      'cuantos dias tiene febrero': '28',
      'cuantos dias tiene abril': '30',
    };
    for (final MapEntry(key: pregunta, value: esperado) in casos.entries) {
      test('"$pregunta"', () {
        expect(_todo(_cerebro().escribir(pregunta)), contains(esperado));
      });
    }

    test('en Japon ya es jueves', () {
      expect(
        _todo(_cerebro().escribir('que hora es en japon')),
        contains('jueves'),
      );
    });

    test('el horario de verano de Europa se termina en octubre', () {
      final enero = _cerebro(ahora: DateTime(2027, 1, 15, 15, 30));
      expect(_todo(enero.escribir('que hora es en españa')), contains('20:30'));
    });
  });

  group('memoria', () {
    test('"¿quién soy?" con lo que sabe', () {
      final memoria = MemoriaMacias()..carrera = 'Ingeniería de Sistemas';
      final texto = _todo(_cerebro(memoria: memoria).escribir('quien soy'));
      expect(texto, contains('Juan'));
      expect(texto, contains('Ingeniería de Sistemas'));
    });

    test('adivinar la edad: si no la sabe, no la inventa', () {
      expect(
        _todo(_cerebro().escribir('cuantos años crees que tengo')),
        contains('no tengo forma de saberlo'),
      );
      final memoria = MemoriaMacias()..edad = 21;
      expect(
        _todo(_cerebro(memoria: memoria).escribir('adivina mi edad')),
        contains('21'),
      );
    });

    test('los gustos en plural', () {
      final memoria = MemoriaMacias();
      final texto = _todo(
        _cerebro(memoria: memoria).escribir('me gustan los gatos'),
      );
      expect(texto, contains('te gustan los gatos'));
      expect(memoria.gustos, contains('los gatos'));
    });

    test('lo que no le gusta, en plural', () {
      final texto = _todo(_cerebro().escribir('odio las arañas'));
      expect(texto, contains('no te gustan las arañas'));
      expect(texto, contains('No te las voy a recomendar'));
    });
  });

  group('otro más', () {
    test('despues de un piropo, otro piropo distinto', () {
      final cerebro = _cerebro();
      final primero = cerebro.escribir('dime un piropo');
      final segundo = cerebro.escribir('otro mas');
      expect(segundo.intencion, 'charla:piropo');
      expect(_todo(segundo), isNot(_todo(primero)));
    });

    test('despues de un chiste, otro chiste', () {
      final cerebro = _cerebro()..escribir('cuentame un chiste');
      expect(cerebro.escribir('otro').temaId, 'chiste');
    });

    test('sin nada antes, pregunta otro que', () {
      final respuesta = _cerebro().escribir('otro mas');
      expect(respuesta.intencion, 'charla:otro');
      expect(respuesta.burbujas.last.opciones, isNotEmpty);
    });
  });

  group('lo nuevo que sabe', () {
    const casos = {
      'que es una tesis': 'tribunal',
      'que es un framework': 'Flutter',
      'que es todos santos': 'tantawawas',
      'quien es el ekeko': 'abundancia',
      'como se hace una salteña': 'jigote',
      'receta de majadito': 'charque',
      'como se prepara el api': 'maíz morado',
    };
    for (final MapEntry(key: pregunta, value: esperado) in casos.entries) {
      test('"$pregunta"', () {
        expect(_todo(_cerebro().escribir(pregunta)), contains(esperado));
      });
    }
  });

  group('como habla la gente de verdad', () {
    _cadaUno(const {
      'que macana': 'charla:lastima',
      'estoy hecho bolsa': 'charla:cansado',
      'me jodi': 'charla:en_problemas',
      'que bronca': 'charla:enojado',
      'ya fue': 'charla:resignacion',
      'nada que ver': 'charla:desacuerdo',
      'no te creo': 'charla:en_serio',
      'estas loco': 'charla:loco',
      'somos amigos': 'charla:amistad',
      'no puedo dormir': 'charla:insomnio',
      'mis papas no me entienden': 'charla:familia',
      'no se que hacer con mi vida': 'charla:existencial',
      'me gusta una chica de mi curso': 'charla:crush',
      'xq no me respondes': 'charla:presencia',
      'cuentame un secreto': 'charla:secreto',
      'que musica te gusta': 'charla:favorito',
      'que piensas de mi': 'charla:opinion',
      'me odias': 'charla:macias',
      'te pagan': 'charla:macias',
      'quiero bajar de peso': 'charla:consejo',
      'necesito trabajo': 'universidad:carrera',
      'cuanto necesito para aprobar': 'util:aprobar',
      'no entiendo derivadas': 'saber:concepto',
      'explicame la regla de la cadena': 'saber:concepto',
      'quien pinto la mona lisa': 'saber:invento',
      'cuando fue la segunda guerra mundial': 'saber:general',
      'por que el cielo es azul': 'saber:general',
    });

    _cadaUno(const {
      'que significa pendiente': 'estados',
      'no puedo publicar': 'app_no_puedo_publicar',
      'mi foto no se sube': 'app_foto_no_sube',
      'se puede pedir para otra persona': 'app_pedir_para_otro',
      'puedo dar clases particulares': 'app_permitido',
      'como pongo mi whatsapp': 'editar_perfil',
      'como oculto mi publicacion': 'faq_ocultar',
      'es seguro comprar': 'seguridad_encuentro',
      'olvide mi contraseña': 'como_entrar',
    }, porTema: true);

    test('"¿qué piensas de mí?" no habla de "mi" como de una cosa', () {
      expect(
        _todo(_cerebro().escribir('que piensas de mi')),
        isNot(contains('mi tiene')),
      );
    });

    test('dos gustos en un mensaje', () {
      final memoria = MemoriaMacias();
      final texto = _todo(
        _cerebro(
          memoria: memoria,
        ).escribir('me gusta la pizza y odio el brocoli'),
      );
      expect(texto, contains('no te gusta el brocoli'));
      expect(memoria.gustos, ['la pizza']);
      expect(memoria.disgustos, ['el brocoli']);
    });

    test('al presentarse, el hola va sin el nombre viejo', () {
      final texto = _todo(_cerebro().escribir('hola macias me llamo carla'));
      expect(texto, isNot(contains('Juan')));
      expect(texto, contains('Carla'));
    });

    test('a Derecho no se le ofrece C++', () {
      final texto = _todo(_cerebro().escribir('estudio derecho'));
      expect(texto, isNot(contains('C++')));
    });
  });

  group('cuanto falta para aprobar', () {
    test('con dos parciales de 30% cada uno', () {
      final texto = _todo(
        _cerebro().escribir(
          'saque 60 en un parcial de 30% y 70 en otro de 30%, cuanto necesito '
          'para aprobar',
        ),
      );
      expect(texto, contains('**39 puntos**'));
      expect(texto, contains('**30**'));
    });

    test('si ya alcanza, lo dice', () {
      final texto = _todo(
        _cerebro().escribir(
          'saque 90 en un parcial de 60%, cuanto necesito '
          'para aprobar',
        ),
      );
      expect(texto, contains('Ya pasaste'));
    });

    test('estudiar para aprobar no es una cuenta', () {
      expect(
        _cerebro().escribir('como estudio para aprobar calculo').intencion,
        isNot('util:aprobar'),
      );
    });
  });

  group('cocina', () {
    const recetas = {
      'Y dabes hacer bife': '**Bife**',
      'Si sabes hacer bife': '**Bife**',
      'y sabes hacer fideos': '**Fideo con salsa**',
      'receta de silpancho': '**Silpancho**',
      'como se hace una salchipapa': '**Salchipapa**',
      'sabes hacer sushi': 'nori',
      'como preparo un frappe': '**Frappé**',
      'receta de brownies': '**Brownies**',
      'que lleva el pique macho': '**Pique macho**',
      'ingredientes de la salteña': 'jigote',
      'como hago arroz': '**Arroz blanco**',
      'como se hace la llajua': 'locoto',
      'receta de anticuchos': 'corazón',
    };
    for (final MapEntry(key: pregunta, value: esperado) in recetas.entries) {
      test('"$pregunta"', () {
        final respuesta = _cerebro().escribir(pregunta);
        expect(respuesta.intencion, 'saber:receta');
        expect(_todo(respuesta), contains(esperado));
      });
    }

    _cadaUno(const {
      'que es una salchipapa': 'saber:concepto',
      'que es la llajua': 'saber:concepto',
      'que puedo cocinar hoy': 'saber:recetas',
      'receta de lasaña': 'saber:receta_desconocida',
      'quiero una salchipapa': 'charla:antojo',
    });

    test('lo que no es comida no se confunde con una receta', () {
      expect(
        _cerebro().escribir('sabes hacer integrales').intencion,
        isNot(startsWith('saber:receta')),
      );
      expect(
        _cerebro().escribir('como hacer una app').temaId,
        'app_como_se_hizo',
      );
    });

    test('"si sabes hacer bife" no ofrece temas que no van', () {
      final texto = _todo(_cerebro().escribir('si sabes hacer bife'));
      expect(texto, isNot(contains('¿Qué sabes de mí?')));
    });
  });

  group('memoria de varias cosas a la vez', () {
    test('"soy Jotade" es un nombre', () {
      final memoria = MemoriaMacias();
      _cerebro(memoria: memoria).escribir('soy jotade');
      expect(memoria.nombre, 'Jotade');
    });

    test('"soy Jotade, me gusta el fútbol" anota las dos', () {
      final memoria = MemoriaMacias();
      final texto = _todo(
        _cerebro(memoria: memoria).escribir('soy Jotade, me gusta el futbol'),
      );
      expect(memoria.nombre, 'Jotade');
      expect(memoria.gustos, contains('el fútbol'));
      expect(texto, contains('te llamo Jotade y te gusta el fútbol'));
    });

    test('tres cosas en un mensaje', () {
      final memoria = MemoriaMacias();
      _cerebro(
        memoria: memoria,
      ).escribir('tengo 20 años, soy de la paz y me gustan los perros');
      expect(memoria.edad, 20);
      expect(memoria.ciudad, 'La Paz');
      expect(memoria.gustos, contains('los perros'));
    });

    test('"soy feliz" o "soy camba" no son nombres', () {
      for (final frase in ['soy feliz', 'soy camba', 'soy estudiante']) {
        final memoria = MemoriaMacias();
        _cerebro(memoria: memoria).escribir(frase);
        expect(memoria.nombre, isNull, reason: frase);
      }
    });
  });

  group('el aviso de crisis, sin falsas alarmas', () {
    test('lo grave se toma en serio', () {
      for (final frase in ['me quiero morir', 'quiero cortarme las venas']) {
        expect(_cerebro().escribir(frase).intencion, 'cuidado', reason: frase);
      }
    });

    test('las frases de todos los dias no', () {
      for (final frase in [
        'me corto el pelo mañana',
        'me quiero morir de risa',
        'quiero cortarme el cabello',
      ]) {
        expect(
          _cerebro().escribir(frase).intencion,
          isNot('cuidado'),
          reason: frase,
        );
      }
    });
  });

  group('suena a persona', () {
    test('la charla corta no suena a folleto', () {
      for (final frase in [
        'hola',
        'que haces',
        'como estas',
        'gracias',
        'ok',
        'jaja',
        'chau',
        'estas ahi',
      ]) {
        for (var semilla = 0; semilla < 6; semilla++) {
          final cerebro = CerebroMacias(
            contexto: () =>
                ContextoMacias(nombre: 'Juan', ahora: _hoy, version: '1.0'),
            azar: Random(semilla),
          );
          final texto = _todo(cerebro.escribir(frase));
          for (final robot in [
            'Baldor',
            'integrales',
            'En qué te ayudo',
            'Para eso estoy',
            'Un gusto ayudarte',
          ]) {
            expect(texto, isNot(contains(robot)), reason: '$frase: $texto');
          }
        }
      }
    });

    test('si le preguntan lo mismo dos veces, se da cuenta', () {
      final cerebro = _cerebro();
      cerebro.escribir('que haces?');
      final segunda = _todo(cerebro.escribir('que haces?'));
      expect(segunda, anyOf(contains('lo mismo'), contains('Sigo igual')));
    });
  });

  group('no se confunde', () {
    test('"idioma" no es "idiota" ni "hombre" es "hambre"', () {
      expect(LenguajeMacias.contiene(['idioma'], 'idiota'), isFalse);
      expect(LenguajeMacias.contiene(['hombre'], 'hambre'), isFalse);
      expect(
        LenguajeMacias.contiene(['me', 'gustan', 'los', 'gatos'], 'me gustas'),
        isFalse,
      );
    });

    test('"mmm" sigue siendo "mmm"', () {
      expect(LenguajeMacias.normalizar('mmm'), 'mmm');
      expect(LenguajeMacias.normalizar('Hmmmm'), 'mmm');
    });

    test('"te" solo es la bebida si lo parece', () {
      expect(CharlaMacias.conTildes('el te'), 'el té');
      expect(CharlaMacias.conTildes('que te rias'), 'que te rias');
    });

    test('"cómo me titulo" no es un "me titulé"', () {
      expect(
        _cerebro().escribir('como me titulo').intencion,
        isNot('charla:aprobe'),
      );
    });

    test('una pregunta de quimica no es una regla de la app', () {
      expect(
        _cerebro().escribir('que es el alcohol').temaId,
        isNot('app_prohibido'),
      );
    });

    test('lo de C++ sigue en su sitio', () {
      expect(_cerebro().escribir('hola mundo').temaId, 'p_hola');
      expect(
        _cerebro().escribir('que es el polimorfismo').temaId,
        'p_herencia',
      );
    });
  });
}
