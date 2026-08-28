import 'package:flutter/material.dart';

import '../modelos/usuario_upsa.dart';
import '../pantalla/pantalla_editar_perfil.dart';

/// Encabezado de perfil centrado de la pantalla de ajustes.
class TarjetaPerfilUsuario extends StatelessWidget {
  const TarjetaPerfilUsuario({required this.usuario, super.key});

  final UsuarioUpsa usuario;

  void _editar(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const PantallaEditarPerfil()));

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF121418);
    final textoSecundario = esOscuro
        ? const Color(0xFFA7ADB5)
        : const Color(0xFF737A83);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 132,
              height: 132,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: esOscuro
                    ? const Color(0xFF202429)
                    : const Color(0xFFDCE1E7),
                shape: BoxShape.circle,
              ),
              child: switch (usuario.avatarUrl) {
                final String url => Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _Inicial(usuario: usuario),
                ),
                _ => _Inicial(usuario: usuario),
              },
            ),
            Positioned(
              right: -3,
              bottom: 5,
              child: Material(
                color: esOscuro ? const Color(0xFF138A5B) : Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _editar(context),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 21,
                      color: esOscuro ? Colors.white : colorTexto,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          usuario.nombre,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorTexto,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          usuario.correo,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textoSecundario,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (usuario.carrera.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            usuario.carrera,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textoSecundario, fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _editar(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorTexto,
            backgroundColor: esOscuro
                ? const Color(0xFF15171A)
                : const Color(0xFFF7F9FB),
            side: BorderSide(
              color: esOscuro
                  ? const Color(0xFF30343A)
                  : const Color(0xFFDCE1E7),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: const Text(
            'Editar perfil',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _Inicial extends StatelessWidget {
  const _Inicial({required this.usuario});

  final UsuarioUpsa usuario;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      usuario.inicial,
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF30353B),
        fontSize: 54,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
