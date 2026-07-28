import 'package:flutter/material.dart';

import '../estados_aplicacion/indicador_carga.dart';
import 'servicio_imagenes.dart';

/// Galeria de fotos de una publicacion, al estilo de un marketplace.
///
/// La primera foto es la portada: es la que se ve en las tarjetas del
/// catalogo, por eso se puede reordenar arrastrando y se marca cual es.
class SelectorGaleria extends StatelessWidget {
  const SelectorGaleria({
    required this.rutas,
    required this.alCambiar,
    this.maximo = 12,
    super.key,
  });

  final List<String> rutas;
  final ValueChanged<List<String>> alCambiar;
  final int maximo;

  @override
  Widget build(BuildContext context) => _SelectorGaleriaInterno(
    rutas: rutas,
    alCambiar: alCambiar,
    maximo: maximo,
  );
}

class _SelectorGaleriaInterno extends StatefulWidget {
  const _SelectorGaleriaInterno({
    required this.rutas,
    required this.alCambiar,
    required this.maximo,
  });

  final List<String> rutas;
  final ValueChanged<List<String>> alCambiar;
  final int maximo;

  @override
  State<_SelectorGaleriaInterno> createState() => _SelectorGaleriaState();
}

class _SelectorGaleriaState extends State<_SelectorGaleriaInterno> {
  bool _subiendo = false;

  Future<void> _agregar() async {
    if (widget.rutas.length >= widget.maximo) return;

    setState(() => _subiendo = true);
    try {
      final ruta = await ServicioImagenes.elegirYSubir(etiqueta: 'producto');
      if (ruta != null) widget.alCambiar([...widget.rutas, ruta]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo subir la foto.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  void _quitar(int indice) =>
      widget.alCambiar([...widget.rutas]..removeAt(indice));

  /// Cualquier foto puede pasar a ser la portada sin volver a subirla.
  void _hacerPortada(int indice) {
    final nuevas = [...widget.rutas];
    nuevas.insert(0, nuevas.removeAt(indice));
    widget.alCambiar(nuevas);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Fotos',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.rutas.length}/${widget.maximo}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'La primera es la portada.',
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < widget.rutas.length; i++)
            _Miniatura(
              url: ServicioImagenes.urlPublica(widget.rutas[i])!,
              esPortada: i == 0,
              alQuitar: () => _quitar(i),
              alHacerPortada: i == 0 ? null : () => _hacerPortada(i),
            ),
          if (widget.rutas.length < widget.maximo)
            _BotonAgregar(subiendo: _subiendo, alPresionar: _agregar),
        ],
      ),
    ],
  );
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.url,
    required this.esPortada,
    required this.alQuitar,
    this.alHacerPortada,
  });

  final String url;
  final bool esPortada;
  final VoidCallback alQuitar;
  final VoidCallback? alHacerPortada;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    height: 92,
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        ),
        if (esPortada)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF5C8A63),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Portada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
        else
          Positioned(
            left: 4,
            bottom: 4,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: alHacerPortada,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  child: Text(
                    'Portada',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: alQuitar,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({required this.subiendo, required this.alPresionar});

  final bool subiendo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: subiendo ? null : alPresionar,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        border: Border.all(color: const Color(0xFFC9CEC9)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: subiendo
            ? const SizedBox(
                width: 22,
                height: 22,
                child: IndicadorCarga(tamanio: 22),
              )
            : const Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFF7C827E),
              ),
      ),
    ),
  );
}
