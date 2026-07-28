import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../diseno/boton_cerrar_sesion.dart';
import '../diseno/opcion_ayuda.dart';
import '../diseno/opcion_cuenta_institucional.dart';
import '../diseno/opcion_favoritos.dart';
import '../diseno/opcion_mis_publicaciones.dart';
import '../diseno/opcion_notificaciones.dart';
import '../diseno/opcion_pedidos.dart';
import '../diseno/opcion_privacidad.dart';
import '../diseno/opcion_tema_aplicacion.dart';
import '../diseno/tarjeta_perfil_usuario.dart';
import '../logica/controlador_configuracion.dart';
import '../modelos/usuario_upsa.dart';

/// Perfil y preferencias organizados en tarjetas agrupadas.
class PantallaConfiguracionUsuario extends StatefulWidget {
  const PantallaConfiguracionUsuario({super.key});

  @override
  State<PantallaConfiguracionUsuario> createState() =>
      _PantallaConfiguracionUsuarioState();
}

class _PantallaConfiguracionUsuarioState
    extends State<PantallaConfiguracionUsuario> {
  final controlador = ControladorConfiguracion();
  final sesion = SesionUsuario.instancia;

  @override
  void initState() {
    super.initState();
    sesion.cargar();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([controlador, sesion]),
    builder: (context, _) {
      final esOscuro = Theme.of(context).brightness == Brightness.dark;

      return ColoredBox(
        color: esOscuro ? Colors.black : const Color(0xFFEEF0F4),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 126),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  switch (sesion.perfil) {
                    final UsuarioUpsa perfil => TarjetaPerfilUsuario(
                      usuario: perfil,
                    ),
                    _ => const SizedBox(
                      height: 280,
                      child: Center(child: IndicadorCarga()),
                    ),
                  },
                  const SizedBox(height: 28),
                  const _GrupoAjustes(
                    titulo: 'Cuenta',
                    opciones: [OpcionCuentaInstitucional(), OpcionPrivacidad()],
                  ),
                  const SizedBox(height: 22),
                  const _GrupoAjustes(
                    titulo: 'Actividad',
                    opciones: [
                      OpcionPedidos(),
                      OpcionFavoritos(),
                      OpcionMisPublicaciones(),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _GrupoAjustes(
                    titulo: 'Preferencias',
                    opciones: [
                      OpcionNotificaciones(),
                      OpcionTemaAplicacion(),
                      OpcionAyuda(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  BotonCerrarSesion(
                    alPresionar: () => Supabase.instance.client.auth.signOut(),
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final textoPrincipal = esOscuro ? Colors.white : const Color(0xFF17191D);
    final textoSecundario = esOscuro
        ? const Color(0xFF9DA2AA)
        : const Color(0xFF747B84);
    final colorIcono = esOscuro
        ? const Color(0xFF7EB287)
        : const Color(0xFF7D858E);

    final temaGrupo = Theme.of(context).copyWith(
      dividerColor: esOscuro
          ? const Color(0xFF282B30)
          : const Color(0xFFE5E8EC),
      listTileTheme: ListTileThemeData(
        iconColor: colorIcono,
        textColor: textoPrincipal,
        titleTextStyle: TextStyle(
          color: textoPrincipal,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: textoSecundario,
          fontSize: 12,
          height: 1.2,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        minLeadingWidth: 28,
        minTileHeight: 72,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFF8F8F8),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? const Color(0xFF5F9368)
              : const Color(0xFFD0D4D8),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 10),
          child: Text(
            titulo.toUpperCase(),
            style: TextStyle(
              color: textoSecundario,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ),
        Material(
          color: esOscuro ? const Color(0xFF15171A) : Colors.white,
          borderRadius: BorderRadius.circular(27),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: temaGrupo,
            child: Column(
              children: [
                for (var i = 0; i < opciones.length; i++) ...[
                  IconTheme(
                    data: IconThemeData(color: colorIcono, size: 26),
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
