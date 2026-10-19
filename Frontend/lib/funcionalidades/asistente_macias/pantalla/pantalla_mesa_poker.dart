import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/mesa_poker.dart';
import '../logica/evaluador_poker.dart';
import '../logica/mesa_poker.dart';
import '../logica/repositorio_poker.dart';
import '../logica/sonidos_casino.dart';

/// Una mesa de poker: hasta 6, por turnos, contra otros de la U.
///
/// El servidor es el arbitro. Esta pantalla mira el estado (que llega en
/// vivo), muestra lo que cada uno puede ver y manda las jugadas. Ademas,
/// cualquier telefono de la mesa pide repartir cuando toca y vence el turno
/// de quien no jugo: el servidor hace cada cosa una sola vez.
class PantallaMesaPoker extends StatefulWidget {
  const PantallaMesaPoker({
    required this.salaId,
    this.repositorio = const RepositorioPokerSupabase(),
    this.sonidos,
    this.conSonido = true,
    super.key,
  });

  final String salaId;
  final RepositorioPoker repositorio;
  final SonidosMesa? sonidos;
  final bool conSonido;

  static Route<void> ruta({
    required String salaId,
    RepositorioPoker repositorio = const RepositorioPokerSupabase(),
    SonidosMesa? sonidos,
    bool conSonido = true,
  }) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => PantallaMesaPoker(
      salaId: salaId,
      repositorio: repositorio,
      sonidos: sonidos,
      conSonido: conSonido,
    ),
    transitionsBuilder: (context, animacion, _, hijo) {
      final curva = CurvedAnimation(
        parent: animacion,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(
          scale: Tween(begin: .93, end: 1.0).animate(curva),
          child: hijo,
        ),
      );
    },
  );

  @override
  State<PantallaMesaPoker> createState() => _PantallaMesaPokerState();
}

class _PantallaMesaPokerState extends State<PantallaMesaPoker> {
  static const _sonidosDeLaMesa = {
    SonidoMesa.fichas,
    SonidoMesa.ficha,
    SonidoMesa.barajar,
    SonidoMesa.voltear,
    SonidoMesa.ganar,
    SonidoMesa.pista,
    SonidoMesa.boton,
  };

  /// Despues de una mano, lo que se espera para ver como termino.
  static const _pausaEntreManos = Duration(milliseconds: 4500);

  late final SonidosMesa _sonidos =
      widget.sonidos ?? SonidosMesa.delSistema(solo: _sonidosDeLaMesa);

  EstadoMesaPoker? _estado;
  String? _error;
  bool _enviando = false;
  bool _saliendo = false;
  VoidCallback? _dejarDeEscuchar;
  Timer? _tic;
  DateTime? _pedidoReparto;
  DateTime? _pedidoVencer;

  @override
  void initState() {
    super.initState();
    unawaited(_sonidos.preparar());
    _cargar();
    _dejarDeEscuchar = widget.repositorio.escucharMesa(widget.salaId, _cargar);
    _tic = Timer.periodic(const Duration(milliseconds: 500), (_) => _cadaTic());
  }

  @override
  void dispose() {
    _tic?.cancel();
    _dejarDeEscuchar?.call();
    if (widget.sonidos == null) unawaited(_sonidos.liberar());
    super.dispose();
  }

  void _sonar(SonidoMesa sonido, {double volumen = 1}) {
    if (widget.conSonido) _sonidos.tocar(sonido, volumen: volumen);
  }

  Future<void> _cargar() async {
    try {
      final estado = await widget.repositorio.estado(widget.salaId);
      if (!mounted) return;
      _avisarCambios(_estado, estado);
      setState(() {
        _estado = estado;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = mensajePoker(error));
    }
  }

  /// Los sonidos y la vibracion salen de comparar lo de antes con lo nuevo.
  void _avisarCambios(EstadoMesaPoker? antes, EstadoMesaPoker ahora) {
    final manoAntes = antes?.mano;
    final mano = ahora.mano;
    if (mano == null) return;

    if (mano.numero != manoAntes?.numero && mano.enJuego) {
      _sonar(SonidoMesa.barajar, volumen: .7);
    } else if (manoAntes != null && mano.numero == manoAntes.numero) {
      if (mano.comunitarias.length > manoAntes.comunitarias.length) {
        _sonar(SonidoMesa.voltear);
      } else if (mano.bote > manoAntes.bote) {
        _sonar(SonidoMesa.fichas, volumen: .7);
      }
      final yo = ahora.yo;
      if (manoAntes.enJuego && !mano.enJuego && yo != null) {
        if (mano.resultado.containsKey(yo)) {
          _sonar(SonidoMesa.ganar);
          RetroalimentacionHaptica.exito();
        }
      }
    }
    if (ahora.esMiTurno && !(antes?.esMiTurno ?? false)) {
      _sonar(SonidoMesa.pista, volumen: .8);
      RetroalimentacionHaptica.seleccion();
    }
  }

  bool _puedePedir(DateTime? ultimo) =>
      ultimo == null ||
      DateTime.now().difference(ultimo) > const Duration(milliseconds: 2500);

  /// Cada medio segundo: el reloj del turno, repartir y vencer turnos.
  void _cadaTic() {
    final estado = _estado;
    if (estado == null || !mounted) return;
    setState(() {});

    if (estado.sentado &&
        !estado.manoEnJuego &&
        estado.listos >= 2 &&
        (estado.mano == null || estado.desdeQueTermino() >= _pausaEntreManos) &&
        _puedePedir(_pedidoReparto)) {
      _pedidoReparto = DateTime.now();
      unawaited(
        widget.repositorio
            .empezarMano(widget.salaId)
            .then((_) => _cargar(), onError: (_) {}),
      );
    }

    // Un segundo de gracia despues del cero: si el que tenia el turno jugo
    // justo a tiempo, su jugada llega primero.
    final vencido =
        estado.manoEnJuego &&
        estado.mano!.venceEn != null &&
        estado.restante(DateTime.now().subtract(const Duration(seconds: 1))) ==
            Duration.zero;
    if (vencido && _puedePedir(_pedidoVencer)) {
      _pedidoVencer = DateTime.now();
      unawaited(
        widget.repositorio
            .vencerTurno(widget.salaId)
            .then((_) => _cargar(), onError: (_) {}),
      );
    }
  }

  void _avisar(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _hacer(Future<void> Function() accion) async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      await accion();
    } catch (error) {
      if (mounted) _avisar(mensajePoker(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
      await _cargar();
    }
  }

  void _jugar(String accion, {int monto = 0}) {
    RetroalimentacionHaptica.accion();
    _sonar(
      accion == 'retirarse' || accion == 'pasar'
          ? SonidoMesa.boton
          : SonidoMesa.ficha,
      volumen: .8,
    );
    _hacer(() => widget.repositorio.jugar(widget.salaId, accion, monto: monto));
  }

  Future<void> _subir() async {
    final estado = _estado;
    if (estado == null) return;
    final total = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF241D19),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HojaSubida(estado: estado),
    );
    if (total == null || !mounted) return;
    if (total >= estado.maximoTotal) {
      _jugar('todo');
    } else {
      _jugar('subir', monto: total);
    }
  }

  Future<void> _salir() async {
    final estado = _estado;
    final enLaMano =
        estado != null &&
        estado.manoEnJuego &&
        estado.miJugador != null &&
        !estado.miJugador!.retirado;
    if (enLaMano) {
      final seguro = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text('¿Te levantas de la mesa?'),
          content: const Text(
            'Estás en una mano: si te vas ahora, te retiras y pierdes lo que '
            'ya apostaste.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogo).pop(false),
              child: const Text('Seguir jugando'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogo).pop(true),
              child: const Text('Levantarme'),
            ),
          ],
        ),
      );
      if (seguro != true) return;
    }
    if (!mounted) return;
    try {
      if (estado?.sentado ?? false) {
        await widget.repositorio.levantarse(widget.salaId);
      }
    } catch (_) {
      // Igual se va: el reloj lo retira de la mano y la limpieza, de la mesa.
    }
    if (!mounted) return;
    // canPop se lee del ultimo dibujo: se cierra despues de redibujar, o el
    // PopScope todavia lo frenaria y volveria a preguntar.
    setState(() => _saliendo = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _saliendo,
    onPopInvokedWithResult: (salio, _) {
      if (!salio) _salir();
    },
    child: Scaffold(
      backgroundColor: ColoresPoker.fondo,
      body: SafeArea(child: _cuerpo()),
    ),
  );

  Widget _cuerpo() {
    final estado = _estado;
    if (estado == null) {
      final error = _error;
      return Center(
        child: error == null
            ? const IndicadorCarga()
            : Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: ColoresPoker.crema),
                    ),
                    const SizedBox(height: 14),
                    BotonMesa(
                      texto: 'Reintentar',
                      chico: true,
                      alPresionar: _cargar,
                    ),
                  ],
                ),
              ),
      );
    }

    return Column(
      children: [
        _Encabezado(estado: estado, alSalir: _salir),
        Expanded(child: _Mesa(estado: estado)),
        _MisCartas(estado: estado),
        _BarraAcciones(
          estado: estado,
          enviando: _enviando,
          alJugar: _jugar,
          alSubir: _subir,
          alSentarse: () =>
              _hacer(() => widget.repositorio.sentarse(widget.salaId)),
          alVolver: () =>
              _hacer(() => widget.repositorio.volver(widget.salaId)),
          alRecargar: () =>
              _hacer(() => widget.repositorio.recargar(widget.salaId)),
        ),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.estado, required this.alSalir});

  final EstadoMesaPoker estado;
  final VoidCallback alSalir;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 14, 0),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Levantarme de la mesa',
          onPressed: alSalir,
          icon: const Icon(Icons.close_rounded, color: ColoresPoker.crema),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                estado.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresPoker.crema,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                'Ciegas ${fichasPoker(estado.ciegaChica)}/'
                '${fichasPoker(estado.ciegaGrande)}'
                '${estado.mano == null ? '' : ' · mano ${estado.mano!.numero}'}',
                style: const TextStyle(
                  color: ColoresPoker.cremaApagada,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (estado.sentado) PildoraFichas(fichas: estado.misFichas),
      ],
    ),
  );
}

/// El paño con los seis asientos, las cartas de la mesa y el bote.
class _Mesa extends StatelessWidget {
  const _Mesa({required this.estado});

  final EstadoMesaPoker estado;

  /// Donde va cada lugar alrededor del paño, desde el de abajo (el mio) en
  /// el sentido de las agujas del reloj. En fracciones del paño.
  static const _lugares = [
    Offset(.5, 1.0),
    Offset(0, .74),
    Offset(0, .26),
    Offset(.5, 0),
    Offset(1, .26),
    Offset(1, .74),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, area) {
      final ancho = area.maxWidth;
      final alto = area.maxHeight;
      // El paño deja lugar a los asientos de los costados y de arriba.
      final pano = Rect.fromLTRB(
        46,
        62,
        math.max(47, ancho - 46),
        math.max(63, alto - 58),
      );
      final centro = pano.center;
      final mano = estado.mano;
      final yo = estado.yo ?? 0;
      final restante = estado.restante();
      final fraccion = estado.segundosTurno == 0
          ? 0.0
          : (restante.inMilliseconds / (estado.segundosTurno * 1000)).clamp(
              0.0,
              1.0,
            );
      final terminada = mano != null && !mano.enJuego;
      final cartaComun = math.min(42.0, pano.width / 7.2);

      final asientos = <Widget>[];
      final apuestas = <Widget>[];
      for (var posicion = 0; posicion < 6; posicion++) {
        final lugar = _lugares[(posicion - yo + 6) % 6];
        final punto = Offset(
          pano.left + lugar.dx * pano.width,
          pano.top + lugar.dy * pano.height,
        );
        final asiento = estado.asiento(posicion);
        final jugador = estado.jugador(posicion);
        const anchoAsiento = 92.0;
        const altoAsiento = 138.0;
        asientos.add(
          Positioned(
            left: (punto.dx - anchoAsiento / 2).clamp(0, ancho - anchoAsiento),
            top: (punto.dy - altoAsiento / 2).clamp(0, alto - altoAsiento),
            width: anchoAsiento,
            height: altoAsiento,
            child: AsientoPokerVista(
              asiento: asiento,
              jugador: jugador,
              esBoton: mano != null && mano.boton == posicion,
              esTurno: mano != null && mano.enJuego && mano.turno == posicion,
              fraccionTurno: fraccion,
              esYo: estado.yo == posicion,
              // Las mias van grandes abajo; las demas, tapadas o vistas.
              mostrarCartas: estado.yo != posicion && mano != null,
              ganancia: terminada ? mano.resultado[posicion] : null,
            ),
          ),
        );
        final apuesta = jugador?.apuestaRonda ?? 0;
        if (mano != null && mano.enJuego && apuesta > 0) {
          final donde = Offset.lerp(punto, centro, .42)!;
          apuestas.add(
            Positioned(
              left: donde.dx - 30,
              top: donde.dy - 9,
              width: 60,
              child: Center(child: ApuestaEnMesa(monto: apuesta)),
            ),
          );
        }
      }

      return Stack(
        children: [
          Positioned.fromRect(
            rect: pano,
            // Aparte: el reloj del turno redibuja cada medio segundo, y el
            // paño (con su trama) no tiene por que repintarse con el.
            child: const RepaintBoundary(
              child: CustomPaint(painter: PintorMesaPoker()),
            ),
          ),
          Positioned(
            left: pano.left,
            right: ancho - pano.right,
            top: centro.dy - cartaComun * .7 - 16,
            child: Column(
              children: [
                CartasComunitarias(
                  cartas: mano?.comunitarias ?? const [],
                  ancho: cartaComun,
                ),
                const SizedBox(height: 8),
                if (mano != null && mano.bote > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bote ${fichasPoker(mano.bote)}',
                      style: const TextStyle(
                        color: ColoresPoker.oro,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ...apuestas,
          ...asientos,
        ],
      );
    },
  );
}

/// Mis dos cartas, grandes, y lo que tengo con la mesa.
class _MisCartas extends StatelessWidget {
  const _MisCartas({required this.estado});

  final EstadoMesaPoker estado;

  @override
  Widget build(BuildContext context) {
    final cartas = estado.misCartas;
    final mano = estado.mano;
    final retirado = estado.miJugador?.retirado ?? false;
    if (!estado.sentado || mano == null || cartas.length != 2) {
      return const SizedBox(height: 8);
    }
    final miMano = estado.miMano;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -.06,
                child: CartaPoker(
                  ancho: 56,
                  codigo: cartas[0],
                  apagada: retirado,
                ),
              ),
              const SizedBox(width: 6),
              Transform.rotate(
                angle: .06,
                child: CartaPoker(
                  ancho: 56,
                  codigo: cartas[1],
                  apagada: retirado,
                ),
              ),
            ],
          ),
          if (miMano != null && !retirado) ...[
            const SizedBox(height: 4),
            Text(
              miMano,
              style: const TextStyle(
                color: ColoresPoker.oro,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lo de abajo: las jugadas cuando es mi turno, y si no, que esta pasando.
class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.estado,
    required this.enviando,
    required this.alJugar,
    required this.alSubir,
    required this.alSentarse,
    required this.alVolver,
    required this.alRecargar,
  });

  final EstadoMesaPoker estado;
  final bool enviando;
  final void Function(String accion, {int monto}) alJugar;
  final VoidCallback alSubir;
  final VoidCallback alSentarse;
  final VoidCallback alVolver;
  final VoidCallback alRecargar;

  @override
  Widget build(BuildContext context) {
    final mano = estado.mano;
    final miJugador = estado.miJugador;
    final enMano =
        estado.manoEnJuego && miJugador != null && !miJugador.retirado;

    Widget? boton;
    String texto;

    if (!estado.sentado) {
      texto = 'Estás mirando.';
      if (estado.asientos.length < 6) {
        boton = BotonMesa(
          texto: 'Sentarme',
          estilo: EstiloBoton.principal,
          alPresionar: enviando ? null : alSentarse,
        );
      }
    } else if (estado.miAsiento!.afuera) {
      texto = 'Estás sentado afuera: se te pasó el turno dos veces.';
      boton = BotonMesa(
        texto: 'Volver a jugar',
        estilo: EstiloBoton.principal,
        alPresionar: enviando ? null : alVolver,
      );
    } else if (estado.misFichas == 0 && !enMano) {
      texto = 'Te quedaste sin fichas.';
      boton = BotonMesa(
        texto: 'Recargar ${fichasPoker(estado.fichasIniciales)}',
        estilo: EstiloBoton.principal,
        alPresionar: enviando ? null : alRecargar,
      );
    } else if (estado.esMiTurno) {
      return _MisJugadas(
        estado: estado,
        enviando: enviando,
        alJugar: alJugar,
        alSubir: alSubir,
      );
    } else {
      texto = _queEstaPasando();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresPoker.crema,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (boton != null) ...[const SizedBox(height: 10), boton],
          if (boton == null && mano != null) const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _queEstaPasando() {
    final mano = estado.mano;
    if (mano == null || !mano.enJuego) {
      if (mano != null && mano.resultado.isNotEmpty) return _resultado(mano);
      if (estado.listos < 2) {
        return 'Esperando que se siente alguien más…';
      }
      return 'Repartiendo…';
    }
    final turno = mano.turno == null ? null : estado.asiento(mano.turno!);
    final segundos = estado.restante().inSeconds;
    if (turno == null) return 'Repartiendo…';
    return 'Turno de ${turno.primerNombre} · $segundos s';
  }

  String _resultado(ManoPoker mano) {
    final ganadores = mano.resultado.entries.toList();
    final nombres = [
      for (final g in ganadores)
        g.key == estado.yo
            ? 'Tú'
            : estado.asiento(g.key)?.primerNombre ?? 'Alguien',
    ];
    final total = ganadores.fold<int>(0, (suma, g) => suma + g.value);
    final valor = estado.jugador(ganadores.first.key)?.valor;
    final con = valor == null ? '' : ' con ${EvaluadorPoker.nombre(valor)}';
    if (nombres.length == 1) {
      final verbo = nombres.first == 'Tú' ? 'ganas' : 'gana';
      return '${nombres.first} $verbo ${fichasPoker(total)}$con.';
    }
    return '${nombres.join(' y ')} se reparten ${fichasPoker(total)}$con.';
  }
}

class _MisJugadas extends StatelessWidget {
  const _MisJugadas({
    required this.estado,
    required this.enviando,
    required this.alJugar,
    required this.alSubir,
  });

  final EstadoMesaPoker estado;
  final bool enviando;
  final void Function(String accion, {int monto}) alJugar;
  final VoidCallback alSubir;

  @override
  Widget build(BuildContext context) {
    final falta = estado.falta;
    final igualarEsTodo = falta >= estado.misFichas;
    final apostando = (estado.mano?.apuesta ?? 0) == 0;
    final segundos = estado.restante().inSeconds;
    final puedeSubirOTodo = estado.misFichas > falta;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu turno · $segundos s',
            style: TextStyle(
              color: segundos <= 7 ? const Color(0xFFE5484D) : ColoresPoker.oro,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          // Tres botones en un telefono de 360: letra chica, y el del medio
          // (que lleva el monto) un poco mas ancho.
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BotonMesa(
                  texto: 'Retirarme',
                  chico: true,
                  alto: 46,
                  estilo: EstiloBoton.secundario,
                  alPresionar: enviando ? null : () => alJugar('retirarse'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: falta == 0
                    ? BotonMesa(
                        texto: 'Pasar',
                        chico: true,
                        alto: 46,
                        alPresionar: enviando ? null : () => alJugar('pasar'),
                      )
                    : BotonMesa(
                        texto: igualarEsTodo
                            ? 'Todo ${fichasPoker(estado.misFichas)}'
                            : 'Igualar ${fichasPoker(falta)}',
                        chico: true,
                        alto: 46,
                        alPresionar: enviando
                            ? null
                            : () => alJugar(igualarEsTodo ? 'todo' : 'igualar'),
                      ),
              ),
              if (puedeSubirOTodo) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: BotonMesa(
                    texto: apostando ? 'Apostar' : 'Subir',
                    chico: true,
                    alto: 46,
                    estilo: EstiloBoton.principal,
                    alPresionar: enviando ? null : alSubir,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A cuanto subir: el minimo, medio bote, el bote o todo, y lo del medio
/// con la barra.
class _HojaSubida extends StatefulWidget {
  const _HojaSubida({required this.estado});

  final EstadoMesaPoker estado;

  @override
  State<_HojaSubida> createState() => _HojaSubidaState();
}

class _HojaSubidaState extends State<_HojaSubida> {
  late final int _minimo = math.min(
    widget.estado.subidaMinimaTotal,
    widget.estado.maximoTotal,
  );
  late final int _maximo = widget.estado.maximoTotal;
  late int _total = _minimo;

  int get _paso => math.max(1, widget.estado.ciegaChica);

  List<(String, int)> get _rapidas {
    final mano = widget.estado.mano!;
    final opciones = <(String, int)>[
      ('Mínimo', _minimo),
      ('½ bote', mano.apuesta + mano.bote ~/ 2),
      ('Bote', mano.apuesta + mano.bote),
      ('Todo', _maximo),
    ];
    final vistos = <int>{};
    return [
      for (final (texto, monto) in opciones)
        if (monto >= _minimo && monto <= _maximo && vistos.add(monto))
          (texto, monto),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final apostando = (widget.estado.mano?.apuesta ?? 0) == 0;
    final todo = _total >= _maximo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloHojaMesa(apostando ? '¿Cuánto apuestas?' : '¿A cuánto subes?'),
          const SizedBox(height: 12),
          Text(
            fichasPoker(_total),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ColoresPoker.oro,
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          if (_maximo > _minimo)
            Slider(
              value: _total.toDouble(),
              min: _minimo.toDouble(),
              max: _maximo.toDouble(),
              activeColor: ColoresPoker.oro,
              onChanged: (valor) => setState(() {
                final redondeado = (valor / _paso).round() * _paso;
                _total = redondeado.clamp(_minimo, _maximo);
              }),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (texto, monto) in _rapidas)
                ChoiceChip(
                  label: Text(texto),
                  selected: _total == monto,
                  onSelected: (_) => setState(() => _total = monto),
                ),
            ],
          ),
          const SizedBox(height: 16),
          BotonMesa(
            texto: todo
                ? 'Todo: ${fichasPoker(_maximo)}'
                : apostando
                ? 'Apostar ${fichasPoker(_total)}'
                : 'Subir a ${fichasPoker(_total)}',
            estilo: EstiloBoton.principal,
            alPresionar: () => Navigator.of(context).pop(_total),
          ),
        ],
      ),
    );
  }
}
