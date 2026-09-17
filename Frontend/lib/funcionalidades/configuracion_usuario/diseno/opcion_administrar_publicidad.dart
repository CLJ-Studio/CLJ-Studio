import 'package:flutter/material.dart';

import '../datos/repositorio_publicidad_admin.dart';
import '../pantalla/pantalla_administrar_publicidad.dart';

/// Entrada invisible para usuarios comunes y visible para administradores.
class OpcionAdministrarPublicidad extends StatefulWidget {
  const OpcionAdministrarPublicidad({super.key});

  @override
  State<OpcionAdministrarPublicidad> createState() =>
      _OpcionAdministrarPublicidadState();
}

class _OpcionAdministrarPublicidadState
    extends State<OpcionAdministrarPublicidad> {
  final _repositorio = const RepositorioPublicidadAdmin();
  late final Future<bool> _permiso = _repositorio.esAdministrador();

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _permiso,
    builder: (context, resultado) {
      if (resultado.data != true) return const SizedBox.shrink();
      return ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PantallaAdministrarPublicidad(),
          ),
        ),
        leading: const Icon(Icons.campaign_rounded, color: Colors.black),
        title: const Text('Administrar publicidad'),
        subtitle: const Text('Agregar, programar o retirar anuncios'),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
    },
  );
}
