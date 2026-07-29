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
  const PantallaAdministrarLocal({required this.controlador, super.key});

  final ControladorMiLocal controlador;

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
          child: const ContenidoCentrado(
            anchoMaximo: 620,
            child: EditorNegocio(),
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
