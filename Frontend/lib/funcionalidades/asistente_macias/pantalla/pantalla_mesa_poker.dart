import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/cartas_blackjack.dart';
import '../diseno/fichas_blackjack.dart';
import '../diseno/geometria_mesa_poker.dart';
import '../diseno/hoja_entrada_poker.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/mesa_poker.dart';
import '../logica/coreografia_poker.dart';
import '../logica/evaluador_poker.dart';
import '../logica/mesa_blackjack.dart' show Carta, Palo;
import '../logica/mesa_poker.dart';
import '../logica/repositorio_poker.dart';
import '../logica/sonidos_casino.dart';

/// Una mesa de poker: hasta 6, por turnos, contra otros de la U.
///
/// El servidor es el arbitro. Esta pantalla mira el estado (que llega en
/// vivo), lo muestra con su coreografia (las cartas que se reparten, las
/// fichas que van al bote y al que gana) y manda las jugadas. Ademas,
/// cualquier telefono de la mesa pide repartir cuando toca y vence el turno
/// de quien no jugo: el servidor hace cada cosa una sola vez.
///
/// Al cerrarse devuelve las fichas que vuelven al casino.
class PantallaMesaPoker extends StatefulWidget {
  const PantallaMesaPoker({
    required this.salaId,
    this.repositorio = const RepositorioPokerSupabase(),
    this.sonidos,
    this.conSonido = true,
    this.abrirEnlace,
    super.key,
  });

  final String salaId;
  final RepositorioPoker repositorio;
  final SonidosMesa? sonidos;
  final bool conSonido;

  /// Para las pruebas. En la app, abre WhatsApp para invitar.
  final Future<bool> Function(Uri enlace)? abrirEnlace;

  static Route<int> ruta({
    required String salaId,
    RepositorioPoker repositorio = const RepositorioPokerSupabase(),
    SonidosMesa? sonidos,
    bool conSonido = true,
  }) => PageRouteBuilder<int>(
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
    SonidoMesa.cartaSale,
    SonidoMesa.cobrar,
    SonidoMesa.ganar,
    SonidoMesa.pista,
    SonidoMesa.boton,
  };

  /// Despues de una mano, lo que se espera para verla terminar: las cartas
  /// que se dan vuelta y el bote que va al que gano.
  static const _pausaEntreManos = Duration(milliseconds: 5500);

  late final SonidosMesa _sonidos =
      widget.sonidos ?? SonidosMesa.delSistema(solo: _sonidosDeLaMesa);
  late final CoreografiaPoker _coreografia = CoreografiaPoker(
    sonar: _sonar,
    alGanar: RetroalimentacionHaptica.exito,
  );

  /// El reloj del turno: de 1 a 0, y los segundos que quedan. Solo esto se
  /// repinta mientras corre, no la mesa entera.
  final _turno = ValueNotifier<double>(0);
  final _segundos = ValueNotifier<int>(0);

  EstadoMesaPoker? _estado;
  String? _error;
  bool _enviando = false;
  bool _saliendo = false;
  VoidCallback? _dejarDeEscuchar;
  Timer? _tic;
  Timer? _reloj;
  DateTime? _pedidoReparto;
  DateTime? _pedidoVencer;

  @override
  void initState() {
    super.initState();
    unawaited(_sonidos.preparar());
    _cargar();
    _dejarDeEscuchar = widget.repositorio.escucharMesa(widget.salaId, _cargar);
    _tic = Timer.periodic(const Duration(milliseconds: 500), (_) => _cadaTic());
    _reloj = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _marcarReloj(),
    );
  }

  @override
  void dispose() {
    _tic?.cancel();
    _reloj?.cancel();
    _dejarDeEscuchar?.call();
    _coreografia.dispose();
    _turno.dispose();
    _segundos.dispose();
    if (widget.sonidos == null) unawaited(_sonidos.liberar());
    super.dispose();
  }

  void _sonar(SonidoMesa sonido, {double volumen = 1}) {
    if (widget.conSonido) _sonidos.tocar(sonido, volumen: volumen);
  }

  Future<void> _cargar() async {
    try {
      final estado = await widget.repositorio.estado(widget.salaId);
      if (mounted) _recibir(estado);
    } catch (error) {
      if (mounted && _estado == null) {
        setState(() => _error = mensajePoker(error));
      }
    }
  }

  /// Un estado del servidor. Si llega uno mas viejo que el que se ve (dos
  /// pedidos que se cruzaron), se descarta: antes pisaba al nuevo y la mesa
  /// saltaba para atras.
  void _recibir(EstadoMesaPoker estado) {
    final antes = _estado;
    if (antes != null &&
        estado.version > 0 &&
        estado.version <= antes.version) {
      // El mismo: solo trae la hora del servidor mas fresca.
      if (estado.version == antes.version) _estado = estado;
      return;
    }
    _avisarCambios(antes, estado);
    _coreografia.cambio(antes, estado);
    setState(() {
      _estado = estado;
      _error = null;
    });
    _marcarReloj();
  }

  /// Lo que no es de la coreografia: me toca jugar.
  void _avisarCambios(EstadoMesaPoker? antes, EstadoMesaPoker ahora) {
    if (antes != null && ahora.esMiTurno && !antes.esMiTurno) {
      _sonar(SonidoMesa.pista, volumen: .8);
      RetroalimentacionHaptica.seleccion();
    }
  }

  void _marcarReloj() {
    final estado = _estado;
    if (estado == null || !estado.manoEnJuego) return;
    final restante = estado.restante();
    final total = estado.segundosTurno * 1000;
    _turno.value = total == 0
        ? 0
        : (restante.inMilliseconds / total).clamp(0.0, 1.0);
    _segundos.value = (restante.inMilliseconds / 1000).ceil();
  }

  bool _puedePedir(DateTime? ultimo) =>
      ultimo == null ||
      DateTime.now().difference(ultimo) > const Duration(milliseconds: 2500);

  /// Cada medio segundo: repartir cuando toca y vencer turnos.
  void _cadaTic() {
    final estado = _estado;
    if (estado == null || !mounted || !estado.existe) return;

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

  Future<void> _hacer(
    Future<void> Function() accion, {
    bool recargar = true,
  }) async {
    if (_enviando) return;
    setState(() => _enviando = true);
    var fallo = false;
    try {
      await accion();
    } catch (error) {
      fallo = true;
      if (mounted) _avisar(mensajePoker(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
    if (recargar || fallo) await _cargar();
  }

  /// La jugada vuelve con la mesa como quedo: no hace falta otra vuelta.
  void _jugar(String accion, {int monto = 0}) => _hacer(() async {
    final estado = await widget.repositorio.jugar(
      widget.salaId,
      accion,
      monto: monto,
    );
    if (!mounted) return;
    if (estado != null) {
      _recibir(estado);
    } else {
      await _cargar();
    }
  }, recargar: false);

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

  /// Con cuantas fichas del casino: para sentarme mirando, o para recargar.
  Future<int?> _elegirEntrada({required String boton}) {
    final estado = _estado!;
    return HojaEntradaPoker.mostrar(
      context,
      titulo: boton == 'Recargar' ? 'Recargar fichas' : 'Sentarme a la mesa',
      minima: estado.compraMinima,
      maxima: estado.compraMaxima,
      sugerida: estado.fichasIniciales,
      billetera: estado.billetera!,
      ciegaGrande: estado.ciegaGrande,
      boton: boton,
    );
  }

  Future<void> _sentarme() async {
    final estado = _estado;
    if (estado == null || _enviando) return;
    // Sin saber cuantas tengo, el servidor elige las de la mesa.
    if (estado.billetera == null) {
      return _hacer(() => widget.repositorio.sentarse(widget.salaId));
    }
    final monto = await _elegirEntrada(boton: 'Sentarme');
    if (monto == null || !mounted) return;
    await _hacer(
      () => widget.repositorio.sentarse(widget.salaId, fichas: monto),
    );
  }

  Future<void> _recargar() async {
    final estado = _estado;
    if (estado == null || _enviando) return;
    if (estado.billetera == null) {
      return _hacer(() => widget.repositorio.recargar(widget.salaId));
    }
    final monto = await _elegirEntrada(boton: 'Recargar');
    if (monto == null || !mounted) return;
    await _hacer(
      () => widget.repositorio.recargar(widget.salaId, fichas: monto),
    );
  }

  /// Un mensaje listo para mandar por WhatsApp: se juega desde 2, y el
  /// segundo suele ser un amigo al que hay que avisar.
  Future<void> _invitar() async {
    final nombre = _estado?.nombre ?? 'mi mesa';
    final mensaje =
        '¿Jugamos póker? Estoy en la mesa "$nombre" de U market. Entra a '
        'MacIAs, escribe "casino" y en Póker toca Sentarme.';
    final enlace = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(mensaje)}',
    );
    final abrir =
        widget.abrirEnlace ??
        (Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
    if (!await abrir(enlace) && mounted) _avisar('No se pudo abrir WhatsApp.');
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
            'ya apostaste. Lo demás vuelve a tus fichas del casino.',
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
    final sentado = estado?.sentado ?? false;
    final llevo = sentado ? estado!.misFichas : 0;
    try {
      if (sentado) await widget.repositorio.levantarse(widget.salaId);
    } catch (_) {
      // Igual se va: el reloj lo retira de la mano y la limpieza, de la mesa.
    }
    if (!mounted) return;
    // canPop se lee del ultimo dibujo: se cierra despues de redibujar, o el
    // PopScope todavia lo frenaria y volveria a preguntar.
    setState(() => _saliendo = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(llevo);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<int>(
    canPop: _saliendo,
    onPopInvokedWithResult: (salio, _) {
      if (!salio) _salir();
    },
    child: Scaffold(
      backgroundColor: ColoresPoker.fondo,
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: PintorSalaPoker()),
            ),
          ),
          SafeArea(child: _cuerpo()),
        ],
      ),
    ),
  );

  Widget _cuerpo() {
    final estado = _estado;
    if (estado == null) {
      final error = _error;
      return Center(
        child: error == null
            ? const IndicadorCarga()
            : _Aviso(texto: error, boton: 'Reintentar', alPresionar: _cargar),
      );
    }
    if (!estado.existe) {
      return Center(
        child: _Aviso(
          texto: 'Esta mesa se cerró.',
          boton: 'Volver',
          alPresionar: _salir,
        ),
      );
    }

    return Column(
      children: [
        _Encabezado(estado: estado, alSalir: _salir),
        Expanded(
          child: ListenableBuilder(
            listenable: _coreografia,
            builder: (context, _) => _Mesa(
              estado: estado,
              coreografia: _coreografia,
              turno: _turno,
              alSentarme: estado.sentado || _enviando ? null : _sentarme,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          // Tambien escucha a la coreografia: quien gano se dice cuando le
          // llegan las fichas, no antes.
          child: ListenableBuilder(
            listenable: _coreografia,
            builder: (context, _) => _BarraAcciones(
              estado: estado,
              enviando: _enviando,
              ocultaResultado: _coreografia.oculto(CoreografiaPoker.resultado),
              segundos: _segundos,
              turno: _turno,
              alJugar: _jugar,
              alSubir: _subir,
              alSentarse: _sentarme,
              alVolver: () =>
                  _hacer(() => widget.repositorio.volver(widget.salaId)),
              alRecargar: _recargar,
              alInvitar: _invitar,
            ),
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.texto,
    required this.boton,
    required this.alPresionar,
  });

  final String texto;
  final String boton;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ColoresPoker.crema, height: 1.4),
        ),
        const SizedBox(height: 14),
        BotonMesa(texto: boton, chico: true, alPresionar: alPresionar),
      ],
    ),
  );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.estado, required this.alSalir});

  final EstadoMesaPoker estado;
  final VoidCallback alSalir;

  @override
  Widget build(BuildContext context) {
    final billetera = estado.billetera;
    return Padding(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ColoresPoker.cremaApagada,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (estado.sentado)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PildoraFichas(fichas: estado.misFichas),
                if (billetera != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Text(
                      '${fichasPoker(billetera)} en el casino',
                      style: const TextStyle(
                        color: ColoresPoker.cremaApagada,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// El paño con todo lo de arriba: los asientos, las cartas, las fichas y lo
/// que esta volando. Se dibuja con el ultimo estado; la coreografia tapa lo
/// que todavia no llego.
class _Mesa extends StatelessWidget {
  const _Mesa({
    required this.estado,
    required this.coreografia,
    required this.turno,
    this.alSentarme,
  });

  final EstadoMesaPoker estado;
  final CoreografiaPoker coreografia;
  final ValueNotifier<double> turno;
  final VoidCallback? alSentarme;

  /// Algo de [tamano] centrado en [centro].
  static Widget _en(Offset centro, Size tamano, Widget hijo, {Key? key}) =>
      Positioned(
        key: key,
        left: centro.dx - tamano.width / 2,
        top: centro.dy - tamano.height / 2,
        width: tamano.width,
        height: tamano.height,
        child: hijo,
      );

  /// Una pila de fichas con su base en [base].
  static Widget _pila(Offset base, int monto, double diametro) {
    final medida = PilaFichas.medida(diametro);
    return Positioned(
      left: base.dx - medida.width / 2,
      top: base.dy - (medida.height - 22 - diametro / 2),
      child: IgnorePointer(
        child: PilaFichas(monto: monto, diametro: diametro),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, area) {
      final geo = GeometriaMesa(area.biggest, yo: estado.yo);
      final c = coreografia;
      final mano = estado.mano;
      final terminada = mano != null && !mano.enJuego;
      final verResultado = terminada && !c.oculto(CoreografiaPoker.resultado);
      final ganadoras = verResultado
          ? estado.cincoGanadoras.toSet()
          : const <String>{};
      final resaltar = ganadoras.isNotEmpty;
      final comunes = mano?.comunitarias ?? const <String>[];
      final anchoComun = geo.anchoComun;
      final tamanoComun = Size(anchoComun, anchoComun * 1.4);
      final hijos = <Widget>[
        Positioned.fromRect(
          rect: geo.pano,
          child: const RepaintBoundary(
            child: CustomPaint(painter: PintorMesaPoker()),
          ),
        ),
      ];

      // Las cinco de la mesa.
      for (var i = 0; i < 5; i++) {
        final visible =
            i < comunes.length && !c.oculto(CoreografiaPoker.comunitaria(i));
        hijos.add(
          _en(
            geo.comunitaria(i),
            tamanoComun,
            visible
                ? CartaVolteable(
                    key: ValueKey('comun${mano!.id}$i'),
                    ancho: anchoComun,
                    codigo: comunes[i],
                    resaltada: ganadoras.contains(comunes[i]),
                    apagada: resaltar && !ganadoras.contains(comunes[i]),
                  )
                : HuecoCarta(ancho: anchoComun),
          ),
        );
      }

      // El bote y las apuestas de cada uno.
      final bote = c.valor(CoreografiaPoker.bote) ?? estado.boteVisible;
      if (bote > 0) hijos.add(_pila(geo.bote, bote, 22));
      for (final j in estado.jugadores) {
        final monto =
            c.valor(CoreografiaPoker.apuesta(j.posicion)) ??
            estado.apuestaVisible(j.posicion);
        if (monto > 0) hijos.add(_pila(geo.apuesta(j.posicion), monto, 16));
      }

      // Las cartas de los demas, chicas, del lado del centro: tapadas, o
      // dadas vuelta al final.
      for (final j in estado.jugadores) {
        if (j.posicion == estado.yo || j.retirado) continue;
        final vistas = j.cartasVistas;
        final mostrar =
            vistas != null && !c.oculto(CoreografiaPoker.vistas(j.posicion));
        for (var i = 0; i < 2; i++) {
          if (c.oculto(CoreografiaPoker.carta(j.posicion, i))) continue;
          final codigo = mostrar ? vistas[i] : null;
          final ancho = geo.anchoMano(j.posicion);
          hijos.add(
            _en(
              geo.mano(j.posicion, i),
              Size(ancho, ancho * 1.4),
              CartaVolteable(
                key: ValueKey('mano${mano!.id}${j.posicion}$i'),
                ancho: ancho,
                codigo: codigo,
                giro: geo.giroMano(j.posicion, i),
                resaltada: codigo != null && ganadoras.contains(codigo),
                apagada:
                    resaltar && codigo != null && !ganadoras.contains(codigo),
              ),
            ),
          );
        }
      }

      // Los asientos.
      for (var p = 0; p < 6; p++) {
        final asiento = estado.asiento(p);
        final caja = geo.cajaAsiento(p);
        if (asiento == null) {
          hijos.add(
            Positioned.fromRect(
              rect: caja,
              child: Align(
                alignment: Alignment.topCenter,
                child: AsientoLibre(alTocar: alSentarme),
              ),
            ),
          );
          continue;
        }
        hijos.add(
          Positioned.fromRect(
            key: ValueKey('asiento${asiento.usuarioId}'),
            rect: caja,
            child: Align(
              alignment: Alignment.topCenter,
              child: AsientoPokerVista(
                asiento: asiento,
                fichas: c.valor(CoreografiaPoker.fichas(p)) ?? asiento.fichas,
                esYo: estado.yo == p,
                jugador: estado.jugador(p),
                turno: mano != null && mano.enJuego && mano.turno == p
                    ? turno
                    : null,
                ganancia: verResultado ? mano.resultado[p] : null,
              ),
            ),
          ),
        );
      }

      // El boton del repartidor se desliza al siguiente en cada mano.
      if (mano != null) {
        final punto = geo.botonDealer(mano.boton);
        hijos.add(
          AnimatedPositioned(
            key: const ValueKey('dealer'),
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeInOutCubic,
            left: punto.dx - 10,
            top: punto.dy - 10,
            width: 20,
            height: 20,
            child: const BotonDealer(),
          ),
        );
      }

      // Mis cartas, grandes, encima de mi foto, y lo que tengo con la mesa.
      final yo = estado.yo;
      final miJugador = estado.miJugador;
      if (yo != null && miJugador != null && estado.misCartas.length == 2) {
        for (var i = 0; i < 2; i++) {
          if (c.oculto(CoreografiaPoker.carta(yo, i))) continue;
          final codigo = estado.misCartas[i];
          hijos.add(
            _en(
              geo.mano(yo, i),
              const Size(
                GeometriaMesa.anchoMiCarta,
                GeometriaMesa.anchoMiCarta * 1.4,
              ),
              CartaVolteable(
                key: ValueKey('mia${mano!.id}$i'),
                ancho: GeometriaMesa.anchoMiCarta,
                codigo: codigo,
                giro: geo.giroMano(yo, i),
                apagada:
                    miJugador.retirado ||
                    (resaltar && !ganadoras.contains(codigo)),
                resaltada: ganadoras.contains(codigo),
              ),
            ),
          );
        }
        final miMano = estado.miMano;
        final cartasQuietas =
            !c.oculto(CoreografiaPoker.carta(yo, 1)) &&
            !c.oculto(
              CoreografiaPoker.comunitaria(math.max(0, comunes.length - 1)),
            );
        if (miMano != null &&
            !miJugador.retirado &&
            cartasQuietas &&
            !verResultado) {
          final punto =
              geo.mano(yo, 1) +
              const Offset(GeometriaMesa.anchoMiCarta * .5 + 8, 0);
          hijos.add(
            Positioned(
              left: punto.dx,
              top: punto.dy - 11,
              child: IgnorePointer(child: _MiMano(texto: miMano)),
            ),
          );
        }
      }

      // Al final, con que gano el que mas se llevo.
      final ganador = verResultado ? estado.ganadorPrincipal : null;
      final valor = ganador == null ? null : estado.jugador(ganador)?.valor;
      if (valor != null) {
        hijos.add(
          Positioned(
            left: geo.pano.left + 16,
            right: area.maxWidth - geo.pano.right + 16,
            top: geo.comunitaria(0).dy + anchoComun * .7 + 10,
            child: Center(
              child: ManoGanadora(
                key: ValueKey('ganadora${mano!.id}'),
                texto: EvaluadorPoker.nombre(valor),
              ),
            ),
          ),
        );
      }

      // Lo que esta volando, encima de todo.
      for (final vuelo in c.vuelos) {
        hijos.add(_vuelo(geo, vuelo));
      }

      return Stack(clipBehavior: Clip.none, children: hijos);
    },
  );

  static Widget _vuelo(GeometriaMesa geo, VueloPoker vuelo) {
    final llave = ValueKey('vuelo${vuelo.id}');
    return switch (vuelo) {
      VueloFichas(:final monto) => FichasEnVuelo(
        key: llave,
        desde: geo.punto(vuelo.desde),
        hasta: geo.punto(vuelo.hasta),
        monto: monto,
        diametro: vuelo.desde is EnBote || vuelo.hasta is EnBote ? 20 : 16,
        duracion: vuelo.duracion,
      ),
      VueloCarta(:final codigo, :final bocaArriba, :final desvanecer) =>
        CartaEnVuelo(
          key: llave,
          carta:
              (codigo == null
                  ? null
                  : CartasPoker.carta(codigo, id: vuelo.id)) ??
              Carta(1, Palo.picas, vuelo.id),
          centro: geo.punto(vuelo.hasta),
          origen: geo.punto(vuelo.desde),
          ancho: desvanecer
              ? geo.anchoCarta(vuelo.desde)
              : geo.anchoCarta(vuelo.hasta),
          giro: geo.giroCarta(vuelo.hasta),
          bocaArriba: bocaArriba,
          desvanecer: desvanecer,
          duracion: vuelo.duracion,
        ),
    };
  }
}

/// "Par de ases": lo que tengo con la mesa, al lado de mis cartas.
class _MiMano extends StatelessWidget {
  const _MiMano({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 110),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: ColoresPoker.placa,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x80F2CC5C)),
    ),
    child: Text(
      texto,
      maxLines: 2,
      style: const TextStyle(
        color: ColoresPoker.oro,
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        height: 1.2,
      ),
    ),
  );
}

/// Lo de abajo: las jugadas cuando es mi turno, y si no, que esta pasando.
class _BarraAcciones extends StatelessWidget {
  const _BarraAcciones({
    required this.estado,
    required this.enviando,
    required this.ocultaResultado,
    required this.segundos,
    required this.turno,
    required this.alJugar,
    required this.alSubir,
    required this.alSentarse,
    required this.alVolver,
    required this.alRecargar,
    required this.alInvitar,
  });

  final EstadoMesaPoker estado;
  final bool enviando;

  /// Las fichas del final todavia van en camino: el resultado, despues.
  final bool ocultaResultado;
  final ValueNotifier<int> segundos;
  final ValueNotifier<double> turno;
  final void Function(String accion, {int monto}) alJugar;
  final VoidCallback alSubir;
  final VoidCallback alSentarse;
  final VoidCallback alVolver;
  final VoidCallback alRecargar;
  final VoidCallback alInvitar;

  @override
  Widget build(BuildContext context) {
    final mano = estado.mano;
    final miJugador = estado.miJugador;
    final enMano =
        estado.manoEnJuego && miJugador != null && !miJugador.retirado;

    Widget? boton;
    Widget texto;

    if (!estado.sentado) {
      texto = const _Texto('Estás mirando.');
      if (estado.asientos.length < 6) {
        boton = BotonMesa(
          texto: 'Sentarme',
          estilo: EstiloBoton.principal,
          alPresionar: enviando ? null : alSentarse,
        );
      }
    } else if (estado.miAsiento!.afuera) {
      texto = const _Texto(
        'Estás sentado afuera: se te pasó el turno dos veces. Si no '
        'vuelves en 20 minutos, MacIAs te levanta y tus fichas vuelven al '
        'casino.',
      );
      boton = BotonMesa(
        texto: 'Volver a jugar',
        estilo: EstiloBoton.principal,
        alPresionar: enviando ? null : alVolver,
      );
    } else if (estado.misFichas == 0 && !enMano) {
      texto = const _Texto('Te quedaste sin fichas en la mesa.');
      boton = BotonMesa(
        texto: 'Recargar',
        icono: Icons.add_circle_outline_rounded,
        estilo: EstiloBoton.principal,
        alPresionar: enviando ? null : alRecargar,
      );
    } else if (estado.esMiTurno) {
      return _MisJugadas(
        estado: estado,
        enviando: enviando,
        segundos: segundos,
        turno: turno,
        alJugar: alJugar,
        alSubir: alSubir,
      );
    } else {
      texto = _queEstaPasando(mano);
      if (!estado.manoEnJuego && estado.listos < 2) {
        boton = BotonMesa(
          texto: 'Invitar por WhatsApp',
          icono: Icons.send_rounded,
          alPresionar: alInvitar,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          texto,
          if (boton != null) ...[const SizedBox(height: 10), boton],
          if (boton == null && mano != null) const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _queEstaPasando(ManoPoker? mano) {
    if (mano == null || !mano.enJuego) {
      if (mano != null && mano.resultado.isNotEmpty) {
        return _Texto(
          ocultaResultado ? 'Se reparte el bote…' : _resultado(mano),
        );
      }
      if (estado.listos < 2) {
        return const _Texto(
          'Esperando un rival: con 2 ya se juega, no hace falta llenar la '
          'mesa.',
        );
      }
      return const _Texto('Repartiendo…');
    }
    final turno = mano.turno == null ? null : estado.asiento(mano.turno!);
    if (turno == null) return const _Texto('Repartiendo…');
    return ValueListenableBuilder<int>(
      valueListenable: segundos,
      builder: (context, s, _) =>
          _Texto('Turno de ${turno.primerNombre} · $s s'),
    );
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

class _Texto extends StatelessWidget {
  const _Texto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: Text(
      texto,
      key: ValueKey(texto.replaceAll(RegExp(r'\d+ s$'), '')),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: ColoresPoker.crema,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
    ),
  );
}

/// Mi turno: el reloj que se vacia y las tres jugadas.
class _MisJugadas extends StatelessWidget {
  const _MisJugadas({
    required this.estado,
    required this.enviando,
    required this.segundos,
    required this.turno,
    required this.alJugar,
    required this.alSubir,
  });

  final EstadoMesaPoker estado;
  final bool enviando;
  final ValueNotifier<int> segundos;
  final ValueNotifier<double> turno;
  final void Function(String accion, {int monto}) alJugar;
  final VoidCallback alSubir;

  @override
  Widget build(BuildContext context) {
    final falta = estado.falta;
    final igualarEsTodo = falta >= estado.misFichas;
    final apostando = (estado.mano?.apuesta ?? 0) == 0;
    final puedeSubirOTodo = estado.misFichas > falta;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, hijo) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: hijo,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: segundos,
              builder: (context, s, _) => Text(
                'Tu turno · $s s',
                style: TextStyle(
                  color: s <= 7 ? const Color(0xFFE5484D) : ColoresPoker.oro,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // El mismo reloj que el anillo de mi foto, en una barra.
            SizedBox(
              height: 4,
              child: ValueListenableBuilder<double>(
                valueListenable: turno,
                builder: (context, f, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: f,
                    backgroundColor: const Color(0x26F2CC5C),
                    color: f < .25 ? const Color(0xFFE5484D) : ColoresPoker.oro,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                              : () =>
                                    alJugar(igualarEsTodo ? 'todo' : 'igualar'),
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
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: ColoresPoker.oro,
                inactiveTrackColor: const Color(0x33E6E1D5),
                thumbColor: ColoresPoker.oro,
                overlayColor: const Color(0x29F2CC5C),
              ),
              child: Slider(
                value: _total.toDouble(),
                min: _minimo.toDouble(),
                max: _maximo.toDouble(),
                onChanged: (valor) => setState(() {
                  final redondeado = (valor / _paso).round() * _paso;
                  _total = redondeado.clamp(_minimo, _maximo);
                }),
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (texto, monto) in _rapidas)
                OpcionPoker(
                  texto: texto,
                  detalle: fichasPoker(monto),
                  elegida: _total == monto,
                  alTocar: () => setState(() => _total = monto),
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
