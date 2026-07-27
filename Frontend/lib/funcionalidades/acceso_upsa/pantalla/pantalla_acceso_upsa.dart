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
  Widget build(BuildContext context) {
    // Con el teclado abierto la pantalla pierde altura. Si se sigue exigiendo
    // el alto completo, el contenido se recentra y encoge a cada tecla; asi
    // solo se desplaza.
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricciones) => Stack(
            children: [
              const _FormasDecorativas(),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: tecladoAbierto ? 0 : restricciones.maxHeight,
                    maxWidth: double.infinity,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'UPSA Eat',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'Metropolis',
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ),
                        ),
                        // Fuera del padding lateral: la rama tiene que cruzar
                        // la pantalla entera.
                        _BuhosAnimados(ancho: restricciones.maxWidth),
                        Center(
                          child: SizedBox(
                            width: 430,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 12),
                                  const EncabezadoAccesoUpsa(),
                                  const SizedBox(height: 28),
                                  FormularioCorreoUpsa(
                                    esValido: _codigoCompleto,
                                    digitos: _digitos,
                                    alCambiar: (valor) => setState(
                                      () => _digitos = valor.replaceAll(
                                        RegExp(r'\D'),
                                        '',
                                      ),
                                    ),
                                  ),
                                  if (_errorDeRedireccion != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _errorDeRedireccion!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
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
                      ],
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
}

/// Búhos de bienvenida sobre una rama que cruza la pantalla de lado a lado.
///
/// Se mide por el ancho y nunca por el alto. Antes salia de la altura
/// disponible, asi que al abrir el teclado la pantalla se encogia, la
/// animacion se achicaba y todo el formulario daba un salto.
class _BuhosAnimados extends StatelessWidget {
  const _BuhosAnimados({required this.ancho});

  /// Ancho completo de la pantalla, sin el padding del formulario.
  final double ancho;

  /// El dibujo deja aire a los costados dentro de su propio lienzo, asi que
  /// a tamaño exacto la rama termina antes del borde y parece un palo
  /// flotando. Ampliarlo y recortar hace que las puntas salgan de la
  /// pantalla en cualquier ancho, que es como se lee una rama de verdad.
  static const _desborde = 1.3;

  /// Banda visible del lienzo: recorta el aire de arriba y abajo para que la
  /// escena no se coma media pantalla en telefonos angostos.
  static const _proporcionAlto = .38;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: ClipRect(
          child: SizedBox(
            width: ancho,
            height: ancho * _proporcionAlto,
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
  );
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
