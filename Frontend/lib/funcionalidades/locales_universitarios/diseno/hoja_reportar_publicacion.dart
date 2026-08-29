import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Motivos por los que se puede reportar. Coinciden con el enum
/// `motivo_reporte` de Postgres: el valor viaja tal cual.
enum MotivoReporte {
  ofensivo(
    'ofensivo',
    'Contenido ofensivo',
    'Lenguaje o imágenes que no deberían estar',
  ),
  enganoso(
    'enganoso',
    'No es lo que dice',
    'La publicación engaña sobre lo que vende',
  ),
  prohibido(
    'prohibido',
    'Producto prohibido',
    'Alcohol, drogas, armas u otra cosa vetada',
  ),
  spam('spam', 'Spam o repetido', 'Publicidad, o lo mismo subido muchas veces'),
  otro('otro', 'Otra cosa', 'Cuéntanos qué pasa');

  const MotivoReporte(this.valor, this.titulo, this.explicacion);

  final String valor;
  final String titulo;
  final String explicacion;
}

/// Pide el motivo y manda el reporte.
///
/// Reportar NO oculta nada: el servidor guarda el aviso y lo revisa una
/// persona. Si bastara con reportar, tumbar a un competidor costaría tres
/// toques, así que la hoja lo dice en voz alta para que nadie espere que la
/// publicación desaparezca al instante.
Future<void> mostrarHojaReportar(
  BuildContext context, {
  required String productoId,
  required String nombreProducto,
}) async {
  final enviado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _HojaReportar(productoId: productoId, nombreProducto: nombreProducto),
  );

  if (enviado == true && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Gracias. Vamos a revisarlo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _HojaReportar extends StatefulWidget {
  const _HojaReportar({required this.productoId, required this.nombreProducto});

  final String productoId;
  final String nombreProducto;

  @override
  State<_HojaReportar> createState() => _HojaReportarState();
}

class _HojaReportarState extends State<_HojaReportar> {
  MotivoReporte? _motivo;
  final _detalle = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final motivo = _motivo;
    if (motivo == null) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.rpc(
        'reportar_publicacion',
        params: {
          'p_product_id': widget.productoId,
          'p_motivo': motivo.valor,
          'p_detalle': _detalle.text.trim().isEmpty
              ? null
              : _detalle.text.trim(),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = _mensajeDeError(error);
        });
      }
    }
  }

  /// El servidor manda códigos, no frases. Sin traducirlos, la hoja mostraría
  /// un volcado de Postgres a alguien que solo quería avisar de algo.
  String _mensajeDeError(Object error) {
    final texto = error.toString();
    if (texto.contains('NO_TE_REPORTES_A_TI_MISMO')) {
      return 'Esta publicación es tuya.';
    }
    if (texto.contains('CONTENIDO_NO_PERMITIDO')) {
      return 'Quita las groserías del detalle y vuelve a intentarlo.';
    }
    if (texto.contains('PUBLICACION_INEXISTENTE')) {
      return 'Esta publicación ya no existe.';
    }
    return 'No se pudo enviar el reporte. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      // El teclado tapa el campo de detalle sin esto.
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportar publicación',
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nombreProducto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tema.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 18),

            // El grupo va en un ancestro: desde Flutter 3.32 cada opcion ya
            // no lleva su propio `groupValue` ni su `onChanged`.
            RadioGroup<MotivoReporte>(
              groupValue: _motivo,
              onChanged: (valor) {
                if (_enviando) return;
                setState(() => _motivo = valor);
              },
              child: Column(
                children: [
                  for (final motivo in MotivoReporte.values)
                    RadioListTile<MotivoReporte>(
                      value: motivo,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        motivo.titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        motivo.explicacion,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _detalle,
              enabled: !_enviando,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: 'Detalle (opcional)',
                hintText: '¿Qué viste?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFAE7960), fontSize: 13),
              ),
            ],

            const SizedBox(height: 10),
            // Se dice antes de enviar, no después: quien reporta esperando que
            // la publicación se caiga al instante volvería a reportar creyendo
            // que no funcionó.
            Text(
              'Lo revisa una persona. La publicación no se oculta por '
              'reportarla.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: tema.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _motivo == null || _enviando ? null : _enviar,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAE7960),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                ),
                child: Text(_enviando ? 'Enviando…' : 'Enviar reporte'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
