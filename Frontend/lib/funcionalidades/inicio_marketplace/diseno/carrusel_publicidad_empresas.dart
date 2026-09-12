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
class CarruselPublicidadEmpresas extends StatelessWidget {
  const CarruselPublicidadEmpresas({required this.avisos, super.key});

  final List<Publicidad> avisos;

  /// Alto en puntos lógicos. El ancho sale de la proporción 270 × 104, que
  /// es la medida con la que los anunciantes preparan sus imágenes.
  static const _alto = 104.0;
  static const _ancho = 270.0;

  @override
  Widget build(BuildContext context) {
    if (avisos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _alto,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: avisos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, indice) => SizedBox(
          width: _ancho,
          child: _TarjetaPublicidad(aviso: avisos[indice]),
        ),
      ),
    );
  }
}

class _TarjetaPublicidad extends StatelessWidget {
  const _TarjetaPublicidad({required this.aviso});

  final Publicidad aviso;

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
      onTap: aviso.tieneEnlace ? () => abrirEnlacePublicidad(context, aviso) : null,
      child: ImagenPublicidad(aviso: aviso),
    ),
  );
}
