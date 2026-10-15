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

/// Lo que dice MacIAs en la entrada del casino.
class FrasesLobby extends _Frases<MomentoLobby> {
  FrasesLobby({super.azar, super.nombre}) : super(frases);

  static const frases = <MomentoLobby, List<String>>{
    MomentoLobby.bienvenida: [
      'Bienvenido a mi casino, {n}. Las fichas van por mi cuenta. '
          '¿Qué jugamos?',
      'Pasa, {n}. Ruleta, blackjack, y pronto póker. Tú eliges.',
      'Encontraste el casino escondido. Elige una mesa, {n}.',
    ],
    MomentoLobby.bienvenidaDeVuelta: [
      'Volviste, {n}. Tus fichas siguen acá. ¿Qué jugamos?',
      'De vuelta en el casino. ¿Ruleta o blackjack?',
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
      'El póker lo estoy armando: mesas de hasta 6, con otros de la U. '
          'Muy pronto.',
      'Todavía estoy barajando el póker. Mientras, ¿ruleta o blackjack?',
    ],
  };
}
