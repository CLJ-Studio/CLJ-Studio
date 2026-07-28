import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../datos/repositorio_acceso_upsa.dart';
import '../diseno/boton_continuar_google.dart';
import '../diseno/encabezado_acceso_upsa.dart';
import '../diseno/formulario_correo_upsa.dart';
import '../diseno/mensaje_acceso_exclusivo.dart';

/// Acceso institucional minimalista y responsivo.
class PantallaAccesoUpsa extends StatefulWidget {
  const PantallaAccesoUpsa({required this.repositorio, super.key});

  final RepositorioAccesoUpsa repositorio;

  @override
  State<PantallaAccesoUpsa> createState() => _PantallaAccesoUpsaState();
}

class _PantallaAccesoUpsaState extends State<PantallaAccesoUpsa> {
  bool _cargando = false;
  String _digitos = '';

  /// Formato real del codigo: año de ingreso (4), periodo (11 para el primer
  /// semestre, 12 para el segundo) y correlativo (4). Aceptar diez digitos
  /// cualesquiera dejaba pasar codigos inventados como "8382848283".
  bool get _codigoCompleto {
    if (!RegExp(r'^\d{4}(11|12)\d{4}$').hasMatch(_digitos)) return false;
    final anio = int.parse(_digitos.substring(0, 4));
    return anio >= 2000 && anio <= DateTime.now().year;
  }

  /// Solo se envia como sugerencia si esta completo; a medio escribir
  /// confundiria al selector de Google en vez de ayudar.
  String? get _correoSugerido =>
      _codigoCompleto ? 'a$_digitos@estudiantes.upsa.edu.bo' : null;

  /// Si Supabase rechazo el alta (dominio no institucional), el redirect de
  /// vuelta trae el motivo en la URL en vez de una sesion activa.
  String? get _errorDeRedireccion {
    final descripcion = Uri.base.queryParameters['error_description'];
    if (descripcion == null) return null;
    if (descripcion.contains('DOMINIO_NO_INSTITUCIONAL')) {
      return 'Solo se permite el acceso con un correo institucional UPSA.';
    }
    return 'No se pudo completar el acceso con Google. Intenta de nuevo.';
  }

  Future<void> _continuar() async {
    setState(() => _cargando = true);
    try {
      await widget.repositorio.iniciarSesionConGoogle(
        correoSugerido: _correoSugerido,
      );
      // En Flutter Web la pestana navega fuera de la app aqui mismo;
      // si el widget sigue vivo es porque no hubo redireccion (p. ej. error).
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, restricciones) => Stack(
          children: [
            const _FormasDecorativas(),
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
                        SizedBox(
                          height: 25,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                top: -30,
                                child: Text(
                                  'UPSA Eat',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontFamily: 'Metropolis',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _BuhosAnimados(ancho: restricciones.maxWidth),
                        const SizedBox(height: 4),
                        const EncabezadoAccesoUpsa(),
                        const SizedBox(height: 28),
                        FormularioCorreoUpsa(
                          esValido: _codigoCompleto,
                          digitos: _digitos,
                          alCambiar: (valor) => setState(
                            () =>
                                _digitos = valor.replaceAll(RegExp(r'\D'), ''),
                          ),
                        ),
                        if (_errorDeRedireccion != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorDeRedireccion!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        BotonContinuarGoogle(
                          habilitado: !_cargando,
                          alPresionar: _continuar,
                        ),
                        const SizedBox(height: 18),
                        const MensajeAccesoExclusivo(),
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

/// Búhos de bienvenida sobre una rama que cruza la pantalla de lado a lado.
///
/// Se mide por el ancho, nunca por el alto ni con desplazamientos en pixeles.
/// Un `Offset` fijo cuadra solo en el telefono donde se probo: en el resto la
/// escena sale corrida y con un buho cortado. Y salir del alto disponible
/// hace que abrir el teclado encoja la pantalla, achique la animacion y todo
/// el formulario de un salto.
class _BuhosAnimados extends StatelessWidget {
  const _BuhosAnimados({required this.ancho});

  /// Ancho completo de la pantalla, sin el padding del formulario.
  final double ancho;

  /// La rama no llega a los bordes de su propio lienzo, asi que a tamaño
  /// exacto termina antes que la pantalla y parece un palo flotando.
  /// Ampliarla y recortar hace que las puntas salgan por los costados en
  /// cualquier ancho, que es como se lee una rama de verdad. El escalado va
  /// desde el centro, asi que aleja las dos puntas por igual.
  static const _desborde = 1.5;

  /// Banda visible del lienzo: recorta el aire de arriba y abajo para que la
  /// escena no se coma media pantalla en telefonos angostos.
  static const _proporcionAlto = .38;

  @override
  Widget build(BuildContext context) {
    final alto = ancho * _proporcionAlto;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            height: alto,
            // El formulario lleva padding lateral y un ancho maximo; la rama
            // no debe respetarlos, o volveria a terminar antes del borde.
            child: OverflowBox(
              maxWidth: ancho,
              maxHeight: alto,
              child: ClipRect(
                child: SizedBox(
                  width: ancho,
                  height: alto,
                  child: Transform.scale(
                    scale: _desborde,
                    child: Lottie.asset(
                      'assets/animations/owls.json',
                      fit: BoxFit.cover,
                      repeat: true,
                      frameRate: const FrameRate(24),
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                ),
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
          child: Transform.rotate(angle: .24, child: _forma(context, 105, 92)),
        ),
        Positioned(
          top: 290,
          left: -36,
          child: Transform.rotate(angle: -.22, child: _forma(context, 112, 94)),
        ),
        Positioned(
          top: 355,
          right: -20,
          child: Transform.rotate(angle: .3, child: _forma(context, 92, 82)),
        ),
      ],
    ),
  );

  Widget _forma(BuildContext context, double ancho, double alto) => Container(
    width: ancho,
    height: alto,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(24),
    ),
  );
}
