import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../asistente_macias/diseno/identidad_macias.dart';
import '../../asistente_macias/pantalla/pantalla_chat_macias.dart';
import '../datos/contacto_soporte.dart';

/// Ayuda: MacIAs, el contacto con el equipo y las preguntas frecuentes.
class PantallaAyuda extends StatelessWidget {
  const PantallaAyuda({super.key});

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
            _Contacto(
              alChatear: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PantallaChatMacias(),
                ),
              ),
              alEscribir: () => ContactoSoporte.abrirWhatsapp(context),
              alEnviarCorreo: () => ContactoSoporte.abrirCorreo(context),
            ),
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
                  'pedido se abre un chat entre los dos para que acuerden el '
                  'pago y el punto de entrega dentro del campus.',
            ),
            const _Pregunta(
              pregunta: '¿Quién ve mi número de WhatsApp?',
              respuesta:
                  'Nadie mientras navega la app. Con un pedido aceptado, '
                  'todo se habla por el chat de la app; solo si alguien deja '
                  'de responder aparece la opción de seguir por WhatsApp, y '
                  'solo entre el comprador y el vendedor de ese pedido.',
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
              // Decia "Por confirmar", que hoy es el nombre de otro estado
              // (uno marco la entrega y falta el otro), y mandaba a
              // WhatsApp cuando el pedido ya tiene su chat.
              respuesta:
                  'Mientras esperas la respuesta del vendedor, toca '
                  '"Cancelar solicitud" en la pantalla de espera. Si ya '
                  'saliste de ahí, no pasa nada: si no la acepta en 15 '
                  'minutos, vence sola. Si ya la aceptó, háblalo en el chat '
                  'del pedido: quien vende puede cancelarlo.',
            ),
          ],
        ),
      ),
    ),
  );
}

class _Contacto extends StatelessWidget {
  const _Contacto({
    required this.alChatear,
    required this.alEscribir,
    required this.alEnviarCorreo,
  });

  final VoidCallback alChatear;
  final VoidCallback alEscribir;
  final VoidCallback alEnviarCorreo;

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
          'MacIAs te responde al instante. Si prefieres a una persona, '
          'escríbenos y te respondemos lo antes posible.',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 16),
        BotonChatMacias(alPresionar: alChatear),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: alEnviarCorreo,
            icon: const Icon(Icons.mail_outline_rounded),
            // El correo SI se muestra: es una casilla de contacto, no un
            // numero personal, y quien no tiene un cliente de correo
            // configurado al menos puede copiarlo.
            label: const Text(ContactoSoporte.correo),
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
