import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../estados_aplicacion/indicador_carga.dart';

/// El carrete del teléfono, dentro de la aplicación.
///
/// Hasta ahora agregar fotos abría el selector del sistema: salías de la app,
/// elegías, y volvías. Funciona, pero se siente como un trámite ajeno, y en
/// Android cada fabricante pone el suyo, así que la pantalla es distinta en
/// cada teléfono.
///
/// Aquí las fotos se ven en una cuadrícula propia, se tocan para numerarlas
/// en el orden en que se eligen (ese orden es el que van a tener después) y
/// se confirman de una vez.
///
/// No existe en web: `photo_manager` lee el almacenamiento del sistema y un
/// navegador no da acceso a eso. Quien llame debe quedarse con el selector
/// del sistema como camino alternativo, que además sigue siendo el correcto
/// si la persona no concede el permiso.
class PantallaGaleriaDispositivo extends StatefulWidget {
  const PantallaGaleriaDispositivo({required this.maximo, super.key});

  /// Cuántas caben todavía. Al llegar al tope se dejan de poder marcar más,
  /// en vez de aceptarlas y descartarlas en silencio al volver.
  final int maximo;

  @override
  State<PantallaGaleriaDispositivo> createState() =>
      _PantallaGaleriaDispositivoState();
}

class _PantallaGaleriaDispositivoState
    extends State<PantallaGaleriaDispositivo> {
  static const _porPagina = 90;

  final _desplazamiento = ScrollController();
  final List<AssetEntity> _fotos = [];
  final List<AssetEntity> _elegidas = [];

  AssetPathEntity? _album;
  int _pagina = 0;
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _seAcabaron = false;
  bool _preparando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _desplazamiento.addListener(_alDesplazar);
    _abrirCarrete();
  }

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (_cargandoMas || _seAcabaron) return;
    final posicion = _desplazamiento.position;
    // Se pide la siguiente tanda antes de llegar al final, para que el
    // desplazamiento no se frene esperando miniaturas.
    if (posicion.pixels > posicion.maxScrollExtent - 600) _cargarPagina();
  }

  Future<void> _abrirCarrete() async {
    try {
      final permiso = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;
      if (!permiso.hasAccess) {
        setState(() {
          _cargando = false;
          _error = 'Necesitamos permiso para ver tus fotos.';
        });
        return;
      }

      final albumes = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
      if (!mounted) return;
      if (albumes.isEmpty) {
        setState(() {
          _cargando = false;
          _error = 'No encontramos fotos en este teléfono.';
        });
        return;
      }

      _album = albumes.first;
      await _cargarPagina();
      if (mounted) setState(() => _cargando = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo abrir la galería.';
        });
      }
    }
  }

  Future<void> _cargarPagina() async {
    final album = _album;
    if (album == null || _cargandoMas || _seAcabaron) return;
    _cargandoMas = true;

    try {
      final tanda = await album.getAssetListPaged(
        page: _pagina,
        size: _porPagina,
      );
      if (!mounted) return;
      setState(() {
        _fotos.addAll(tanda);
        _pagina++;
        _seAcabaron = tanda.length < _porPagina;
      });
    } catch (_) {
      _seAcabaron = true;
    } finally {
      _cargandoMas = false;
    }
  }

  void _alternar(AssetEntity foto) {
    setState(() {
      if (_elegidas.remove(foto)) return;
      if (_elegidas.length >= widget.maximo) return;
      _elegidas.add(foto);
    });
  }

  /// Devuelve los bytes en el orden en que se marcaron.
  ///
  /// Se leen aqui y no en quien llama porque `AssetEntity` es un identificador
  /// del sistema, no una foto: fuera de esta pantalla puede dejar de resolver.
  Future<void> _confirmar() async {
    if (_elegidas.isEmpty || _preparando) return;
    setState(() => _preparando = true);

    final bytes = <Uint8List>[];
    for (final foto in _elegidas) {
      final datos = await foto.originBytes;
      if (datos != null) bytes.add(datos);
    }

    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF474646),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFFE6E1D5),
      title: Text(
        _elegidas.isEmpty
            ? 'Elige tus fotos'
            : '${_elegidas.length} de ${widget.maximo}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      actions: [
        TextButton(
          onPressed: _elegidas.isEmpty || _preparando ? null : _confirmar,
          child: Text(
            _preparando ? 'Preparando…' : 'Listo',
            style: TextStyle(
              color: _elegidas.isEmpty
                  ? const Color(0x66E6E1D5)
                  : const Color(0xFFE6E1D5),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
    body: switch ((_cargando, _error)) {
      (true, _) => const Center(child: IndicadorCarga()),
      (_, final String mensaje) => _Aviso(mensaje: mensaje),
      _ => GridView.builder(
        controller: _desplazamiento,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _fotos.length,
        itemBuilder: (_, indice) {
          final foto = _fotos[indice];
          final puesto = _elegidas.indexOf(foto);
          return _Celda(
            foto: foto,
            puesto: puesto < 0 ? null : puesto + 1,
            // Al llegar al tope, las no elegidas se apagan: es mas honesto
            // que dejar tocarlas y no reaccionar.
            apagada: puesto < 0 && _elegidas.length >= widget.maximo,
            alTocar: () => _alternar(foto),
          );
        },
      ),
    },
  );
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.foto,
    required this.puesto,
    required this.apagada,
    required this.alTocar,
  });

  final AssetEntity foto;
  final int? puesto;
  final bool apagada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: apagada ? null : alTocar,
    child: Stack(
      fit: StackFit.expand,
      children: [
        // La miniatura del sistema, no la foto entera: una cuadricula de
        // fotos de 12 MP a tamano completo agota la memoria enseguida.
        FutureBuilder<Uint8List?>(
          future: foto.thumbnailDataWithSize(
            const ThumbnailSize.square(300),
            quality: 80,
          ),
          builder: (_, snapshot) => snapshot.data == null
              ? const ColoredBox(color: Color(0x1AE6E1D5))
              : Image.memory(snapshot.data!, fit: BoxFit.cover),
        ),
        if (apagada) const ColoredBox(color: Color(0x99474646)),
        if (puesto != null) ...[
          const ColoredBox(color: Color(0x4D000000)),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE6E1D5),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$puesto',
                style: const TextStyle(
                  color: Color(0xFF474646),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE6E1D5), fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextButton(
            // Volver sin nada deja a quien llama usar el selector del
            // sistema, que no necesita este permiso.
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Usar el selector del teléfono'),
          ),
        ],
      ),
    ),
  );
}
