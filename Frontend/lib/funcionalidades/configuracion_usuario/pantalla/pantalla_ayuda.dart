import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';

/// Ayuda y contacto de soporte.
const _whatsappSoporte = '59167972211';

class PantallaAyuda extends StatelessWidget {
  const PantallaAyuda({super.key});

  Future<void> _abrirWhatsapp(BuildContext context) async {
    final url = Uri.parse(
      'https://wa.me/$_whatsappSoporte'
      '?text=${Uri.encodeComponent('Hola, necesito ayuda con U market.')}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ayuda', style: TextStyle(fontWeight: FontWeight.w900)),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      child: ContenidoCentrado(
        anchoMaximo: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Contacto(alEscribir: () => _abrirWhatsapp(context)),
            const SizedBox(height: 30),
            Text(
              'Preguntas frecuentes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const _Pregunta(
              pregunta: '¿Necesito abrir un local para vender?',
              respuesta:
                  'No. Publica directamente desde el botón Publicar y tu '
                  'anuncio aparecerá en el inicio con tu nombre. Abrir un '
                  'local es para quien vende con una marca y quiere su '
                  'propia vitrina en la sección Locales.',
            ),
            const _Pregunta(
              pregunta: '¿Cómo se paga?',
              respuesta:
                  'La app no procesa pagos. Cuando el vendedor acepta tu '
                  'pedido se habilita el WhatsApp de ambos para que acuerden '
                  'el pago y el punto de entrega dentro del campus.',
            ),
            const _Pregunta(
              pregunta: '¿Quién ve mi número de WhatsApp?',
              respuesta:
                  'Nadie, hasta que un pedido es aceptado. Ahí se comparte '
                  'solo entre comprador y vendedor de ese pedido.',
            ),
            const _Pregunta(
              pregunta: 'Mi publicación quedó muy abajo, ¿qué hago?',
              respuesta:
                  'Usa "Relanzar" desde el menú de la publicación en Tu '
                  'local. Vuelve al inicio del catálogo sin perder sus '
                  'favoritos ni su historial.',
            ),
            const _Pregunta(
              pregunta: '¿Puedo ocultar algo sin borrarlo?',
              respuesta:
                  'Sí. "Ocultar" la retira del catálogo pero la conserva '
                  'para que puedas volver a mostrarla cuando quieras.',
            ),
            const _Pregunta(
              pregunta: 'No me llegan las notificaciones',
              respuesta:
                  'Actívalas en Configuración. En iPhone solo funcionan si '
                  'agregaste la app a la pantalla de inicio: ábrela en '
                  'Safari, toca Compartir y elige "Agregar a inicio".',
            ),
            const _Pregunta(
              pregunta: 'Alguien publicó algo ofensivo',
              respuesta:
                  'Escríbenos por WhatsApp con el nombre de la publicación '
                  'y la revisamos. Hay un filtro automático, pero no atrapa '
                  'todo.',
            ),
            const _Pregunta(
              pregunta: '¿Cómo cancelo un pedido?',
              respuesta:
                  'Desde Pedidos, en la tarjeta del pedido que todavía '
                  'diga "Por confirmar". Si el vendedor ya lo aceptó, '
                  'coordina con él por WhatsApp.',
            ),
          ],
        ),
      ),
    ),
  );
}

class _Contacto extends StatelessWidget {
  const _Contacto({required this.alEscribir});

  final VoidCallback alEscribir;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Necesitas ayuda?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Escríbenos y te respondemos lo antes posible.',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: alEscribir,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF848381),
              foregroundColor: Color(0xFFE6E1D5),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.chat_rounded),
            // El numero no se muestra: quedaria expuesto a cualquiera. El
            // enlace igual abre el chat correcto.
            label: const Text('Contactar a soporte'),
          ),
        ),
      ],
    ),
  );
}

class _Pregunta extends StatelessWidget {
  const _Pregunta({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;

  @override
  Widget build(BuildContext context) => Theme(
    // Quita las lineas divisorias que Material dibuja por defecto en el
    // desplegable, que rompen el aire de las tarjetas.
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 14),
      title: Text(
        pregunta,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(respuesta, style: const TextStyle(height: 1.5)),
        ),
      ],
    ),
  );
}
