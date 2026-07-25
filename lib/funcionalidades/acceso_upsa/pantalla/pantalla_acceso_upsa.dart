import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../configuracion_aplicacion/configuracion_rutas.dart';
import '../datos/repositorio_acceso_upsa.dart';
import '../diseno/boton_continuar_google.dart';
import '../diseno/encabezado_acceso_upsa.dart';
import '../diseno/formulario_correo_upsa.dart';
import '../diseno/mensaje_acceso_exclusivo.dart';
import '../logica/controlador_acceso_upsa.dart';
import '../modelos/solicitud_acceso_upsa.dart';

/// Acceso institucional minimalista y responsivo.
class PantallaAccesoUpsa extends StatefulWidget {
  const PantallaAccesoUpsa({
    required this.controlador,
    required this.repositorio,
    super.key,
  });

  final ControladorAccesoUpsa controlador;
  final RepositorioAccesoUpsa repositorio;

  @override
  State<PantallaAccesoUpsa> createState() => _PantallaAccesoUpsaState();
}

class _PantallaAccesoUpsaState extends State<PantallaAccesoUpsa> {
  Future<void> _continuar() async {
    final estado = widget.controlador.estado;
    if (!estado.esValido) return;
    final acceso = await widget.repositorio.acceder(
      SolicitudAccesoUpsa(codigo: estado.codigo, correo: estado.correo),
    );
    if (acceso && mounted) {
      Navigator.of(context).pushReplacementNamed(ConfiguracionRutas.principal);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFEFEFE),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, restricciones) => Stack(
          children: [
            const _FormasDecorativas(),
            _BuhosAnimados(
              anchoPantalla: restricciones.maxWidth,
              altoPantalla: restricciones.maxHeight,
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: restricciones.maxHeight,
                  maxWidth: double.infinity,
                ),
                child: Center(
                  child: SizedBox(
                    width: 430,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'UPSA Eat',
                            style: TextStyle(
                              color: Color(0xFF181818),
                              fontFamily: 'Metropolis',
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: (restricciones.maxHeight * .30).clamp(
                            100,
                            260,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: widget.controlador,
                          builder: (context, _) {
                            final estado = widget.controlador.estado;
                            return Column(
                              children: [
                                const EncabezadoAccesoUpsa(),
                                const SizedBox(height: 28),
                                FormularioCorreoUpsa(
                                  alCambiar:
                                      widget.controlador.actualizarCodigo,
                                  error: estado.error,
                                  esValido: estado.esValido,
                                ),
                                const SizedBox(height: 14),
                                BotonContinuarGoogle(
                                  habilitado: estado.esValido,
                                  alPresionar: _continuar,
                                ),
                                const SizedBox(height: 18),
                                const MensajeAccesoExclusivo(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Ubica la animación contra la pared derecha sin interceptar los toques.
class _BuhosAnimados extends StatelessWidget {
  const _BuhosAnimados({
    required this.anchoPantalla,
    required this.altoPantalla,
  });

  final double anchoPantalla;
  final double altoPantalla;

  @override
  Widget build(BuildContext context) {
    final ancho = (anchoPantalla * .74).clamp(390.0, 760.0);
    return Positioned(
      // Posición vertical: aumenta el valor para bajar y redúcelo para subir.
      top: (altoPantalla * .12).clamp(70.0, 150.0),
      // Posición horizontal: aumenta `right` para mover a la izquierda.
      // El primer valor es para móvil y el segundo para pantallas grandes.
      right: anchoPantalla < 600 ? -65 : -20,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: SizedBox(
              // Tamaño: `width` controla el ancho y `.56` la proporción de alto.
              width: ancho,
              height: ancho * .56,
              child: Lottie.asset(
                'assets/animations/owls.json',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                repeat: true,
                frameRate: const FrameRate(24),
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Manchas suaves que conservan el gran espacio en blanco de la referencia.
class _FormasDecorativas extends StatelessWidget {
  const _FormasDecorativas();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        Positioned(
          top: 150,
          right: -28,
          child: Transform.rotate(angle: .24, child: _forma(105, 92)),
        ),
        Positioned(
          top: 290,
          left: -36,
          child: Transform.rotate(angle: -.22, child: _forma(112, 94)),
        ),
        Positioned(
          top: 355,
          right: -20,
          child: Transform.rotate(angle: .3, child: _forma(92, 82)),
        ),
      ],
    ),
  );

  Widget _forma(double ancho, double alto) => Container(
    width: ancho,
    height: alto,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6F0),
      borderRadius: BorderRadius.circular(24),
    ),
  );
}
