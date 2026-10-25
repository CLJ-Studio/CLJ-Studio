import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fichas_blackjack.dart';
import 'mesa_casino.dart';
import 'mesa_poker.dart';

/// Con cuantas fichas del casino se sienta uno a una mesa (o recarga): de
/// 20 a 100 ciegas grandes, sin pasarse de lo que tiene. Lo que quede en la
/// mesa al levantarse vuelve al casino.
class HojaEntradaPoker extends StatefulWidget {
  const HojaEntradaPoker({
    required this.titulo,
    required this.minima,
    required this.maxima,
    required this.sugerida,
    required this.billetera,
    required this.ciegaGrande,
    this.boton = 'Sentarme',
    this.alPedirFichas,
    super.key,
  });

  final String titulo;
  final int minima;
  final int maxima;

  /// Con cuantas arranca la barra: las de la mesa (50 ciegas grandes).
  final int sugerida;

  /// Las fichas del casino que tengo.
  final int billetera;
  final int ciegaGrande;

  /// Lo que dice el boton: "Sentarme", "Recargar".
  final String boton;

  /// Si no me alcanza y MacIAs puede prestar: lo pide y la hoja se cierra.
  final VoidCallback? alPedirFichas;

  /// Devuelve con cuantas, o null si se cancelo.
  static Future<int?> mostrar(
    BuildContext context, {
    required String titulo,
    required int minima,
    required int maxima,
    required int sugerida,
    required int billetera,
    required int ciegaGrande,
    String boton = 'Sentarme',
    VoidCallback? alPedirFichas,
  }) => showModalBottomSheet<int>(
    context: context,
    // Mas alta que lo que deja una hoja comun (9/16 de la pantalla): crece
    // con lo que tiene y, en un telefono chico, se desplaza.
    isScrollControlled: true,
    backgroundColor: const Color(0xFF241D19),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => HojaEntradaPoker(
      titulo: titulo,
      minima: minima,
      maxima: maxima,
      sugerida: sugerida,
      billetera: billetera,
      ciegaGrande: ciegaGrande,
      boton: boton,
      alPedirFichas: alPedirFichas,
    ),
  );

  @override
  State<HojaEntradaPoker> createState() => _HojaEntradaPokerState();
}

class _HojaEntradaPokerState extends State<HojaEntradaPoker> {
  /// Lo mas que puedo poner: el tope de la mesa o lo que tengo.
  late final int _tope = math.min(widget.maxima, widget.billetera);
  late int _monto = widget.sugerida.clamp(
    widget.minima,
    math.max(widget.minima, _tope),
  );

  bool get _alcanza => _tope >= widget.minima;

  List<(String, int)> get _rapidas {
    final vistos = <int>{};
    return [
      for (final (texto, monto) in [
        ('Mínimo', widget.minima),
        ('La mesa', widget.sugerida),
        ('Máximo', _tope),
      ])
        if (monto >= widget.minima && monto <= _tope && vistos.add(monto))
          (texto, monto),
    ];
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloHojaMesa(widget.titulo),
        Row(
          children: [
            const FichaDibujada(valor: 1000, diametro: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tienes ${conMiles(widget.billetera)} en el casino',
                style: const TextStyle(
                  color: ColoresPoker.cremaApagada,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_alcanza) ..._eleccion() else ..._faltan(),
      ],
    ),
  );

  List<Widget> _eleccion() => [
    Text(
      fichasPoker(_monto),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: ColoresPoker.oro,
        fontWeight: FontWeight.w900,
        fontSize: 32,
      ),
    ),
    Text(
      '${_monto ~/ widget.ciegaGrande} ciegas grandes',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: ColoresPoker.cremaApagada,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
    if (_tope > widget.minima)
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: ColoresPoker.oro,
          inactiveTrackColor: const Color(0x33E6E1D5),
          thumbColor: ColoresPoker.oro,
          overlayColor: const Color(0x29F2CC5C),
        ),
        child: Slider(
          value: _monto.toDouble(),
          min: widget.minima.toDouble(),
          max: _tope.toDouble(),
          onChanged: (valor) => setState(() {
            final paso = widget.ciegaGrande;
            _monto = ((valor / paso).round() * paso).clamp(
              widget.minima,
              _tope,
            );
          }),
        ),
      )
    else
      const SizedBox(height: 10),
    Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (texto, monto) in _rapidas)
          OpcionPoker(
            texto: texto,
            detalle: fichasPoker(monto),
            elegida: _monto == monto,
            alTocar: () => setState(() => _monto = monto),
          ),
      ],
    ),
    const SizedBox(height: 12),
    const Text(
      'Al levantarte, lo que tengas en la mesa vuelve a tus fichas del '
      'casino.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ColoresPoker.cremaApagada,
        fontSize: 12,
        height: 1.35,
      ),
    ),
    const SizedBox(height: 14),
    BotonMesa(
      texto: '${widget.boton} con ${fichasPoker(_monto)}',
      estilo: EstiloBoton.principal,
      alPresionar: () => Navigator.of(context).pop(_monto),
    ),
  ];

  List<Widget> _faltan() {
    final alPedir = widget.alPedirFichas;
    return [
      Text(
        'Esta mesa pide al menos ${fichasPoker(widget.minima)} fichas y '
        'tienes ${fichasPoker(widget.billetera)}.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColoresPoker.crema,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        alPedir == null
            ? 'Junta más en la ruleta o el blackjack, o elige una mesa de '
                  'ciegas más chicas.'
            : 'Elige una mesa de ciegas más chicas, o pídele fichas a '
                  'MacIAs.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColoresPoker.cremaApagada,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 16),
      if (alPedir != null)
        BotonMesa(
          texto: 'MacIAs te presta ${conMiles(1000)}',
          icono: Icons.volunteer_activism_rounded,
          estilo: EstiloBoton.principal,
          alPresionar: () {
            Navigator.of(context).pop();
            alPedir();
          },
        )
      else
        BotonMesa(
          texto: 'Entendido',
          alPresionar: () => Navigator.of(context).pop(),
        ),
    ];
  }
}
