import 'package:flutter/material.dart';

/// Envuelve una pantalla de foto para que no se cierre de un toque suelto.
///
/// El problema que resuelve: recortar una foto son varios pasos (abrir la
/// galeria, elegir, encuadrar) y cualquiera de las tres formas de salir de
/// una pantalla en Android — la flecha, el boton del sistema y el gesto de
/// deslizar desde el borde — descartaba todo ese trabajo sin decir nada. Un
/// roce al ajustar el encuadre y hay que empezar de cero.
///
/// Se pregunta solo cuando de verdad hay algo que perder ([hayCambios]): en
/// una pantalla recien abierta, preguntar estorba.
class SalirSinGuardarFoto extends StatelessWidget {
  const SalirSinGuardarFoto({
    required this.child,
    this.hayCambios = true,
    this.mensaje = '¿Descartar esta foto?',
    this.detalle = 'Vas a perder el encuadre que ajustaste.',
    super.key,
  });

  final Widget child;
  final bool hayCambios;
  final String mensaje;
  final String detalle;

  /// Pregunta y devuelve si hay que salir. Publica para que la flecha de la
  /// barra superior use exactamente el mismo camino que el gesto de volver:
  /// si cada una hiciera lo suyo, una preguntaria y la otra no.
  static Future<bool> confirmar(
    BuildContext context, {
    String mensaje = '¿Descartar esta foto?',
    String detalle = 'Vas a perder el encuadre que ajustaste.',
  }) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(contexto).colorScheme.error,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !hayCambios,
    onPopInvokedWithResult: (salio, _) async {
      if (salio || !context.mounted) return;
      if (await confirmar(context, mensaje: mensaje, detalle: detalle)) {
        if (context.mounted) Navigator.of(context).pop();
      }
    },
    child: child,
  );
}
