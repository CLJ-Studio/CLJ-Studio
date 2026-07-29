import 'package:flutter/material.dart';

import '../diseno/ajustes_visibilidad.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';

/// Política de privacidad.
///
/// Es un requisito de las tiendas y de Google OAuth, pero sobre todo importa
/// porque la app maneja el número de WhatsApp de estudiantes reales: hay que
/// decir con claridad qué se guarda y quién puede verlo.
class PantallaPrivacidad extends StatelessWidget {
  const PantallaPrivacidad({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Privacidad',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      child: ContenidoCentrado(
        anchoMaximo: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Intro(),
            const SizedBox(height: 24),
            const AjustesVisibilidad(),
            const SizedBox(height: 28),
            const _Seccion(
              icono: Icons.badge_outlined,
              titulo: 'Qué datos guardamos',
              parrafos: [
                'Tu nombre y tu correo institucional, tal como los entrega '
                    'Google al iniciar sesión. El nombre no se puede editar: '
                    'es el que respalda la universidad.',
                'Tu carrera y tu número de WhatsApp, que tú mismo escribes '
                    'al completar el perfil.',
                'Lo que publicas: títulos, descripciones, precios y fotos.',
                'Tus pedidos, favoritos y notificaciones.',
              ],
            ),
            _Seccion(
              icono: Icons.chat_outlined,
              titulo: 'Tu WhatsApp no es público',
              parrafos: const [
                'Nadie puede ver tu número navegando la aplicación.',
                'Solo se revela entre comprador y vendedor, y únicamente '
                    'después de que el vendedor acepta el pedido. Antes de '
                    'eso el servidor se niega a entregarlo.',
                'Si un pedido es rechazado o vencido, el número nunca se '
                    'comparte.',
              ],
              destacado: true,
            ),
            const _Seccion(
              icono: Icons.school_outlined,
              titulo: 'Quién puede entrar',
              parrafos: [
                'Solo cuentas con correo institucional de la UPSA. La '
                    'validación ocurre en el servidor antes de crear la '
                    'cuenta, así que un correo externo no llega a registrarse.',
              ],
            ),
            const _Seccion(
              icono: Icons.payments_outlined,
              titulo: 'Los pagos son entre ustedes',
              parrafos: [
                'La aplicación no procesa pagos ni guarda datos bancarios o '
                    'de tarjetas. El pago se acuerda directamente entre '
                    'comprador y vendedor, en efectivo o por transferencia.',
                'Tampoco intervenimos en la entrega. Coordinen siempre en '
                    'puntos concurridos del campus.',
              ],
            ),
            const _Seccion(
              icono: Icons.gavel_rounded,
              titulo: 'Contenido no permitido',
              parrafos: [
                'No se puede publicar contenido ofensivo, sexual, '
                    'discriminatorio, ni sustancias prohibidas. Un filtro '
                    'automático revisa títulos, descripciones y las notas de '
                    'los pedidos.',
                'Las publicaciones que incumplan pueden eliminarse sin aviso.',
              ],
            ),
            const _Seccion(
              icono: Icons.delete_outline_rounded,
              titulo: 'Tus datos son tuyos',
              parrafos: [
                'Puedes editar tu carrera, tu WhatsApp y tu foto cuando '
                    'quieras desde Editar perfil.',
                'Si quieres que borremos tu cuenta y todo lo asociado, '
                    'escríbenos y lo hacemos.',
              ],
            ),
            const _Seccion(
              icono: Icons.notifications_none_rounded,
              titulo: 'Notificaciones',
              parrafos: [
                'Solo se envían si tú las activas. Puedes desactivarlas '
                    'cuando quieras desde Configuración, y dejamos de tener '
                    'forma de enviarte avisos a ese dispositivo.',
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Última actualización: julio de 2026',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hecho por estudiantes, para estudiantes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'UPSA Eat conecta a la comunidad de la universidad para comprar '
          'y vender dentro del campus. Aquí explicamos, sin rodeos, qué '
          'hacemos con tu información.',
          style: TextStyle(height: 1.45),
        ),
      ],
    ),
  );
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.icono,
    required this.titulo,
    required this.parrafos,
    this.destacado = false,
  });

  final IconData icono;
  final String titulo;
  final List<String> parrafos;

  /// Resalta lo más sensible: el dato personal que más preocupa compartir.
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: destacado ? const EdgeInsets.all(18) : EdgeInsets.zero,
      decoration: destacado
          ? BoxDecoration(
              color: primario.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primario.withValues(alpha: .3)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: primario),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final parrafo in parrafos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: primario,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(parrafo, style: const TextStyle(height: 1.45)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
