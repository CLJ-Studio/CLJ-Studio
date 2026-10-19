import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../diseno/mesa_casino.dart';
import '../diseno/mesa_poker.dart';
import '../logica/mesa_poker.dart';
import '../logica/repositorio_poker.dart';
import '../logica/sonidos_casino.dart';
import 'pantalla_mesa_poker.dart';

/// Las mesas de poker abiertas: sentarse en una o crear otra.
class PantallaSalasPoker extends StatefulWidget {
  const PantallaSalasPoker({
    required this.nombre,
    this.repositorio = const RepositorioPokerSupabase(),
    this.sonidos,
    this.conSonido = true,
    super.key,
  });

  /// Tu nombre, para proponer el de la mesa.
  final String nombre;
  final RepositorioPoker repositorio;
  final SonidosMesa? sonidos;
  final bool conSonido;

  static Route<void> ruta({
    required String nombre,
    RepositorioPoker repositorio = const RepositorioPokerSupabase(),
    SonidosMesa? sonidos,
    bool conSonido = true,
  }) => MaterialPageRoute(
    builder: (_) => PantallaSalasPoker(
      nombre: nombre,
      repositorio: repositorio,
      sonidos: sonidos,
      conSonido: conSonido,
    ),
  );

  @override
  State<PantallaSalasPoker> createState() => _PantallaSalasPokerState();
}

class _PantallaSalasPokerState extends State<PantallaSalasPoker> {
  List<SalaPoker>? _salas;
  String? _error;
  bool _ocupado = false;
  VoidCallback? _dejarDeEscuchar;

  @override
  void initState() {
    super.initState();
    _cargar();
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

  Future<void> _entrar(String salaId, {bool sentarse = true}) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      if (sentarse) await widget.repositorio.sentarse(salaId);
      if (!mounted) return;
      RetroalimentacionHaptica.accion();
      await Navigator.of(context).push(
        PantallaMesaPoker.ruta(
          salaId: salaId,
          repositorio: widget.repositorio,
          sonidos: widget.sonidos,
          conSonido: widget.conSonido,
        ),
      );
    } catch (error) {
      if (mounted) _avisar(mensajePoker(error));
    } finally {
      if (mounted) setState(() => _ocupado = false);
      await _cargar();
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

    setState(() => _ocupado = true);
    try {
      final sala = await widget.repositorio.crearSala(pedido.$1, pedido.$2);
      if (!mounted) return;
      setState(() => _ocupado = false);
      await _entrar(sala, sentarse: false);
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
    body: SafeArea(
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
                        "Texas Hold'em · mesas de hasta 6",
                        style: TextStyle(
                          color: ColoresPoker.cremaApagada,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
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
            'No hay mesas abiertas. Crea una y avísales a tus amigos: '
            'cuando se sienten dos, MacIAs reparte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ColoresPoker.cremaApagada, height: 1.45),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: salas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _TarjetaSala(
          sala: salas[i],
          ocupado: _ocupado,
          alEntrar: () => _entrar(salas[i].id),
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
  });

  final SalaPoker sala;
  final bool ocupado;
  final VoidCallback alEntrar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2C2350), Color(0xFF15102C)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: sala.mia ? ColoresPoker.oro : const Color(0x33F2CC5C),
        width: sala.mia ? 1.6 : 1,
      ),
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
                'Ciegas ${fichasPoker(sala.ciegaChica)}/'
                '${fichasPoker(sala.ciegaGrande)} · te sientas con '
                '${fichasPoker(sala.fichasIniciales)}',
                style: const TextStyle(
                  color: ColoresPoker.cremaApagada,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
                          : '${sala.jugadores}/6 · esperando',
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

  static const _ciegas = [20, 50, 100, 200];

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
        TextField(
          controller: _nombre,
          maxLength: 30,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: ColoresPoker.crema),
          decoration: const InputDecoration(
            labelText: 'Nombre de la mesa',
            labelStyle: TextStyle(color: ColoresPoker.cremaApagada),
            counterStyle: TextStyle(color: ColoresPoker.cremaApagada),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ciegas',
          style: TextStyle(
            color: ColoresPoker.cremaApagada,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final grande in _ciegas)
              ChoiceChip(
                label: Text('${grande ~/ 2}/$grande'),
                selected: _ciegaGrande == grande,
                onSelected: (_) => setState(() => _ciegaGrande = grande),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Cada uno se sienta con ${fichasPoker(_ciegaGrande * 50)} fichas de '
          'la mesa. No son las del casino ni dinero.',
          style: const TextStyle(
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
