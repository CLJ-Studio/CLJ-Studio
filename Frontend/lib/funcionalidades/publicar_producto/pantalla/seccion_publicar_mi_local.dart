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
            child: _SelectorSegmentado(
              seleccionado: seleccionado,
              tieneLocal: tieneLocal,
              esOscuro: esOscuro,
              colorActivo: esOscuro ? tema.colorScheme.primary : Colors.black,
              alSeleccionar: (valor) => segmento.value = valor,
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

class _SelectorSegmentado extends StatelessWidget {
  const _SelectorSegmentado({
    required this.seleccionado,
    required this.tieneLocal,
    required this.esOscuro,
    required this.colorActivo,
    required this.alSeleccionar,
  });

  final int seleccionado;
  final bool tieneLocal;
  final bool esOscuro;
  final Color colorActivo;
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 50,
    padding: const EdgeInsets.all(4),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: esOscuro ? const Color(0xFF252725) : const Color(0xFFF0F1EF),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: seleccionado == 0
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: tieneLocal ? .5 : 1,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorActivo,
                borderRadius: BorderRadius.circular(21),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => alSeleccionar(0),
                child: _EtiquetaSegmento(
                  icono: Icons.add_circle_outline_rounded,
                  texto: 'Publicar',
                  activo: seleccionado == 0,
                  esOscuro: esOscuro,
                ),
              ),
            ),
            if (tieneLocal)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => alSeleccionar(1),
                  child: _EtiquetaSegmento(
                    icono: Icons.storefront_rounded,
                    texto: 'Mi local',
                    activo: seleccionado == 1,
                    esOscuro: esOscuro,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
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
