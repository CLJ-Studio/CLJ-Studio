import 'package:flutter/material.dart';

import '../../funcionalidades/inicio_marketplace/modelos/variante_producto.dart';

/// Cuantas variantes caben en una publicacion.
///
/// Un tope bajo a proposito: pasada una docena de sabores, el desplegable del
/// comprador deja de ayudar y lo que hace falta son publicaciones distintas.
const maximoVariantes = 12;

/// Los sabores (o tamanos, o versiones) de una publicacion, con su precio.
///
/// POR QUE: sin esto, quien vende empanadas de queso y de carne tiene que
/// publicar dos veces lo mismo, con la misma foto, y corregir las dos cada vez
/// que sube el precio. El catalogo se llena de copias.
///
/// EL PRECIO ES OPCIONAL y ese es el punto: dejarlo vacio significa "vale lo
/// que el producto", que es el caso normal. Solo se escribe en el sabor que
/// cuesta distinto. Obligar a ponerlo en los doce seria peor que no tenerlo.
///
/// Cada variante es una fila y no una ficha porque una ficha no tiene donde
/// meter un precio; y se editan en el sitio, sin un campo aparte para
/// agregar, para que corregir un nombre no obligue a borrarlo y reescribirlo.
class EditorVariantes extends StatefulWidget {
  const EditorVariantes({
    required this.variantes,
    required this.alCambiar,
    required this.precioProducto,
    this.titulo,
    super.key,
  });

  final List<VarianteEditable> variantes;
  final ValueChanged<List<VarianteEditable>> alCambiar;

  /// Lo que cuesta el producto, para poder decir en el campo vacio con que
  /// precio se va a cobrar si no se escribe nada.
  final double? precioProducto;

  /// Encabezado propio, para cuando el contenedor no pone ninguno.
  ///
  /// En el formulario de publicar va sin el: la tarjeta que lo envuelve ya
  /// dice "Sabores o tamaños", y poner debajo otro titulo dejaba dos
  /// encabezados pegados diciendo lo mismo.
  final String? titulo;

  @override
  State<EditorVariantes> createState() => _EditorVariantesState();
}

class _EditorVariantesState extends State<EditorVariantes> {
  /// Los controladores son la fuente de la verdad mientras se escribe, y de
  /// ellos sale lo que se le devuelve al formulario en cada cambio.
  late List<_FilaVariante> _filas = [
    for (final variante in widget.variantes) _FilaVariante.desde(variante),
  ];

  @override
  void didUpdateWidget(covariant EditorVariantes anterior) {
    super.didUpdateWidget(anterior);
    // Solo cuando el cambio viene de fuera (recuperar un borrador), no cuando
    // viene de escribir aqui: reconstruir en cada tecla perderia el cursor.
    if (widget.variantes.length != _filas.length) {
      for (final fila in _filas) {
        fila.liberar();
      }
      _filas = [
        for (final variante in widget.variantes) _FilaVariante.desde(variante),
      ];
    }
  }

  @override
  void dispose() {
    for (final fila in _filas) {
      fila.liberar();
    }
    super.dispose();
  }

  /// Las filas sin nombre no se emiten: una fila recien agregada esta vacia
  /// hasta que se escriba algo, y una variante sin nombre no significa nada.
  void _avisar() => widget.alCambiar([
    for (final fila in _filas)
      if (fila.nombre.text.trim().isNotEmpty) fila.aVariante(),
  ]);

  void _agregar() {
    if (_filas.length >= maximoVariantes) return;
    setState(() => _filas = [..._filas, _FilaVariante.vacia()]);
    // El foco va a la fila nueva: se agregan de a varias, una tras otra.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _filas.isNotEmpty) _filas.last.foco.requestFocus();
    });
  }

  void _quitar(int indice) {
    final fuera = _filas[indice];
    setState(() => _filas = [..._filas]..removeAt(indice));
    fuera.liberar();
    _avisar();
  }

  @override
  Widget build(BuildContext context) {
    final lleno = _filas.length >= maximoVariantes;
    final precio = widget.precioProducto;
    final pistaPrecio = precio == null || precio <= 0
        ? 'Bs'
        : 'Bs ${precio.toStringAsFixed(0)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.titulo case final String encabezado) ...[
          Text(
            encabezado,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'Si es el mismo producto con varios sabores o tamaños, ponlos aquí '
          'en vez de publicarlo varias veces. El precio solo hace falta en los '
          'que cuesten distinto.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _filas.length; i++) ...[
          _Fila(
            fila: _filas[i],
            pistaPrecio: pistaPrecio,
            alEscribir: _avisar,
            alQuitar: () => _quitar(i),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: lleno ? null : _agregar,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              lleno
                  ? 'Ya son $maximoVariantes opciones'
                  : _filas.isEmpty
                  ? 'Agregar una opción'
                  : 'Agregar otra',
            ),
          ),
        ),
      ],
    );
  }
}

/// Una fila del editor con sus dos campos vivos.
class _FilaVariante {
  _FilaVariante({required String nombre, required String precio})
    : nombre = TextEditingController(text: nombre),
      precio = TextEditingController(text: precio);

  factory _FilaVariante.vacia() => _FilaVariante(nombre: '', precio: '');

  factory _FilaVariante.desde(VarianteEditable variante) => _FilaVariante(
    nombre: variante.nombre,
    precio: variante.precio == null ? '' : variante.precio!.toStringAsFixed(2),
  );

  final TextEditingController nombre;
  final TextEditingController precio;
  final FocusNode foco = FocusNode();

  VarianteEditable aVariante() => VarianteEditable(
    nombre: nombre.text.trim(),
    // Vacio o ilegible significa "vale lo que el producto", no cero.
    precio: double.tryParse(precio.text.trim().replaceAll(',', '.')),
  );

  void liberar() {
    nombre.dispose();
    precio.dispose();
    foco.dispose();
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.fila,
    required this.pistaPrecio,
    required this.alEscribir,
    required this.alQuitar,
  });

  final _FilaVariante fila;
  final String pistaPrecio;
  final VoidCallback alEscribir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 3,
        child: TextField(
          controller: fila.nombre,
          focusNode: fila.foco,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => alEscribir(),
          decoration: const InputDecoration(
            hintText: 'Por ejemplo: queso',
            counterText: '',
            isDense: true,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: TextField(
          controller: fila.precio,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => alEscribir(),
          decoration: InputDecoration(
            // La pista es el precio del producto: asi se ve que dejarlo
            // vacio no es un error ni un cero, es "el mismo de siempre".
            hintText: pistaPrecio,
            isDense: true,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Quitar esta opción',
        onPressed: alQuitar,
        icon: const Icon(Icons.close_rounded, size: 20),
      ),
    ],
  );
}
