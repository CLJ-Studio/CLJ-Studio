import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/categoria_marketplace.dart';
import '../logica/controlador_mi_local.dart';

/// Flujo guiado de cuatro pasos para registrar un local.
class PantallaCrearLocal extends StatefulWidget {
  const PantallaCrearLocal({
    required this.controlador,
    required this.alCompletar,
    super.key,
  });

  final ControladorMiLocal controlador;
  final VoidCallback alCompletar;

  @override
  State<PantallaCrearLocal> createState() => _PantallaCrearLocalState();
}

class _PantallaCrearLocalState extends State<PantallaCrearLocal> {
  static const _ultimaPagina = 3;

  final _paginas = PageController();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  var _pagina = 0;
  var _logo = '🍽️';
  String? _categoriaId;
  String? _logoPath;
  bool _subiendoLogo = false;
  bool _guardando = false;

  // 'todas' es un filtro de interfaz: un local real no puede pertenecer ahi.
  late final Future<List<CategoriaMarketplace>> _categorias =
      const RepositorioInicioMarketplace().obtenerCategorias().then(
        (lista) => lista.where((c) => c.id != 'todas').toList(),
      );

  static const _logos = ['🍽️', '☕', '🍔', '🍕', '🥗', '🧁', '🥤', '🍱'];

  @override
  void dispose() {
    _paginas.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  bool get _puedeContinuar => switch (_pagina) {
    0 => _nombre.text.trim().length >= 3,
    1 => _descripcion.text.trim().length >= 10,
    2 => _categoriaId != null,
    _ => true,
  };

  String get _avisoDelPaso => switch (_pagina) {
    0 => 'Escribe un nombre de al menos 3 caracteres.',
    1 => 'Cuéntanos un poco más sobre tu local.',
    _ => 'Elige la categoría de tu local.',
  };

  Future<void> _continuar() async {
    if (!_puedeContinuar) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_avisoDelPaso)));
      return;
    }

    if (_pagina < _ultimaPagina) {
      _paginas.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await widget.controlador.crearLocal(
        nuevoNombre: _nombre.text,
        nuevaDescripcion: _descripcion.text,
        nuevoLogo: _logo,
        categoriaId: _categoriaId!,
        logoPath: _logoPath,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.alCompletar();
    } catch (error) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.toString().contains('stores_un_local_por_dueno')
                  ? 'Ya tienes un local abierto.'
                  : 'No se pudo crear tu local. Intenta de nuevo.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Abre tu local'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    _ultimaPagina + 1,
                    (indice) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 5,
                        margin: EdgeInsets.only(
                          right: indice == _ultimaPagina ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: indice <= _pagina
                              ? const Color(0xFF6F9A76)
                              : const Color(0xFFDDE3DD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView(
                    controller: _paginas,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (valor) => setState(() => _pagina = valor),
                    children: [
                      _PasoFormulario(
                        icono: Icons.storefront_rounded,
                        titulo: '¿Cómo se llamará tu local?',
                        descripcion:
                            'Este será el nombre que verán los estudiantes.',
                        child: TextField(
                          controller: _nombre,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del local',
                            hintText: 'Ej. Sabor Campus',
                          ),
                        ),
                      ),
                      _PasoFormulario(
                        icono: Icons.notes_rounded,
                        titulo: 'Cuéntanos qué ofreces',
                        descripcion:
                            'Una descripción breve ayuda a encontrar tu local.',
                        child: TextField(
                          controller: _descripcion,
                          onChanged: (_) => setState(() {}),
                          maxLines: 5,
                          maxLength: 180,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Comida fresca preparada en el campus...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      _PasoFormulario(
                        icono: Icons.sell_outlined,
                        titulo: '¿Qué tipo de local es?',
                        descripcion:
                            'La categoría define dónde te encuentran los '
                            'estudiantes al filtrar.',
                        child: FutureBuilder<List<CategoriaMarketplace>>(
                          future: _categorias,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final categoria in snapshot.data!)
                                  _FichaCategoria(
                                    categoria: categoria,
                                    activa: _categoriaId == categoria.id,
                                    alPresionar: () => setState(
                                      () => _categoriaId = categoria.id,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      _PasoFormulario(
                        icono: Icons.auto_awesome_rounded,
                        titulo: 'Elige tu logo',
                        descripcion:
                            'Selecciona un icono o sube tu propia imagen.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LogoSubido(
                              logoUrl: ServicioImagenes.urlPublica(_logoPath),
                              subiendo: _subiendoLogo,
                              alElegir: () async {
                                setState(() => _subiendoLogo = true);
                                try {
                                  final ruta =
                                      await ServicioImagenes.elegirYSubir(
                                        etiqueta: 'logo',
                                      );
                                  if (ruta != null) {
                                    setState(() => _logoPath = ruta);
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo subir el logo.',
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  setState(() => _subiendoLogo = false);
                                }
                              },
                              alQuitar: () =>
                                  setState(() => _logoPath = null),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final logo in _logos)
                                  InkWell(
                                    onTap: () => setState(() => _logo = logo),
                                    borderRadius: BorderRadius.circular(22),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 68,
                                      height: 68,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _logo == logo
                                            ? const Color(0xFFE1F0E3)
                                            : Colors.white,
                                        border: Border.all(
                                          color: _logo == logo
                                              ? const Color(0xFF6F9A76)
                                              : const Color(0xFFE3E7E3),
                                          width: _logo == logo ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          22,
                                        ),
                                      ),
                                      child: Text(
                                        logo,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardando ? null : _continuar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C8A63),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _pagina == _ultimaPagina
                                ? 'Crear mi local'
                                : 'Continuar',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Ficha seleccionable de categoría, al estilo de los chips del feed.
class _FichaCategoria extends StatelessWidget {
  const _FichaCategoria({
    required this.categoria,
    required this.activa,
    required this.alPresionar,
  });

  final CategoriaMarketplace categoria;
  final bool activa;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Material(
    color: activa ? const Color(0xFFE1F0E3) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(
            color: activa ? const Color(0xFF6F9A76) : const Color(0xFFE3E7E3),
            width: activa ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoria.icono,
              size: 19,
              color: activa
                  ? const Color(0xFF5C8A63)
                  : const Color(0xFF7C827E),
            ),
            const SizedBox(width: 8),
            Text(
              categoria.nombre,
              style: TextStyle(
                color: activa
                    ? const Color(0xFF5C8A63)
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PasoFormulario extends StatelessWidget {
  const _PasoFormulario({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compacto = constraints.maxWidth < 500;
      final buho = const _BuhoGuia();
      final burbuja = _BurbujaPregunta(
        icono: icono,
        titulo: titulo,
        descripcion: descripcion,
        puntaArriba: compacto,
        child: child,
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 26),
        child: compacto
            ? Column(children: [buho, const SizedBox(height: 2), burbuja])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 190, child: _BuhoGuia()),
                  const SizedBox(width: 18),
                  Expanded(child: burbuja),
                ],
              ),
      );
    },
  );
}

/// Personaje guía presente en cada pregunta del registro.
class _BuhoGuia extends StatelessWidget {
  const _BuhoGuia();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    height: 205,
    child: Lottie.asset(
      'assets/animations/owls-2.json',
      fit: BoxFit.contain,
      repeat: true,
      frameRate: FrameRate.composition,
    ),
  );
}

/// Burbuja que agrupa la pregunta y su control de respuesta.
class _BurbujaPregunta extends StatelessWidget {
  const _BurbujaPregunta({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.puntaArriba,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool puntaArriba;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: puntaArriba ? 52 : -9,
        top: puntaArriba ? -9 : 54,
        child: Transform.rotate(
          angle: .785,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(-2, -2),
                ),
              ],
            ),
          ),
        ),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              foregroundColor: const Color(0xFF5C8A63),
              child: Icon(icono, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              descripcion,
              style: const TextStyle(color: Color(0xFF7C827E), height: 1.4),
            ),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    ],
  );
}

/// Logo propio subido por el dueno; reemplaza al emoji como portada.
class _LogoSubido extends StatelessWidget {
  const _LogoSubido({
    required this.logoUrl,
    required this.subiendo,
    required this.alElegir,
    required this.alQuitar,
  });

  final String? logoUrl;
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
              height: 130,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton.filled(
              tooltip: 'Quitar imagen',
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: alQuitar,
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: subiendo ? null : alElegir,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF55785A),
        side: const BorderSide(color: Color(0xFF6F9D76), width: 1.4),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      ),
      icon: subiendo
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_photo_alternate_outlined, size: 19),
      label: Text(subiendo ? 'Subiendo...' : 'Subir imagen de portada'),
    );
  }
}
