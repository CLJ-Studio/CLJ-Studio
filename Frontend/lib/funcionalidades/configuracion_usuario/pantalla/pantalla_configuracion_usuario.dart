import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../instalacion_app/diseno/opcion_instalar_app.dart';
import '../../instalacion_app/logica/controlador_instalacion.dart';
import '../diseno/opcion_chats.dart';
import '../diseno/opcion_mis_publicaciones.dart';
import '../diseno/boton_cerrar_sesion.dart';
import '../diseno/opcion_acerca_de.dart';
import '../diseno/opcion_ayuda.dart';
import '../diseno/opcion_cuenta_institucional.dart';
import '../diseno/opcion_notificaciones.dart';
import '../diseno/opcion_privacidad.dart';

/// Perfil y preferencias organizados en tarjetas agrupadas.
class PantallaConfiguracionUsuario extends StatefulWidget {
  const PantallaConfiguracionUsuario({this.alCerrarSesion, super.key});

  final VoidCallback? alCerrarSesion;

  @override
  State<PantallaConfiguracionUsuario> createState() =>
      _PantallaConfiguracionUsuarioState();
}

class _PantallaConfiguracionUsuarioState
    extends State<PantallaConfiguracionUsuario> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ControladorInstalacion.instancia,
    builder: (context, _) {
      return ColoredBox(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 126),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const _GrupoAjustes(
                    titulo: 'Cuenta',
                    opciones: [OpcionCuentaInstitucional(), OpcionPrivacidad()],
                  ),
                  const SizedBox(height: 22),
                  _GrupoAjustes(
                    titulo: 'Preferencias',
                    opciones: [
                      // Volvio al menu: la pantalla existia pero se quedo
                      // sin acceso, asi que la unica forma de ver lo propio
                      // era el perfil.
                      const OpcionMisPublicaciones(),
                      const OpcionChats(),
                      const OpcionNotificaciones(),
                      if (ControladorInstalacion.instancia.disponible)
                        const OpcionInstalarApp(),
                      const OpcionAyuda(),
                      const OpcionAcercaDe(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BotonCerrarSesion(
                    alPresionar: () {
                      if (widget.alCerrarSesion != null) {
                        widget.alCerrarSesion?.call();
                        return;
                      }
                      Supabase.instance.client.auth.signOut();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _GrupoAjustes extends StatelessWidget {
  const _GrupoAjustes({required this.titulo, required this.opciones});

  final String titulo;
  final List<Widget> opciones;

  @override
  Widget build(BuildContext context) {
    const colorContenido = Colors.black;

    final temaGrupo = Theme.of(context).copyWith(
      dividerColor: colorContenido,
      listTileTheme: const ListTileThemeData(
        iconColor: colorContenido,
        textColor: colorContenido,
        titleTextStyle: TextStyle(
          color: colorContenido,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: colorContenido,
          fontSize: 12,
          height: 1.2,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        minLeadingWidth: 28,
        minTileHeight: 72,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Colors.white
              : Colors.black,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.black),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 10),
          child: Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              color: colorContenido,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: temaGrupo,
            child: Column(
              children: [
                for (var i = 0; i < opciones.length; i++) ...[
                  IconTheme(
                    data: const IconThemeData(color: colorContenido, size: 26),
                    child: opciones[i],
                  ),
                  if (i < opciones.length - 1)
                    const Divider(height: 1, indent: 68),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
