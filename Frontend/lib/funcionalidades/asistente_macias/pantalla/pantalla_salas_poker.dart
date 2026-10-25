import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/hoja_entrada_poker.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/mesa_poker.dart';
import '../logica/almacen_casino.dart';
import '../logica/casino.dart';
import '../logica/mesa_poker.dart';
import '../logica/repositorio_poker.dart';
import '../logica/sonidos_casino.dart';
import 'pantalla_mesa_poker.dart';

/// Las mesas de poker abiertas: sentarse en una o crear otra, con las fichas
/// del casino. Lo que se gana en la mesa vuelve al casino al levantarse.
class PantallaSalasPoker extends StatefulWidget {
  const PantallaSalasPoker({
    required this.nombre,
    this.almacen,
    this.repositorio = const RepositorioPokerSupabase(),
    this.sonidos,
    this.conSonido = true,
    super.key,
  });

  /// Tu nombre, para proponer el de la mesa.
  final String nombre;

  /// Las fichas del casino. Sin indicarlo, en memoria (pruebas).
  final AlmacenCasino? almacen;
  final RepositorioPoker repositorio;
  final SonidosMesa? sonidos;
  final bool conSonido;

  static Route<void> ruta({
    required String nombre,
    AlmacenCasino? almacen,
    RepositorioPoker repositorio = const RepositorioPokerSupabase(),
    SonidosMesa? sonidos,
    bool conSonido = true,
  }) => MaterialPageRoute(
    builder: (_) => PantallaSalasPoker(
      nombre: nombre,
      almacen: almacen,
      repositorio: repositorio,
      sonidos: sonidos,
      conSonido: conSonido,
    ),
  );

  @override
  State<PantallaSalasPoker> createState() => _PantallaSalasPokerState();
}

class _PantallaSalasPokerState extends State<PantallaSalasPoker> {
  late final AlmacenCasino _almacen =
      widget.almacen ?? AlmacenCasinoEnMemoria();
  List<SalaPoker>? _salas;
  int? _billetera;
  String? _error;
  bool _ocupado = false;
  VoidCallback? _dejarDeEscuchar;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarBilletera();
    _dejarDeEscuchar = widget.repositorio.escucharSalas(_cargar);
  }

  @override
  void dispose() {
    _dejarDeEscuchar?.call();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final salas = await widget.repositorio.salas();
      if (mounted) {
        setState(() {
          _salas = salas;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = mensajePoker(error));
    }
  }

  Future<int> _cargarBilletera() async {
    final fichas = await _almacen.fichas() ?? Casino.fichasIniciales;
    if (mounted) setState(() => _billetera = fichas);
    return fichas;
  }

  /// MacIAs presta las fichas de regalo, como en las otras mesas.
  Future<void> _pedirFichas() async {
    final antes = await _cargarBilletera();
    await _almacen.guardarFichas(antes + Casino.fichasIniciales);
    // Que el servidor ya las tenga antes de sentarse con ellas.
    await _cargarBilletera();
    if (mounted) {
      RetroalimentacionHaptica.exito();
      _avisar(
        'MacIAs te prestó ${fichasPoker(Casino.fichasIniciales)} fichas.',
      );
    }
  }

  /// Con cuantas me siento. Null si no alcanza o se arrepintio. Si MacIAs
  /// presta, la hoja vuelve a abrirse con las fichas nuevas.
  Future<int?> _elegirEntrada({
    required int minima,
    required int maxima,
    required int sugerida,
    required int ciegaGrande,
  }) async {
    for (var vez = 0; vez < 2; vez++) {
      final billetera = await _cargarBilletera();
      if (!mounted) return null;
      var pidio = false;
      final monto = await HojaEntradaPoker.mostrar(
        context,
        titulo: '¿Con cuántas te sientas?',
        minima: minima,
        maxima: maxima,
        sugerida: sugerida,
        billetera: billetera,
        ciegaGrande: ciegaGrande,
        // Si no alcanza ni para las fichas de regalo, MacIAs presta.
        alPedirFichas: billetera < Casino.fichasIniciales
            ? () => pidio = true
            : null,
      );
      if (!pidio) return monto;
      await _pedirFichas();
      if (!mounted) return null;
    }
    return null;
  }

  Future<void> _entrar(SalaPoker sala) async {
    if (_ocupado) return;
    if (sala.mia) return _abrir(sala.id);
    final monto = await _elegirEntrada(
      minima: sala.compraMinima,
      maxima: sala.compraMaxima,
      sugerida: sala.fichasIniciales,
      ciegaGrande: sala.ciegaGrande,
    );
    if (monto == null || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await widget.repositorio.sentarse(sala.id, fichas: monto);
      if (!mounted) return;
      setState(() => _ocupado = false);
      await _abrir(sala.id);
    } catch (error) {
      if (mounted) {
        setState(() => _ocupado = false);
        _avisar(mensajePoker(error));
      }
    }
  }

  Future<void> _abrir(String salaId) async {
    RetroalimentacionHaptica.accion();
    final volvieron = await Navigator.of(context).push<int>(
      PantallaMesaPoker.ruta(
        salaId: salaId,
        repositorio: widget.repositorio,
        sonidos: widget.sonidos,
        conSonido: widget.conSonido,
      ),
    );
    if (!mounted) return;
    await Future.wait([_cargar(), _cargarBilletera()]);
    if (mounted && volvieron != null && volvieron > 0) {
      _avisar('Volvieron ${fichasPoker(volvieron)} fichas a tu casino.');
    }
  }

  Future<void> _crear() async {
    final pedido = await showModalBottomSheet<(String, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF241D19),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (hoja) => _HojaCrearMesa(nombre: widget.nombre),
    );
    if (pedido == null || !mounted) return;
    final (nombre, ciegaGrande) = pedido;
    final monto = await _elegirEntrada(
      minima: ciegaGrande * 20,
      maxima: ciegaGrande * 100,
      sugerida: ciegaGrande * 50,
      ciegaGrande: ciegaGrande,
    );
    if (monto == null || !mounted) return;

    setState(() => _ocupado = true);
    try {
      final sala = await widget.repositorio.crearSala(
        nombre,
        ciegaGrande,
        fichas: monto,
      );
      if (!mounted) return;
      setState(() => _ocupado = false);
      await _abrir(sala);
    } catch (error) {
      if (mounted) {
        setState(() => _ocupado = false);
        _avisar(mensajePoker(error));
      }
    }
  }

  void _avisar(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ColoresPoker.fondo,
    body: Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: PintorSalaPoker()),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Volver al casino',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: ColoresPoker.crema,
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Póker',
                            style: TextStyle(
                              color: ColoresPoker.crema,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Con tus fichas del casino',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColoresPoker.cremaApagada,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_billetera != null) PildoraFichas(fichas: _billetera!),
                  ],
                ),
              ),
              Expanded(child: _cuerpo()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: BotonMesa(
                  texto: 'Crear una mesa',
                  icono: Icons.add_rounded,
                  estilo: EstiloBoton.principal,
                  alPresionar: _ocupado || _error != null ? null : _crear,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _cuerpo() {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ColoresPoker.crema, height: 1.4),
              ),
              const SizedBox(height: 14),
              BotonMesa(texto: 'Reintentar', alPresionar: _cargar, chico: true),
            ],
          ),
        ),
      );
    }
    final salas = _salas;
    if (salas == null) return const Center(child: IndicadorCarga());
    if (salas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No hay mesas abiertas. Crea una y avísales a tus amigos: con '
            'que se siente uno más, MacIAs reparte. Lo que ganes vuelve a tus '
            'fichas del casino al levantarte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresPoker.cremaApagada, height: 1.45),
          ),
        ),
      );
    }
    final enPoker = _almacen.enPoker;
    return RefreshIndicator(
      onRefresh: () => Future.wait([_cargar(), _cargarBilletera()]),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: salas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _TarjetaSala(
          sala: salas[i],
          ocupado: _ocupado,
          // Lo que tengo sentado ahi, si es la mia.
          enMesa: salas[i].mia && enPoker.fichas > 0 ? enPoker.fichas : null,
          alEntrar: () => _entrar(salas[i]),
        ),
      ),
    );
  }
}

class _TarjetaSala extends StatelessWidget {
  const _TarjetaSala({
    required this.sala,
    required this.ocupado,
    required this.alEntrar,
    this.enMesa,
  });

  final SalaPoker sala;
  final bool ocupado;
  final VoidCallback alEntrar;
  final int? enMesa;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF175A3C), Color(0xFF0B2F20)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: sala.mia ? ColoresPoker.oro : const Color(0x40F2CC5C),
        width: sala.mia ? 1.6 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x80000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sala.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColoresPoker.crema,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                enMesa != null
                    ? 'Tienes ${fichasPoker(enMesa!)} en esta mesa'
                    : 'Ciegas ${fichasPoker(sala.ciegaChica)}/'
                          '${fichasPoker(sala.ciegaGrande)} · entras con '
                          '${fichasPoker(sala.compraMinima)} a '
                          '${fichasPoker(sala.compraMaxima)}',
                maxLines: 2,
                style: TextStyle(
                  color: enMesa != null
                      ? ColoresPoker.oro
                      : ColoresPoker.cremaApagada,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < SalaPoker.asientos; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < sala.jugadores
                            ? ColoresPoker.oro
                            : const Color(0x33E6E1D5),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      sala.enJuego
                          ? '${sala.jugadores}/6 · jugando'
                          : sala.jugadores < 2
                          ? '${sala.jugadores}/6 · falta 1 para empezar'
                          : '${sala.jugadores}/6 · por empezar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ColoresPoker.cremaApagada,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        BotonMesa(
          texto: sala.mia
              ? 'Volver'
              : sala.llena
              ? 'Llena'
              : 'Sentarme',
          chico: true,
          estilo: sala.mia ? EstiloBoton.principal : EstiloBoton.terciario,
          alPresionar: ocupado || (sala.llena && !sala.mia) ? null : alEntrar,
        ),
      ],
    ),
  );
}

/// El nombre de la mesa y de cuanto son las ciegas.
class _HojaCrearMesa extends StatefulWidget {
  const _HojaCrearMesa({required this.nombre});

  final String nombre;

  @override
  State<_HojaCrearMesa> createState() => _HojaCrearMesaState();
}

class _HojaCrearMesaState extends State<_HojaCrearMesa> {
  late final _nombre = TextEditingController(
    text: widget.nombre.trim().isEmpty
        ? 'Mesa de la U'
        : 'Mesa de ${widget.nombre.trim().split(' ').first}',
  );
  int _ciegaGrande = 20;

  static const _ciegas = [10, 20, 50, 100];

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  bool get _valido {
    final largo = _nombre.text.trim().length;
    return largo >= 3 && largo <= 30;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloHojaMesa('Crear una mesa'),
        const SizedBox(height: 14),
        CampoPoker(
          controlador: _nombre,
          etiqueta: 'Nombre de la mesa',
          largoMaximo: 30,
          alCambiar: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ciegas',
          style: TextStyle(
            color: ColoresPoker.cremaApagada,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        // Dos por fila: en un telefono de 360 las cuatro juntas no entran
        // con las fichas debajo.
        for (final fila in [_ciegas.sublist(0, 2), _ciegas.sublist(2)]) ...[
          Row(
            children: [
              for (final grande in fila) ...[
                if (grande != fila.first) const SizedBox(width: 8),
                Expanded(
                  child: OpcionPoker(
                    texto: '${grande ~/ 2}/$grande',
                    detalle: 'desde ${fichasPoker(grande * 20)} fichas',
                    elegida: _ciegaGrande == grande,
                    alTocar: () => setState(() => _ciegaGrande = grande),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        const Text(
          'Te sientas con fichas del casino, y al levantarte vuelve lo que '
          'tengas en la mesa. Se juega desde 2: no hace falta llenarla.',
          style: TextStyle(
            color: ColoresPoker.cremaApagada,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        BotonMesa(
          texto: 'Crear y sentarme',
          estilo: EstiloBoton.principal,
          alPresionar: _valido
              ? () => Navigator.of(
                  context,
                ).pop((_nombre.text.trim(), _ciegaGrande))
              : null,
        ),
      ],
    ),
  );
}
