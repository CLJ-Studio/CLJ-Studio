import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/animaciones/escala_al_presionar.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import 'cartas_blackjack.dart';
import 'fichas_blackjack.dart';

// Las piezas que comparten las mesas del casino de MacIAs: la barra de
// arriba con tus fichas, el estante de fichas, los botones y las hojas del
// menu.

/// La barra de arriba de una mesa: salir, el nombre, tus fichas y el menu.
class BarraMesa extends StatelessWidget {
  const BarraMesa({
    required this.llaveFichas,
    required this.fichas,
    required this.titulo,
    required this.subtitulo,
    this.alMenu,
    this.salir = 'Salir de la mesa',
    super.key,
  });

  final GlobalKey llaveFichas;
  final int fichas;
  final String titulo;
  final String subtitulo;
  final VoidCallback? alMenu;

  /// Lo que dice el boton de cerrar.
  final String salir;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        IconButton(
          tooltip: salir,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded, color: ConfiguracionTema.crema),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ConfiguracionTema.crema,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0x99E6E1D5),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        PildoraFichas(key: llaveFichas, fichas: fichas),
        if (alMenu != null)
          IconButton(
            tooltip: 'Más opciones',
            onPressed: alMenu,
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: ConfiguracionTema.crema,
            ),
          )
        else
          const SizedBox(width: 12),
      ],
    ),
  );
}

/// Tus fichas: el numero corre hasta el nuevo valor.
class PildoraFichas extends StatelessWidget {
  const PildoraFichas({required this.fichas, super.key});

  final int fichas;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tus fichas: $fichas',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1714),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColoresCarta.oro.withValues(alpha: .75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FichaDibujada(valor: 1000, diametro: 22),
          const SizedBox(width: 7),
          TweenAnimationBuilder<double>(
            tween: Tween(end: fichas.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, valor, _) => Text(
              conMiles(valor.round()),
              style: const TextStyle(
                color: ColoresCarta.oroClaro,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Una ficha del estante. En el blackjack se toca y vuela a la apuesta; en
/// la ruleta se elige ([seleccionada]: sube y brilla) y despues se toca el
/// paño.
class FichaRack extends StatelessWidget {
  const FichaRack({
    required this.llave,
    required this.valor,
    required this.habilitada,
    required this.alTocar,
    this.seleccionada,
    this.diametro = 50,
    super.key,
  });

  final GlobalKey llave;
  final int valor;
  final bool habilitada;
  final VoidCallback alTocar;

  /// Null si el estante no elige (el blackjack).
  final bool? seleccionada;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final elegida = seleccionada ?? false;
    return Semantics(
      button: true,
      enabled: habilitada,
      selected: seleccionada,
      label: valor == valorTodo
          ? 'All in'
          : seleccionada == null
          ? 'Apostar ${conMiles(valor)}'
          : 'Ficha de ${conMiles(valor)}',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: habilitada ? 1 : .3,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          offset: Offset(0, elegida ? -.16 : 0),
          child: EscalaAlPresionar(
            escala: .88,
            builder: (context, alResaltar) => Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: habilitada ? alTocar : null,
                onHighlightChanged: alResaltar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: elegida
                        ? [
                            BoxShadow(
                              color: ColoresCarta.oroClaro.withValues(
                                alpha: .75,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : const [],
                  ),
                  child: SizedBox.square(
                    key: llave,
                    dimension: diametro,
                    child: FichaDibujada(valor: valor, diametro: diametro),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum EstiloBoton { principal, secundario, terciario }

class BotonMesa extends StatelessWidget {
  const BotonMesa({
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.estilo = EstiloBoton.terciario,
    this.resaltado = false,
    this.chico = false,
    this.alto,
    this.etiqueta,
    super.key,
  });

  final String texto;
  final IconData? icono;
  final VoidCallback? alPresionar;
  final EstiloBoton estilo;

  /// MacIAs lo recomienda: brilla.
  final bool resaltado;
  final bool chico;
  final double? alto;

  /// Lo que lee el lector de pantalla, si el boton es solo un icono.
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final habilitado = alPresionar != null;
    final altura = alto ?? (chico ? 40.0 : 46.0);
    final color = switch (estilo) {
      EstiloBoton.principal => const Color(0xFF2B1E05),
      EstiloBoton.secundario => const Color(0xFF2E2A26),
      EstiloBoton.terciario => ConfiguracionTema.crema,
    };
    final radio = BorderRadius.circular(altura / 2);
    Widget boton = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: habilitado ? 1 : .35,
      child: EscalaAlPresionar(
        escala: .95,
        builder: (context, alResaltar) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: estilo == EstiloBoton.principal
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ColoresCarta.oroClaro, ColoresCarta.oro],
                  )
                : null,
            color: switch (estilo) {
              EstiloBoton.principal => null,
              EstiloBoton.secundario => const Color(0xFFF3EBDD),
              EstiloBoton.terciario => const Color(0x14FFFFFF),
            },
            borderRadius: radio,
            border: estilo == EstiloBoton.terciario
                ? Border.all(
                    color: ConfiguracionTema.crema.withValues(alpha: .4),
                  )
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radio,
              onTap: habilitado
                  ? () {
                      RetroalimentacionHaptica.accion();
                      alPresionar!();
                    }
                  : null,
              onHighlightChanged: alResaltar,
              child: SizedBox(
                height: altura,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: chico ? 11 : 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icono != null)
                        Icon(icono, size: chico ? 16 : 19, color: color),
                      if (icono != null && texto.isNotEmpty)
                        SizedBox(width: chico ? 4 : 7),
                      if (texto.isNotEmpty)
                        Flexible(
                          child: Text(
                            texto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: chico ? 13 : 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (resaltado && habilitado) {
      boton = BrilloDorado(radio: radio, child: boton);
    }
    final nombre = etiqueta ?? texto;
    return Semantics(
      button: true,
      enabled: habilitado,
      label: resaltado ? '$nombre (lo que haría MacIAs)' : nombre,
      excludeSemantics: true,
      child: boton,
    );
  }
}

/// Un brillo dorado que late alrededor de lo que MacIAs recomienda.
class BrilloDorado extends StatefulWidget {
  const BrilloDorado({required this.radio, required this.child, super.key});

  final BorderRadius radio;
  final Widget child;

  @override
  State<BrilloDorado> createState() => _BrilloDoradoState();
}

class _BrilloDoradoState extends State<BrilloDorado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _latido,
    child: widget.child,
    builder: (context, hijo) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.radio,
        boxShadow: [
          BoxShadow(
            color: ColoresCarta.oroClaro.withValues(
              alpha: .35 + .45 * _latido.value,
            ),
            blurRadius: 8 + 10 * _latido.value,
            spreadRadius: 1 + 2 * _latido.value,
          ),
        ],
      ),
      child: hijo,
    ),
  );
}

class OpcionMenuMesa extends StatelessWidget {
  const OpcionMenuMesa({
    required this.icono,
    required this.titulo,
    required this.alTocar,
    this.detalle,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icono, color: ColoresCarta.oroClaro),
    title: Text(
      titulo,
      style: const TextStyle(
        color: ConfiguracionTema.crema,
        fontWeight: FontWeight.w800,
      ),
    ),
    subtitle: detalle == null
        ? null
        : Text(
            detalle!,
            style: TextStyle(
              color: ConfiguracionTema.crema.withValues(alpha: .6),
            ),
          ),
    onTap: alTocar,
  );
}

class TituloHojaMesa extends StatelessWidget {
  const TituloHojaMesa(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texto,
      style: const TextStyle(
        color: ColoresCarta.oroClaro,
        fontWeight: FontWeight.w900,
        fontSize: 20,
      ),
    ),
  );
}

class ReglaMesa extends StatelessWidget {
  const ReglaMesa(this.titulo, this.detalle, {super.key});

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: ConfiguracionTema.crema,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detalle,
          style: TextStyle(
            color: ConfiguracionTema.crema.withValues(alpha: .72),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
