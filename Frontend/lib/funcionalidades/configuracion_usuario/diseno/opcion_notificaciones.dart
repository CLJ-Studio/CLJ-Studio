import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../notificaciones/datos/servicio_push.dart';

/// Enciende y apaga las notificaciones del sistema en este dispositivo.
///
/// Apagar no revoca el permiso del navegador (ninguna API lo permite): lo
/// que hace es cancelar la suscripcion, con lo que el servidor se queda sin
/// via para enviar. Volver a encender es inmediato, sin dialogo, porque el
/// permiso sigue concedido.
class OpcionNotificaciones extends StatefulWidget {
  const OpcionNotificaciones({super.key});

  @override
  State<OpcionNotificaciones> createState() => _OpcionNotificacionesState();
}

class _OpcionNotificacionesState extends State<OpcionNotificaciones> {
  bool _activas = false;
  bool _trabajando = false;

  @override
  void initState() {
    super.initState();
    _sincronizar();
  }

  /// El interruptor refleja si hay suscripcion viva, no solo el permiso.
  Future<void> _sincronizar() async {
    final activo = await ServicioPush.estaActivo();
    if (mounted) setState(() => _activas = activo);
  }

  Future<void> _cambiar(bool valor) async {
    setState(() => _trabajando = true);

    final listo = valor
        ? await ServicioPush.activar()
        : await ServicioPush.desactivar();

    if (!mounted) return;
    setState(() {
      _activas = valor ? listo : !listo;
      _trabajando = false;
    });

    if (valor && !listo) {
      final motivo = ServicioPush.ultimoError;
      _avisar(
        ServicioPush.denegado
            ? 'Bloqueaste las notificaciones. Habilítalas en los ajustes '
                  'del navegador para poder activarlas.'
            // Mostrar el motivo evita tener que abrir las herramientas del
            // navegador para saber que fallo.
            : motivo == null
            ? 'No se pudieron activar en este dispositivo.'
            : 'No se pudieron activar: $motivo',
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
    activeThumbColor: Color(0xFFE6E1D5),
    activeTrackColor: const Color(0xFF474646),
    inactiveThumbColor: Color(0xFFE6E1D5),
    inactiveTrackColor: const Color(0xFFE6E1D5),
    secondary: _trabajando
        ? const SizedBox(
            width: 22,
            height: 22,
            child: IndicadorCarga(tamanio: 22),
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
