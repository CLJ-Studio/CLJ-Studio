import 'package:flutter/material.dart';

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
                'El equipo',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const _Integrante(
                nombre: 'Juan Diego Salazar',
                papel: 'Backend, base de datos e infraestructura',
              ),
              const _Integrante(
                nombre: 'Lucas Tejerina',
                papel: 'Interfaz, diseño y experiencia de uso',
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 16),
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
  const _Integrante({required this.nombre, required this.papel});

  final String nombre;
  final String papel;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            child: Text(
              nombre.characters.first,
              style: TextStyle(
                color: tema.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  papel,
                  style: TextStyle(
                    color: tema.textTheme.bodyMedium?.color,
                    fontSize: 13,
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
