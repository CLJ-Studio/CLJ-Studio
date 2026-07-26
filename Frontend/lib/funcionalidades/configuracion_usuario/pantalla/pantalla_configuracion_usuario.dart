import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../diseno/boton_cerrar_sesion.dart';
import '../diseno/opcion_ayuda.dart';
import '../diseno/opcion_cuenta_institucional.dart';
import '../diseno/opcion_favoritos.dart';
import '../diseno/opcion_mis_publicaciones.dart';
import '../diseno/opcion_notificaciones.dart';
import '../diseno/opcion_privacidad.dart';
import '../diseno/opcion_tema_aplicacion.dart';
import '../diseno/tarjeta_perfil_usuario.dart';
import '../logica/controlador_configuracion.dart';
import '../modelos/usuario_upsa.dart';

/// Perfil y preferencias organizados en paneles claros.
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
    builder: (_, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 126),
      child: ContenidoCentrado(
        anchoMaximo: 620,
        child: Column(
          children: [
            if (sesion.perfil case final UsuarioUpsa perfil)
              TarjetaPerfilUsuario(usuario: perfil)
            else
              const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 30),
            const _PanelConfiguracion(
              titulo: 'Cuenta',
              children: [
                OpcionCuentaInstitucional(),
                Divider(height: 1, indent: 58, endIndent: 18),
                OpcionPrivacidad(),
              ],
            ),
            const SizedBox(height: 18),
            _PanelConfiguracion(
              titulo: 'Ajustes',
              children: [
                const OpcionFavoritos(),
                const Divider(height: 1, indent: 58, endIndent: 18),
                const OpcionMisPublicaciones(),
                const Divider(height: 1, indent: 58, endIndent: 18),
                OpcionNotificaciones(
                  valor: controlador.notificaciones,
                  alCambiar: controlador.cambiarNotificaciones,
                ),
                const Divider(height: 1, indent: 58, endIndent: 18),
                OpcionTemaAplicacion(
                  valor: controlador.temaOscuro,
                  alCambiar: controlador.cambiarTema,
                ),
                const Divider(height: 1, indent: 58, endIndent: 18),
                const OpcionAyuda(),
              ],
            ),
            const SizedBox(height: 22),
            // No se navega manualmente: PortonAutenticacion escucha
            // onAuthStateChange y cambia de pantalla solo al cerrar sesion.
            BotonCerrarSesion(
              alPresionar: () => Supabase.instance.client.auth.signOut(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PanelConfiguracion extends StatelessWidget {
  const _PanelConfiguracion({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  // Material (y no Container/DecoratedBox) porque los ListTile de adentro
  // pintan su fondo y sus ondas sobre el Material mas cercano: con un
  // DecoratedBox de por medio, esos efectos quedaban invisibles.
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF5F6F5),
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFF1E1F1E),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    ),
  );
}
