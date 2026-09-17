import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../../../elementos_compartidos/interaccion/retroalimentacion_haptica.dart';
import '../../../elementos_compartidos/navegacion/bloqueo_deslizamiento_principal.dart';

/// Cámara rápida para comenzar una publicación desde Inicio.
///
/// Las fotos se mantienen locales mientras se compone el lote. Solo se suben
/// al pulsar Siguiente, así cancelar no deja archivos sueltos en Storage.
class PantallaCamaraPublicacion extends StatefulWidget {
  const PantallaCamaraPublicacion({
    required this.activa,
    required this.alCerrar,
    required this.alContinuar,
    super.key,
  });

  final bool activa;
  final VoidCallback alCerrar;
  final ValueChanged<List<String>> alContinuar;

  @override
  State<PantallaCamaraPublicacion> createState() =>
      _PantallaCamaraPublicacionState();
}

class _PantallaCamaraPublicacionState extends State<PantallaCamaraPublicacion>
    with WidgetsBindingObserver {
  static const _maximoFotos = 12;

  final _selector = ImagePicker();
  final List<_FotoPendiente> _fotos = [];

  CameraController? _controlador;
  List<CameraDescription> _camaras = const [];
  CameraDescription? _camaraActiva;
  FlashMode _flash = FlashMode.off;
  bool _cargandoCamara = true;
  bool _capturando = false;
  bool _subiendo = false;
  int _subidas = 0;
  String? _errorCamara;
  Uint8List? _miniaturaReciente;
  double _zoomMinimo = 1;
  double _zoomMaximo = 1;
  double _zoomActual = 1;
  double _zoomAlComenzar = 1;
  double? _distanciaInicialZoom;
  final Map<int, Offset> _puntosZoom = {};
  bool _zoomEnCurso = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.activa) _activarCamara();
  }

  @override
  void didUpdateWidget(covariant PantallaCamaraPublicacion anterior) {
    super.didUpdateWidget(anterior);
    if (widget.activa && !anterior.activa) {
      _activarCamara();
    } else if (!widget.activa && anterior.activa) {
      _desactivarCamara();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final actual = _controlador;
      _controlador = null;
      actual?.dispose();
      return;
    }
    if (state == AppLifecycleState.resumed && widget.activa) {
      if (_camaraActiva != null) {
        _inicializarCamara(_camaraActiva!);
      }
    }
  }

  void _activarCamara() {
    _prepararCamaras();
    _cargarMiniaturaReciente();
  }

  void _desactivarCamara() {
    final actual = _controlador;
    _controlador = null;
    if (_zoomEnCurso) {
      _zoomEnCurso = false;
      const BloqueoDeslizamientoPrincipal(false).dispatch(context);
    }
    _puntosZoom.clear();
    _distanciaInicialZoom = null;
    unawaited(actual?.dispose());
    if (mounted) {
      setState(() {
        _cargandoCamara = true;
        _errorCamara = null;
      });
    }
  }

  Future<void> _cargarMiniaturaReciente() async {
    try {
      final permiso = await PhotoManager.requestPermissionExtend();
      if (!permiso.hasAccess) return;
      final albumes = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: const [OrderOption(type: OrderOptionType.createDate)],
        ),
      );
      if (albumes.isEmpty) return;
      final fotos = await albumes.first.getAssetListPaged(page: 0, size: 1);
      if (fotos.isEmpty) return;
      final miniatura = await fotos.first.thumbnailDataWithSize(
        const ThumbnailSize.square(180),
        quality: 82,
      );
      if (!mounted || miniatura == null) return;
      setState(() => _miniaturaReciente = miniatura);
    } catch (_) {
      // El selector nativo sigue disponible aunque no haya vista previa.
    }
  }

  Future<void> _prepararCamaras() async {
    try {
      final disponibles = await availableCameras();
      if (!mounted) return;
      _camaras = disponibles;
      if (disponibles.isEmpty) {
        setState(() {
          _cargandoCamara = false;
          _errorCamara = 'No encontramos una cámara disponible.';
        });
        return;
      }

      var elegida = disponibles.first;
      for (final camara in disponibles) {
        if (camara.lensDirection == CameraLensDirection.back) {
          elegida = camara;
          break;
        }
      }
      await _inicializarCamara(elegida);
    } on CameraException catch (error) {
      _mostrarErrorCamara(error);
    } catch (_) {
      _mostrarErrorCamara();
    }
  }

  Future<void> _inicializarCamara(CameraDescription descripcion) async {
    if (mounted) {
      setState(() {
        _cargandoCamara = true;
        _errorCamara = null;
      });
    }

    final anterior = _controlador;
    _controlador = null;
    await anterior?.dispose();

    final nuevo = CameraController(
      descripcion,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await nuevo.initialize();
      final zoomMinimo = await nuevo.getMinZoomLevel();
      final zoomMaximo = await nuevo.getMaxZoomLevel();
      try {
        await nuevo.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {
        // Web y algunas cámaras externas no permiten bloquear orientación.
      }
      try {
        await nuevo.setFlashMode(FlashMode.off);
      } catch (_) {
        // Una cámara frontal o web puede no exponer flash.
      }
      if (!mounted || !widget.activa) {
        await nuevo.dispose();
        return;
      }
      setState(() {
        _controlador = nuevo;
        _camaraActiva = descripcion;
        _flash = FlashMode.off;
        _zoomMinimo = zoomMinimo;
        _zoomMaximo = zoomMaximo;
        _zoomActual = zoomMinimo;
        _cargandoCamara = false;
      });
    } on CameraException catch (error) {
      await nuevo.dispose();
      _mostrarErrorCamara(error);
    } catch (_) {
      await nuevo.dispose();
      _mostrarErrorCamara();
    }
  }

  void _alTocarVista(PointerDownEvent evento) {
    _puntosZoom[evento.pointer] = evento.localPosition;
    if (_puntosZoom.length == 2 && !_zoomEnCurso) {
      final puntos = _puntosZoom.values.take(2).toList(growable: false);
      _distanciaInicialZoom = (puntos.first - puntos.last).distance;
      _zoomAlComenzar = _zoomActual;
      _zoomEnCurso = true;
      const BloqueoDeslizamientoPrincipal(true).dispatch(context);
    }
  }

  void _alMoverSobreVista(PointerMoveEvent evento) {
    if (!_puntosZoom.containsKey(evento.pointer)) return;
    _puntosZoom[evento.pointer] = evento.localPosition;
    final distanciaInicial = _distanciaInicialZoom;
    if (_puntosZoom.length < 2 ||
        distanciaInicial == null ||
        distanciaInicial <= 0) {
      return;
    }
    final puntos = _puntosZoom.values.take(2).toList(growable: false);
    final distancia = (puntos.first - puntos.last).distance;
    final nuevoZoom = (_zoomAlComenzar * distancia / distanciaInicial).clamp(
      _zoomMinimo,
      _zoomMaximo,
    );
    if ((nuevoZoom - _zoomActual).abs() < 0.015) return;
    _zoomActual = nuevoZoom;
    final controlador = _controlador;
    if (controlador != null && controlador.value.isInitialized) {
      unawaited(controlador.setZoomLevel(nuevoZoom).catchError((_) {}));
      if (mounted) setState(() {});
    }
  }

  void _alDejarVista(PointerEvent evento) {
    _puntosZoom.remove(evento.pointer);
    if (_puntosZoom.length < 2) {
      _distanciaInicialZoom = null;
    }
    // El PageView permanece bloqueado hasta que se levantan todos los dedos.
    // Soltar uno antes que el otro ya no convierte el pellizco en un swipe.
    if (_puntosZoom.isEmpty && _zoomEnCurso) {
      _zoomEnCurso = false;
      const BloqueoDeslizamientoPrincipal(false).dispatch(context);
    }
  }

  void _mostrarErrorCamara([CameraException? error]) {
    if (!mounted) return;
    final permisoDenegado =
        error?.code == 'CameraAccessDenied' ||
        error?.code == 'CameraAccessDeniedWithoutPrompt' ||
        error?.code == 'CameraAccessRestricted';
    setState(() {
      _cargandoCamara = false;
      _errorCamara = permisoDenegado
          ? 'Activa el permiso de Cámara para U market en Ajustes.'
          : 'No pudimos iniciar la cámara. Puedes elegir fotos de tu galería.';
    });
  }

  Future<void> _cambiarFlash() async {
    final controlador = _controlador;
    if (controlador == null || !controlador.value.isInitialized) return;

    final siguiente = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await controlador.setFlashMode(siguiente);
      if (!mounted) return;
      RetroalimentacionHaptica.seleccion();
      setState(() => _flash = siguiente);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta cámara no permite controlar el flash.'),
        ),
      );
    }
  }

  Future<void> _cambiarCamara() async {
    if (_camaras.length < 2 || _cargandoCamara) return;
    final activa = _camaraActiva;
    CameraDescription? siguiente;
    for (final camara in _camaras) {
      if (camara.lensDirection != activa?.lensDirection) {
        siguiente = camara;
        break;
      }
    }
    if (siguiente == null) return;
    RetroalimentacionHaptica.seleccion();
    await _inicializarCamara(siguiente);
  }

  Future<void> _tomarFoto() async {
    final controlador = _controlador;
    if (controlador == null ||
        !controlador.value.isInitialized ||
        _capturando ||
        _fotos.length >= _maximoFotos) {
      return;
    }

    setState(() => _capturando = true);
    try {
      final archivo = await controlador.takePicture();
      final bytes = await archivo.readAsBytes();
      if (!mounted) return;
      RetroalimentacionHaptica.accion();
      setState(() {
        _fotos.add(
          _FotoPendiente(bytes: bytes, tipo: archivo.mimeType ?? 'image/jpeg'),
        );
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo tomar la fotografía.')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  Future<void> _elegirDeGaleria() async {
    final disponibles = _maximoFotos - _fotos.length;
    if (disponibles <= 0 || _subiendo) return;
    try {
      final archivos = await _selector.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 86,
        limit: disponibles,
        requestFullMetadata: false,
      );
      if (archivos.isEmpty || !mounted) return;

      final nuevas = <_FotoPendiente>[];
      for (final archivo in archivos.take(disponibles)) {
        nuevas.add(
          _FotoPendiente(
            bytes: await archivo.readAsBytes(),
            tipo: archivo.mimeType ?? 'image/jpeg',
          ),
        );
      }
      if (!mounted) return;
      RetroalimentacionHaptica.seleccion();
      setState(() => _fotos.addAll(nuevas));
      _cargarMiniaturaReciente();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron abrir esas fotografías.'),
          ),
        );
      }
    }
  }

  Future<void> _continuar() async {
    if (_fotos.isEmpty || _subiendo) return;
    setState(() {
      _subiendo = true;
      _subidas = 0;
    });

    try {
      final rutas = <String>[];
      for (var indice = 0; indice < _fotos.length; indice++) {
        final foto = _fotos[indice];
        foto.rutaSubida ??= ModoLocal.activo
            ? 'data:${foto.tipo};base64,${base64Encode(foto.bytes)}'
            : await ServicioImagenes.subir(
                bytes: foto.bytes,
                etiqueta: 'producto_camara',
                tipo: foto.tipo,
              );
        rutas.add(foto.rutaSubida!);
        if (mounted) setState(() => _subidas = indice + 1);
      }

      if (!mounted) return;
      RetroalimentacionHaptica.exito();
      setState(() {
        _fotos.clear();
        _subiendo = false;
        _subidas = 0;
      });
      widget.alContinuar(rutas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar todas las fotos. Intenta nuevamente.',
          ),
        ),
      );
    }
  }

  IconData get _iconoFlash => switch (_flash) {
    FlashMode.auto => Icons.flash_auto_rounded,
    FlashMode.always || FlashMode.torch => Icons.flash_on_rounded,
    _ => Icons.flash_off_rounded,
  };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, _) {
          final zonaSegura = MediaQuery.paddingOf(context);
          return Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _alTocarVista,
                onPointerMove: _alMoverSobreVista,
                onPointerUp: _alDejarVista,
                onPointerCancel: _alDejarVista,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _VistaPreviaCamara(
                      controlador: _controlador,
                      cargando: _cargandoCamara,
                      error: _errorCamara,
                      alAbrirGaleria: _elegirDeGaleria,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: zonaSegura.top + 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BotonCamara(
                      etiqueta: 'Cerrar cámara',
                      icono: Icons.close_rounded,
                      alPresionar: _subiendo ? null : widget.alCerrar,
                    ),
                    _BotonCamara(
                      etiqueta: 'Cambiar flash',
                      icono: _iconoFlash,
                      alPresionar: _cambiarFlash,
                    ),
                    _BotonCamara(
                      etiqueta: 'Cambiar cámara',
                      icono: Icons.cameraswitch_rounded,
                      alPresionar: _camaras.length > 1 ? _cambiarCamara : null,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: zonaSegura.bottom + 18,
                height: 88,
                child: _ControlesInferioresCamara(
                  fotos: _fotos,
                  miniaturaReciente: _miniaturaReciente,
                  capturando: _capturando,
                  subiendo: _subiendo,
                  alGaleria: _elegirDeGaleria,
                  alCapturar: _tomarFoto,
                  alContinuar: _continuar,
                ),
              ),
              if (_subiendo)
                ColoredBox(
                  color: const Color(0xA6000000),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 14),
                        Text(
                          'Cargando $_subidas de ${_fotos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

class _VistaPreviaCamara extends StatelessWidget {
  const _VistaPreviaCamara({
    required this.controlador,
    required this.cargando,
    required this.error,
    required this.alAbrirGaleria,
  });

  final CameraController? controlador;
  final bool cargando;
  final String? error;
  final VoidCallback alAbrirGaleria;

  @override
  Widget build(BuildContext context) {
    final camara = controlador;
    final tamano = camara?.value.previewSize;
    if (camara != null && camara.value.isInitialized && tamano != null) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: tamano.height,
            height: tamano.width,
            child: CameraPreview(camara),
          ),
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFF182125),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: cargando
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.no_photography_outlined,
                      size: 48,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      error ?? 'La cámara no está disponible.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: alAbrirGaleria,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Abrir galería'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ControlesInferioresCamara extends StatelessWidget {
  const _ControlesInferioresCamara({
    required this.fotos,
    required this.miniaturaReciente,
    required this.capturando,
    required this.subiendo,
    required this.alGaleria,
    required this.alCapturar,
    required this.alContinuar,
  });

  final List<_FotoPendiente> fotos;
  final Uint8List? miniaturaReciente;
  final bool capturando;
  final bool subiendo;
  final VoidCallback alGaleria;
  final VoidCallback alCapturar;
  final VoidCallback alContinuar;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _AccionInferiorCamara(
        etiqueta: 'Galería',
        alPresionar: subiendo ? null : alGaleria,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 54,
                height: 54,
                child: fotos.isNotEmpty
                    ? Image.memory(fotos.last.bytes, fit: BoxFit.cover)
                    : miniaturaReciente != null
                    ? Image.memory(miniaturaReciente!, fit: BoxFit.cover)
                    : const ColoredBox(
                        color: Color(0xFF242B2E),
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
              ),
            ),
            if (fotos.isNotEmpty)
              Positioned(
                top: -7,
                right: -7,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: fotos.length < 10
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: fotos.length < 10
                        ? null
                        : BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF050A0D),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${fotos.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      Semantics(
        button: true,
        label: 'Tomar fotografía',
        child: GestureDetector(
          onTap: subiendo ? null : alCapturar,
          child: AnimatedScale(
            scale: capturando ? 0.9 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: capturando ? Colors.white60 : const Color(0xFFF7F5EF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        width: 94,
        height: 52,
        child: FilledButton(
          onPressed: fotos.isEmpty || subiendo ? null : alContinuar,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            backgroundColor: const Color(0xFFF7F5EF),
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF272E32),
            disabledForegroundColor: Colors.white24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Siguiente',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    ],
  );
}

class _BotonCamara extends StatelessWidget {
  const _BotonCamara({
    required this.etiqueta,
    required this.icono,
    required this.alPresionar,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: etiqueta,
    child: IconButton(
      onPressed: alPresionar,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x73000000),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icono, size: 27),
    ),
  );
}

class _AccionInferiorCamara extends StatelessWidget {
  const _AccionInferiorCamara({
    required this.etiqueta,
    required this.alPresionar,
    required this.child,
  });

  final String etiqueta;
  final VoidCallback? alPresionar;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: etiqueta,
    child: InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(width: 68, height: 68, child: Center(child: child)),
    ),
  );
}

class _FotoPendiente {
  _FotoPendiente({required this.bytes, required this.tipo});

  final Uint8List bytes;
  final String tipo;
  String? rutaSubida;
}
