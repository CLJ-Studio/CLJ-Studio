import 'dart:collection';
import 'dart:math';

/// Cuando habla MacIAs en la ruleta.
enum MomentoRuleta {
  bienvenida,
  bienvenidaDeVuelta,
  hagan,
  noVaMas,
  apuestaFuerte,
  todo,
  ganaste,
  recuperaste,
  granPremio,
  pleno,
  perdiste,
  cero,
  ceroGanado,
  racha,
  quiebra,
  rescate,
}

/// Cuando habla MacIAs en la pesca.
enum MomentoPesca {
  bienvenida,
  bienvenidaDeVuelta,
  noVaMas,
  apuestaFuerte,
  todo,
  nieve,
  sinNada,
  moneda,
  bono,
  pescaChica,
  pescaGrande,
  noLeApostaste,
  ganaste,
  recuperaste,
  conBola,
  granPremio,
  perdiste,
  racha,
  quiebra,
  rescate,
}

/// Cuando habla MacIAs en la entrada del casino.
enum MomentoLobby {
  bienvenida,
  bienvenidaDeVuelta,
  ganoAlgo,
  perdioAlgo,
  poker,
}

/// Frases de un momento, sin repetirse: no vuelve a decir ninguna de las
/// ultimas quince. "{n}" se cambia por el nombre de quien juega.
class _Frases<T extends Enum> {
  _Frases(this._todas, {Random? azar, this.nombre = ''})
    : _azar = azar ?? Random();

  final Map<T, List<String>> _todas;
  final Random _azar;
  final String nombre;
  final _recientes = Queue<String>();

  String decir(T momento) {
    final todas = _todas[momento]!;
    final nuevas = [
      for (final frase in todas)
        if (!_recientes.contains(frase)) frase,
    ];
    final opciones = nuevas.isEmpty ? todas : nuevas;
    final elegida = opciones[_azar.nextInt(opciones.length)];
    _recientes.addLast(elegida);
    while (_recientes.length > 15) {
      _recientes.removeFirst();
    }
    final quien = nombre.trim();
    return elegida
        .replaceAll(', {n}', quien.isEmpty ? '' : ', $quien')
        .replaceAll('{n}', quien.isEmpty ? 'crack' : quien);
  }
}

/// Lo que dice MacIAs en la ruleta. Cortito: la caja de dialogo de la
/// ruleta es angosta (la rueda ocupa la otra mitad).
class FrasesRuleta extends _Frases<MomentoRuleta> {
  FrasesRuleta({super.azar, super.nombre}) : super(frases);

  static const frases = <MomentoRuleta, List<String>>{
    MomentoRuleta.bienvenida: [
      'Bienvenido a la ruleta, {n}. Elige ficha y apuesta.',
      'Rueda europea, un solo cero. Hagan sus apuestas.',
      'Pasa, {n}. La bola ya está lustrada.',
      'Mi ruleta, {n}: 37 números y uno es tuyo.',
    ],
    MomentoRuleta.bienvenidaDeVuelta: [
      'Volviste, {n}. La bola te extrañaba.',
      '¿Otra vuelta, {n}? Hagan sus apuestas.',
      'Tu número favorito te está esperando.',
    ],
    MomentoRuleta.hagan: [
      'Hagan sus apuestas.',
      'Hagan juego, señores.',
      '¿Dónde caerá ahora? Apuesta.',
      'Otra vuelta. Fichas al paño.',
      'Hagan sus apuestas, {n}.',
    ],
    MomentoRuleta.noVaMas: [
      '¡No va más!',
      'No va más. Que gire.',
      '¡No va más! Ojos en la bola.',
      'Allá va... ¡no va más!',
    ],
    MomentoRuleta.apuestaFuerte: [
      'Uy, apuesta fuerte. Me gusta.',
      'Eso sí es apostar, {n}.',
      'Fichas grandes. Hasta yo me pongo nervioso.',
    ],
    MomentoRuleta.todo: [
      '¿Todo al paño? Valiente.',
      'Todas tus fichas en juego. Nadie respira.',
    ],
    MomentoRuleta.ganaste: [
      'Ganaste, {n}. Te pago.',
      'Bien jugado. Ahí van tus fichas.',
      'La bola te quiere hoy.',
      'Premio para ti. Yo pago, sin llorar.',
      'Ganaste. Ni modo, la casa paga.',
    ],
    MomentoRuleta.recuperaste: [
      'Algo se salva: te devuelvo una parte.',
      'No fue redondo, pero algo cobras.',
      'Cobras algo. Peor es nada.',
    ],
    MomentoRuleta.granPremio: [
      '¡Premio grande! Tráiganme más fichas.',
      '¡Uf! Casi me quiebras la banca, {n}.',
      'Eso fue un golpazo. Felicidades.',
    ],
    MomentoRuleta.pleno: [
      '¡Pleno! 35 a 1, {n}. Increíble.',
      '¡Le diste al número exacto! Pleno.',
      '¡PLENO! Esto no pasa todos los días.',
    ],
    MomentoRuleta.perdiste: [
      'Esta vez gana la casa.',
      'Casi, {n}. La próxima.',
      'La bola tenía otros planes.',
      'Se fue para el otro lado. Otra vuelta.',
      'Nada esta vez. La ruleta da y quita.',
    ],
    MomentoRuleta.cero: [
      '¡Cero! Todo para la casa. Perdón.',
      'El cero, el amigo de la banca.',
      'Salió el cero. Así es la ruleta.',
    ],
    MomentoRuleta.ceroGanado: [
      '¡Le apostaste al cero y salió! Crack.',
      'Nadie le cree al cero. Tú sí.',
    ],
    MomentoRuleta.racha: [
      'Racha, {n}. ¿Me estás leyendo la bola?',
      'Otra más. Voy a revisar esta rueda.',
      '{n} está imparable.',
    ],
    MomentoRuleta.quiebra: [
      'Sin fichas... Tranquilo, te presto.',
      'Se acabaron las fichas. Acá estoy yo.',
    ],
    MomentoRuleta.rescate: [
      'Ahí van 1.000 fichas. Esta va por mi cuenta.',
      'Te presto 1.000. Sin intereses, palabra.',
    ],
  };
}

/// Lo que dice MacIAs en la pesca. "{p}" es el pez y "{x}" lo que
/// multiplica: los pone la pantalla.
class FrasesPesca extends _Frases<MomentoPesca> {
  FrasesPesca({super.azar, super.nombre}) : super(frases);

  static const frases = <MomentoPesca, List<String>>{
    MomentoPesca.bienvenida: [
      'Bienvenido al lago, {n}. El hielo paga 1 a 1 y los peces, mucho más.',
      'Abrígate, {n}: acá se pesca sobre el hielo. Apuesta y giramos.',
      'Si la rueda para en un pez, salgo a pescarlo yo. Apuesta, {n}.',
    ],
    MomentoPesca.bienvenidaDeVuelta: [
      'Volviste al lago, {n}. Los peces siguen picando.',
      '¿Otra tarde de pesca, {n}? Apuesta y giramos.',
      'Te guardé la caña, {n}. ¿Hielo o peces?',
    ],
    MomentoPesca.noVaMas: [
      '¡No va más!',
      'No va más. A ver qué trae el lago.',
      '¡No va más! Ojo con la nieve.',
    ],
    MomentoPesca.apuestaFuerte: [
      'Uy, apuesta fuerte. Me gusta.',
      'Eso sí es apostar, {n}.',
      'Fichas grandes. Hasta el hielo cruje.',
    ],
    MomentoPesca.todo: [
      '¿Todo al lago? Valiente.',
      'Todas tus fichas en juego. Nadie respira.',
    ],
    MomentoPesca.nieve: [
      '¡Bolas de nieve! El hielo donde caen paga más.',
      'Caen bolas de nieve: si para ahí, paga lo que dice.',
      '¡Nieve! Ese hielo ya no paga 1 a 1.',
    ],
    MomentoPesca.sinNada: [
      'Esta vez sin nieve ni moneda. Gira igual.',
      'Ronda limpia: sin multiplicadores.',
      'Hoy no nieva. A girar.',
    ],
    MomentoPesca.moneda: [
      '¡Moneda de oro! Los {p} pagan {x}.',
      'La moneda cae en los {p}: lo que pesque, {x}.',
      '¡Oro para los {p}! Todo {x}.',
    ],
    MomentoPesca.bono: [
      '¡{p}! Salgo a pescar.',
      '¡Cayó en {p}! Agarro la caña.',
      '¡{p}! A ver qué tan grande es.',
    ],
    MomentoPesca.pescaChica: [
      'Un pescadito. Algo es algo.',
      'Chiquito, pero se cobra.',
      'Era una sardina. La próxima, más grande.',
    ],
    MomentoPesca.pescaGrande: [
      '¡Qué pez! Casi me lleva al agua.',
      '¡Monstruo! Esto no sale todos los días.',
      '¡Ni en mis mejores pescas, {n}!',
    ],
    MomentoPesca.noLeApostaste: [
      'Buen pez, pero no le apostaste. La próxima.',
      'Ese pez era tuyo... si le ponías una ficha.',
    ],
    MomentoPesca.ganaste: [
      'Ganaste, {n}. Te pago.',
      'Bien jugado. Ahí van tus fichas.',
      'El lago te quiere hoy.',
      'Premio para ti. Yo pago, sin llorar.',
    ],
    MomentoPesca.recuperaste: [
      'Algo se salva: te devuelvo una parte.',
      'No fue redondo, pero algo cobras.',
    ],
    MomentoPesca.conBola: [
      '¡Con bola de nieve! {x}, {n}.',
      '¡Y tenía nieve! Paga {x}.',
    ],
    MomentoPesca.granPremio: [
      '¡Premio grande! Tráiganme más fichas.',
      '¡Uf! Casi me quiebras la banca, {n}.',
      'Eso fue un golpazo. Felicidades.',
    ],
    MomentoPesca.perdiste: [
      'Esta vez gana la casa.',
      'Casi, {n}. La próxima.',
      'El hielo tenía otros planes.',
      'Se fue para el otro lado. Otra vuelta.',
    ],
    MomentoPesca.racha: [
      'Racha, {n}. ¿Le hablas a los peces?',
      'Otra más. Voy a revisar esta rueda.',
      '{n} está imparable.',
    ],
    MomentoPesca.quiebra: [
      'Sin fichas... Tranquilo, te presto.',
      'Se acabaron las fichas. Acá estoy yo.',
    ],
    MomentoPesca.rescate: [
      'Ahí van 1.000 fichas. Esta va por mi cuenta.',
      'Te presto 1.000. Sin intereses, palabra.',
    ],
  };
}

/// Lo que dice MacIAs en la entrada del casino.
class FrasesLobby extends _Frases<MomentoLobby> {
  FrasesLobby({super.azar, super.nombre}) : super(frases);

  static const frases = <MomentoLobby, List<String>>{
    MomentoLobby.bienvenida: [
      'Bienvenido a mi casino, {n}. Las fichas van por mi cuenta. '
          '¿Qué jugamos?',
      'Pasa, {n}. Ruleta, blackjack, póker o pesca en el hielo. Tú eliges.',
      'Encontraste el casino escondido. Elige una mesa, {n}.',
    ],
    MomentoLobby.bienvenidaDeVuelta: [
      'Volviste, {n}. Tus fichas siguen acá. ¿Qué jugamos?',
      'De vuelta en el casino. ¿Ruleta, blackjack o una pesca?',
      'Te guardé las fichas, {n}. Elige mesa.',
    ],
    MomentoLobby.ganoAlgo: [
      'Saliste ganando, {n}. ¿Otra mesa?',
      'Ganancia limpia. ¿Seguimos?',
      'Te vas con más fichas de las que trajiste. Bien ahí.',
    ],
    MomentoLobby.perdioAlgo: [
      'Hoy la casa ganó un poco. ¿Revancha?',
      'No pasa nada, {n}. Hay otra mesa esperando.',
      'Así es el juego. ¿Probamos en otra mesa?',
    ],
    MomentoLobby.poker: [
      'Póker con otros de la U: siéntate en una mesa o arma la tuya.',
      'En el póker reparto yo y nadie ve las cartas de nadie. Suerte.',
    ],
  };
}
