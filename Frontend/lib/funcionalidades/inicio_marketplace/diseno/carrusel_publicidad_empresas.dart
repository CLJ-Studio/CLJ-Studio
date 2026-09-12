import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../modelos/publicidad.dart';
import 'imagen_publicidad.dart';

/// Carrusel horizontal con los avisos de empresas.
///
/// A diferencia del banner grande, aquí no hay autoplay ni indicadores: son
/// tarjetas que se deslizan con el dedo. Cada una es un anunciante distinto,
/// y moverlas solas haría que quien está mirando una la pierda.
///
/// Si no hay avisos vigentes la sección desaparece entera, sin dejar un
/// hueco ni un título huérfano: un espacio publicitario vacío se ve como un
/// error de carga.
class CarruselPublicidadEmpresas extends StatefulWidget {
  const CarruselPublicidadEmpresas({required this.avisos, super.key});

  final List<Publicidad> avisos;

  @override
  State<CarruselPublicidadEmpresas> createState() =>
      _CarruselPublicidadEmpresasState();
}

class _CarruselPublicidadEmpresasState
    extends State<CarruselPublicidadEmpresas> {
  /// Alto en puntos lógicos. El ancho sale de la proporción 270 × 104, que
  /// es la medida con la que los anunciantes preparan sus imágenes.
  static const _alto = 104.0;
  static const _ancho = 270.0;

  /// Avisos cuya imagen no cargó. Una tarjeta en blanco dentro del carrusel
  /// parece un hueco de diseño, así que se saca de la fila.
  final Set<String> _rotos = {};

  void _descartar(Publicidad aviso) {
    if (!mounted || _rotos.contains(aviso.id)) return;
    setState(() => _rotos.add(aviso.id));
  }

  @override
  Widget build(BuildContext context) {
    final visibles = widget.avisos
        .where((aviso) => !_rotos.contains(aviso.id))
        .toList(growable: false);

    if (visibles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _alto,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: visibles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, indice) => SizedBox(
          width: _ancho,
          child: _TarjetaPublicidad(
            aviso: visibles[indice],
            alFallar: () => _descartar(visibles[indice]),
          ),
        ),
      ),
    );
  }
}

class _TarjetaPublicidad extends StatelessWidget {
  const _TarjetaPublicidad({required this.aviso, this.alFallar});

  final Publicidad aviso;
  final VoidCallback? alFallar;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? ConfiguracionTema.grafito
        : Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      // Sin enlace la tarjeta no responde al toque: un aviso que se hunde
      // al tocarlo y no lleva a ningún lado se siente roto.
      onTap: aviso.tieneEnlace
          ? () => abrirEnlacePublicidad(context, aviso)
          : null,
      child: ImagenPublicidad(aviso: aviso, alFallar: alFallar),
    ),
  );
}
