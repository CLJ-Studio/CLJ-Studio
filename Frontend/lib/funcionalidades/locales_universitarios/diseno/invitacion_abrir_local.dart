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
    // Con local ya abierto lleva a administrarlo; sin el, a crearlo. Antes
    // se quedaba muerta al tenerlo, que es justo cuando mas se toca.
    onTap: alPresionar,
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
                        ? 'Administra tu local aquí'
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
                        // La instruccion anterior mandaba a Publicar, donde
                        // el local ya no vive. Ahora la tarjeta ES el acceso.
                        ? 'Tu inventario, tu ubicación y tu marca, en un '
                              'solo sitio.'
                        : 'Crea tu perfil y empieza a publicar tus productos.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // La llamada a la accion sale siempre: la tarjeta lleva a
                  // algun sitio en los dos casos, y sin ella no parecia
                  // pulsable justo cuando ya tienes local.
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        yaTieneLocal ? 'Administrar' : 'Comenzar',
                        style: const TextStyle(
                          color: Color(0xFF4D7955),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF4D7955),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
