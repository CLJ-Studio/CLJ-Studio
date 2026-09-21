import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Indicador de espera único para toda la aplicación.
///
/// La animación es un archivo Lottie, y si ese archivo no carga el widget
/// dibujaba un hueco: como el fondo del tema es crema, una pantalla que
/// estaba esperando se veia igual que una pantalla rota. Por eso hay una
/// rueda normal de respaldo. Un indicador que no se ve no es un indicador.
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
        errorBuilder: (_, _, _) => const Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    ),
  );
}
