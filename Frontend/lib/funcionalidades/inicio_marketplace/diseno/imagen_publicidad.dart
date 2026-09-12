import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modelos/publicidad.dart';

/// La imagen de un aviso, estirada a todo el espacio que le den.
///
/// `BoxFit.cover` a propósito: el aviso se preparó con la proporción de su
/// ubicación, así que cubrir llena el marco sin deformarlo. Si alguien sube
/// una imagen con otra proporción se recorta por los bordes, y por eso la
/// recomendación para los anunciantes es dejar los logos y el texto dentro
/// del centro de la pieza.
class ImagenPublicidad extends StatelessWidget {
  const ImagenPublicidad({required this.aviso, super.key});

  final Publicidad aviso;

  @override
  Widget build(BuildContext context) => Image.network(
    aviso.urlImagen,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    // El título es interno, pero es lo único que describe la pieza a quien
    // usa lector de pantalla; sin esto anunciaría "imagen" y nada más.
    semanticLabel: aviso.titulo.isEmpty ? null : aviso.titulo,
    // Mientras baja se deja el espacio en gris en vez de saltar: el aviso ya
    // reservó su altura, y un hueco que aparece de golpe empuja el feed
    // justo cuando alguien está leyendo.
    loadingBuilder: (context, hijo, progreso) =>
        progreso == null ? hijo : const _Marcador(),
    // Una imagen rota no debe dejar un cuadro negro con un icono de error en
    // medio del inicio; simplemente no se muestra nada.
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
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
