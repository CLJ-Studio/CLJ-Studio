import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Indicador de espera único para toda la aplicación.
class IndicadorCarga extends StatelessWidget {
  const IndicadorCarga({this.tamanio = 110, super.key});

  final double tamanio;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    child: SizedBox.square(
      dimension: tamanio,
      child: Lottie.asset(
        'assets/animations/loader.json',
        fit: BoxFit.contain,
        repeat: true,
        frameRate: const FrameRate(30),
        filterQuality: FilterQuality.medium,
        backgroundLoading: true,
      ),
    ),
  );
}
