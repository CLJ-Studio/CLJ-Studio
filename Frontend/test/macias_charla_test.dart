import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conversacion_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/lenguaje_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/memoria_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/utilidades_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';

/// Un miercoles a media tarde, como cuando se probo con el equipo.
final _hoy = DateTime(2026, 10, 7, 15, 30);

CerebroMacias _cerebro({
  DateTime? ahora,
  MemoriaMacias? memoria,
  int semilla = 7,
}) => CerebroMacias(
  contexto: () =>
      ContextoMacias(nombre: 'Juan', ahora: ahora ?? _hoy, version: '1.0'),
  memoria: memoria,
  azar: Random(semilla),
);

String _todo(RespuestaMacias respuesta) =>
    respuesta.burbujas.map((burbuja) => burbuja.texto).join('\n');

void main() {
  group('lo que escribe cualquiera para probarlo', () {
    // La captura que motivo todo esto: "Me gustas" y "Callate" caian en
    // "no te entendí".
    const casos = {
      'Me gustas': 'charla:gustar',
      'Callate': 'charla:callate',
      'cállate ya': 'charla:callate',
      'eres medio tontito che': 'charla:insulto',
      'eres un bot de mierda': 'charla:insulto',
      'sos un inutil': 'charla:insulto',
      'no me entiendes': 'charla:no_entiendes',
      'te odio': 'charla:odio',
      'te amo macias': 'charla:querer',
      'quieres ser mi novia?': 'charla:pareja',
      'eres lindo': 'charla:elogio',
      'eres un crack': 'charla:elogio',
      'jajaja': 'charla:risa',
      'jsjsjs': 'charla:risa',
      'xD': 'charla:risa',
      'gracias': 'charla:gracias',
      'ok gracias': 'charla:gracias',
      'no gracias': 'charla:negacion',
      'gracias, chau': 'charla:despedida',
      'chau': 'charla:despedida',
      'me voy a dormir': 'charla:despedida',
      'hola': 'charla:saludo',
      'holaaa': 'charla:saludo',
      'que onda': 'charla:como_estas',
      'hola como estas?': 'charla:como_estas',
      'que haces': 'charla:que_haces',
      'estas ahi?': 'charla:presencia',
      'test': 'charla:presencia',
      'perdon': 'charla:perdon',
      'ayuda': 'charla:ayuda',
      'tengo una pregunta': 'charla:pregunta',
      'ok': 'charla:acuerdo',
      'dale': 'charla:acuerdo',
      'no': 'charla:negacion',
      'mal': 'charla:mal',
      'estoy aburrido': 'charla:aburrido',
      'estoy re cansado': 'charla:cansado',
      'tengo sueño': 'charla:sueno',
      'ando estresada': 'charla:estresado',
      'estoy triste': 'charla:triste',
      'me siento solo': 'charla:solo',
      'tengo hambre': 'charla:hambre',
      'estoy yesca': 'charla:plata',
      'que flojera': 'charla:flojera',
      'me fue mal en el parcial': 'charla:reprobe',
      'aprobe!': 'charla:aprobe',
      'me dejo mi novia': 'charla:ruptura',
      'me gusta alguien': 'charla:crush',
      'que es el amor': 'charla:filosofia',
      'modo meme': 'charla:meme',
      'speak english?': 'charla:ingles',
      'borra el chat': 'charla:borrar_chat',
      'pasame el pack': 'charla:inapropiado',
      'quien te creo': 'charla:macias',
      'eres humano?': 'charla:macias',
      'eres chatgpt?': 'charla:macias',
      'por que te llamas macias': 'charla:macias',
      'cuantos años tienes': 'charla:macias',
      'cual es tu comida favorita': 'charla:favorito',
      'te gusta la pizza?': 'charla:opinion',
      'que prefieres pizza o salteña': 'charla:opinion',
      'que opinas de la politica': 'charla:delicado',
      'quiero matar a mi profe': 'charla:delicado',
      'dame un consejo': 'charla:consejo',
      'como me concentro': 'charla:consejo',
      'motivame': 'charla:motivacion',
      'recomiendame una pelicula': 'charla:recomendacion',
      'escribe un poema': 'charla:poema',
      'voy a aprobar calculo?': 'charla:bola',
      'juguemos': 'juego:menu',
      'tira un dado': 'util:dado',
      'cara o sello': 'util:moneda',
      'que hora es': 'util:fecha',
      'cuanto falta para navidad': 'util:fecha',
      'capital de francia': 'saber:general',
    };
    for (final MapEntry(key: mensaje, value: intencion) in casos.entries) {
      test('"$mensaje" → $intencion', () {
        final respuesta = _cerebro().escribir(mensaje);
        expect(
          respuesta.intencion,
          intencion,
          reason: 'respondio: ${_todo(respuesta)}',
        );
      });
    }

    test('ninguna de estas cae en "no te entendí"', () {
      const mensajes = [
        'holi',
        'buenas tardes',
        'q tal',
        'y vos?',
        'mas o menos',
        'oye macias',
        'MacIAs!!',
        '?',
        '...',
        '😂',
        '❤️',
        '😢',
        'que bot mas tonto',
        'no sabes nada',
        'eres pesado',
        'te extrañé',
        'me gustas mucho',
        'gracias crack',
        'lol',
        'eres real?',
        'tienes sentimientos?',
        'que dia es hoy',
        'es fin de semana?',
        'va a llover?',
        'hace frio',
        'que calor',
        'cuantos planetas hay',
        'quien descubrio america',
        'cuanto mide el everest',
        'velocidad de la luz',
        'existe dios?',
        'como vendo',
        'cuanto cobran?',
        'la app esta lenta',
        'ayuda con calculo',
        'tengo parcial de algebra mañana',
        'tengo 19 años',
        'soy de cochabamba',
        'soy camba',
        'mi cumple es el 3 de mayo',
        'recuerdame estudiar',
        'mi color favorito es el azul',
        'piedra papel o tijera',
        'adivinanza',
        'numero random del 1 al 10',
        'cuentame algo',
        'otro chiste',
        'cuenta hasta 10',
        'trabalenguas',
        'dame animos',
        'recomiendame musica para estudiar',
        'donde compro marihuana',
        'hello',
        'how are you',
        'que sabes hacer',
        'para que sirves',
        'eres mejor que chatgpt?',
        'cual es el sentido de la vida',
        'que es u market',
        'asdfgh',
        'gracias por escucharme',
        'que es la fotosintesis',
        'quien gano el mundial',
      ];
      final cerebro = _cerebro();
      for (final mensaje in mensajes) {
        final respuesta = cerebro.escribir(mensaje);
        expect(
          respuesta.intencion,
          isNot('no_entendi'),
          reason: '"$mensaje" respondio: ${_todo(respuesta)}',
        );
      }
    });

    test('lo que no sabe, lo dice nombrando de que se pregunto', () {
      final respuesta = _cerebro().escribir('¿Qué es la mecánica cuántica?');
      expect(respuesta.intencion, 'desconocido');
      expect(_todo(respuesta), contains('mecánica cuántica'));
      // Sin la lista de todo lo que sabe.
      expect(_todo(respuesta), isNot(contains('álgebra')));
    });

    test('"creo que m empezaste a gustar" es un piropo', () {
      expect(
        _cerebro().escribir('Creo que m empezaste a gustar').intencion,
        'charla:gustar',
      );
      expect(_cerebro().escribir('t quiero mucho').intencion, 'charla:querer');
      expect(
        _cerebro().escribir('la verdad me caes muy bien').intencion,
        'charla:elogio',
      );
      // Envuelto en una frase larga tambien se entiende.
      expect(
        _cerebro().escribir('no se como decirte esto pero me gustas').intencion,
        'charla:gustar',
      );
    });

    test('un "hola" adelante no hace ignorar el resto', () {
      final respuesta = _cerebro().escribir('hola, me gustas');
      expect(respuesta.intencion, 'charla:gustar');
      expect(respuesta.burbujas.first.texto, startsWith('¡Hola, Juan!'));
      final gracias = _cerebro().escribir('gracias! y como pago?');
      expect(gracias.temaId, 'faq_pago');
      expect(gracias.burbujas.first.texto, startsWith('¡De nada!'));
    });

    test('una palabrota no esconde la pregunta', () {
      expect(
        _cerebro().escribir('como mierda publico algo').temaId,
        'como_publicar',
      );
      expect(_cerebro().escribir('mierda').intencion, 'charla:groseria');
    });

    test('solo emojis tambien dicen algo', () {
      expect(_cerebro().escribir('😂').intencion, 'charla:emoji');
      expect(_cerebro().escribir('👍').intencion, 'sirvio');
      expect(_cerebro().escribir('👎').intencion, 'no_sirvio');
    });

    test('no repite la misma frase seguido', () {
      final cerebro = _cerebro();
      final respuestas = {
        for (var i = 0; i < 3; i++) _todo(cerebro.escribir('callate')),
      };
      expect(respuestas, hasLength(3));
    });
  });

  group('se acuerda de lo que pregunto', () {
    test('"¿y tú?" y la respuesta', () {
      final cerebro = _cerebro();
      expect(cerebro.escribir('como estas').intencion, 'charla:como_estas');
      expect(cerebro.espera, isA<EsperaAnimo>());
      final respuesta = cerebro.escribir('bien y tu?');
      expect(respuesta.intencion, 'charla:animo');
      expect(_todo(respuesta), contains('Yo también'));
    });

    test(
      'a "¿algo más?" un "no" cierra, pero "no me entiendes" no es un no',
      () {
        final cerebro = _cerebro();
        cerebro.escribir('como publico algo');
        expect(cerebro.escribir('no').intencion, 'charla:negacion');
        cerebro.escribir('como publico algo');
        expect(
          cerebro.escribir('no me entiendes').intencion,
          'charla:no_entiendes',
        );
      },
    );

    test('a "¿algo más?" una pregunta nueva se contesta', () {
      final cerebro = _cerebro();
      cerebro.escribir('como publico algo');
      expect(cerebro.escribir('si, como pago?').temaId, 'faq_pago');
    });

    test('si le ofrece una persona, "sí" la trae', () {
      final cerebro = _cerebro()
        ..escribir('zxqw plorf')
        ..escribir('blorf zxqw');
      expect(cerebro.escribir('si').temaId, ConocimientoMacias.humano);
    });

    test('despues de un chiste, "jaja" ofrece otro y "sí" lo cuenta', () {
      final cerebro = _cerebro()..escribir('cuentame un chiste');
      final risa = cerebro.escribir('jaja');
      expect(_todo(risa), contains('¿Otro?'));
      expect(cerebro.escribir('si').temaId, 'chiste');
    });

    test('"¿y el tuyo?" despues de su favorito se anota', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(
        _todo(cerebro.escribir('cual es tu comida favorita')),
        contains('¿Y la tuya?'),
      );
      cerebro.escribir('el majadito');
      expect(memoria.favoritos['comida'], 'el majadito');
    });

    test('despues de "estoy triste" escucha antes de buscar temas', () {
      final cerebro = _cerebro()..escribir('estoy triste');
      final respuesta = cerebro.escribir('nada, problemas en la casa');
      expect(respuesta.intencion, 'charla:desahogo');
    });
  });

  group('juegos', () {
    test('adivina el numero hasta acertar', () {
      final cerebro = _cerebro();
      cerebro.escribir('adivina el numero');
      final juego = cerebro.espera! as EsperaNumero;
      final pista = cerebro.escribir(
        '${juego.secreto == 1 ? 2 : juego.secreto - 1}',
      );
      expect(_todo(pista), contains('Es **más'));
      final acierto = cerebro.escribir('${juego.secreto}');
      expect(_todo(acierto), contains('Lo adivinaste'));
      // "¿Otra partida?" -> "no".
      expect(cerebro.escribir('no').intencion, 'juego:fin');
    });

    test('mientras juega, un numero es un intento y no una opcion', () {
      final cerebro = _cerebro()..bienvenida();
      cerebro.escribir('adivina el numero');
      expect(cerebro.escribir('3').intencion, 'juego:numero');
    });

    test('rendirse revela el numero', () {
      final cerebro = _cerebro()..escribir('adivina el numero');
      final juego = cerebro.espera! as EsperaNumero;
      expect(
        _todo(cerebro.escribir('me rindo')),
        contains('**${juego.secreto}**'),
      );
    });

    test('piedra, papel o tijera', () {
      final cerebro = _cerebro()..escribir('piedra papel o tijera');
      expect(cerebro.espera, isA<EsperaPpt>());
      expect(_todo(cerebro.escribir('piedra')), contains('Yo saqué'));
      // Desde los atajos tambien se juega.
      cerebro.elegir(const OpcionMacias(id: 'o:juego_ppt', texto: 'Piedra'));
      expect(
        _todo(
          cerebro.elegir(
            const OpcionMacias(id: 'o:ppt_tijera', texto: 'Tijera'),
          ),
        ),
        contains('Yo saqué'),
      );
    });

    test('una adivinanza se contesta', () {
      final cerebro = _cerebro()..escribir('adivinanza');
      final adivinanza = cerebro.espera! as EsperaAdivinanza;
      expect(
        _todo(cerebro.escribir(adivinanza.respuestas.first)),
        contains('¡Correcto!'),
      );
    });

    test('elegir entre opciones respeta como se escribieron', () {
      final texto = _todo(
        _cerebro().escribir('elige entre pizza, salteña o empanada'),
      );
      expect(
        texto,
        anyOf(
          contains('**pizza**'),
          contains('**salteña**'),
          contains('**empanada**'),
        ),
      );
    });
  });

  group('fechas', () {
    test('Pascua, de la que salen Carnaval y Semana Santa', () {
      expect(FechasMacias.pascua(2025), DateTime(2025, 4, 20));
      expect(FechasMacias.pascua(2026), DateTime(2026, 4, 5));
      expect(FechasMacias.pascua(2027), DateTime(2027, 3, 28));
    });

    test('cuanto falta para algo', () {
      expect(
        _todo(_cerebro().escribir('cuanto falta para navidad')),
        contains('**79 días**'),
      );
      expect(
        _todo(_cerebro().escribir('cuanto falta para carnaval')),
        allOf(contains('**124 días**'), contains('8 de febrero')),
      );
      expect(
        _todo(_cerebro().escribir('cuantos dias faltan para el 15 de octubre')),
        contains('**8 días**'),
      );
      expect(
        _todo(_cerebro().escribir('que dia es mañana')),
        contains('jueves 8 de octubre'),
      );
      expect(
        _todo(_cerebro().escribir('que dia cae navidad')),
        contains('viernes 25 de diciembre'),
      );
    });

    test('lee fechas como se dicen', () {
      DateTime? fecha(String texto) =>
          FechasMacias.fechaEn(LenguajeMacias.normalizar(texto), _hoy);
      expect(fecha('mañana'), DateTime(2026, 10, 8));
      expect(fecha('pasado mañana'), DateTime(2026, 10, 9));
      expect(fecha('el viernes'), DateTime(2026, 10, 9));
      // El mismo dia de la semana es el de la semana que viene.
      expect(fecha('el miércoles'), DateTime(2026, 10, 14));
      expect(fecha('el 15'), DateTime(2026, 10, 15));
      expect(fecha('el 3'), DateTime(2026, 11, 3));
      expect(fecha('el 15 de noviembre'), DateTime(2026, 11, 15));
      expect(fecha('5 de mayo'), DateTime(2027, 5, 5));
      expect(fecha('en 3 dias'), DateTime(2026, 10, 10));
      expect(fecha('mañana en la mañana'), DateTime(2026, 10, 8));
      expect(fecha('estudio en la mañana'), isNull);
      expect(fecha('31 de junio'), isNull);
    });
  });

  group('memoria', () {
    test('un examen: suerte antes, y despues pregunta como le fue', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      final anotado = cerebro.escribir('tengo parcial de calculo el viernes');
      expect(_todo(anotado), contains('el parcial de cálculo'));
      expect(memoria.examenes.single.fecha, DateTime(2026, 10, 9));
      expect(memoria.examenes.single.tipo, 'parcial');

      // El jueves, al abrir el chat: mañana es el examen.
      final jueves = _cerebro(
        ahora: DateTime(2026, 10, 8, 9),
        memoria: memoria,
      );
      expect(_todo(jueves.alVolver()!), contains('Mañana es el parcial'));
      // Una sola vez por dia.
      expect(jueves.alVolver(), isNull);

      // El lunes: ¿cómo te fue?
      final lunes = _cerebro(
        ahora: DateTime(2026, 10, 12, 9),
        memoria: memoria,
      );
      expect(
        _todo(lunes.alVolver()!),
        contains('¿Cómo te fue en el parcial de cálculo'),
      );
      expect(_todo(lunes.escribir('bien!')), contains('Felicidades'));
      expect(memoria.examenes.single.preguntado, isTrue);
    });

    test('un examen sin fecha pregunta cuando es', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(
        _todo(cerebro.escribir('tengo examen de fisica')),
        contains('¿Cuándo es?'),
      );
      cerebro.escribir('el lunes');
      expect(memoria.examenes.single.materia, 'física');
      expect(memoria.examenes.single.fecha, DateTime(2026, 10, 12));
    });

    test('recordatorios: se anotan, se cuentan y se recuerdan', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(
        _todo(
          cerebro.escribir('recuérdame comprar las fotocopias de mi clase'),
        ),
        contains('comprar las fotocopias de tu clase'),
      );
      expect(
        _todo(cerebro.escribir('que te pedi que recordaras')),
        contains('fotocopias'),
      );
      final manana = _cerebro(
        ahora: DateTime(2026, 10, 8, 9),
        memoria: memoria,
      );
      expect(_todo(manana.alVolver()!), contains('me pediste que te recuerde'));
      manana.escribir('ya lo hice');
      expect(memoria.notas, isEmpty);
    });

    test('cumpleaños: lo anota y ese dia saluda una vez', () {
      final memoria = MemoriaMacias();
      _cerebro(memoria: memoria).escribir('mi cumpleaños es el 3 de mayo');
      expect((memoria.cumpleMes, memoria.cumpleDia), (5, 3));
      final ese = _cerebro(ahora: DateTime(2027, 5, 3, 10), memoria: memoria);
      expect(_todo(ese.alVolver()!), contains('¡Feliz cumpleaños'));
      expect(ese.alVolver(), isNull);
      expect(
        _todo(
          _cerebro(
            memoria: memoria,
          ).escribir('cuanto falta para mi cumpleaños'),
        ),
        contains('**208 días**'),
      );
    });

    test('nacio en un año: tambien sabe su edad', () {
      final memoria = MemoriaMacias();
      _cerebro(memoria: memoria).escribir('naci el 3 de abril de 2005');
      expect(memoria.edad, 21);
    });

    test('edad, ciudad y favoritos', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria)
        ..escribir('tengo 20 años')
        ..escribir('soy camba')
        ..escribir('mi color favorito es el azul');
      expect(memoria.edad, 20);
      expect(memoria.ciudad, 'Santa Cruz');
      expect(memoria.favoritos['color'], 'el azul');
      expect(
        _todo(cerebro.escribir('cual es mi color favorito')),
        contains('el azul'),
      );
      expect(_todo(cerebro.escribir('de donde soy')), contains('Santa Cruz'));
    });

    test('se acuerda de como se llaman su mascota y su gente', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(
        cerebro.escribir('mi perro se llama rocky').intencion,
        'memoria:persona',
      );
      cerebro.escribir('tengo una gata que se llama Luna');
      cerebro.escribir('mi mejor amiga se llama Valeria');
      expect(memoria.personas, {
        'perro': 'Rocky',
        'gata': 'Luna',
        'mejor amiga': 'Valeria',
      });
      expect(
        _todo(cerebro.escribir('como se llama mi gata?')),
        contains('Luna'),
      );
      expect(
        _todo(cerebro.escribir('como se llama mi novia')),
        contains('No me lo dijiste'),
      );
      // Y si esta triste, se acuerda de la mascota.
      expect(_todo(cerebro.escribir('estoy triste')), contains('Rocky'));
    });

    test('donde trabaja', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      cerebro.escribir('trabajo en una tienda de ropa');
      expect(memoria.trabajo, 'en una tienda de ropa');
      expect(
        _todo(cerebro.escribir('donde trabajo?')),
        contains('en una tienda de ropa'),
      );
      // "Trabajo de matemática" es un trabajo práctico, no un empleo.
      final otra = MemoriaMacias();
      _cerebro(memoria: otra).escribir('trabajo de matematica');
      expect(otra.trabajo, isNull);
    });

    test('"¿qué me gusta?" no es un piropo', () {
      final cerebro = _cerebro(memoria: MemoriaMacias(gustos: ['la pizza']));
      expect(cerebro.escribir('que me gusta').intencion, 'memoria:recuerdo');
    });

    test('todo se guarda y se lee igual', () {
      final memoria = MemoriaMacias(
        nombre: 'Ana',
        carrera: 'Derecho',
        gustos: ['la pizza'],
        disgustos: ['el surazo'],
        favoritos: {'color': 'el azul'},
        edad: 20,
        cumpleMes: 5,
        cumpleDia: 3,
        ciudad: 'Cochabamba',
        examenes: [
          ExamenMacias(
            materia: 'cálculo',
            fecha: DateTime(2026, 10, 9),
            tipo: 'parcial',
          ),
        ],
        notas: ['comprar fotocopias'],
        personas: {'perro': 'Rocky'},
        trabajo: 'en una tienda',
      );
      final leida = MemoriaMacias.desdeJson(memoria.aJson());
      expect(leida.aJson(), memoria.aJson());
      expect(leida.examenes.single.nombre, 'el parcial de cálculo');
    });

    test('"olvida todo" borra todo', () {
      final memoria = MemoriaMacias(
        nombre: 'Ana',
        edad: 20,
        notas: ['algo'],
        favoritos: {'color': 'azul'},
      );
      _cerebro(memoria: memoria).escribir('olvida todo');
      expect(memoria.vacia, isTrue);
    });

    test('"¿qué sabes de mí?" cuenta todo lo que sabe', () {
      final memoria = MemoriaMacias(
        nombre: 'Ana',
        ciudad: 'Tarija',
        edad: 22,
        notas: ['llevar la calculadora'],
      );
      final texto = _todo(
        _cerebro(memoria: memoria).escribir('que sabes de mi'),
      );
      expect(
        texto,
        allOf(
          contains('Ana'),
          contains('Tarija'),
          contains('22 años'),
          contains('llevar la calculadora'),
        ),
      );
    });
  });

  group('lenguaje', () {
    test('normaliza como se escribe en un chat', () {
      expect(LenguajeMacias.normalizar('HOLAAAA!!'), 'hola');
      expect(LenguajeMacias.normalizar('jajajaja'), 'jaja');
      expect(LenguajeMacias.normalizar('jsjsjs'), 'jaja');
      expect(LenguajeMacias.normalizar('xD'), 'jaja');
      expect(LenguajeMacias.palabrasDe(LenguajeMacias.normalizar('graciass')), [
        'gracias',
      ]);
      expect(LenguajeMacias.normalizar('gauss'), 'gauss');
      expect(LenguajeMacias.normalizar('css'), 'css');
      expect(LenguajeMacias.normalizar('siii'), 'si');
      // Lo que no hay que tocar.
      expect(LenguajeMacias.normalizar('1000'), '1000');
      expect(LenguajeMacias.normalizar('hijo'), 'hijo');
      expect(LenguajeMacias.normalizar('poo'), 'poo');
      expect(LenguajeMacias.normalizar('app'), 'app');
      expect(LenguajeMacias.normalizar('perro'), 'perro');
    });

    test('dice de vuelta lo que se le pidio recordar', () {
      expect(
        LenguajeMacias.reflejar(
          'comprar mis fotocopias y estudiar con mi grupo',
        ),
        'comprar tus fotocopias y estudiar con tu grupo',
      );
      expect(LenguajeMacias.reflejar('que tengo examen'), 'que tienes examen');
    });
  });
}
