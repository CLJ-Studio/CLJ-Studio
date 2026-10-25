import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/coreografia_poker.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/mesa_poker.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/sonidos_casino.dart';

/// La mesa se dibuja siempre con el ultimo estado del servidor; la
/// coreografia tapa por un rato lo que todavia esta volando. Estas pruebas
/// miran que vuele lo que tiene que volar, en orden, y que al final no quede
/// nada tapado.
final _hora = DateTime.utc(2026, 10, 25, 15);

Map<String, dynamic> _asiento(int posicion, int fichas) => {
  'posicion': posicion,
  'usuario_id': 'u$posicion',
  'nombre': posicion == 0 ? 'Ana Perez' : 'Beto Rojas',
  'avatar_path': null,
  'fichas': fichas,
  'afuera': false,
};

Map<String, dynamic> _jugador(
  int posicion, {
  int ronda = 0,
  int aportado = 0,
  bool retirado = false,
  String? accion,
  List<String>? vistas,
  int? valor,
}) => {
  'posicion': posicion,
  'usuario_id': 'u$posicion',
  'apuesta_ronda': ronda,
  'aportado': aportado,
  'retirado': retirado,
  'todo': false,
  'ultima_accion': accion,
  'cartas_vistas': vistas,
  'valor': valor,
};

Map<String, dynamic> _mano({
  String id = 'm1',
  String fase = 'preflop',
  int? turno = 0,
  int apuesta = 20,
  int bote = 30,
  List<String> comunitarias = const [],
  List<Map<String, int>>? resultado,
}) => {
  'id': id,
  'numero': 3,
  'boton': 1,
  'fase': fase,
  'comunitarias': comunitarias,
  'turno': fase == 'terminada' ? null : turno,
  'vence_en': fase == 'terminada'
      ? null
      : _hora.add(const Duration(seconds: 25)).toIso8601String(),
  'apuesta': apuesta,
  'subida_minima': 20,
  'bote': bote,
  'resultado': resultado,
  'terminada_en': fase == 'terminada' ? _hora.toIso8601String() : null,
};

EstadoMesaPoker _mesa({
  required int version,
  Map<String, dynamic>? mano,
  List<Map<String, dynamic>> jugadores = const [],
  List<String>? misCartas,
  List<Map<String, dynamic>>? asientos,
}) => EstadoMesaPoker.desdeMapa({
  'ahora': _hora.toIso8601String(),
  'sala': {
    'id': 's1',
    'nombre': 'Mesa',
    'ciega_chica': 10,
    'ciega_grande': 20,
    'fichas_iniciales': 1000,
    'segundos_turno': 30,
    'version': version,
  },
  'yo': 0,
  'asientos': asientos ?? [_asiento(0, 980), _asiento(1, 990)],
  'mano': mano,
  'jugadores': jugadores,
  'mis_cartas': misCartas,
});

/// La coreografia, anotando que sono y cada cosa que llego a volar.
({CoreografiaPoker c, List<SonidoMesa> sonidos, Map<int, VueloPoker> vuelos})
_coreografia() {
  final sonidos = <SonidoMesa>[];
  final vuelos = <int, VueloPoker>{};
  final c = CoreografiaPoker(
    sonar: (sonido, {volumen = 1}) => sonidos.add(sonido),
  );
  c.addListener(() {
    for (final v in c.vuelos) {
      vuelos[v.id] = v;
    }
  });
  return (c: c, sonidos: sonidos, vuelos: vuelos);
}

void main() {
  testWidgets('la primera vez no se anima nada', (tester) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    c.cambio(
      null,
      _mesa(
        version: 3,
        mano: _mano(),
        jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 10)],
        misCartas: ['As', 'Kd'],
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(vuelos, isEmpty);
    expect(sonidos, isEmpty);
    expect(c.oculto(CoreografiaPoker.carta(0, 0)), isFalse);
  });

  testWidgets('se reparte de a una, las mias boca arriba, y despues las '
      'ciegas', (tester) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    c.cambio(
      _mesa(version: 1),
      _mesa(
        version: 2,
        mano: _mano(),
        jugadores: [
          _jugador(0, ronda: 20, aportado: 20, accion: 'ciega_grande'),
          _jugador(1, ronda: 10, aportado: 10, accion: 'ciega_chica'),
        ],
        misCartas: ['As', 'Kd'],
      ),
    );

    // Todo tapado hasta que llega volando; las ciegas, todavia en cero.
    expect(c.oculto(CoreografiaPoker.carta(0, 0)), isTrue);
    expect(c.oculto(CoreografiaPoker.carta(1, 1)), isTrue);
    expect(c.valor(CoreografiaPoker.apuesta(0)), 0);
    expect(sonidos.first, SonidoMesa.barajar);

    await tester.pump(const Duration(milliseconds: 300));
    final primera = c.vuelos.single as VueloCarta;
    // Empieza el de la izquierda del boton (el boton es Beto, en el 1).
    expect((primera.hasta as EnMano).posicion, 0);
    expect(primera.codigo, 'As');
    expect(primera.bocaArriba, isTrue);

    await tester.pump(const Duration(seconds: 3));
    final cartas = vuelos.values.whereType<VueloCarta>().toList();
    final fichas = vuelos.values.whereType<VueloFichas>().toList();
    expect(cartas, hasLength(4));
    expect(
      [for (final v in cartas) (v.hasta as EnMano).posicion],
      [0, 1, 0, 1],
    );
    expect(cartas.where((v) => v.codigo != null), hasLength(2));
    expect({for (final v in fichas) v.monto}, {20, 10});
    expect(c.vuelos, isEmpty);
    expect(c.oculto(CoreografiaPoker.carta(1, 1)), isFalse);
    expect(c.valor(CoreografiaPoker.apuesta(0)), isNull);
    expect(c.enMovimiento, isFalse);
  });

  testWidgets('una apuesta va del asiento a su lugar', (tester) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    c.cambio(
      _mesa(
        version: 2,
        mano: _mano(turno: 1),
        jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 10)],
      ),
      _mesa(
        version: 3,
        mano: _mano(apuesta: 60, bote: 80),
        jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 60)],
      ),
    );

    // Mientras viaja, delante de Beto se ve lo de antes.
    expect(c.valor(CoreografiaPoker.apuesta(1)), 10);
    await tester.pump(const Duration(milliseconds: 1));
    final vuelo = c.vuelos.single as VueloFichas;
    expect(vuelo.monto, 50);
    expect((vuelo.desde as EnAsiento).posicion, 1);
    expect((vuelo.hasta as EnApuesta).posicion, 1);
    expect(sonidos, [SonidoMesa.ficha]);

    await tester.pump(const Duration(milliseconds: 600));
    expect(c.valor(CoreografiaPoker.apuesta(1)), isNull);
    expect(c.vuelos, isEmpty);
    expect(vuelos, hasLength(1));
  });

  testWidgets('se cierra la ronda: todo al bote y despues el flop', (
    tester,
  ) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    c.cambio(
      _mesa(
        version: 3,
        mano: _mano(apuesta: 40, bote: 80),
        jugadores: [
          _jugador(0, ronda: 40, aportado: 40),
          _jugador(1, ronda: 40, aportado: 40),
        ],
      ),
      _mesa(
        version: 4,
        mano: _mano(
          fase: 'flop',
          apuesta: 0,
          bote: 80,
          comunitarias: ['2c', '7d', 'Jh'],
        ),
        jugadores: [_jugador(0, aportado: 40), _jugador(1, aportado: 40)],
      ),
    );

    // El bote muestra lo de antes hasta que caen las fichas.
    expect(c.valor(CoreografiaPoker.bote), 0);
    for (var i = 0; i < 3; i++) {
      expect(c.oculto(CoreografiaPoker.comunitaria(i)), isTrue);
    }
    await tester.pump(const Duration(milliseconds: 1));
    expect(c.vuelos.whereType<VueloFichas>(), hasLength(2));
    expect(c.vuelos.every((v) => v.hasta is EnBote), isTrue);

    await tester.pump(const Duration(seconds: 3));
    final cartas = vuelos.values.whereType<VueloCarta>().toList();
    expect([for (final v in cartas) v.codigo], ['2c', '7d', 'Jh']);
    expect(cartas.every((v) => v.bocaArriba), isTrue);
    expect(sonidos, containsAll([SonidoMesa.fichas, SonidoMesa.voltear]));
    expect(c.valor(CoreografiaPoker.bote), isNull);
    expect(c.oculto(CoreografiaPoker.comunitaria(2)), isFalse);
    expect(c.enMovimiento, isFalse);
  });

  testWidgets('al final se dan vuelta las cartas y el bote va al que gano', (
    tester,
  ) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    final comunes = ['Ks', '3c', '3d', '9s', '2h'];
    c.cambio(
      _mesa(
        version: 7,
        mano: _mano(
          fase: 'river',
          apuesta: 100,
          bote: 340,
          comunitarias: comunes,
        ),
        jugadores: [
          _jugador(0, ronda: 0, aportado: 170),
          _jugador(1, ronda: 100, aportado: 170),
        ],
        misCartas: ['Ah', 'Qh'],
        asientos: [_asiento(0, 830), _asiento(1, 830)],
      ),
      _mesa(
        version: 8,
        mano: _mano(
          fase: 'terminada',
          apuesta: 100,
          bote: 440,
          comunitarias: comunes,
          resultado: [
            {'posicion': 1, 'monto': 440},
          ],
        ),
        jugadores: [
          _jugador(
            0,
            ronda: 100,
            aportado: 270,
            vistas: ['Ah', 'Qh'],
            valor: 1,
          ),
          _jugador(
            1,
            ronda: 100,
            aportado: 270,
            vistas: ['Kh', 'Kd'],
            valor: 2,
          ),
        ],
        misCartas: ['Ah', 'Qh'],
        asientos: [_asiento(0, 730), _asiento(1, 1270)],
      ),
    );

    // Quien gano y con que se ve recien cuando le llegan las fichas.
    expect(c.oculto(CoreografiaPoker.resultado), isTrue);
    expect(c.oculto(CoreografiaPoker.vistas(1)), isTrue);
    expect(c.oculto(CoreografiaPoker.vistas(0)), isFalse, reason: 'las mias');

    await tester.pump(const Duration(milliseconds: 900));
    expect(c.oculto(CoreografiaPoker.vistas(1)), isFalse);
    expect(sonidos, contains(SonidoMesa.voltear));

    // El bote sale hacia Beto; su pila muestra lo de antes hasta que llega.
    await tester.pump(const Duration(milliseconds: 1000));
    final pago = vuelos.values
        .whereType<VueloFichas>()
        .where((v) => v.desde is EnBote)
        .single;
    expect(pago.monto, 440);
    expect((pago.hasta as EnAsiento).posicion, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(c.oculto(CoreografiaPoker.resultado), isFalse);
    expect(c.valor(CoreografiaPoker.fichas(1)), isNull);
    expect(sonidos, contains(SonidoMesa.cobrar));
    expect(sonidos, isNot(contains(SonidoMesa.ganar)), reason: 'gano Beto');
    expect(c.enMovimiento, isFalse);
  });

  testWidgets('quien se retira tira sus cartas al centro', (tester) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    c.cambio(
      _mesa(
        version: 3,
        mano: _mano(turno: 1),
        jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 10)],
      ),
      _mesa(
        version: 4,
        mano: _mano(turno: 0),
        jugadores: [
          _jugador(0, ronda: 20),
          _jugador(1, ronda: 10, retirado: true, accion: 'retirarse'),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final tiradas = vuelos.values.whereType<VueloCarta>().toList();
    expect(tiradas, hasLength(2));
    expect(tiradas.every((v) => v.desvanecer && v.hasta is EnDescarte), isTrue);
  });

  testWidgets('si llega otro estado, lo que volaba se corta', (tester) async {
    final (:c, :sonidos, :vuelos) = _coreografia();
    addTearDown(c.dispose);
    final antes = _mesa(
      version: 2,
      mano: _mano(turno: 1),
      jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 10)],
    );
    final ahora = _mesa(
      version: 3,
      mano: _mano(apuesta: 60, bote: 80),
      jugadores: [_jugador(0, ronda: 20), _jugador(1, ronda: 60)],
    );
    c.cambio(antes, ahora);
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.vuelos, isNotEmpty);

    // Ana iguala enseguida: lo de Beto queda en su lugar, sin esperar.
    c.cambio(
      ahora,
      _mesa(
        version: 4,
        mano: _mano(apuesta: 60, bote: 120, turno: 1),
        jugadores: [_jugador(0, ronda: 60), _jugador(1, ronda: 60)],
      ),
    );
    expect(c.valor(CoreografiaPoker.apuesta(1)), isNull);
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      c.vuelos.whereType<VueloFichas>().map(
        (v) => (v.hasta as EnApuesta).posicion,
      ),
      [0],
    );
    await tester.pump(const Duration(seconds: 1));
  });
}
