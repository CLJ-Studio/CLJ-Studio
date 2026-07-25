import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../../../datos_prueba/usuario_prueba.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../diseno/boton_cerrar_sesion.dart';
import '../diseno/encabezado_configuracion.dart';
import '../diseno/opcion_ayuda.dart';
import '../diseno/opcion_cuenta_institucional.dart';
import '../diseno/opcion_notificaciones.dart';
import '../diseno/opcion_privacidad.dart';
import '../diseno/opcion_tema_aplicacion.dart';
import '../diseno/tarjeta_perfil_usuario.dart';
import '../logica/controlador_configuracion.dart';

/// Vista de configuración con preferencias simuladas.
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
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
      child: ContenidoCentrado(
        anchoMaximo: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EncabezadoConfiguracion(),
            const SizedBox(height: 20),
            const TarjetaPerfilUsuario(usuario: UsuarioPrueba.estudiante),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  const OpcionCuentaInstitucional(),
                  const Divider(height: 1),
                  OpcionNotificaciones(
                    valor: controlador.notificaciones,
                    alCambiar: controlador.cambiarNotificaciones,
                  ),
                  const Divider(height: 1),
                  OpcionTemaAplicacion(
                    valor: controlador.temaOscuro,
                    alCambiar: controlador.cambiarTema,
                  ),
                  const Divider(height: 1),
                  const OpcionPrivacidad(),
                  const Divider(height: 1),
                  const OpcionAyuda(),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
