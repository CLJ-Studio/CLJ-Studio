import 'package:flutter/material.dart';

import '../modelos/usuario_upsa.dart';
import '../pantalla/pantalla_editar_perfil.dart';

/// Perfil institucional centrado, inspirado en la referencia visual.
class TarjetaPerfilUsuario extends StatelessWidget {
  const TarjetaPerfilUsuario({required this.usuario, super.key});

  final UsuarioUpsa usuario;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      // Los nombres institucionales son largos y con dos apellidos rompen en
      // dos lineas: sin esto la segunda quedaba pegada a la izquierda.
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 104,
          height: 104,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tema.colorScheme.primary.withValues(alpha: .16),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // Foto si la subio; si no, la inicial de siempre.
          child: switch (usuario.avatarUrl) {
            final String url => Image.network(
              url,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Inicial(usuario: usuario),
            ),
            _ => _Inicial(usuario: usuario),
          },
        ),
        const SizedBox(height: 14),
        Text(
          usuario.nombre,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tema.colorScheme.onSurface,
            // Baja de 28 a 24: los nombres completos de la UPSA son largos y
            // a 28 se partian en tres lineas.
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          usuario.correo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tema.textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          usuario.carrera,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tema.textTheme.bodyMedium?.color,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PantallaEditarPerfil(),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: tema.colorScheme.primary,
            side: BorderSide(
              color: tema.colorScheme.primary.withValues(alpha: .55),
              width: 1.4,
            ),
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
}

/// Respaldo del avatar cuando no hay foto (o esta fallo al cargar).
class _Inicial extends StatelessWidget {
  const _Inicial({required this.usuario});

  final UsuarioUpsa usuario;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      usuario.inicial,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 38,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
