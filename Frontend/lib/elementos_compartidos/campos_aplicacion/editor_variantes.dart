import 'package:flutter/material.dart';

/// Cuantas variantes caben en una publicacion.
///
/// Un tope bajo a proposito: pasada una docena de sabores, el desplegable del
/// comprador deja de ayudar y lo que hace falta son publicaciones distintas.
const maximoVariantes = 12;

/// Los sabores (o tamanos, o versiones) de una publicacion.
///
/// POR QUE: sin esto, quien vende empanadas de queso y de carne tiene que
/// publicar dos veces lo mismo, con la misma foto y el mismo precio, y
/// corregir las dos cada vez que sube el precio. El catalogo se llena de
/// copias y al comprador le cuesta ver que en realidad es un solo producto.
///
/// Se escriben sueltas y se muestran como fichas porque se anaden de a poco y
/// se borran de a una; una caja de texto con comas parece mas simple hasta
/// que hay que quitar la del medio.
class EditorVariantes extends StatefulWidget {
  const EditorVariantes({
    required this.variantes,
    required this.alCambiar,
    super.key,
  });

  final List<String> variantes;
  final ValueChanged<List<String>> alCambiar;

  @override
  State<EditorVariantes> createState() => _EditorVariantesState();
}

class _EditorVariantesState extends State<EditorVariantes> {
  final _campo = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _campo.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _agregar() {
    final nombre = _campo.text.trim();
    if (nombre.isEmpty) return;

    // Repetir un sabor deja el desplegable con dos opciones identicas, que no
    // significan nada distinto para nadie.
    final yaEsta = widget.variantes.any(
      (existente) => existente.toLowerCase() == nombre.toLowerCase(),
    );
    if (yaEsta || widget.variantes.length >= maximoVariantes) {
      _campo.clear();
      return;
    }

    widget.alCambiar([...widget.variantes, nombre]);
    _campo.clear();
    // El foco se queda: los sabores se escriben en rafaga, uno tras otro.
    _foco.requestFocus();
  }

  void _quitar(String nombre) => widget.alCambiar(
    widget.variantes.where((existente) => existente != nombre).toList(),
  );

  @override
  Widget build(BuildContext context) {
    final lleno = widget.variantes.length >= maximoVariantes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones (opcional)',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Si es el mismo producto con varios sabores o tamaños, ponlos aquí '
          'en vez de publicarlo varias veces.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 10),
        if (widget.variantes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final nombre in widget.variantes)
                InputChip(
                  label: Text(nombre),
                  onDeleted: () => _quitar(nombre),
                  deleteIcon: const Icon(Icons.close_rounded, size: 17),
                  deleteButtonTooltipMessage: 'Quitar $nombre',
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _campo,
                focusNode: _foco,
                enabled: !lleno,
                maxLength: 40,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _agregar(),
                decoration: InputDecoration(
                  hintText: lleno
                      ? 'Ya son $maximoVariantes opciones'
                      : 'Por ejemplo: queso',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Agregar opción',
              onPressed: lleno ? null : _agregar,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
