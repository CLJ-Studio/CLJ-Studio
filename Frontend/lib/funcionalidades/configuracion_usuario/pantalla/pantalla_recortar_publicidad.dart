import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/codificar_jpeg.dart';
import '../../inicio_marketplace/modelos/publicidad.dart';

/// Lleva un recorte a la medida de su ubicacion y lo deja listo para subir.
///
/// AGRANDA CON FILTRO SUAVE. Antes se usaba `instantiateImageCodec` con
/// `targetWidth`, y en la web eso agranda copiando pixeles: un recorte chico
/// quedaba hecho cuadritos dentro del PNG, y asi se veia despues en todos
/// lados. Ahora se dibuja con interpolacion; un recorte chico sale algo
/// borroso, pero no en bloques, y ademas se avisa antes (ver
/// [recorteChicoPara]).
///
/// JPEG Y NO PNG, igual que las portadas (ver `comoJpeg`). Un aviso de
/// 1680 x 1000 en PNG puede pesar megas, y en el telefono tardaba tanto en
/// bajar que el banner se quedaba en blanco.
///
/// Devuelve tambien el ancho del recorte original, que es lo que dice si la
/// imagen alcanzaba para el espacio.
Future<({Uint8List bytes, int anchoRecorte})> prepararImagenPublicidad(
  Uint8List recorte,
  UbicacionPublicidad ubicacion,
) async {
  final codec = await ui.instantiateImageCodec(recorte);
  final cuadro = await codec.getNextFrame();
  final original = cuadro.image;
  try {
    final ancho = ubicacion.anchoRecomendado;
    final alto = ubicacion.altoRecomendado;
    final destino = ui.Rect.fromLTWH(0, 0, ancho * 1.0, alto * 1.0);
    final grabadora = ui.PictureRecorder();
    ui.Canvas(grabadora)
      // Lo transparente de un PNG quedaria negro en JPEG. Blanco es como se
      // veia sobre la tarjeta del carrusel.
      ..drawRect(destino, ui.Paint()..color = const ui.Color(0xFFFFFFFF))
      ..drawImageRect(
        original,
        ui.Rect.fromLTWH(0, 0, original.width * 1.0, original.height * 1.0),
        destino,
        // Para agrandar, interpolacion cubica; para achicar, la de las
        // portadas, que promedia y no deja dientes de sierra.
        ui.Paint()
          ..filterQuality = original.width < ancho
              ? ui.FilterQuality.high
              : ui.FilterQuality.medium,
      );
    final dibujo = grabadora.endRecording();
    final imagen = await dibujo.toImage(ancho, alto);
    dibujo.dispose();
    try {
      return (bytes: await comoJpeg(imagen), anchoRecorte: original.width);
    } finally {
      imagen.dispose();
    }
  } finally {
    original.dispose();
    codec.dispose();
  }
}

/// Si un recorte de [anchoRecorte] pixeles se va a ver borroso en
/// [ubicacion]. Menos de la mitad del ancho pedido ya se nota en un telefono.
bool recorteChicoPara(int anchoRecorte, UbicacionPublicidad ubicacion) =>
    anchoRecorte * 2 < ubicacion.anchoRecomendado;

/// Permite encuadrar un anuncio antes de subirlo.
///
/// El marco usa exactamente la proporción del espacio elegido y el resultado
/// se normaliza a la resolución recomendada. Así la imagen que se guarda es
/// la misma que verá el usuario, sin recortes inesperados en el inicio.
class PantallaRecortarPublicidad extends StatefulWidget {
  const PantallaRecortarPublicidad({
    required this.original,
    required this.ubicacion,
    super.key,
  });

  final Uint8List original;
  final UbicacionPublicidad ubicacion;

  @override
  State<PantallaRecortarPublicidad> createState() =>
      _PantallaRecortarPublicidadState();
}

class _PantallaRecortarPublicidadState
    extends State<PantallaRecortarPublicidad> {
  final _controlador = CropController();
  bool _procesando = false;

  Future<void> _entregar(Uint8List recortada) async {
    try {
      final preparada = await prepararImagenPublicidad(
        recortada,
        widget.ubicacion,
      );
      if (!mounted) return;
      if (recorteChicoPara(preparada.anchoRecorte, widget.ubicacion) &&
          !await _usarIgualSiendoChica(preparada.anchoRecorte)) {
        if (mounted) setState(() => _procesando = false);
        return;
      }
      if (mounted) Navigator.of(context).pop(preparada.bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo preparar la imagen.')),
      );
    }
  }

  /// Pregunta antes de subir una imagen que se va a ver borrosa.
  ///
  /// No se prohibe: puede que no haya otra. Pero quien la sube tiene que
  /// saberlo antes de que el aviso aparezca asi en el inicio de todos.
  Future<bool> _usarIgualSiendoChica(int anchoRecorte) async {
    final usar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('La imagen es chica'),
        content: Text(
          'El recorte mide $anchoRecorte px de ancho y este espacio pide '
          '${widget.ubicacion.anchoRecomendado} px: en el inicio se va a ver '
          'borroso. Para que salga nítido, usa una imagen más grande o '
          'recorta menos.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Ajustar de nuevo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Usar igual'),
          ),
        ],
      ),
    );
    return usar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = widget.ubicacion;
    return Scaffold(
      backgroundColor: const Color(0xFF1D211E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Ajusta el anuncio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.original,
              controller: _controlador,
              aspectRatio: ubicacion.proporcion,
              baseColor: const Color(0xFF1D211E),
              maskColor: const Color(0xFF1D211E).withValues(alpha: .68),
              onCropped: (resultado) {
                if (!mounted) return;
                switch (resultado) {
                  case CropSuccess(:final croppedImage):
                    _entregar(croppedImage);
                  case CropFailure():
                    setState(() => _procesando = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo recortar la imagen.'),
                      ),
                    );
                }
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                Text(
                  '${ubicacion.etiqueta} · '
                  '${ubicacion.resolucionRecomendada}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Mueve la imagen y pellizca para ajustar el encuadre.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _procesando
                        ? null
                        : () {
                            setState(() => _procesando = true);
                            _controlador.crop();
                          },
                    icon: _procesando
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _procesando ? 'Preparando…' : 'Usar esta imagen',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
