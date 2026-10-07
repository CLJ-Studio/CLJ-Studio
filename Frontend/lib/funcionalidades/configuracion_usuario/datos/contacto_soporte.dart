import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Como se llega a una persona del equipo de U market.
///
/// Vive aparte porque lo usan la pantalla de Ayuda y MacIAs: con el numero
/// copiado en dos sitios, tarde o temprano uno de los dos apunta a otro lado.
abstract final class ContactoSoporte {
  /// El numero no se muestra en ninguna pantalla: quedaria expuesto a
  /// cualquiera. El enlace igual abre el chat correcto.
  static const _whatsapp = '59167972211';

  /// El correo de contacto de U market. Las tiendas de aplicaciones piden uno,
  /// y hay gente que prefiere escribir antes que chatear.
  static const correo = 'contacto.umarketbo@gmail.com';

  static Future<void> abrirWhatsapp(
    BuildContext context, {
    String mensaje = 'Hola, necesito ayuda con U market.',
  }) async {
    final url = Uri.parse(
      'https://wa.me/$_whatsapp?text=${Uri.encodeComponent(mensaje)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _avisar(context, 'No se pudo abrir WhatsApp.');
    }
  }

  static Future<void> abrirCorreo(
    BuildContext context, {
    String asunto = 'Ayuda con U market',
  }) async {
    final url = Uri(
      scheme: 'mailto',
      path: correo,
      query: 'subject=${Uri.encodeComponent(asunto)}',
    );
    if (!await launchUrl(url) && context.mounted) {
      // Sin cliente de correo configurado no se abre nada: al menos que
      // quede claro a donde escribir.
      _avisar(context, 'Escríbenos a $correo');
    }
  }

  static void _avisar(BuildContext context, String texto) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
        );
}
