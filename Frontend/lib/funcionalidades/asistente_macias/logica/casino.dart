/// Lo que comparten todos los juegos del casino de MacIAs.
///
/// Las fichas son de juego: no valen dinero, no se compran ni se cobran.
/// Son las mismas en todas las mesas: lo que se gana en la ruleta se puede
/// apostar en el blackjack.
abstract final class Casino {
  /// Las fichas de regalo: al entrar por primera vez y cada vez que MacIAs
  /// presta porque no queda nada.
  static const fichasIniciales = 1000;

  /// Las fichas del rack, de menor a mayor.
  static const valoresFichas = [10, 50, 100, 500, 1000];
}
