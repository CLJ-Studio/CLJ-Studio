import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';

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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: InkWell(
      // Con local ya abierto lleva a administrarlo; sin el, a crearlo. Antes
      // se quedaba muerta al tenerlo, que es justo cuando mas se toca.
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        height: 180,
        decoration: BoxDecoration(
          color: ConfiguracionTema.grafito,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  yaTieneLocal
                      ? 'assets/images/locales/buho-chef-administrar.png'
                      : 'assets/images/locales/buho-chef-comenzar.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            // Protege la lectura del texto sobre la zona clara de la imagen.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      ConfiguracionTema.grafito,
                      ConfiguracionTema.grafito.withValues(alpha: .94),
                      ConfiguracionTema.grafito.withValues(alpha: .08),
                    ],
                    stops: [0, .48, .74],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 235,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      yaTieneLocal
                          ? 'Administra tu local aquí'
                          : '¿Quieres abrir tu propio local?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Color(0xFFE6E1D5),
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
                        color: Color(0xFFE6E1D5).withValues(alpha: .9),
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
                            color: Color(0xFFE6E1D5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFFE6E1D5),
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
    ),
  );
}
