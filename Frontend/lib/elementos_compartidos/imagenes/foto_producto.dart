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
