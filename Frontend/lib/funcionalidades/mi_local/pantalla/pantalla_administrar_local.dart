import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../configuracion_usuario/diseno/editor_negocio.dart';
import '../logica/controlador_mi_local.dart';
import 'pantalla_mi_local.dart';

/// Todo lo del negocio en un sitio: inventario, ubicación e identidad.
///
/// Vive aparte y no dentro de Publicar ni de Editar perfil. Administrar una
/// tienda no es publicar algo suelto, ni es un dato de tu cuenta: mezclarlo
/// obligaba a buscar el nombre del local dentro del perfil personal y el
/// inventario dentro de una pestaña de publicar. Se llega desde Locales,
/// que es donde uno piensa en su tienda.
class PantallaAdministrarLocal extends StatelessWidget {
  const PantallaAdministrarLocal({
    required this.controlador,
    this.alCerrarLocal,
    super.key,
  });

  final ControladorMiLocal controlador;
  final ValueChanged<String>? alCerrarLocal;

  Future<void> _confirmarCierre(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar mi local'),
        content: const Text(
          'El local y sus publicaciones dejarán de aparecer en el catálogo. '
          'Los pedidos activos se cancelarán, pero el historial entregado se '
          'conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3453B),
            ),
            child: const Text('Eliminar local'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final localId = controlador.local?.id;
    try {
      await controlador.cerrarLocal();
      if (localId != null) alCerrarLocal?.call(localId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tu local fue eliminado.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el local.')),
      );
    }
  }

  void _editarIdentidad(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (hoja) => DraggableScrollableSheet(
        initialChildSize: .85,
        maxChildSize: .95,
        expand: false,
        builder: (_, controladorScroll) => SingleChildScrollView(
          controller: controladorScroll,
          // Deja sitio al teclado: sin esto el campo en foco queda debajo.
          padding: EdgeInsets.fromLTRB(
            18,
            0,
            18,
            MediaQuery.viewInsetsOf(hoja).bottom + 24,
          ),
          child: ContenidoCentrado(
            anchoMaximo: 620,
            child: EditorNegocio(
              alEliminar: () {
                Navigator.of(hoja).pop();
                _confirmarCierre(context);
              },
            ),
          ),
        ),
      ),
    ).then((_) => controlador.cargar());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Mi local',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        IconButton(
          tooltip: 'Editar nombre, descripción y logo',
          onPressed: () => _editarIdentidad(context),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    ),
    body: PantallaMiLocal(controlador: controlador),
  );
}
