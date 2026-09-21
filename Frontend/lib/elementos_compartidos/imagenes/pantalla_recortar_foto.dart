import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import 'codificar_jpeg.dart';
import 'rotar_imagen.dart';
import 'salir_sin_guardar_foto.dart';

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

  /// Lo que se esta encuadrando. Cambia al girar.
  late Uint8List _imagen = widget.original;
  bool _girando = false;

  /// El recortador entrega PNG. Se convierte antes de devolverlo: un avatar
  /// en PNG ocupa varias veces lo mismo en JPEG y se ve igual dentro de un
  /// circulo de cincuenta pixeles.
  Future<void> _entregar(Uint8List recortada) async {
    try {
      final liviana = await bytesComoJpeg(recortada);
      if (mounted) Navigator.of(context).pop(liviana);
    } catch (_) {
      // Si la conversion falla, mejor la foto pesada que ninguna foto.
      if (mounted) Navigator.of(context).pop(recortada);
    }
  }

  Future<void> _girar() async {
    if (_recortando || _girando) return;
    setState(() => _girando = true);
    try {
      final girada = await rotarUnCuarto(_imagen);
      if (mounted) setState(() => _imagen = girada);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo girar la foto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _girando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SalirSinGuardarFoto(
    // Mientras recorta ya no hay vuelta atras que preguntar: el resultado
    // esta por llegar y la pantalla se cierra sola.
    hayCambios: !_recortando,
    child: Scaffold(
      // Fondo oscuro fijo, en los dos temas: lo que importa es ver la foto, y
      // un lienzo claro compite con ella.
      backgroundColor: const Color(0xFF474646),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE6E1D5),
        // La flecha pasa por la misma confirmacion que el gesto de volver.
        leading: BackButton(
          onPressed: () async {
            if (_recortando) return;
            if (await SalirSinGuardarFoto.confirmar(context) && mounted) {
              if (context.mounted) Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Ajusta tu foto',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Girar',
            onPressed: _recortando || _girando ? null : _girar,
            icon: _girando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE6E1D5),
                    ),
                  )
                : const Icon(Icons.rotate_90_degrees_cw_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: _imagen,
              controller: _controlador,
              // Cuadrado y con máscara redonda: el recorte sale cuadrado y el
              // avatar lo muestra en círculo, así que lo que se ve aquí es
              // exactamente lo que se verá después.
              aspectRatio: 1,
              withCircleUi: true,
              baseColor: const Color(0xFF474646),
              maskColor: Color(0xFF474646).withValues(alpha: .6),
              onCropped: (resultado) {
                if (!mounted) return;
                switch (resultado) {
                  case CropSuccess(:final croppedImage):
                    _entregar(croppedImage);
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
                  style: TextStyle(color: Color(0xB3E6E1D5), fontSize: 13),
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
                              color: Color(0xFFE6E1D5),
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
    ),
  );
}
