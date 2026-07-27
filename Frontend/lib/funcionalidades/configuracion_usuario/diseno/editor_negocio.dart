import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../../mi_local/datos/repositorio_mi_local.dart';

/// Edicion de la identidad del negocio: nombre, descripcion y logo.
///
/// Solo aparece si el estudiante tiene un local formal. Quien vende de forma
/// casual (su espacio personal) no ve nada de esto: no tiene marca que
/// mantener, y llenarle la pantalla de campos vacios seria ruido.
class EditorNegocio extends StatefulWidget {
  const EditorNegocio({super.key});

  @override
  State<EditorNegocio> createState() => _EditorNegocioState();
}

class _EditorNegocioState extends State<EditorNegocio> {
  static const _repositorio = RepositorioMiLocal();

  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();

  String? _categoriaId;
  String? _logoPath;
  String _emoji = '🍽️';
  bool _cargando = true;
  bool _tieneNegocio = false;
  bool _subiendoLogo = false;
  bool _guardando = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final local = await _repositorio.cargarLocal();
      // Un espacio personal no es un negocio: no se ofrece editarlo.
      if (local != null && !local.esPersonal) {
        _tieneNegocio = true;
        _nombre.text = local.nombre;
        _descripcion.text = local.descripcion;
        _categoriaId = local.categoriaId;
        _logoPath = local.logoPath;
        _emoji = local.emoji;
      }
    } catch (_) {
      _aviso = 'No se pudo cargar tu negocio.';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirLogo() async {
    setState(() => _subiendoLogo = true);
    try {
      final ruta = await ServicioImagenes.elegirYSubir(etiqueta: 'logo');
      if (ruta != null) setState(() => _logoPath = ruta);
    } catch (_) {
      if (mounted) setState(() => _aviso = 'No se pudo subir el logo.');
    } finally {
      if (mounted) setState(() => _subiendoLogo = false);
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _aviso = null;
    });
    try {
      await Supabase.instance.client.rpc(
        'actualizar_local',
        params: {
          'p_nombre': _nombre.text,
          'p_descripcion': _descripcion.text,
          'p_emoji': _emoji,
          'p_categoria': _categoriaId,
          'p_logo_path': _logoPath,
        },
      );
      if (mounted) setState(() => _aviso = 'Negocio actualizado.');
    } catch (fallo) {
      if (!mounted) return;
      setState(
        () => _aviso = fallo.toString().contains('CONTENIDO_NO_PERMITIDO')
            ? 'Revisa el nombre o la descripción: contienen texto no permitido.'
            : 'No se pudo guardar tu negocio.',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || !_tieneNegocio) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 40),
        Row(
          children: [
            const Icon(
              Icons.storefront_rounded,
              size: 19,
              color: Color(0xFF5C8A63),
            ),
            const SizedBox(width: 8),
            Text(
              'Tu negocio',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Así te ven los estudiantes en el catálogo.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        _Logo(
          logoUrl: ServicioImagenes.urlPublica(_logoPath),
          emoji: _emoji,
          subiendo: _subiendoLogo,
          alElegir: _elegirLogo,
          alQuitar: () => setState(() => _logoPath = null),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del negocio',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descripcion,
          maxLines: 3,
          maxLength: 180,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            alignLabelWithHint: true,
          ),
        ),
        if (_aviso case final String mensaje) ...[
          const SizedBox(height: 6),
          Text(
            mensaje,
            style: const TextStyle(color: Color(0xFF7C827E), fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _guardando ? null : _guardar,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF55785A),
            side: const BorderSide(color: Color(0xFF6F9D76), width: 1.4),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          icon: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.storefront_outlined, size: 18),
          label: const Text(
            'Guardar negocio',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Portada del negocio: imagen propia o el emoji elegido al abrirlo.
class _Logo extends StatelessWidget {
  const _Logo({
    required this.logoUrl,
    required this.emoji,
    required this.subiendo,
    required this.alElegir,
    required this.alQuitar,
  });

  final String? logoUrl;
  final String emoji;
  final bool subiendo;
  final VoidCallback alElegir;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              logoUrl!,
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton.filled(
              tooltip: 'Quitar logo',
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: alQuitar,
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: subiendo ? null : alElegir,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            if (subiendo)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              subiendo ? 'Subiendo logo...' : 'Subir logo del negocio',
              style: const TextStyle(color: Color(0xFF7C827E), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
