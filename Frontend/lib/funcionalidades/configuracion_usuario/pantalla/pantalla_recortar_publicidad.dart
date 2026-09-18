import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../inicio_marketplace/modelos/publicidad.dart';

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
      final normalizada = await _redimensionar(recortada);
      if (mounted) Navigator.of(context).pop(normalizada);
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo preparar la imagen.')),
      );
    }
  }

  Future<Uint8List> _redimensionar(Uint8List bytes) async {
    final ubicacion = widget.ubicacion;
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: ubicacion.anchoRecomendado,
      targetHeight: ubicacion.altoRecomendado,
      allowUpscaling: true,
    );
    final cuadro = await codec.getNextFrame();
    final datos = await cuadro.image.toByteData(format: ui.ImageByteFormat.png);
    cuadro.image.dispose();
    codec.dispose();
    if (datos == null) throw StateError('Imagen sin datos');
    return datos.buffer.asUint8List();
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
