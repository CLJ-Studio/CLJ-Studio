import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modelos/publicidad.dart';

/// Como se pide la imagen de un aviso, igual en todas partes.
///
/// EN EL TELEFONO PASA POR LA CACHE EN DISCO, como las fotos de producto.
/// Con `Image.network`, que solo recuerda en memoria y vuelve a bajar todo en
/// cada apertura, en la app nativa los avisos no llegaban a aparecer: el
/// banner se quedaba casi blanco (visto en un Galaxy A15 el 2026-10-03; con
/// este cambio, en el mismo telefono, aparecen). Pesan bastante: hasta esa
/// fecha se subian como PNG de 1680 x 1000. En la PWA no pasaba porque el
/// navegador guarda las imagenes por su cuenta (ver `FotoRed`).
///
/// Y EN EL TELEFONO SE DECODIFICA AL ANCHO CON EL QUE SE VE. Ese ancho forma
/// parte de la identidad de la imagen en memoria: la precarga y el dibujo
/// tienen que pedir exactamente el mismo numero, o la precarga no sirve de
/// nada. Por eso los dos pasan por aqui, y por eso se redondea a saltos de
/// 100.
///
/// En la web NO se achica al decodificar: el motor web lo hace copiando
/// pixeles, sin filtro (`scaleImageIfNeeded` dibuja con un `Paint` por
/// defecto), y el texto de un aviso quedaria dentado. Ahi se decodifica
/// entera y la achica la GPU al dibujarla, como se hizo siempre.
ImageProvider proveedorImagenPublicidad(
  BuildContext context,
  Publicidad aviso, {
  required double anchoVisible,
}) {
  final url = aviso.urlImagen;
  if (kIsWeb || !url.startsWith('http')) return NetworkImage(url);
  final escala = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
  final ancho = (anchoVisible * escala / 100).ceil() * 100;
  // Nunca agranda: si la pieza es mas angosta que la pantalla, queda como
  // vino.
  return ResizeImage(CachedNetworkImageProvider(url), width: ancho);
}

/// Empieza a bajar un aviso antes de que aparezca en pantalla.
///
/// Si falla no se avisa a nadie: cuando la diapositiva lo pida, su propio
/// `errorBuilder` se encarga de sacarlo.
void precargarPublicidad(
  BuildContext context,
  Publicidad aviso, {
  required double anchoVisible,
}) {
  precacheImage(
    proveedorImagenPublicidad(context, aviso, anchoVisible: anchoVisible),
    context,
    onError: (_, _) {},
  );
}

/// La imagen de un aviso, estirada a todo el espacio que le den.
///
/// `BoxFit.cover` a propósito: el aviso se preparó con la proporción de su
/// ubicación, así que cubrir llena el marco sin deformarlo. Si alguien sube
/// una imagen con otra proporción se recorta por los bordes, y por eso la
/// recomendación para los anunciantes es dejar los logos y el texto dentro
/// del centro de la pieza.
class ImagenPublicidad extends StatelessWidget {
  const ImagenPublicidad({
    required this.aviso,
    required this.anchoVisible,
    this.alFallar,
    this.alTocar,
    this.marcador,
    super.key,
  });

  final Publicidad aviso;

  /// Ancho aproximado en puntos con el que se va a ver. Decide a que tamano
  /// se decodifica; ver [proveedorImagenPublicidad].
  final double anchoVisible;

  /// Se avisa cuando la imagen no se pudo cargar, para que quien muestra el
  /// aviso lo saque de la lista y deje su lugar al respaldo.
  ///
  /// Pasa de verdad: basta con que una fila apunte a un archivo que no está
  /// en el bucket (un nombre mal escrito, una imagen borrada) para que el
  /// espacio publicitario quede en blanco. Sin este aviso, el hueco se queda
  /// ahí hasta que alguien note que el inicio se ve raro.
  final VoidCallback? alFallar;

  /// Que hacer al tocar el aviso. Solo responde cuando ya se ve: mientras
  /// baja, el toque es de lo que haya en [marcador].
  final VoidCallback? alTocar;

  /// Lo que se ve mientras baja. Por defecto, un gris suave: el aviso ya
  /// reservó su altura, y un hueco que aparece de golpe empuja el feed justo
  /// cuando alguien está leyendo.
  final Widget? marcador;

  static const _fundido = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    Widget tocable(Widget imagen) {
      final tocar = alTocar;
      return tocar == null
          ? imagen
          : GestureDetector(onTap: tocar, child: imagen);
    }

    return Image(
      image: proveedorImagenPublicidad(
        context,
        aviso,
        anchoVisible: anchoVisible,
      ),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Si el aviso se actualiza, el anterior sigue a la vista hasta que
      // llega el nuevo, en vez de pasar por el marcador.
      gaplessPlayback: true,
      // El título es interno, pero es lo único que describe la pieza a quien
      // usa lector de pantalla; sin esto anunciaría "imagen" y nada más.
      semanticLabel: aviso.titulo.isEmpty ? null : aviso.titulo,
      frameBuilder: (_, hijo, cuadro, sincronica) {
        // Ya estaba en memoria: aparece de una, sin fundido.
        if (sincronica) return tocable(hijo);
        // Tuvo que esperar: entra fundiendose sobre el marcador. La
        // estructura es la misma antes y despues de llegar, para que nada
        // se vuelva a montar en el cambio.
        final llego = cuadro != null;
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              ignoring: llego,
              child: AnimatedOpacity(
                opacity: llego ? 0 : 1,
                duration: _fundido,
                child: marcador ?? const _Marcador(),
              ),
            ),
            IgnorePointer(
              ignoring: !llego,
              child: AnimatedOpacity(
                opacity: llego ? 1 : 0,
                duration: _fundido,
                curve: Curves.easeOut,
                child: tocable(hijo),
              ),
            ),
          ],
        );
      },
      // Una imagen rota no debe dejar un cuadro negro con un icono de error en
      // medio del inicio. Se avisa hacia arriba (fuera del build, que si no
      // Flutter se queja de un setState en pleno dibujado) y mientras tanto no
      // se muestra nada.
      errorBuilder: (_, _, _) {
        final avisar = alFallar;
        if (avisar != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => avisar());
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: .05)
        : Colors.black.withValues(alpha: .04),
  );
}

/// Abre el enlace de un aviso en el navegador del sistema.
///
/// Va fuera de la app (`externalApplication`) porque un anuncio lleva al
/// sitio del anunciante: abrirlo dentro dejaría al estudiante navegando una
/// web ajena sin barra de direcciones, sin saber dónde está.
///
/// La migración 49 obliga a que `link_url` sea http(s) con dominio, así que
/// aquí no puede llegar un `javascript:` ni un `intent://`.
Future<void> abrirEnlacePublicidad(
  BuildContext context,
  Publicidad aviso,
) async {
  final destino = Uri.tryParse(aviso.enlaceUrl ?? '');
  if (destino == null) return;

  final mensajero = ScaffoldMessenger.of(context);
  if (!await launchUrl(destino, mode: LaunchMode.externalApplication)) {
    mensajero
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
