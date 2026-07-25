import 'package:flutter/material.dart';
import '../modelos/usuario_upsa.dart';

/// Resumen del perfil institucional simulado.
class TarjetaPerfilUsuario extends StatelessWidget {
  const TarjetaPerfilUsuario({required this.usuario, super.key});
  final UsuarioUpsa usuario;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              usuario.nombre.substring(0, 1),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(usuario.carrera),
                Text(
                  usuario.correo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined),
        ],
      ),
    ),
  );
}
