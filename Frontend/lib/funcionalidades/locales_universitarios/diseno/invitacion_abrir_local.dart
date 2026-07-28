import 'package:flutter/material.dart';

/// Invitación gastronómica visible únicamente dentro de Restaurantes.
class InvitacionAbrirLocal extends StatelessWidget {
  const InvitacionAbrirLocal({
    required this.alPresionar,
    required this.yaTieneLocal,
    super.key,
  });

  final VoidCallback alPresionar;
  final bool yaTieneLocal;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: yaTieneLocal ? null : alPresionar,
    borderRadius: BorderRadius.circular(30),
    child: Ink(
      height: 180,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -12,
            bottom: -12,
            width: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Colors.transparent, Colors.white],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/real/hamburger3.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    yaTieneLocal
                        ? '¡Tu local ya está activo!'
                        : '¿Quieres abrir tu propio local?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    yaTieneLocal
                        ? 'Adminístralo desde “Tu local”.'
                        : 'Crea tu perfil y empieza a publicar tus productos.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!yaTieneLocal) ...[
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Text(
                          'Comenzar',
                          style: TextStyle(
                            color: Color(0xFF4D7955),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF4D7955),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
