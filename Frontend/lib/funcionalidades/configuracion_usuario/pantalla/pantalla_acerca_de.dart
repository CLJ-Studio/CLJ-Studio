import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/version_aplicacion.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';

/// Quiénes hacen la aplicación y bajo qué términos se usa.
class PantallaAcercaDe extends StatelessWidget {
  const PantallaAcercaDe({super.key});

  /// El año se calcula en vez de escribirse: un aviso de copyright con una
  /// fecha vieja envejece la aplicación entera.
  int get _anio => DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acerca de nosotros',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLJ Studio',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Somos un equipo de estudiantes de la UPSA. Hicimos '
                      'UPSA Eat porque en el campus se compra y se vende todo '
                      'el día por grupos de WhatsApp, donde las cosas se '
                      'pierden entre mensajes y nadie sabe quién vende qué.',
                      style: TextStyle(
                        color: tema.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Qué es UPSA Eat',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _Parrafo(
                'Un espacio de compraventa exclusivo para la comunidad de la '
                'Universidad Privada de Santa Cruz. Solo se entra con el '
                'correo institucional, así que sabes que del otro lado hay '
                'alguien de la universidad.',
              ),
              _Parrafo(
                'La aplicación no cobra comisiones ni procesa pagos. Cuando '
                'el vendedor acepta un pedido se comparte el WhatsApp de '
                'ambos y el acuerdo se cierra entre las dos personas, dentro '
                'del campus.',
              ),
              const SizedBox(height: 26),
              Text(
                'Cómo está hecha',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              // Sin nombres propios: quien la usa no necesita saber quién es
              // quién, y el equipo prefiere mantenerse anónimo.
              const _Integrante(
                icono: Icons.brush_outlined,
                titulo: 'Interfaz y diseño',
                detalle:
                    'Las pantallas, la navegación y todo lo que se ve y '
                    'se toca.',
              ),
              const _Integrante(
                icono: Icons.dns_outlined,
                titulo: 'Backend y base de datos',
                detalle:
                    'Las cuentas, los pedidos, las notificaciones y lo que '
                    'guarda cada dato en su sitio.',
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 16),
              // Deja ver de un vistazo que version corre en este aparato.
              Text(
                'Versión ${VersionAplicacion.corta}',
                style: TextStyle(
                  color: tema.textTheme.bodyMedium?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '© $_anio CLJ Studio. Todos los derechos reservados.',
                style: TextStyle(
                  color: tema.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El código, el diseño, el nombre y el logotipo de UPSA Eat '
                'pertenecen a CLJ Studio. Queda prohibida su reproducción o '
                'distribución sin autorización escrita.\n\n'
                'UPSA Eat no es un producto oficial de la Universidad Privada '
                'de Santa Cruz de la Sierra. El contenido de cada publicación '
                'es responsabilidad de quien la publica.',
                style: TextStyle(
                  color: tema.textTheme.bodyMedium?.color,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Parrafo extends StatelessWidget {
  const _Parrafo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      texto,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
        height: 1.5,
      ),
    ),
  );
}

class _Integrante extends StatelessWidget {
  const _Integrante({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tema.colorScheme.primary.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 19, color: tema.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: TextStyle(
                    color: tema.textTheme.bodyMedium?.color,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
