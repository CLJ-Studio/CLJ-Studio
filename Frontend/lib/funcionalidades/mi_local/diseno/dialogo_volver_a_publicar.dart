import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/mensaje_fallo.dart';
import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../../publicar_producto/diseno/selector_vigencia_publicacion.dart';
import '../../publicar_producto/logica/vigencia_publicacion.dart';
import '../datos/repositorio_mi_local.dart';

/// Lo que se elige para que una publicación vuelva al catálogo: hasta cuándo
/// se ve y, si se vendió o se agotó, cuántas hay ahora.
typedef DatosVolverAPublicar = ({DateTime? hasta, int? stock});

/// Para una vencida o vendida. Relanzarla tal cual no sirve: el servidor
/// rechaza mostrar una vencida sin fecha nueva, y una vendida sin unidades
/// volvería agotada.
Future<DatosVolverAPublicar?> mostrarDialogoVolverAPublicar(
  BuildContext context,
  ProductoMarketplace producto,
) async {
  final esPersonal = producto.local?.esPersonal ?? false;
  final pideUnidades =
      !producto.esServicio && (producto.vendida || producto.stock <= 0);
  final unidades = TextEditingController(text: '1');
  VigenciaPublicacion vigencia = VigenciaPublicacion.inicial;

  final resultado = await showDialog<DatosVolverAPublicar>(
    context: context,
    builder: (contexto) => StatefulBuilder(
      builder: (contexto, actualizar) => AlertDialog(
        title: const Text('Volver a publicar'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.vendida
                      ? 'Se vendió. Si tienes más, indica cuántas y hasta '
                            'cuándo se ve.'
                      : 'Ya no se ve en el catálogo. Elige hasta cuándo se ve '
                            'ahora.',
                ),
                if (pideUnidades) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: unidades,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '¿Cuántas tienes ahora?',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  '¿Hasta cuándo se ve?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SelectorVigenciaPublicacion(
                  vigencia: vigencia,
                  esPersonal: esPersonal,
                  alCambiar: (nueva) => actualizar(() => vigencia = nueva),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF474646),
            ),
            onPressed: () {
              int? stock;
              if (pideUnidades) {
                stock = int.tryParse(unidades.text.trim());
                if (stock == null || stock < 1) {
                  ScaffoldMessenger.of(contexto).showSnackBar(
                    const SnackBar(
                      content: Text('Indica al menos una unidad.'),
                    ),
                  );
                  return;
                }
              }
              Navigator.of(
                contexto,
              ).pop((hasta: vigencia.venceEn(DateTime.now()), stock: stock));
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    ),
  );
  unidades.dispose();
  return resultado;
}

/// Pide lo que falta y la vuelve a publicar. True si quedó publicada.
Future<bool> volverAPublicar(
  BuildContext context,
  ProductoMarketplace producto, {
  RepositorioMiLocal repositorio = const RepositorioMiLocal(),
}) async {
  final datos = await mostrarDialogoVolverAPublicar(context, producto);
  if (datos == null) return false;
  try {
    await repositorio.volverAPublicar(
      producto.id,
      venceEn: datos.hasta,
      stock: datos.stock,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Publicada de nuevo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    return true;
  } catch (fallo) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensajeDeFallo(fallo, porDefecto: 'No se pudo volver a publicar.'),
          ),
        ),
      );
    }
    return false;
  }
}

/// "Ya lo vendí": confirma y la saca del catálogo. True si se marcó.
Future<bool> marcarComoVendida(
  BuildContext context,
  ProductoMarketplace producto, {
  RepositorioMiLocal repositorio = const RepositorioMiLocal(),
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: const Text('¿Ya lo vendiste?'),
      content: Text(
        '"${producto.nombre}" sale del catálogo y te queda guardada unos '
        'días por si repones. Después se borra sola.',
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(contexto).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF474646),
          ),
          child: const Text('Sí, ya lo vendí'),
        ),
      ],
    ),
  );
  if (confirmado != true) return false;
  try {
    await repositorio.marcarVendida(producto.id);
    return true;
  } catch (fallo) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensajeDeFallo(
              fallo,
              porDefecto: 'No se pudo marcar como vendida.',
            ),
          ),
        ),
      );
    }
    return false;
  }
}
