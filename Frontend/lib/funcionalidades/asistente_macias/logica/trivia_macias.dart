import '../modelos/mensaje_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';

/// Una pregunta de trivia: el enunciado, las tres opciones, cual es la
/// buena (0, 1 o 2) y una linea que explica.
typedef PreguntaTrivia = (
  String pregunta,
  List<String> opciones,
  int correcta,
  String explicacion,
);

/// Trivia de cultura general, con algo de Bolivia, ciencia y la U.
abstract final class TriviaMacias {
  static const _letras = ['A', 'B', 'C'];

  static const iniciar = [
    'trivia',
    'juguemos trivia',
    'juguemos a la trivia',
    'jugar trivia',
    'una trivia',
    'hazme un quiz',
    'juguemos un quiz',
    'preguntame algo',
    'hazme una pregunta',
    'hazme preguntas',
    'ponme a prueba',
    'preguntas de cultura general',
    'una pregunta de cultura general',
    'cultura general',
  ];

  /// Si pidieron trivia. Null si no.
  static RespuestaCharla? responder(String limpio, ContextoMacias c) {
    if (!iniciar.contains(limpio)) return null;
    return pregunta(c);
  }

  /// Una pregunta que no se haya hecho hace poco.
  static RespuestaCharla pregunta(ContextoMacias c) {
    final disponibles = [
      for (final (i, p) in preguntas.indexed)
        if (!c.recientes.any((dicho) => dicho.contains(p.$1))) i,
    ];
    final indices = disponibles.isEmpty
        ? [for (var i = 0; i < preguntas.length; i++) i]
        : disponibles;
    final indice = indices[c.sorteo % indices.length];
    final (enunciado, opciones, correcta, explicacion) = preguntas[indice];
    final lineas = [
      for (final (i, opcion) in opciones.indexed) '${_letras[i]}) $opcion',
    ].join('\n');
    return RespuestaCharla(
      '$enunciado\n\n$lineas\n\nResponde con la letra (o toca una opción).',
      intencion: 'juego:trivia',
      espera: EsperaTrivia(opciones, correcta, explicacion),
      opciones: [
        for (final (i, opcion) in opciones.indexed)
          OpcionMacias(id: 'o:trivia_$i', texto: '${_letras[i]}) $opcion'),
      ],
    );
  }

  /// Que opcion eligio: la letra, el numero o la respuesta escrita. Null si
  /// no se entiende.
  static int? elegida(String limpio, List<String> opciones) {
    final t = limpio
        .replaceFirst(
          RegExp(r'^(?:es |creo que |la |el |opcion |respuesta )+'),
          '',
        )
        .trim();
    const porLetra = {'a': 0, 'b': 1, 'c': 2, '1': 0, '2': 1, '3': 2};
    final letra = porLetra[t];
    if (letra != null) return letra;
    for (final (i, opcion) in opciones.indexed) {
      final normal = LenguajeMacias.normalizar(opcion);
      if (t == normal || (t.length >= 3 && normal.contains(t))) return i;
    }
    return null;
  }

  /// Lo que se dice despues de responder.
  static RespuestaCharla resultado(
    EsperaTrivia trivia,
    int? elegida,
    ContextoMacias c,
  ) {
    final buena =
        '${_letras[trivia.correcta]}) ${trivia.opciones[trivia.correcta]}';
    final inicio = elegida == null
        ? 'Era la **$buena**.'
        : elegida == trivia.correcta
        ? c.alguna(const ['¡Correcto!', '¡Eso! Bien ahí.', '¡Exacto!'])
        : 'Casi. Era la **$buena**.';
    return RespuestaCharla(
      '$inicio ${trivia.explicacion}\n\n¿Otra?',
      intencion: 'juego:trivia',
      espera: const EsperaSiNo('trivia'),
      opciones: const [
        OpcionMacias(id: 'o:juego_trivia', texto: 'Otra pregunta'),
      ],
    );
  }

  static const preguntas = <PreguntaTrivia>[
    (
      '¿Cuál es la capital constitucional de Bolivia?',
      ['La Paz', 'Sucre', 'Cochabamba'],
      1,
      'Sucre es la capital constitucional; La Paz, la sede de gobierno.',
    ),
    (
      '¿Cuántos departamentos tiene Bolivia?',
      ['7', '9', '12'],
      1,
      'Son 9, cada uno con su capital.',
    ),
    (
      '¿En qué año se independizó Bolivia?',
      ['1810', '1825', '1852'],
      1,
      'El 6 de agosto de 1825.',
    ),
    (
      '¿Cuál es el desierto de sal más grande del mundo?',
      ['Salar de Atacama', 'Salar de Uyuni', 'Salinas Grandes'],
      1,
      'El Salar de Uyuni, en Potosí.',
    ),
    (
      '¿Qué día es el aniversario de Santa Cruz?',
      ['24 de septiembre', '6 de agosto', '16 de julio'],
      0,
      'El 24 de septiembre. El 16 de julio es el de La Paz.',
    ),
    (
      '¿En qué ciudad está el Cerro Rico?',
      ['Oruro', 'Potosí', 'Sucre'],
      1,
      'En Potosí: su plata fue una de las más famosas del mundo.',
    ),
    (
      '¿Qué danza es la estrella del Carnaval de Oruro?',
      ['Taquirari', 'Diablada', 'Cueca'],
      1,
      'La Diablada.',
    ),
    (
      '¿Cuál es el lago navegable más alto del mundo?',
      ['Titicaca', 'Poopó', 'Victoria'],
      0,
      'El Titicaca, a unos 3800 metros, entre Bolivia y Perú.',
    ),
    (
      '¿Por qué metal es famosa Bolivia en el mundo de las baterías?',
      ['Cobre', 'Litio', 'Hierro'],
      1,
      'El litio: Bolivia tiene una de las reservas más grandes del planeta.',
    ),
    (
      '¿Qué planeta es el más grande del sistema solar?',
      ['Saturno', 'Júpiter', 'Neptuno'],
      1,
      'Júpiter: le entrarían más de mil Tierras.',
    ),
    (
      '¿Cuál es el planeta más cercano al Sol?',
      ['Venus', 'Mercurio', 'Marte'],
      1,
      'Mercurio.',
    ),
    (
      '¿Cuántos huesos tiene un adulto?',
      ['186', '206', '300'],
      1,
      '206. Los bebés nacen con unos 300, que se van uniendo.',
    ),
    (
      '¿Cuál es el hueso más largo del cuerpo?',
      ['Fémur', 'Húmero', 'Tibia'],
      0,
      'El fémur, el del muslo.',
    ),
    (
      '¿Cuál es el símbolo químico del oro?',
      ['Ag', 'Au', 'Or'],
      1,
      'Au, del latín aurum. Ag es la plata.',
    ),
    (
      '¿Qué gas absorben las plantas en la fotosíntesis?',
      ['Oxígeno', 'Dióxido de carbono', 'Nitrógeno'],
      1,
      'El CO2: lo toman del aire y liberan oxígeno.',
    ),
    (
      '¿Cuál es la fórmula del agua?',
      ['H2O', 'CO2', 'O2'],
      0,
      'H2O: dos hidrógenos y un oxígeno.',
    ),
    (
      '¿A qué velocidad viaja la luz, más o menos?',
      ['300 000 km/s', '30 000 km/s', '3000 km/s'],
      0,
      'Unos 300 000 km por segundo en el vacío.',
    ),
    (
      '¿Qué vitamina produce tu piel con el sol?',
      ['Vitamina C', 'Vitamina D', 'Vitamina A'],
      1,
      'La vitamina D.',
    ),
    (
      '¿Cuántas patas tiene una araña?',
      ['6', '8', '10'],
      1,
      '8. Por eso no es un insecto: los insectos tienen 6.',
    ),
    (
      '¿Cuál es el animal terrestre más rápido?',
      ['León', 'Guepardo', 'Caballo'],
      1,
      'El guepardo, que pasa los 100 km/h en carreras cortas.',
    ),
    (
      '¿Cuál es el océano más grande?',
      ['Atlántico', 'Índico', 'Pacífico'],
      2,
      'El Pacífico.',
    ),
    (
      '¿En qué país están las pirámides de Giza?',
      ['México', 'Egipto', 'Perú'],
      1,
      'En Egipto, cerca de El Cairo.',
    ),
    ('¿Cuál es la capital de Japón?', ['Pekín', 'Tokio', 'Seúl'], 1, 'Tokio.'),
    (
      '¿Quién pintó la Mona Lisa?',
      ['Miguel Ángel', 'Leonardo da Vinci', 'Rafael'],
      1,
      'Leonardo da Vinci, a principios del siglo XVI.',
    ),
    (
      '¿Quién escribió Don Quijote de la Mancha?',
      ['Lope de Vega', 'Miguel de Cervantes', 'Gabriel García Márquez'],
      1,
      'Miguel de Cervantes.',
    ),
    (
      '¿Qué filósofo dijo "pienso, luego existo"?',
      ['Descartes', 'Platón', 'Kant'],
      0,
      'René Descartes.',
    ),
    (
      '¿Quién es considerado el padre del psicoanálisis?',
      ['Carl Jung', 'Sigmund Freud', 'Jean Piaget'],
      1,
      'Sigmund Freud.',
    ),
    (
      '¿Quién propuso la teoría de la relatividad?',
      ['Isaac Newton', 'Albert Einstein', 'Galileo Galilei'],
      1,
      'Albert Einstein: la especial en 1905 y la general en 1915.',
    ),
    (
      '¿Quién fue el primer ser humano en pisar la Luna?',
      ['Yuri Gagarin', 'Neil Armstrong', 'Buzz Aldrin'],
      1,
      'Neil Armstrong, en 1969. Gagarin fue el primero en el espacio.',
    ),
    (
      '¿Cuánto es 7 × 8?',
      ['54', '56', '64'],
      1,
      '56. El clásico que todos dudan.',
    ),
    (
      '¿Cuánto es la raíz cuadrada de 144?',
      ['12', '14', '16'],
      0,
      '12, porque 12 × 12 = 144.',
    ),
    (
      '¿Cuántos lados tiene un hexágono?',
      ['5', '6', '8'],
      1,
      '6, como las celdas de un panal.',
    ),
    (
      '¿Qué número romano es la X?',
      ['5', '10', '50'],
      1,
      '10. V es 5 y L es 50.',
    ),
    (
      '¿Cuántos minutos tiene un día?',
      ['1240', '1440', '1640'],
      1,
      '24 × 60 = 1440.',
    ),
    ('¿Cuántos bits tiene un byte?', ['4', '8', '16'], 1, '8 bits.'),
    (
      '¿Qué lenguaje creó Bjarne Stroustrup?',
      ['Java', 'Python', 'C++'],
      2,
      'C++, a principios de los 80. Al comienzo se llamaba "C con clases".',
    ),
    (
      '¿Qué significa "www" en una dirección web?',
      ['World Wide Web', 'Web World Wide', 'Wide World Web'],
      0,
      'World Wide Web, la red que inventó Tim Berners-Lee.',
    ),
    (
      '¿De qué país es originario el sushi?',
      ['China', 'Japón', 'Corea'],
      1,
      'De Japón.',
    ),
    (
      '¿Cuántos jugadores tiene un equipo de fútbol en la cancha?',
      ['10', '11', '12'],
      1,
      '11, contando al arquero.',
    ),
    (
      '¿Con qué se hace el api morado?',
      ['Maíz morado', 'Arroz', 'Quinua'],
      0,
      'Con harina de maíz morado, canela y clavo de olor.',
    ),
  ];
}
