import 'dart:collection';
import 'dart:math';

/// Cuando habla MacIAs en la mesa.
enum MomentoCrupier {
  bienvenida,
  bienvenidaDeVuelta,
  apuestaFuerte,
  todo,
  reparto,
  seguroOfrecido,
  seguroTomado,
  seguroGanado,
  seguroPerdido,
  blackjack,
  blackjackCrupier,
  veintiuno,
  tePasaste,
  mePase,
  ganaste,
  ganasteDoblando,
  perdiste,
  empate,
  rendido,
  doblar,
  dividir,
  racha,
  rachaLarga,
  barajar,
  quiebra,
  rescate,
  pidesConMucho,
  cincoCartas,
}

/// Lo que dice MacIAs repartiendo: con onda, sin repetirse.
///
/// Cada momento tiene varias frases, y no se vuelve a decir ninguna de las
/// ultimas veinte: en una mesa de verdad nadie dice lo mismo cada mano.
/// "{n}" se cambia por el nombre de quien juega.
class FrasesCrupier {
  FrasesCrupier({Random? azar, this.nombre = ''}) : _azar = azar ?? Random();

  final Random _azar;
  final String nombre;
  final _recientes = Queue<String>();

  String decir(MomentoCrupier momento) {
    final todas = frases[momento]!;
    final nuevas = [
      for (final frase in todas)
        if (!_recientes.contains(frase)) frase,
    ];
    final elegida = (nuevas.isEmpty
        ? todas
        : nuevas)[_azar.nextInt((nuevas.isEmpty ? todas : nuevas).length)];
    _recientes.addLast(elegida);
    while (_recientes.length > 20) {
      _recientes.removeFirst();
    }
    final quien = nombre.trim();
    return elegida
        .replaceAll(', {n}', quien.isEmpty ? '' : ', $quien')
        .replaceAll('{n}', quien.isEmpty ? 'crack' : quien);
  }

  static const frases = <MomentoCrupier, List<String>>{
    MomentoCrupier.bienvenida: [
      'Bienvenido a mi mesa, {n}. Hoy reparto yo, con traje y todo.',
      'Pasa, {n}. Seis mazos, bien barajados. Que empiece el show.',
      'Mesa secreta abierta. Nadie sabe que existe, así que no le cuentes a '
          'nadie.',
      'Me puse el traje solo para ti, {n}. Haz tu apuesta.',
      'Bienvenido al casino más chico de Santa Cruz: cabe en tu bolsillo.',
      'Llegaste, {n}. Las fichas son de mentira, pero la emoción no.',
    ],
    MomentoCrupier.bienvenidaDeVuelta: [
      'Volviste, {n}. Sabía que no ibas a aguantar.',
      '¿Otra vez por acá? Tus fichas te estaban esperando.',
      'La mesa te extrañaba, {n}. Yo también, un poquito.',
      'De vuelta en la mesa. ¿Revancha o racha?',
      'Te guardé el asiento, {n}. Apuesta cuando quieras.',
    ],
    MomentoCrupier.apuestaFuerte: [
      'Uy, apuesta fuerte. Me gusta tu estilo.',
      'Eso sí es apostar. A ver qué dicen las cartas.',
      'Fichas grandes, nervios grandes. Vamos.',
      'Hoy vienes con todo, {n}. Respeto.',
      'Con esa apuesta hasta yo me puse nervioso. Y eso que soy de código.',
    ],
    MomentoCrupier.todo: [
      '¿Todo? Valiente. O loco. Pronto lo sabremos.',
      'All in, {n}. Esto se pone serio.',
      'Todo al centro. Que la suerte te encuentre.',
      'Todas las fichas en la mesa. Nadie respira.',
    ],
    MomentoCrupier.reparto: [
      'Cartas van.',
      'Reparto. Suerte, {n}.',
      'Ahí van tus cartas.',
      'Que sean buenas.',
      'Veamos qué te toca.',
      'Una para ti, una para mí...',
      'Las cartas no mienten. Veamos.',
      'Mucha suerte, aunque me toque perder.',
      'Atento, que reparto rápido.',
      'Este sabot huele a blackjack.',
    ],
    MomentoCrupier.seguroOfrecido: [
      'Muestro un As. ¿Quieres seguro?',
      'Uy, un As. ¿Te aseguras por si tengo blackjack?',
      'As a la vista. El seguro paga 2 a 1. Tú decides.',
      'Tengo un As arriba. ¿Seguro o te la juegas?',
    ],
    MomentoCrupier.seguroTomado: [
      'Asegurado. Veamos si hacía falta.',
      'Seguro puesto. Espío mi carta...',
      'Precavido. Me gusta. Reviso mi carta.',
    ],
    MomentoCrupier.seguroGanado: [
      'Tenía blackjack, pero el seguro te salvó. Buena lectura.',
      'Blackjack mío... y tu seguro cobra. Bien jugado.',
      'El seguro valió la pena esta vez.',
    ],
    MomentoCrupier.seguroPerdido: [
      'No tengo blackjack: el seguro se va. Seguimos.',
      'Tranqui, no tenía nada. El seguro se pierde, la mano sigue.',
      'Sin blackjack. Seguro perdido, pero la mano es tuya.',
    ],
    MomentoCrupier.blackjack: [
      '¡Blackjack! Paga 3 a 2. Hoy estás iluminado, {n}.',
      '¡BLACKJACK! As y figura, la mano perfecta.',
      '¡Blackjack, {n}! Eso no se enseña, se nace.',
      '¡Blackjack! Me dejaste sin palabras y sin fichas.',
      'As y diez: ¡blackjack! La casa paga con gusto. Bueno, con algo de gusto.',
      '¡Blackjack! Ese As vino directo de la UPSA.',
    ],
    MomentoCrupier.blackjackCrupier: [
      'Blackjack de la casa. Perdón, no lo planeé.',
      'Blackjack mío. La casa también tiene sus días.',
      'As y figura para mí. Lo siento, {n}.',
      'Blackjack del crupier. Ni yo me lo esperaba.',
    ],
    MomentoCrupier.veintiuno: [
      'Veintiuno clavado.',
      '¡21! Ni uno más, ni uno menos.',
      'Veintiuno. Eso es precisión de ingeniero.',
      '21 justito. Ahora me toca sufrir a mí.',
    ],
    MomentoCrupier.tePasaste: [
      'Te pasaste. Le pasa hasta al mejor.',
      'Uf, te pasaste. La próxima es tuya.',
      'Pasado de 21. Las cartas son crueles a veces.',
      'Te pasaste, {n}. Respira y vamos de nuevo.',
      'Se te fue de las manos. Literal.',
      'Ese era un 10 escondido. Pasa.',
    ],
    MomentoCrupier.mePase: [
      'Me pasé. Hoy no es mi día.',
      '¡Me pasé! Las fichas son tuyas.',
      'Me pasé de 21. Qué vergüenza, con traje y todo.',
      'Me volé. Cobra, {n}.',
      'Me pasé. Esto no lo vio nadie, ¿ok?',
    ],
    MomentoCrupier.ganaste: [
      'Ganaste. Me la cobraste.',
      'Mano tuya, {n}. Bien jugada.',
      'Ganaste. Ya me estoy arrepintiendo de abrir esta mesa.',
      'Para ti. Así se juega.',
      'Ganaste limpito.',
      'Tuya. Ni modo, la casa paga.',
      'Ganaste, {n}. Sigue así y me dejas sin trabajo.',
    ],
    MomentoCrupier.ganasteDoblando: [
      'Doblaste y ganaste. Eso es tener visión.',
      'Dobló y cobró doble. Qué jugada, {n}.',
      'Apostaste más en el momento justo. De manual.',
    ],
    MomentoCrupier.perdiste: [
      'La casa gana... esta vez.',
      'Mano para la casa. Ya vendrá la tuya.',
      'Perdiste esta, {n}. La próxima la rompes.',
      'Esta fue mía. Sin rencores.',
      'La casa cobra. Pero la noche es joven.',
      'Me tocó ganar a mí. Perdón, es mi trabajo.',
    ],
    MomentoCrupier.empate: [
      'Empate. Nadie llora.',
      'Empate: tus fichas vuelven a casa.',
      'Mismo total. Quedamos a mano.',
      'Empatamos. Ni tú ni yo.',
    ],
    MomentoCrupier.rendido: [
      'Te rendiste. A veces retirarse también es estrategia.',
      'Rendición aceptada: la mitad vuelve a tus fichas.',
      'Bien visto. Esa mano no pintaba.',
    ],
    MomentoCrupier.doblar: [
      'Doblando... eso es confianza.',
      'Doble apuesta, una sola carta. A ver...',
      'Dobla, {n}. Me gusta el riesgo calculado.',
      'Doblaste. Que venga una figura.',
    ],
    MomentoCrupier.dividir: [
      'Dos manos, el doble de emoción.',
      'Dividido. Ahora juegas por partida doble.',
      'Separando el par. Buena idea.',
      'Dos manos, {n}. Vamos una por una.',
    ],
    MomentoCrupier.racha: [
      'Tres seguidas. ¿Me estás contando cartas?',
      'Vas en racha, {n}. No me gusta nada.',
      'Otra más. ¿Quién te enseñó a jugar así?',
      'Racha caliente. Alguien llame a seguridad.',
    ],
    MomentoCrupier.rachaLarga: [
      'Cinco seguidas. Ya me estoy preocupando en serio.',
      'Esa racha no es normal, {n}. Te estoy mirando.',
      'Racha histórica. Mi jefe me va a despedir.',
    ],
    MomentoCrupier.barajar: [
      'Salió la carta de corte: barajo el sabot.',
      'Toca barajar. Seis mazos, bien mezclados.',
      'Nuevo sabot. Cartas frescas, suerte nueva.',
      'Barajando... nada de trampas en esta mesa.',
    ],
    MomentoCrupier.quiebra: [
      'Te quedaste sin fichas. La casa te invita otras 1000.',
      'Cero fichas. Tranqui, aquí nadie se va con las manos vacías.',
      'Sin fichas, {n}. Te presto 1000, por buena onda.',
    ],
    MomentoCrupier.rescate: [
      'Ahí tienes 1000 fichas. Esta vez, con calma.',
      'Préstamo aprobado. Sin intereses: es MacIAs Bank.',
      'Fichas nuevas. A remontar, {n}.',
    ],
    MomentoCrupier.pidesConMucho: [
      '¿Pides con eso? Valiente.',
      'Uy, ¿otra carta con esa mano? Tú sabrás.',
      'Pedir ahí es de los que viven al límite.',
    ],
    MomentoCrupier.cincoCartas: [
      'Cinco cartas y sin pasarte. Qué mano.',
      'Eso parece un abanico, {n}. Y sigues vivo.',
    ],
  };
}
