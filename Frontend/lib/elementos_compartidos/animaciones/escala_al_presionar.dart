import 'dart:async';

import 'package:flutter/material.dart';

/// Hunde un poco lo que se toca, para que el dedo sienta respuesta.
///
/// POR QUE EXISTE: las tarjetas de publicacion no mostraban nada al tocarlas.
/// Su relleno pinta encima de la onda del `InkWell`, asi que entre el toque y
/// la pantalla nueva no pasaba nada visible, y ese hueco se siente como que la
/// aplicacion se trabo aunque no sea asi.
///
/// Se engancha al resaltado del `InkWell` y no a los dedos directamente: el
/// resaltado ya distingue un toque de un desplazamiento, asi que la tarjeta
/// no se hunde cuando solo se esta pasando la lista.
class EscalaAlPresionar extends StatefulWidget {
  const EscalaAlPresionar({
    required this.builder,
    this.escala = .965,
    super.key,
  });

  /// Construye lo que se hunde. [alResaltar] va al `onHighlightChanged` del
  /// `InkWell` de adentro.
  final Widget Function(BuildContext context, ValueChanged<bool> alResaltar)
  builder;

  /// Cuanto se achica mientras esta presionado.
  final double escala;

  @override
  State<EscalaAlPresionar> createState() => _EscalaAlPresionarState();
}

class _EscalaAlPresionarState extends State<EscalaAlPresionar> {
  /// Un toque rapido presiona y suelta casi en el mismo cuadro: sin este
  /// minimo la animacion no llega a verse.
  static const _minimoHundido = Duration(milliseconds: 90);

  bool _hundido = false;
  DateTime _desde = DateTime.now();
  Timer? _soltar;

  void _alResaltar(bool resaltado) {
    _soltar?.cancel();
    if (resaltado) {
      _desde = DateTime.now();
      if (!_hundido) setState(() => _hundido = true);
      return;
    }
    final falta = _minimoHundido - DateTime.now().difference(_desde);
    if (falta <= Duration.zero) {
      if (mounted) setState(() => _hundido = false);
      return;
    }
    _soltar = Timer(falta, () {
      if (mounted) setState(() => _hundido = false);
    });
  }

  @override
  void dispose() {
    _soltar?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _hundido ? widget.escala : 1,
    // Baja rapido, como algo que cede al dedo; vuelve un poco mas lento y
    // con un rebote apenas visible, como algo que se suelta.
    duration: Duration(milliseconds: _hundido ? 110 : 260),
    curve: _hundido ? Curves.easeOut : Curves.easeOutBack,
    child: widget.builder(context, _alResaltar),
  );
}
