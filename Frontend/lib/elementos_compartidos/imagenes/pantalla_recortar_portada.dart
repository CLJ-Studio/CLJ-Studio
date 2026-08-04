import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../configuracion_aplicacion/modo_local.dart';
import 'servicio_imagenes.dart';

/// Editor comun para todas las portadas de locales y productos.
///
/// El marco siempre es 4:3 y el resultado se guarda realmente a 1200x900.
/// Así cada persona decide que parte de su foto entra en las tarjetas, en vez
/// de dejar que cada pantalla la recorte de una manera distinta.
class PantallaRecortarPortada extends StatefulWidget {
  const PantallaRecortarPortada({required this.original, super.key});

  final Uint8List original;

  @override
  State<PantallaRecortarPortada> createState() =>
      _PantallaRecortarPortadaState();
}

class _PantallaRecortarPortadaState extends State<PantallaRecortarPortada> {
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

  static Future<Uint8List> _redimensionar(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 1200,
      targetHeight: 900,
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF14161A),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: const Text(
        'Ajusta la imagen',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: Crop(
            image: widget.original,
            controller: _controlador,
            aspectRatio: 4 / 3,
            baseColor: const Color(0xFF14161A),
            maskColor: Colors.black.withValues(alpha: .62),
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
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              const Text(
                'Mueve la imagen y pellizca para hacer zoom · Formato 1200 × 900',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
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
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_procesando ? 'Preparando…' : 'Usar esta imagen'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Selecciona, encuadra y recién entonces sube una portada normalizada.
Future<String?> elegirRecortarYSubirPortada(
  BuildContext context, {
  required String etiqueta,
}) async {
  final elegida = await ServicioImagenes.elegir();
  if (elegida == null || !context.mounted) return null;

  final recortada = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      builder: (_) => PantallaRecortarPortada(original: elegida.bytes),
    ),
  );
  if (recortada == null || !context.mounted) return null;

  if (ModoLocal.activo) {
    return 'data:image/png;base64,${base64Encode(recortada)}';
  }
  return ServicioImagenes.subir(
    bytes: recortada,
    etiqueta: etiqueta,
    tipo: 'image/png',
  );
}
