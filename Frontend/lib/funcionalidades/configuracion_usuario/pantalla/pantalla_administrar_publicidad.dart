import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../../inicio_marketplace/modelos/publicidad.dart';
import '../datos/repositorio_publicidad_admin.dart';

class PantallaAdministrarPublicidad extends StatefulWidget {
  const PantallaAdministrarPublicidad({super.key});

  @override
  State<PantallaAdministrarPublicidad> createState() =>
      _PantallaAdministrarPublicidadState();
}

class _PantallaAdministrarPublicidadState
    extends State<PantallaAdministrarPublicidad> {
  final _repositorio = const RepositorioPublicidadAdmin();
  List<Publicidad> _anuncios = const [];
  bool _cargando = true;
  bool _autorizado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final autorizado = await _repositorio.esAdministrador();
      if (!autorizado) {
        if (mounted) setState(() => _autorizado = false);
        return;
      }
      final anuncios = await _repositorio.listar();
      if (mounted) {
        setState(() {
          _autorizado = true;
          _anuncios = anuncios;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo cargar la publicidad.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editar([Publicidad? anuncio]) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) =>
          _FormularioPublicidad(repositorio: _repositorio, anuncio: anuncio),
    );
    if (guardado == true) await _cargar();
  }

  Future<void> _cambiarEstado(Publicidad anuncio, bool activa) async {
    try {
      await _repositorio.cambiarEstado(anuncio, activa);
      await _cargar();
    } catch (_) {
      if (mounted) _mensaje('No se pudo cambiar el estado del anuncio.');
    }
  }

  Future<void> _eliminar(Publicidad anuncio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: Text(
          'Se eliminarán “${anuncio.titulo}” y su imagen. Esta acción no se '
          'puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _repositorio.eliminar(anuncio);
      await _cargar();
    } catch (_) {
      if (mounted) _mensaje('No se pudo eliminar el anuncio.');
    }
  }

  void _mensaje(String texto) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administrar publicidad')),
    floatingActionButton: !_cargando && _autorizado
        ? FloatingActionButton.extended(
            onPressed: _editar,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo anuncio'),
          )
        : null,
    body: switch ((_cargando, _autorizado, _error)) {
      (true, _, _) => const Center(child: CircularProgressIndicator()),
      (_, _, final String error) => _EstadoPublicidad(
        icono: Icons.cloud_off_rounded,
        titulo: error,
        textoBoton: 'Reintentar',
        alPresionar: _cargar,
      ),
      (false, false, _) => const _EstadoPublicidad(
        icono: Icons.lock_rounded,
        titulo: 'Esta cuenta no tiene permiso para administrar publicidad.',
      ),
      (false, true, _) when _anuncios.isEmpty => _EstadoPublicidad(
        icono: Icons.campaign_outlined,
        titulo: 'Todavía no hay anuncios.',
        textoBoton: 'Crear el primero',
        alPresionar: _editar,
      ),
      _ => RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          itemCount: _anuncios.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, indice) {
            final anuncio = _anuncios[indice];
            return _TarjetaPublicidadAdmin(
              anuncio: anuncio,
              alEditar: () => _editar(anuncio),
              alEliminar: () => _eliminar(anuncio),
              alCambiarEstado: (valor) => _cambiarEstado(anuncio, valor),
            );
          },
        ),
      ),
    },
  );
}

class _TarjetaPublicidadAdmin extends StatelessWidget {
  const _TarjetaPublicidadAdmin({
    required this.anuncio,
    required this.alEditar,
    required this.alEliminar,
    required this.alCambiarEstado,
  });

  final Publicidad anuncio;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;
  final ValueChanged<bool> alCambiarEstado;

  String _fecha(DateTime? fecha) {
    if (fecha == null) return 'Sin límite';
    final local = fecha.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final estado = !anuncio.activa
        ? 'Inactivo'
        : anuncio.vigenteAhora
        ? 'Publicado'
        : 'Programado';
    final colorEstado = !anuncio.activa
        ? esquema.outline
        : anuncio.vigenteAhora
        ? const Color(0xFF16A34A)
        : Colors.orange.shade700;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: anuncio.ubicacion.proporcion,
            child: Image.network(
              anuncio.urlImagen,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: esquema.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 42),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        anuncio.titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Switch(value: anuncio.activa, onChanged: alCambiarEstado),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    Chip(label: Text(anuncio.ubicacion.etiqueta)),
                    Chip(
                      avatar: Icon(Icons.circle, size: 10, color: colorEstado),
                      label: Text(estado),
                    ),
                    Chip(label: Text('Orden ${anuncio.orden}')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Desde: ${_fecha(anuncio.iniciaEn)}  ·  '
                  'Hasta: ${_fecha(anuncio.terminaEn)}',
                  style: TextStyle(color: esquema.onSurfaceVariant),
                ),
                if (anuncio.tieneEnlace) ...[
                  const SizedBox(height: 4),
                  Text(
                    anuncio.enlaceUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: esquema.primary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: alEditar,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: alEliminar,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioPublicidad extends StatefulWidget {
  const _FormularioPublicidad({required this.repositorio, this.anuncio});

  final RepositorioPublicidadAdmin repositorio;
  final Publicidad? anuncio;

  @override
  State<_FormularioPublicidad> createState() => _FormularioPublicidadState();
}

class _FormularioPublicidadState extends State<_FormularioPublicidad> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _enlace;
  late final TextEditingController _orden;
  late UbicacionPublicidad _ubicacion;
  late bool _activa;
  DateTime? _iniciaEn;
  DateTime? _terminaEn;
  Uint8List? _imagenNueva;
  String _tipoImagen = 'image/jpeg';
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final anuncio = widget.anuncio;
    _titulo = TextEditingController(text: anuncio?.titulo ?? '');
    _enlace = TextEditingController(text: anuncio?.enlaceUrl ?? '');
    _orden = TextEditingController(text: '${anuncio?.orden ?? 0}');
    _ubicacion = anuncio?.ubicacion ?? UbicacionPublicidad.bannerPrincipal;
    _activa = anuncio?.activa ?? true;
    _iniciaEn = anuncio?.iniciaEn?.toLocal();
    _terminaEn = anuncio?.terminaEn?.toLocal();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _enlace.dispose();
    _orden.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    final elegida = await ServicioImagenes.elegir();
    if (elegida == null || !mounted) return;
    setState(() {
      _imagenNueva = elegida.bytes;
      _tipoImagen = elegida.tipo;
    });
  }

  Future<DateTime?> _elegirFecha(DateTime? actual) => showDatePicker(
    context: context,
    initialDate: actual ?? DateTime.now(),
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    if (_imagenNueva == null && widget.anuncio == null) {
      setState(() => _error = 'Selecciona una imagen para el anuncio.');
      return;
    }
    if (_iniciaEn != null &&
        _terminaEn != null &&
        !_terminaEn!.isAfter(_iniciaEn!)) {
      setState(
        () => _error = 'La fecha final debe ser posterior a la inicial.',
      );
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    String? rutaNueva;
    try {
      if (_imagenNueva != null) {
        rutaNueva = await widget.repositorio.subirImagen(
          bytes: _imagenNueva!,
          tipo: _tipoImagen,
        );
      }
      final ruta = rutaNueva ?? widget.anuncio!.rutaImagen;
      await widget.repositorio.guardar(
        id: widget.anuncio?.id,
        titulo: _titulo.text,
        rutaImagen: ruta,
        ubicacion: _ubicacion,
        orden: int.parse(_orden.text),
        activa: _activa,
        enlaceUrl: _enlace.text,
        iniciaEn: _iniciaEn,
        terminaEn: _terminaEn == null
            ? null
            : DateTime(
                _terminaEn!.year,
                _terminaEn!.month,
                _terminaEn!.day,
                23,
                59,
                59,
              ),
      );
      final anterior = widget.anuncio?.rutaImagen;
      if (rutaNueva != null && anterior != null && anterior != rutaNueva) {
        await widget.repositorio.eliminarImagen(anterior);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (rutaNueva != null) await widget.repositorio.eliminarImagen(rutaNueva);
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo guardar. Revisa los datos y vuelve a intentar.';
        });
      }
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      14,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 22,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.anuncio == null ? 'Nuevo anuncio' : 'Editar anuncio',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _guardando ? null : _elegirImagen,
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: _ubicacion.proporcion,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _imagenNueva != null
                      ? Image.memory(_imagenNueva!, fit: BoxFit.cover)
                      : widget.anuncio != null
                      ? Image.network(
                          widget.anuncio!.urlImagen,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 42,
                                ),
                                SizedBox(height: 6),
                                Text('Seleccionar imagen'),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _guardando ? null : _elegirImagen,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _imagenNueva == null && widget.anuncio == null
                    ? 'Elegir imagen'
                    : 'Cambiar imagen',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Nombre interno',
                hintText: 'Ej. Campaña septiembre',
              ),
              maxLength: 80,
              validator: (valor) => (valor?.trim().length ?? 0) < 2
                  ? 'Escribe un nombre de al menos 2 caracteres.'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<UbicacionPublicidad>(
              initialValue: _ubicacion,
              decoration: const InputDecoration(labelText: 'Ubicación'),
              items: [
                for (final ubicacion in UbicacionPublicidad.values)
                  DropdownMenuItem(
                    value: ubicacion,
                    child: Text(ubicacion.etiqueta),
                  ),
              ],
              onChanged: _guardando
                  ? null
                  : (valor) => setState(() => _ubicacion = valor!),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _RecomendacionImagen(
                key: ValueKey(_ubicacion),
                ubicacion: _ubicacion,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _enlace,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Enlace al tocar (opcional)',
                hintText: 'https://...',
              ),
              validator: (valor) {
                final texto = valor?.trim() ?? '';
                if (texto.isEmpty) return null;
                final uri = Uri.tryParse(texto);
                return uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https') &&
                        uri.host.isNotEmpty
                    ? null
                    : 'Usa un enlace http o https válido.';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _orden,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orden'),
              validator: (valor) => int.tryParse(valor ?? '') == null
                  ? 'Escribe un número entero.'
                  : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Anuncio activo'),
              subtitle: const Text(
                'Puedes guardarlo apagado y activarlo después.',
              ),
              value: _activa,
              onChanged: _guardando
                  ? null
                  : (valor) => setState(() => _activa = valor),
            ),
            const SizedBox(height: 8),
            _SelectorFecha(
              titulo: 'Comienza',
              valor: _formatearFecha(_iniciaEn),
              alElegir: () async {
                final fecha = await _elegirFecha(_iniciaEn);
                if (fecha != null && mounted) setState(() => _iniciaEn = fecha);
              },
              alLimpiar: _iniciaEn == null
                  ? null
                  : () => setState(() => _iniciaEn = null),
            ),
            const SizedBox(height: 8),
            _SelectorFecha(
              titulo: 'Termina',
              valor: _formatearFecha(_terminaEn),
              alElegir: () async {
                final fecha = await _elegirFecha(_terminaEn);
                if (fecha != null && mounted) {
                  setState(() => _terminaEn = fecha);
                }
              },
              alLimpiar: _terminaEn == null
                  ? null
                  : () => setState(() => _terminaEn = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_guardando ? 'Guardando…' : 'Guardar anuncio'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Explica el tamaño ideal para que la imagen no pierda encuadre al publicarse.
class _RecomendacionImagen extends StatelessWidget {
  const _RecomendacionImagen({required this.ubicacion, super.key});

  final UbicacionPublicidad ubicacion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esquema.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esquema.primary.withValues(alpha: .22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.aspect_ratio_rounded, color: esquema.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resolución recomendada',
                  style: TextStyle(
                    color: esquema.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${ubicacion.resolucionRecomendada} · '
                  'proporción ${ubicacion.proporcion.toStringAsFixed(2)}:1',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Usa esta medida para evitar cortes o deformaciones.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({
    required this.titulo,
    required this.valor,
    required this.alElegir,
    this.alLimpiar,
  });

  final String titulo;
  final String valor;
  final VoidCallback alElegir;
  final VoidCallback? alLimpiar;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(14),
    ),
    leading: const Icon(Icons.event_outlined),
    title: Text(titulo),
    subtitle: Text(valor),
    onTap: alElegir,
    trailing: alLimpiar == null
        ? const Icon(Icons.chevron_right_rounded)
        : IconButton(
            tooltip: 'Quitar fecha',
            onPressed: alLimpiar,
            icon: const Icon(Icons.close_rounded),
          ),
  );
}

class _EstadoPublicidad extends StatelessWidget {
  const _EstadoPublicidad({
    required this.icono,
    required this.titulo,
    this.textoBoton,
    this.alPresionar,
  });

  final IconData icono;
  final String titulo;
  final String? textoBoton;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 52),
          const SizedBox(height: 14),
          Text(titulo, textAlign: TextAlign.center),
          if (alPresionar != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: alPresionar, child: Text(textoBoton!)),
          ],
        ],
      ),
    ),
  );
}
