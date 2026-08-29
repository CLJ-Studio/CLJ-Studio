import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../elementos_compartidos/marca/marca_u_market.dart';
import '../datos/codigo_pendiente.dart';
import '../datos/cuentas_recordadas.dart';
import '../datos/servicio_autenticacion_correo.dart';
import '../diseno/boton_acceso_correo.dart';
import '../diseno/campo_codigo_verificacion.dart';
import '../diseno/cuentas_guardadas.dart';
import '../datos/repositorio_acceso_upsa.dart';
import '../diseno/encabezado_acceso_upsa.dart';
import '../diseno/formulario_correo_upsa.dart';
import '../diseno/mensaje_acceso_exclusivo.dart';

/// Acceso institucional minimalista y responsivo.
class PantallaAccesoUpsa extends StatefulWidget {
  const PantallaAccesoUpsa({
    required this.repositorio,
    this.alAccederLocal,
    super.key,
  });

  final RepositorioAccesoUpsa repositorio;
  final VoidCallback? alAccederLocal;

  @override
  State<PantallaAccesoUpsa> createState() => _PantallaAccesoUpsaState();
}

class _PantallaAccesoUpsaState extends State<PantallaAccesoUpsa>
    with WidgetsBindingObserver {
  bool _cargando = false;
  String _digitos = '';
  String _codigo = '';
  String? _error;

  /// Correo al que se mandó el código. Mientras sea null se está en el
  /// primer paso; en cuanto tiene valor, la pantalla pide el código.
  String? _correoPendiente;

  List<String> _cuentas = const [];

  /// Segundos que faltan para poder pedir otro codigo.
  ///
  /// El servidor rechaza las peticiones seguidas, asi que sin esta cuenta
  /// atras el boton de reenviar invita a pulsar y responde con un error. Es
  /// mejor decir cuanto falta que dejar tropezar.
  int _esperaReenvio = 0;
  Timer? _cronometro;

  static const _segundosEntreCodigos = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarCuentas();
    _recuperarPendiente();
  }

  /// Al volver de segundo plano se recalcula la espera con la hora real.
  ///
  /// El navegador frena los temporizadores de una pestaña que no se ve, asi
  /// que el contador se quedaba congelado en el segundo en que se salio y
  /// pedia esperar de nuevo lo que ya habia pasado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado != AppLifecycleState.resumed) return;
    _recuperarPendiente();
  }

  /// Vuelve al paso del codigo si habia uno esperando.
  ///
  /// Salir a leer el correo devolvia la pantalla al principio: el estado
  /// vivia solo en memoria y una PWA en segundo plano puede descartarse.
  /// Al volver parecia que el codigo habia caducado, cuando lo perdido era
  /// la pantalla.
  Future<void> _recuperarPendiente() async {
    final pendiente = await CodigoPendiente.leer();
    if (pendiente == null || !mounted) return;

    if (_correoPendiente != pendiente.correo) {
      setState(() => _correoPendiente = pendiente.correo);
    }
    _iniciarEspera(pendiente.esperaRestante(_segundosEntreCodigos));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cronometro?.cancel();
    super.dispose();
  }

  void _iniciarEspera([int? desde]) {
    _cronometro?.cancel();
    setState(() => _esperaReenvio = desde ?? _segundosEntreCodigos);
    if (_esperaReenvio <= 0) return;

    _cronometro = Timer.periodic(const Duration(seconds: 1), (cronometro) {
      if (!mounted) {
        cronometro.cancel();
        return;
      }
      setState(() => _esperaReenvio--);
      if (_esperaReenvio <= 0) cronometro.cancel();
    });
  }

  Future<void> _cargarCuentas() async {
    final guardadas = await CuentasRecordadas.leer();
    if (mounted) setState(() => _cuentas = guardadas);
  }

  /// Formato real del codigo: año de ingreso (4), periodo (11 para el primer
  /// semestre, 12 para el segundo) y correlativo (4). Aceptar diez digitos
  /// cualesquiera dejaba pasar codigos inventados como "8382848283".
  bool get _registroCompleto {
    if (!RegExp(r'^\d{4}(11|12)\d{4}$').hasMatch(_digitos)) return false;
    final anio = int.parse(_digitos.substring(0, 4));
    return anio >= 2000 && anio <= DateTime.now().year;
  }

  bool get _codigoCompleto => _codigo.length == CampoCodigoVerificacion.largo;

  bool get _esperandoCodigo => _correoPendiente != null;

  bool get _accesoDirecto => widget.alAccederLocal != null;

  /// Pide el código al buzón institucional.
  Future<void> _pedirCodigo([String? correoDirecto]) async {
    // Una pulsacion adicional mientras la red responde no debe iniciar otra
    // solicitud ni mandar varios codigos al mismo correo.
    if (_cargando) return;

    final correo =
        correoDirecto ?? ServicioAutenticacionCorreo.normalizarCorreo(_digitos);
    if (correo == null) return;

    if (widget.alAccederLocal != null) {
      await CuentasRecordadas.recordar(correo);
      widget.alAccederLocal!();
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      // La pantalla de ingreso del codigo aparece en el primer toque; no
      // espera a que termine la llamada de red para dar respuesta visual.
      _correoPendiente = correo;
      _codigo = '';
    });

    final fallo = await widget.repositorio.enviarCodigo(correo);
    if (!mounted) return;

    setState(() {
      _cargando = false;
      _error = fallo;
      // Si no pudo enviarse, se vuelve al selector para poder intentarlo de
      // nuevo. Durante la espera, los toques repetidos ya fueron ignorados.
      if (fallo != null) _correoPendiente = null;
    });

    if (fallo == null) {
      // Se recuerda el paso para poder volver a el si la aplicacion se
      // descarta mientras se lee el correo.
      await CodigoPendiente.guardar(correo);
      _iniciarEspera();
    }
  }

  /// Canjea el código por una sesión.
  Future<void> _verificar() async {
    final correo = _correoPendiente;
    if (_cargando || correo == null || !_codigoCompleto) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    final fallo = await widget.repositorio.verificarCodigo(
      correo: correo,
      codigo: _codigo,
    );
    if (!mounted) return;

    if (fallo == null) {
      // Solo se recuerda cuando la sesión llegó a abrirse: guardar antes
      // llenaría la lista de correos que ni siquiera existen.
      await CuentasRecordadas.recordar(correo);
      // Ya se uso: dejarlo guardado devolveria a pedir codigo al salir.
      await CodigoPendiente.olvidar();
      // No se navega desde aquí: PortonAutenticacion escucha el cambio de
      // sesión y cambia de pantalla solo.
      return;
    }

    setState(() {
      _cargando = false;
      _error = fallo;
    });
  }

  Future<void> _volverAlCorreo() async {
    await CodigoPendiente.olvidar();
    if (!mounted) return;
    setState(() {
      _correoPendiente = null;
      _codigo = '';
      _error = null;
    });
  }

  Future<void> _olvidarCuenta(String correo) async {
    await CuentasRecordadas.olvidar(correo);
    await _cargarCuentas();
  }

  Widget _marca() => const MarcaUMarket(
    textAlign: TextAlign.center,
    colorU: Colors.black,
    colorMarket: Colors.black,
    style: TextStyle(
      color: Colors.black,
      fontFamily: 'Nunito',
      fontSize: 40,
      letterSpacing: -1.4,
    ),
  );

  Widget _contenidoAcceso({required bool escritorio}) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(escritorio ? 1.12 : 1)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EncabezadoAccesoUpsa(),
        SizedBox(height: escritorio ? 22 : 28),
        if (_esperandoCodigo) ...[
          _AvisoCodigoEnviado(correo: _correoPendiente!),
          const SizedBox(height: 16),
          CampoCodigoVerificacion(
            esValido: _codigoCompleto,
            hayError: _error != null,
            alCambiar: (valor) => setState(() => _codigo = valor),
            alEnviar: _verificar,
          ),
        ] else ...[
          CuentasGuardadas(
            cuentas: _cuentas,
            alElegir: _pedirCodigo,
            alOlvidar: _olvidarCuenta,
          ),
          if (_cuentas.isEmpty)
            FormularioCorreoUpsa(
              esValido: _registroCompleto,
              digitos: _digitos,
              alCambiar: (valor) => setState(
                () => _digitos = valor.replaceAll(RegExp(r'\D'), ''),
              ),
            ),
        ],
        if (_error case final String mensaje) ...[
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 14),
        if (_esperandoCodigo || _cuentas.isEmpty)
          BotonAccesoCorreo(
            habilitado: _esperandoCodigo ? _codigoCompleto : _registroCompleto,
            cargando: _cargando,
            texto: _esperandoCodigo
                ? 'Verificar e ingresar'
                : _accesoDirecto
                ? 'Ingresar'
                : 'Enviarme el código',
            icono: _esperandoCodigo
                ? Icons.login_rounded
                : _accesoDirecto
                ? Icons.login_rounded
                : Icons.mark_email_unread_outlined,
            alPresionar: _esperandoCodigo ? _verificar : _pedirCodigo,
          ),
        if (_esperandoCodigo) ...[
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: _cargando ? null : _volverAlCorreo,
                child: const Text('Cambiar de cuenta'),
              ),
              TextButton(
                onPressed: _cargando || _esperaReenvio > 0
                    ? null
                    : () => _pedirCodigo(_correoPendiente),
                child: Text(
                  _esperaReenvio > 0
                      ? 'Reenviar en ${_esperaReenvio}s'
                      : 'Reenviar código',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        const MensajeAccesoExclusivo(),
        const SizedBox(height: 24),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final escritorio = restricciones.maxWidth >= 900;
          return Stack(
            children: [
              const _FormasDecorativas(),
              if (escritorio) ...[
                Positioned(
                  top: 25,
                  left: 0,
                  right: 0,
                  child: _BuhosAnimados(ancho: restricciones.maxWidth),
                ),
                Positioned(top: 18, left: 40, right: 40, child: _marca()),
                Positioned(
                  left: restricciones.maxWidth * .07,
                  top: restricciones.maxHeight * .24,
                  width: (restricciones.maxWidth * .38).clamp(430, 560),
                  bottom: 16,
                  child: SingleChildScrollView(
                    child: _contenidoAcceso(escritorio: true),
                  ),
                ),
              ] else
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
                                    child: _marca(),
                                  ),
                                ],
                              ),
                            ),
                            _BuhosAnimados(ancho: restricciones.maxWidth),
                            const SizedBox(height: 4),
                            _contenidoAcceso(escritorio: false),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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

  // ================================================================
  // MODIFICA SOLAMENTE ESTOS TRES VALORES
  // ================================================================
  // Tamaño: 1.0 normal, 1.5 más grande, 0.7 más pequeño.
  static double tamanoBuhos = 0.7;

  // El archivo Lottie tiene espacio transparente después de la rama.
  // Este porcentaje lo saca fuera de pantalla para que la punta negra sea
  // la que toque la pared. Es proporcional y funciona igual en móvil y PC.
  static double compensacionBordeDerecho = 0.15;

  // Posición: negativo mueve hacia arriba; positivo, hacia abajo.
  static double posicionVerticalBuhos = 0;

  /// La rama no llega a los bordes de su propio lienzo, asi que a tamaño
  /// exacto termina antes que la pantalla y parece un palo flotando.
  /// Ampliarla y recortar hace que las puntas salgan por los costados en
  /// cualquier ancho, que es como se lee una rama de verdad. El escalado va
  /// desde el centro, asi que aleja las dos puntas por igual.
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
              // El formulario mide como máximo 430 px y está centrado. El
              // lienzo, en cambio, mide todo el viewport: centrarlo aquí hace
              // que sus bordes coincidan con las paredes reales de pantalla.
              alignment: Alignment.center,
              minWidth: ancho,
              maxWidth: ancho,
              minHeight: alto,
              maxHeight: alto,
              child: SizedBox(
                width: ancho,
                height: alto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      // El espacio transparente del Lottie también crece o
                      // disminuye con la escala. Compensarlo con el tamaño
                      // mantiene la punta de la rama pegada al borde.
                      right: -(ancho * compensacionBordeDerecho * tamanoBuhos),
                      top: posicionVerticalBuhos,
                      width: ancho,
                      height: alto,
                      child: Transform.scale(
                        scale: tamanoBuhos,
                        alignment: Alignment.centerRight,
                        child: Lottie.asset(
                          'assets/animations/owls.json',
                          fit: BoxFit.cover,
                          repeat: true,
                          frameRate: const FrameRate(24),
                          filterQuality: FilterQuality.low,
                          backgroundLoading: true,
                        ),
                      ),
                    ),
                  ],
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

/// Confirma de forma breve a qué correo se envió el código.
class _AvisoCodigoEnviado extends StatelessWidget {
  const _AvisoCodigoEnviado({required this.correo});

  final String correo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 21,
              color: tema.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Te enviamos un código a',
              style: TextStyle(
                color: tema.textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          correo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tema.textTheme.bodyMedium?.color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
