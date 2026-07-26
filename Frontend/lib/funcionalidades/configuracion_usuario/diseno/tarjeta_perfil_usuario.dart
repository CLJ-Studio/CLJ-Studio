import 'package:flutter/material.dart';

import '../modelos/usuario_upsa.dart';
import '../pantalla/pantalla_editar_perfil.dart';

/// Perfil institucional centrado, inspirado en la referencia visual.
class TarjetaPerfilUsuario extends StatelessWidget {
  const TarjetaPerfilUsuario({required this.usuario, super.key});

  final UsuarioUpsa usuario;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F0E7),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          usuario.inicial,
          style: const TextStyle(
            color: Color(0xFF55785A),
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        usuario.nombre,
        style: const TextStyle(
          color: Color(0xFF1E1F1E),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        usuario.correo,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF7C7D7E), fontSize: 14),
      ),
      const SizedBox(height: 5),
      Text(
        usuario.carrera,
        style: const TextStyle(color: Color(0xFF7C7D7E), fontSize: 13),
      ),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PantallaEditarPerfil(),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF55785A),
          side: const BorderSide(color: Color(0xFF6F9D76), width: 1.4),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        ),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}
