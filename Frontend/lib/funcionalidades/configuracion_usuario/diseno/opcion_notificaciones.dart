import 'package:flutter/material.dart';

import '../../notificaciones/datos/servicio_push.dart';

/// Activa las notificaciones del sistema (suenan con la app cerrada).
///
/// Antes era un interruptor decorativo. Ahora pide el permiso real del
/// navegador y registra el dispositivo para Web Push.
class OpcionNotificaciones extends StatefulWidget {
  const OpcionNotificaciones({super.key});

  @override
  State<OpcionNotificaciones> createState() => _OpcionNotificacionesState();
}

class _OpcionNotificacionesState extends State<OpcionNotificaciones> {
  late bool _activas = ServicioPush.yaConcedido;
  bool _trabajando = false;

  Future<void> _cambiar(bool valor) async {
    // El permiso del navegador no se puede revocar por codigo: desactivar
    // se hace desde los ajustes del sitio. Se explica en vez de fingirlo.
    if (!valor) {
      _avisar(
        'Para desactivarlas, quita el permiso de notificaciones en los '
        'ajustes de tu navegador.',
      );
      return;
    }

    setState(() => _trabajando = true);
    final listo = await ServicioPush.activar();
    if (!mounted) return;

    setState(() {
      _activas = listo;
      _trabajando = false;
    });

    if (!listo) {
      _avisar(
        ServicioPush.denegado
            ? 'Bloqueaste las notificaciones. Habilítalas en los ajustes '
                  'del navegador.'
            : 'No se pudieron activar en este dispositivo.',
      );
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    activeThumbColor: Colors.white,
    activeTrackColor: const Color(0xFF5F9368),
    inactiveThumbColor: Colors.white,
    inactiveTrackColor: const Color(0xFFD2D5D2),
    secondary: _trabajando
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : const Icon(Icons.notifications_outlined),
    title: const Text('Notificaciones'),
    subtitle: Text(
      _activas
          ? 'Activas en este dispositivo'
          : 'Recibe avisos aunque la app esté cerrada',
    ),
    value: _activas,
    onChanged: _trabajando ? null : _cambiar,
  );
}
