import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../datos_prueba/usuario_prueba.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../diseno/boton_cerrar_sesion.dart';
import '../diseno/opcion_ayuda.dart';
import '../diseno/opcion_cuenta_institucional.dart';
import '../diseno/opcion_notificaciones.dart';
import '../diseno/opcion_privacidad.dart';
import '../diseno/opcion_tema_aplicacion.dart';
import '../diseno/tarjeta_perfil_usuario.dart';
import '../logica/controlador_configuracion.dart';

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

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (_, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 126),
      child: ContenidoCentrado(
        anchoMaximo: 620,
        child: Column(
          children: [
            const TarjetaPerfilUsuario(usuario: UsuarioPrueba.estudiante),
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
            BotonCerrarSesion(
              alPresionar: () => Navigator.of(context).pushNamedAndRemoveUntil(
                ConfiguracionRutas.acceso,
                (_) => false,
              ),
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

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6F5),
      borderRadius: BorderRadius.circular(26),
    ),
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
  );
}
