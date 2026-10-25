import 'dart:math' as math;

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import 'evaluador_poker.dart';

/// Una mesa abierta, como la lista poker_salas_abiertas().
class SalaPoker {
  const SalaPoker({
    required this.id,
    required this.nombre,
    required this.creador,
    required this.ciegaChica,
    required this.ciegaGrande,
    required this.fichasIniciales,
    required this.jugadores,
    required this.enJuego,
    required this.mia,
  });

  factory SalaPoker.desdeMapa(Map<String, dynamic> fila) => SalaPoker(
    id: fila['sala_id'] as String,
    nombre: (fila['nombre'] as String?) ?? 'Mesa',
    creador: (fila['creador'] as String?) ?? '',
    ciegaChica: (fila['ciega_chica'] as num?)?.toInt() ?? 10,
    ciegaGrande: (fila['ciega_grande'] as num?)?.toInt() ?? 20,
    fichasIniciales: (fila['fichas_iniciales'] as num?)?.toInt() ?? 1000,
    jugadores: (fila['jugadores'] as num?)?.toInt() ?? 0,
    enJuego: (fila['en_juego'] as bool?) ?? false,
    mia: (fila['mia'] as bool?) ?? false,
  );

  final String id;
  final String nombre;
  final String creador;
  final int ciegaChica;
  final int ciegaGrande;
  final int fichasIniciales;
  final int jugadores;
  final bool enJuego;

  /// Estoy sentado en esta.
  final bool mia;

  static const asientos = 6;
  bool get llena => jugadores >= asientos;

  /// Con cuantas fichas de la billetera se sienta uno: de 20 a 100 ciegas
  /// grandes, como pide el servidor (poker_cobrar_entrada).
  int get compraMinima => ciegaGrande * 20;
  int get compraMaxima => ciegaGrande * 100;
}

class AsientoPoker {
  const AsientoPoker({
    required this.posicion,
    required this.usuarioId,
    required this.nombre,
    required this.fichas,
    this.avatarPath,
    this.afuera = false,
    this.egresado = false,
  });

  factory AsientoPoker.desdeMapa(Map<String, dynamic> fila) => AsientoPoker(
    posicion: (fila['posicion'] as num).toInt(),
    usuarioId: fila['usuario_id'] as String,
    nombre: ((fila['nombre'] as String?) ?? '').trim(),
    avatarPath: fila['avatar_path'] as String?,
    fichas: (fila['fichas'] as num?)?.toInt() ?? 0,
    afuera: (fila['afuera'] as bool?) ?? false,
    egresado: (fila['egresado'] as bool?) ?? false,
  );

  final int posicion;
  final String usuarioId;
  final String nombre;
  final String? avatarPath;
  final int fichas;

  /// Sentado afuera: no entra en las manos hasta que vuelva.
  final bool afuera;

  /// Egresado verificado: la insignia dorada junto al nombre.
  final bool egresado;

  String get primerNombre {
    final partes = nombre.split(' ');
    return partes.first.isEmpty ? 'Alguien' : partes.first;
  }

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();

  String? get avatarUrl => ServicioImagenes.urlPublica(avatarPath);
}

/// Lo que se ve de cada uno en la mano.
class JugadorPoker {
  const JugadorPoker({
    required this.posicion,
    required this.usuarioId,
    this.apuestaRonda = 0,
    this.aportado = 0,
    this.retirado = false,
    this.todo = false,
    this.ultimaAccion,
    this.cartasVistas,
    this.valor,
  });

  factory JugadorPoker.desdeMapa(Map<String, dynamic> fila) => JugadorPoker(
    posicion: (fila['posicion'] as num).toInt(),
    usuarioId: fila['usuario_id'] as String,
    apuestaRonda: (fila['apuesta_ronda'] as num?)?.toInt() ?? 0,
    aportado: (fila['aportado'] as num?)?.toInt() ?? 0,
    retirado: (fila['retirado'] as bool?) ?? false,
    todo: (fila['todo'] as bool?) ?? false,
    ultimaAccion: fila['ultima_accion'] as String?,
    cartasVistas: (fila['cartas_vistas'] as List?)?.cast<String>(),
    valor: (fila['valor'] as num?)?.toInt(),
  );

  final int posicion;
  final String usuarioId;
  final int apuestaRonda;
  final int aportado;
  final bool retirado;

  /// Fue con todo: no apuesta mas en esta mano.
  final bool todo;
  final String? ultimaAccion;

  /// Sus cartas, solo si la mano llego a mostrarse.
  final List<String>? cartasVistas;

  /// Su mejor mano al mostrarse (el mismo numero que EvaluadorPoker).
  final int? valor;
}

class ManoPoker {
  const ManoPoker({
    required this.id,
    required this.numero,
    required this.boton,
    required this.fase,
    required this.comunitarias,
    required this.apuesta,
    required this.subidaMinima,
    required this.bote,
    this.turno,
    this.venceEn,
    this.resultado = const {},
    this.terminadaEn,
  });

  factory ManoPoker.desdeMapa(Map<String, dynamic> fila) => ManoPoker(
    id: fila['id'] as String,
    numero: (fila['numero'] as num?)?.toInt() ?? 0,
    boton: (fila['boton'] as num?)?.toInt() ?? 0,
    fase: (fila['fase'] as String?) ?? 'terminada',
    comunitarias: ((fila['comunitarias'] as List?) ?? const []).cast<String>(),
    turno: (fila['turno'] as num?)?.toInt(),
    venceEn: _fecha(fila['vence_en']),
    apuesta: (fila['apuesta'] as num?)?.toInt() ?? 0,
    subidaMinima: (fila['subida_minima'] as num?)?.toInt() ?? 0,
    bote: (fila['bote'] as num?)?.toInt() ?? 0,
    resultado: {
      for (final pago in (fila['resultado'] as List?) ?? const [])
        ((pago as Map)['posicion'] as num).toInt(): (pago['monto'] as num)
            .toInt(),
    },
    terminadaEn: _fecha(fila['terminada_en']),
  );

  final String id;
  final int numero;
  final int boton;

  /// preflop, flop, turn, river o terminada.
  final String fase;
  final List<String> comunitarias;
  final int? turno;
  final DateTime? venceEn;

  /// La apuesta mas alta de la ronda.
  final int apuesta;
  final int subidaMinima;
  final int bote;

  /// Quien cobro y cuanto (posicion -> fichas), al terminar.
  final Map<int, int> resultado;
  final DateTime? terminadaEn;

  bool get enJuego => fase != 'terminada';
}

/// Todo lo que ve uno de una mesa, de poker_estado().
class EstadoMesaPoker {
  EstadoMesaPoker({
    required this.salaId,
    required this.nombre,
    required this.ciegaChica,
    required this.ciegaGrande,
    required this.fichasIniciales,
    required this.segundosTurno,
    required this.asientos,
    required this.jugadores,
    required this.horaServidor,
    DateTime? recibidoEn,
    this.version = 0,
    this.existe = true,
    this.billetera,
    int? compraMinima,
    int? compraMaxima,
    this.yo,
    this.mano,
    this.misCartas = const [],
  }) : recibidoEn = recibidoEn ?? DateTime.now(),
       compraMinima = compraMinima ?? ciegaGrande * 20,
       compraMaxima = compraMaxima ?? ciegaGrande * 100;

  factory EstadoMesaPoker.desdeMapa(
    Map<String, dynamic> datos, {
    DateTime? recibidoEn,
  }) {
    final salaLeida = (datos['sala'] as Map?)?.cast<String, dynamic>();
    final sala = salaLeida ?? const <String, dynamic>{};
    final mano = (datos['mano'] as Map?)?.cast<String, dynamic>();
    return EstadoMesaPoker(
      salaId: (sala['id'] as String?) ?? '',
      version: (sala['version'] as num?)?.toInt() ?? 0,
      existe: salaLeida != null,
      billetera: (datos['billetera'] as num?)?.toInt(),
      compraMinima: (sala['compra_minima'] as num?)?.toInt(),
      compraMaxima: (sala['compra_maxima'] as num?)?.toInt(),
      nombre: (sala['nombre'] as String?) ?? 'Mesa',
      ciegaChica: (sala['ciega_chica'] as num?)?.toInt() ?? 10,
      ciegaGrande: (sala['ciega_grande'] as num?)?.toInt() ?? 20,
      fichasIniciales: (sala['fichas_iniciales'] as num?)?.toInt() ?? 1000,
      segundosTurno: (sala['segundos_turno'] as num?)?.toInt() ?? 30,
      horaServidor: _fecha(datos['ahora']) ?? DateTime.now(),
      recibidoEn: recibidoEn,
      yo: (datos['yo'] as num?)?.toInt(),
      asientos: [
        for (final fila in (datos['asientos'] as List?) ?? const [])
          AsientoPoker.desdeMapa((fila as Map).cast<String, dynamic>()),
      ],
      mano: mano == null ? null : ManoPoker.desdeMapa(mano),
      jugadores: [
        for (final fila in (datos['jugadores'] as List?) ?? const [])
          JugadorPoker.desdeMapa((fila as Map).cast<String, dynamic>()),
      ],
      misCartas: ((datos['mis_cartas'] as List?) ?? const []).cast<String>(),
    );
  }

  final String salaId;
  final String nombre;
  final int ciegaChica;
  final int ciegaGrande;

  /// Con cuantas se sienta uno si no elige: 50 ciegas grandes.
  final int fichasIniciales;
  final int segundosTurno;

  /// Sube con cada cambio de la mesa: un estado con una version mas vieja
  /// llego tarde y no se muestra.
  final int version;

  /// La mesa sigue abierta. Se cierra cuando se levanta el ultimo.
  final bool existe;

  /// Mis fichas del casino (las que no estan en la mesa).
  final int? billetera;

  /// Entre cuantas fichas de la billetera me puedo sentar o recargar.
  final int compraMinima;
  final int compraMaxima;
  final List<AsientoPoker> asientos;
  final List<JugadorPoker> jugadores;

  /// La hora del servidor cuando contesto, y la del telefono cuando llego:
  /// el reloj del turno se cuenta con la del servidor, que es la que vale.
  final DateTime horaServidor;
  final DateTime recibidoEn;

  /// Mi asiento, si estoy sentado.
  final int? yo;

  /// La ultima mano (en juego o recien terminada).
  final ManoPoker? mano;
  final List<String> misCartas;

  AsientoPoker? asiento(int posicion) {
    for (final a in asientos) {
      if (a.posicion == posicion) return a;
    }
    return null;
  }

  JugadorPoker? jugador(int posicion) {
    final mano = this.mano;
    if (mano == null) return null;
    for (final j in jugadores) {
      if (j.posicion == posicion) return j;
    }
    return null;
  }

  bool get sentado => yo != null;
  AsientoPoker? get miAsiento => yo == null ? null : asiento(yo!);
  JugadorPoker? get miJugador => yo == null ? null : jugador(yo!);
  int get misFichas => miAsiento?.fichas ?? 0;

  bool get manoEnJuego => mano?.enJuego ?? false;
  bool get esMiTurno => manoEnJuego && yo != null && mano!.turno == yo;

  /// Lo que me falta poner para igualar.
  int get falta {
    final mano = this.mano;
    final yo = miJugador;
    if (mano == null || yo == null) return 0;
    return (mano.apuesta - yo.apuestaRonda).clamp(0, 1 << 30);
  }

  bool get puedoPasar => esMiTurno && falta == 0;

  /// Lo que pongo al igualar: lo que falta, o todo lo que tengo si no
  /// alcanza.
  int get paraIgualar => falta < misFichas ? falta : misFichas;

  /// A cuanto queda mi apuesta con la subida minima, y con todo.
  int get subidaMinimaTotal {
    final mano = this.mano;
    if (mano == null) return 0;
    return mano.apuesta + mano.subidaMinima;
  }

  int get maximoTotal => (miJugador?.apuestaRonda ?? 0) + misFichas;

  /// Puedo subir algo mas que el minimo sin ir con todo.
  bool get puedoSubir => esMiTurno && maximoTotal > subidaMinimaTotal;

  /// Cuanto queda del turno, con la hora del servidor.
  Duration restante([DateTime? ahora]) {
    final vence = mano?.venceEn;
    if (vence == null) return Duration.zero;
    final transcurrido = (ahora ?? DateTime.now()).difference(recibidoEn);
    final resta = vence.difference(horaServidor.add(transcurrido));
    return resta.isNegative ? Duration.zero : resta;
  }

  /// Desde que termino la ultima mano, con la hora del servidor.
  Duration desdeQueTermino([DateTime? ahora]) {
    final terminada = mano?.terminadaEn;
    if (terminada == null || manoEnJuego) return Duration.zero;
    final transcurrido = (ahora ?? DateTime.now()).difference(recibidoEn);
    return horaServidor.add(transcurrido).difference(terminada);
  }

  /// Sentados con fichas y jugando: con dos o mas se reparte.
  int get listos => asientos.where((a) => !a.afuera && a.fichas > 0).length;

  /// Lo que tiene alguien delante en esta ronda. Al terminar la mano ya
  /// esta todo en el bote.
  int apuestaVisible(int posicion) =>
      manoEnJuego ? (jugador(posicion)?.apuestaRonda ?? 0) : 0;

  /// Lo que hay en el centro: el bote sin las apuestas que todavia estan
  /// delante de cada uno. Terminada la mano, ya se pago.
  int get boteVisible {
    final mano = this.mano;
    if (mano == null || !mano.enJuego) return 0;
    final delante = jugadores.fold<int>(0, (s, j) => s + j.apuestaRonda);
    return math.max(0, mano.bote - delante);
  }

  /// Los de la mano en el orden en que se reparte: desde el de la
  /// izquierda del boton, en el sentido de las agujas del reloj.
  List<int> get ordenReparto {
    final mano = this.mano;
    if (mano == null) return const [];
    return [for (final j in jugadores) j.posicion]..sort(
      (a, b) => ((a - mano.boton - 1 + 12) % 6).compareTo(
        (b - mano.boton - 1 + 12) % 6,
      ),
    );
  }

  /// Quien se llevo mas en la mano que termino.
  int? get ganadorPrincipal {
    final resultado = mano?.resultado ?? const {};
    if (resultado.isEmpty) return null;
    return resultado.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// Las cinco con que gano el que mas se llevo, si se mostraron cartas.
  List<String> get cincoGanadoras {
    final ganador = ganadorPrincipal;
    final vistas = ganador == null ? null : jugador(ganador)?.cartasVistas;
    if (vistas == null || mano == null) return const [];
    return EvaluadorPoker.mejoresCinco([...vistas, ...mano!.comunitarias]);
  }

  /// Mi mejor mano con lo que hay en la mesa ("Par de reyes").
  String? get miMano {
    if (misCartas.length != 2 || (mano?.comunitarias.length ?? 0) < 3) {
      return null;
    }
    return EvaluadorPoker.nombre(
      EvaluadorPoker.mejorValor([...misCartas, ...mano!.comunitarias]),
    );
  }
}

DateTime? _fecha(Object? valor) =>
    valor is String ? DateTime.tryParse(valor)?.toUtc() : null;
