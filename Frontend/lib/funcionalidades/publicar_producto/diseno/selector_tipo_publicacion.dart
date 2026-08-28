import 'package:flutter/material.dart';

/// Selector segmentado del tipo de publicación.
class SelectorTipoPublicacion extends StatelessWidget {
  const SelectorTipoPublicacion({
    required this.valor,
    required this.alCambiar,
    super.key,
  });
  final String valor;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF090B09)
          : const Color(0xFFE9ECE9),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        _OpcionTipo(
          texto: 'Producto',
          descripcion: 'Algo físico',
          icono: Icons.inventory_2_outlined,
          activo: valor == 'Producto',
          alPresionar: () => alCambiar('Producto'),
        ),
        const SizedBox(width: 6),
        _OpcionTipo(
          texto: 'Servicio',
          descripcion: 'Tu talento',
          icono: Icons.handyman_outlined,
          activo: valor == 'Servicio',
          alPresionar: () => alCambiar('Servicio'),
        ),
      ],
    ),
  );
}

class _OpcionTipo extends StatelessWidget {
  const _OpcionTipo({
    required this.texto,
    required this.descripcion,
    required this.icono,
    required this.activo,
    required this.alPresionar,
  });

  final String texto;
  final String descripcion;
  final IconData icono;
  final bool activo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: activo ? const Color(0xFF138A5B) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alPresionar,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  color: activo
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  size: 23,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texto,
                        style: TextStyle(
                          color: activo
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        descripcion,
                        style: TextStyle(
                          color: activo
                              ? Colors.white70
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
