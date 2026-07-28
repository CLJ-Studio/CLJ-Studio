import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../mi_local/logica/controlador_mi_local.dart';
import '../../mi_local/pantalla/pantalla_mi_local.dart';
import '../arbol/arbol_publicar_producto.dart';

/// Reúne la creación de publicaciones y la administración del local.
///
/// El selector vive dentro de la sección Publicar para que "Mi local" no
/// cambie la cantidad ni los índices de la barra de navegación principal.
class SeccionPublicarMiLocal extends StatelessWidget {
  const SeccionPublicarMiLocal({
    required this.miLocal,
    required this.segmento,
    super.key,
  });

  final ControladorMiLocal miLocal;
  final ValueNotifier<int> segmento;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([miLocal, segmento]),
    builder: (context, _) {
      final tieneLocal = miLocal.tieneLocal;
      final seleccionado = tieneLocal ? segmento.value.clamp(0, 1) : 0;
      final tema = Theme.of(context);
      final esOscuro = tema.brightness == Brightness.dark;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: seleccionado,
                backgroundColor: esOscuro
                    ? const Color(0xFF252725)
                    : const Color(0xFFF0F1EF),
                thumbColor: esOscuro ? tema.colorScheme.primary : Colors.black,
                padding: const EdgeInsets.all(4),
                children: {
                  0: _EtiquetaSegmento(
                    icono: Icons.add_circle_outline_rounded,
                    texto: 'Publicar',
                    activo: seleccionado == 0,
                    esOscuro: esOscuro,
                  ),
                  if (tieneLocal)
                    1: _EtiquetaSegmento(
                      icono: Icons.storefront_rounded,
                      texto: 'Mi local',
                      activo: seleccionado == 1,
                      esOscuro: esOscuro,
                    ),
                },
                onValueChanged: (valor) {
                  if (valor != null) segmento.value = valor;
                },
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: seleccionado,
              children: [
                ArbolPublicarProducto(miLocal: miLocal),
                if (tieneLocal) PantallaMiLocal(controlador: miLocal),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _EtiquetaSegmento extends StatelessWidget {
  const _EtiquetaSegmento({
    required this.icono,
    required this.texto,
    required this.activo,
    required this.esOscuro,
  });

  final IconData icono;
  final String texto;
  final bool activo;
  final bool esOscuro;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = activo
        ? esOscuro
              ? tema.colorScheme.onPrimary
              : Colors.white
        : esOscuro
        ? Colors.white
        : Colors.black;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      style: TextStyle(
        color: color,
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 19, color: color),
            const SizedBox(width: 7),
            Text(texto),
          ],
        ),
      ),
    );
  }
}
