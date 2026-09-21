import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Una foto que viene de Storage, mostrada como corresponde.
///
/// Reemplaza a `Image.network` en todo el catalogo. Lo que arregla:
///
/// 1. DECODIFICAR AL TAMANO QUE SE VE. Las fotos se suben a 1280 px de
///    ancho, pero la tarjeta del inicio las pinta en 132 px de alto. Sin
///    decir nada, Flutter arma el mapa de bits completo: 1280 x 960 x 4
///    bytes son casi 5 MB de memoria POR FOTO. Veinte publicaciones en la
///    cuadricula llenan los 100 MB que Flutter guarda en memoria, empieza a
///    descartar, y al volver a subir la lista hay que decodificarlas otra
///    vez. Eso es el gris que tarda: no es la red, es el telefono rehaciendo
///    trabajo que ya habia hecho.
///
/// 2. GUARDARLAS EN DISCO. `Image.network` solo recuerda en memoria: al
///    cerrar la aplicacion se pierde todo y el catalogo entero se vuelve a
///    descargar desde cero. Con cache en disco, la segunda vez es instantanea.
///
/// 3. NO PARPADEAR. Una foto que ya estaba en cache aparece de una, sin el
///    fundido de entrada, que si no hace que la lista "titile" al desplazarse.
class FotoRed extends StatelessWidget {
  const FotoRed({
    required this.url,
    this.ajuste = BoxFit.cover,
    this.alineacion = Alignment.center,
    this.anchoVisible,
    this.marcador,
    this.alFallar,
    super.key,
  });

  final String url;
  final BoxFit ajuste;
  final Alignment alineacion;

  /// Ancho aproximado en pixeles logicos con el que se va a ver la foto.
  ///
  /// De aqui sale el tamano de decodificacion. Es una pista, no un recorte:
  /// la imagen se sigue mostrando completa, solo que su mapa de bits se arma
  /// a la medida en vez de a 1280 px. Sin este dato se decodifica entera,
  /// que es el caso que conviene evitar.
  final double? anchoVisible;

  /// Que mostrar mientras baja. Por defecto, un gris del color del tema.
  final Widget? marcador;

  /// Que mostrar si la foto no existe o falla la descarga.
  final Widget? alFallar;

  @override
  Widget build(BuildContext context) {
    final vacio = alFallar ?? const SizedBox.shrink();
    if (url.isEmpty) return vacio;

    // Las fotos recien elegidas (todavia sin subir) llegan como blob: o
    // data:, y el modo local usa rutas del dispositivo. Nada de eso se puede
    // cachear ni pedir por HTTP, asi que va por el camino de siempre.
    if (!url.startsWith('http')) {
      return Image.network(
        url,
        fit: ajuste,
        alignment: alineacion,
        errorBuilder: (_, _, _) => vacio,
      );
    }

    // La relacion de pixeles del dispositivo importa: 132 puntos logicos en
    // un telefono 3x son 396 pixeles reales. Decodificar a 132 se veria
    // borroso.
    //
    // Se redondea a saltos de 50 a proposito. Este numero forma parte de la
    // identidad de la imagen guardada: si cambia, aunque sea por un pixel,
    // deja de encontrarse la que ya estaba y hay que volver a bajarla. Al
    // rotar la pantalla o al animarse una transicion el ancho baila, y sin
    // redondear cada rebote generaba una copia nueva.
    final escala = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final anchoEnMemoria = anchoVisible == null
        ? null
        : ((anchoVisible! * escala / 50).ceil() * 50);

    // En la web manda `Image.network`, y no es un atajo: el almacen en disco
    // de `CachedNetworkImage` casi no funciona en un navegador, asi que cada
    // reconstruccion se iba a buscar la foto de nuevo y mientras tanto
    // enseñaba el hueco. El navegador ya guarda las fotos el mismo (las
    // servimos con un ano de cache), y la memoria de Flutter las devuelve
    // SIN esperar, que es lo que hace que al volver de otra pestaña la foto
    // ya este ahi. Las pestañas viven en un PageView y se destruyen al
    // salir, asi que esto pasa todo el tiempo.
    if (kIsWeb) {
      return Image.network(
        url,
        fit: ajuste,
        alignment: alineacion,
        cacheWidth: anchoEnMemoria,
        // Conserva lo ya dibujado mientras llega lo nuevo, en vez de
        // parpadear a vacio.
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => vacio,
        frameBuilder: (_, hijo, cuadro, vinoDeLaMemoria) =>
            cuadro != null || vinoDeLaMemoria
            ? hijo
            : marcador ?? const _Marcador(),
      );
    }

    // En el telefono si vale la pena: guarda en disco de verdad y sobrevive
    // a cerrar la aplicacion, cosa que `Image.network` no hace.
    return CachedNetworkImage(
      imageUrl: url,
      fit: ajuste,
      alignment: alineacion,
      memCacheWidth: anchoEnMemoria,
      // Sin fundido cuando ya estaba guardada: el efecto es para tapar una
      // espera, y si no hay espera solo hace parpadear la lista.
      fadeInDuration: const Duration(milliseconds: 180),
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, _) => marcador ?? const _Marcador(),
      errorWidget: (_, _, _) => vacio,
    );
  }
}

/// Relleno neutro mientras la foto baja. Del color del tema y sin girador:
/// veinte ruedas girando a la vez en una cuadricula marean mas que informan.
class _Marcador extends StatelessWidget {
  const _Marcador();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: .05)
        : Colors.black.withValues(alpha: .04),
  );
}
