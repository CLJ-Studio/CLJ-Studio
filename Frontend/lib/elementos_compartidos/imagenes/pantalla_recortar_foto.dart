import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

/// Ajusta la foto antes de subirla, con la máscara del círculo a la vista.
///
/// El avatar se pinta redondo, así que una foto rectangular se recorta sola
/// por el centro y suele cortar la cara. Aquí se decide qué parte entra,
/// como en cualquier red social.
///
/// Devuelve los bytes recortados, o null si se cancela.
class PantallaRecortarFoto extends StatefulWidget {
  const PantallaRecortarFoto({required this.original, super.key});

  final Uint8List original;

  @override
  State<PantallaRecortarFoto> createState() => _PantallaRecortarFotoState();
}

class _PantallaRecortarFotoState extends State<PantallaRecortarFoto> {
  final _controlador = CropController();
  bool _recortando = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    // Fondo oscuro fijo, en los dos temas: lo que importa es ver la foto, y
    // un lienzo claro compite con ella.
    backgroundColor: const Color(0xFF14161A),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: const Text(
        'Ajusta tu foto',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: Crop(
            image: widget.original,
            controller: _controlador,
            // Cuadrado y con máscara redonda: el recorte sale cuadrado y el
            // avatar lo muestra en círculo, así que lo que se ve aquí es
            // exactamente lo que se verá después.
            aspectRatio: 1,
            withCircleUi: true,
            baseColor: const Color(0xFF14161A),
            maskColor: Colors.black.withValues(alpha: .6),
            onCropped: (resultado) {
              if (!mounted) return;
              switch (resultado) {
                case CropSuccess(:final croppedImage):
                  Navigator.of(context).pop(croppedImage);
                case CropFailure():
                  setState(() => _recortando = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo recortar la foto.'),
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
                'Arrastra y pellizca para encuadrar',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _recortando
                      ? null
                      : () {
                          setState(() => _recortando = true);
                          _controlador.crop();
                        },
                  icon: _recortando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_recortando ? 'Recortando…' : 'Usar esta foto'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
