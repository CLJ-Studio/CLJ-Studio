import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../configuracion_aplicacion/modo_local.dart';
import '../estados_aplicacion/indicador_carga.dart';
import 'foto_red.dart';
import 'normalizar_portada.dart';
import 'pantalla_galeria_dispositivo.dart';
import 'pantalla_recortar_portada.dart';
import 'servicio_imagenes.dart';

/// Galeria de fotos de una publicacion, al estilo de un marketplace.
///
/// La primera foto es la portada: es la que se ve en las tarjetas del
/// catalogo, por eso se puede reordenar arrastrando y se marca cual es.
class SelectorGaleria extends StatelessWidget {
  const SelectorGaleria({
    required this.rutas,
    required this.alCambiar,
    this.maximo = 12,
    super.key,
  });

  final List<String> rutas;
  final ValueChanged<List<String>> alCambiar;
  final int maximo;

  @override
  Widget build(BuildContext context) => _SelectorGaleriaInterno(
    rutas: rutas,
    alCambiar: alCambiar,
    maximo: maximo,
  );
}

class _SelectorGaleriaInterno extends StatefulWidget {
  const _SelectorGaleriaInterno({
    required this.rutas,
    required this.alCambiar,
    required this.maximo,
  });

  final List<String> rutas;
  final ValueChanged<List<String>> alCambiar;
  final int maximo;

  @override
  State<_SelectorGaleriaInterno> createState() => _SelectorGaleriaState();
}

class _SelectorGaleriaState extends State<_SelectorGaleriaInterno> {
  final _selector = ImagePicker();

  bool _subiendo = false;
  int _subidas = 0;
  int _porSubir = 0;

  /// Elige varias fotos de una pasada y las sube.
  ///
  /// Antes era de a una: abrir el selector del sistema, elegir UNA, encuadrar,
  /// subir, volver, y repetir el viaje entero por cada foto. Para cinco fotos
  /// eran cinco vueltas completas.
  ///
  /// Cada foto se encuadra sola a 4:3 en vez de pedir el recorte cinco veces
  /// seguidas. Quien quiera corregir una la ajusta despues, con el boton de
  /// la propia miniatura.
  Future<void> _agregar() async {
    final disponibles = widget.maximo - widget.rutas.length;
    if (disponibles <= 0 || _subiendo) return;

    // Primero la galeria propia; si no esta disponible (web, o permiso
    // denegado), el selector del sistema, que siempre funciona.
    var tanda = await _elegirEnLaApp(disponibles);
    tanda ??= await _elegirConElSistema(disponibles);
    if (tanda == null || tanda.isEmpty || !mounted) return;

    setState(() {
      _subiendo = true;
      _subidas = 0;
      _porSubir = tanda!.length;
    });

    // Se van agregando de a una y no todas al final: en una conexion de
    // campus cinco fotos tardan, y ver aparecer la primera mientras suben las
    // demas es la diferencia entre "esta funcionando" y "se colgo".
    var fallaron = 0;
    for (final bytes in tanda) {
      try {
        final ruta = await _subirNormalizada(bytes);
        if (!mounted) return;
        widget.alCambiar([...widget.rutas, ruta]);
      } catch (_) {
        fallaron++;
      }
      if (!mounted) return;
      setState(() => _subidas++);
    }

    if (!mounted) return;
    setState(() {
      _subiendo = false;
      _subidas = 0;
      _porSubir = 0;
    });

    if (fallaron > 0) {
      _avisar(
        fallaron == tanda.length
            ? 'No se pudieron subir las fotos.'
            : 'No se pudieron subir $fallaron de ${tanda.length} fotos.',
      );
    }
  }

  /// La galeria dentro de la aplicacion. Null cuando no se puede usar y hay
  /// que caer al selector del sistema; lista vacia cuando se salio sin elegir.
  Future<List<Uint8List>?> _elegirEnLaApp(int disponibles) async {
    // En web no hay carrete al que asomarse: el navegador no da acceso al
    // almacenamiento del telefono.
    if (kIsWeb) return null;

    final elegidas = await Navigator.of(context).push<List<Uint8List>>(
      MaterialPageRoute<List<Uint8List>>(
        builder: (_) => PantallaGaleriaDispositivo(maximo: disponibles),
      ),
    );
    // Volver sin nada puede ser "me arrepenti" o "no di permiso". La pantalla
    // ofrece el selector del sistema en el segundo caso, asi que aqui se
    // interpreta como que no hay nada que subir.
    return elegidas ?? const [];
  }

  Future<List<Uint8List>?> _elegirConElSistema(int disponibles) async {
    try {
      final archivos = await _selector.pickMultiImage(
        // Reencoda al elegir: nadie necesita 12 MP en una tarjeta de producto.
        maxWidth: 1600,
        imageQuality: 86,
        limit: disponibles,
        requestFullMetadata: false,
      );
      final bytes = <Uint8List>[];
      for (final archivo in archivos.take(disponibles)) {
        bytes.add(await archivo.readAsBytes());
      }
      return bytes;
    } catch (_) {
      _avisar('No se pudieron abrir esas fotos.');
      return null;
    }
  }

  Future<String> _subirNormalizada(Uint8List bytes) async {
    final encuadrada = await normalizarPortada(bytes);
    if (ModoLocal.activo) {
      return 'data:image/jpeg;base64,${base64Encode(encuadrada)}';
    }
    return ServicioImagenes.subir(
      bytes: encuadrada,
      etiqueta: 'producto',
      tipo: 'image/jpeg',
    );
  }

  /// Reencuadra una foto ya subida, para la que el recorte automatico cortó
  /// justo lo que importaba. Se baja, se abre el encuadre y se sube de nuevo:
  /// la ruta cambia, asi que ninguna copia vieja queda cacheada.
  Future<void> _ajustar(int indice) async {
    if (_subiendo) return;
    final ruta = widget.rutas[indice];
    if (ruta.startsWith('data:') || ruta.startsWith('blob:')) return;

    setState(() => _subiendo = true);
    try {
      final original = await ServicioImagenes.descargar(ruta);
      if (!mounted || original == null) return;

      final recortada = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => PantallaRecortarPortada(original: original),
        ),
      );
      if (!mounted || recortada == null) return;

      final nueva = await ServicioImagenes.subir(
        bytes: recortada,
        etiqueta: 'producto',
        tipo: 'image/jpeg',
      );
      if (!mounted) return;
      widget.alCambiar([...widget.rutas]..[indice] = nueva);
    } catch (_) {
      _avisar('No se pudo ajustar la foto.');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
      );
  }

  void _quitar(int indice) =>
      widget.alCambiar([...widget.rutas]..removeAt(indice));

  /// Cualquier foto puede pasar a ser la portada sin volver a subirla.
  void _hacerPortada(int indice) {
    final nuevas = [...widget.rutas];
    nuevas.insert(0, nuevas.removeAt(indice));
    widget.alCambiar(nuevas);
  }

  /// Mueve una foto al sitio de otra, arrastrando.
  void _mover(int desde, int hasta) {
    if (desde == hasta) return;
    final nuevas = [...widget.rutas];
    nuevas.insert(hasta, nuevas.removeAt(desde));
    widget.alCambiar(nuevas);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < widget.rutas.length; i++)
            _MiniaturaArrastrable(
              indice: i,
              url: ServicioImagenes.urlPublica(widget.rutas[i])!,
              esPortada: i == 0,
              alQuitar: () => _quitar(i),
              alHacerPortada: i == 0 ? null : () => _hacerPortada(i),
              alAjustar: () => _ajustar(i),
              alSoltarEncima: (desde) => _mover(desde, i),
            ),
          if (widget.rutas.length < widget.maximo)
            _BotonAgregar(
              subiendo: _subiendo,
              alPresionar: _agregar,
              mostrarIndicacion: widget.rutas.isEmpty,
              subidas: _subidas,
              porSubir: _porSubir,
            ),
        ],
      ),
      if (widget.rutas.length > 1) ...[
        const SizedBox(height: 8),
        Text(
          'Mantén presionada una foto para cambiarla de orden. '
          'La primera es la portada.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
          ),
        ),
      ],
    ],
  );
}

/// Miniatura que se puede arrastrar sobre otra para cambiar el orden.
///
/// Arrastrar es la unica forma comoda de decir "esta va primero" cuando ya
/// hay seis fotos: el boton de portada sirve para una, pero ordenar las seis
/// a base de toques es un rompecabezas.
class _MiniaturaArrastrable extends StatelessWidget {
  const _MiniaturaArrastrable({
    required this.indice,
    required this.url,
    required this.esPortada,
    required this.alQuitar,
    required this.alAjustar,
    required this.alSoltarEncima,
    this.alHacerPortada,
  });

  final int indice;
  final String url;
  final bool esPortada;
  final VoidCallback alQuitar;
  final VoidCallback alAjustar;
  final ValueChanged<int> alSoltarEncima;
  final VoidCallback? alHacerPortada;

  @override
  Widget build(BuildContext context) {
    final miniatura = _Miniatura(
      url: url,
      esPortada: esPortada,
      alQuitar: alQuitar,
      alHacerPortada: alHacerPortada,
      alAjustar: alAjustar,
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (detalles) => detalles.data != indice,
      onAcceptWithDetails: (detalles) => alSoltarEncima(detalles.data),
      builder: (context, encima, _) => AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: encima.isEmpty ? 1 : 1.06,
        child: LongPressDraggable<int>(
          data: indice,
          // La miniatura arrastrada viaja sin sus botones: con ellos parece
          // que se pueden tocar en pleno arrastre.
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: .9,
              child: SizedBox(
                width: 92,
                height: 92,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FotoRed(url: url, anchoVisible: 92),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: .3, child: miniatura),
          child: miniatura,
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.url,
    required this.esPortada,
    required this.alQuitar,
    this.alHacerPortada,
    this.alAjustar,
  });

  final String url;
  final bool esPortada;
  final VoidCallback alQuitar;
  final VoidCallback? alHacerPortada;

  /// Reencuadra esta foto. El recorte automatico acierta casi siempre, pero
  /// cuando corta justo el producto hace falta poder corregirlo.
  final VoidCallback? alAjustar;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    height: 92,
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FotoRed(url: url, anchoVisible: 92),
          ),
        ),
        if (esPortada)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF474646),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Portada',
                style: TextStyle(
                  color: Color(0xFFE6E1D5),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
        else
          Positioned(
            left: 4,
            bottom: 4,
            child: Material(
              color: Color(0x8A474646),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: alHacerPortada,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  child: Text(
                    'Portada',
                    style: TextStyle(color: Color(0xFFE6E1D5), fontSize: 9),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: Color(0x8A474646),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: alQuitar,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Color(0xFFE6E1D5),
                ),
              ),
            ),
          ),
        ),
        if (alAjustar != null)
          Positioned(
            top: 2,
            left: 2,
            child: Material(
              color: Color(0x8A474646),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: alAjustar,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.crop_rounded,
                    size: 14,
                    color: Color(0xFFE6E1D5),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({
    required this.subiendo,
    required this.alPresionar,
    required this.mostrarIndicacion,
    this.subidas = 0,
    this.porSubir = 0,
  });

  final bool subiendo;
  final VoidCallback alPresionar;
  final bool mostrarIndicacion;

  /// Cuantas van y cuantas son. Subir cinco fotos por una conexion de campus
  /// tarda, y una rueda girando sin numeros no dice si avanza o se colgo.
  final int subidas;
  final int porSubir;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: subiendo ? null : alPresionar,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: mostrarIndicacion ? 176 : 92,
      height: 92,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        border: Border.all(color: const Color(0xFFE6E1D5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: subiendo
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: IndicadorCarga(tamanio: 22),
                  ),
                  if (porSubir > 1) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${subidas + 1} de $porSubir',
                      style: const TextStyle(
                        color: Color(0xFF848381),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              )
            : mostrarIndicacion
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF848381),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Agrega fotos reales\nLa primera será portada',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              )
            : const Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFF848381),
              ),
      ),
    ),
  );
}
