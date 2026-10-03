import 'package:flutter/material.dart';

import 'foto_red.dart';
import 'normalizar_portada.dart';

/// La forma que tiene una foto de publicacion en cualquier parte de la app.
///
/// Es la misma con la que se guarda: `normalizarPortada` recorta toda portada
/// a 1200 x 900 justamente para que el catalogo no tenga que recortar por su
/// cuenta. Se declara aqui a partir de esas dos medidas para que cambiar una
/// no deje a la otra atras.
const proporcionFotoProducto = anchoPortada / altoPortada;

/// La foto de una publicacion, siempre con la misma proporcion.
///
/// POR QUE EXISTE: cada pantalla dibujaba la foto en la caja que le venia
/// bien —132 px de alto en el inicio, lo que sobrara en la cuadricula, 190 px
/// en "mis publicaciones", 108 x 138 (vertical!) en el carrito, 330 px en el
/// detalle—. Como todas recortan con `BoxFit.cover`, la misma foto perdia un
/// trozo distinto en cada sitio: el producto que se veia entero en el inicio
/// aparecia descabezado en el detalle. Al usar la proporcion en la que la
/// foto fue guardada, no se recorta nada y el producto se ve igual siempre.
///
/// El alto sale del ancho disponible, asi que quien la use tiene que darle un
/// ancho acotado (una columna de cuadricula, una tarjeta, el cuerpo de la
/// pantalla) y no ponerla dentro de un `Expanded` vertical.
class FotoProducto extends StatelessWidget {
  const FotoProducto({
    required this.url,
    required this.anchoVisible,
    this.alFallar,
    super.key,
  });

  /// Ruta publica de la portada. Null cuando la publicacion no tiene foto.
  final String? url;

  /// Ancho aproximado en pixeles logicos, para decidir a que tamano se
  /// decodifica. Ver `FotoRed.anchoVisible`.
  final double anchoVisible;

  /// Lo que se dibuja sin foto o si la descarga falla; normalmente el emoji.
  final Widget? alFallar;

  @override
  Widget build(BuildContext context) {
    final vacio = alFallar ?? const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: proporcionFotoProducto,
      child: switch (url) {
        final String ruta when ruta.isNotEmpty => FotoRed(
          url: ruta,
          anchoVisible: anchoVisible,
          alFallar: vacio,
        ),
        _ => vacio,
      },
    );
  }
}

/// A que ancho se decodifica la foto de una tarjeta de publicacion.
///
/// Es parte de la identidad de la imagen en memoria: quien quiera reusar la
/// foto que la tarjeta ya tiene cargada (el detalle, mientras baja la grande)
/// tiene que pedirla con este mismo numero.
const anchoFotoTarjeta = 220.0;

/// La etiqueta que une una foto de publicacion entre dos pantallas.
///
/// [prefijo] distingue el lugar de donde se abrio: la misma publicacion puede
/// estar a la vez en el carrusel de populares y en la cuadricula, y dos
/// `Hero` con la misma etiqueta en una pantalla no pueden convivir.
String etiquetaFotoProducto(String prefijo, int indice) =>
    '$prefijo-imagen-producto-$indice';

/// La foto de una tarjeta que, al abrir la publicacion, viaja hasta su lugar
/// en el detalle, y al volver regresa a la tarjeta.
///
/// En el vuelo se dibuja siempre la foto de la tarjeta, que ya esta cargada.
/// Si se usara la del detalle (lo normal en un `Hero`), volaria un recuadro
/// vacio mientras la version grande todavia baja. Las esquinas de arriba se
/// enderezan en el camino, porque en el detalle la foto va a sangre.
class FotoProductoViajera extends StatelessWidget {
  const FotoProductoViajera({
    required this.etiqueta,
    required this.radio,
    required this.child,
    super.key,
  });

  final String etiqueta;

  /// Radio de las esquinas de arriba en la tarjeta.
  final double radio;

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Hero(tag: etiqueta, flightShuttleBuilder: _enVuelo, child: child);

  Widget _enVuelo(
    BuildContext contextoVuelo,
    Animation<double> animacion,
    HeroFlightDirection direccion,
    BuildContext desde,
    BuildContext hacia,
  ) {
    final deLaTarjeta =
        (direccion == HeroFlightDirection.push ? desde : hacia).widget as Hero;
    return AnimatedBuilder(
      animation: animacion,
      builder: (_, foto) => ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radio * (1 - animacion.value)),
        ),
        child: foto,
      ),
      child: deLaTarjeta.child,
    );
  }
}
