import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/imagenes/pantalla_recortar_portada.dart';
import '../../../elementos_compartidos/imagenes/servicio_imagenes.dart';
import '../logica/controlador_mi_local.dart';

/// Flujo guiado para registrar un local.
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
  static const _ultimaPagina = 2;

  final _paginas = PageController();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  var _pagina = 0;
  static const _categoriaId = 'otros';
  static const _logoPredeterminado = '🏪';
  String? _logoPath;
  bool _subiendoLogo = false;
  bool _guardando = false;

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
    _ => true,
  };

  String get _avisoDelPaso => switch (_pagina) {
    0 => 'Escribe un nombre de al menos 3 caracteres.',
    _ => 'Cuéntanos un poco más sobre tu local.',
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
        nuevoLogo: _logoPredeterminado,
        categoriaId: _categoriaId,
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
    // El teclado se superpone al contenido: el boton permanece anclado abajo
    // y no salta hacia arriba al enfocar un campo.
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Abre tu local'),
    ),
    body: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
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
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              _continuar();
                            },
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: Color(0xFF263029)),
                            cursorColor: const Color(0xFF138A5B),
                            decoration: const InputDecoration(
                              labelText: 'Nombre del local',
                              hintText: 'Ej. Sabor Campus',
                              filled: true,
                              fillColor: Color(0xFFF0F2EF),
                              labelStyle: TextStyle(color: Color(0xFF68716B)),
                              hintStyle: TextStyle(color: Color(0xFF8B928D)),
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
                              hintText:
                                  'Comida fresca preparada en el campus...',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                        _PasoFormulario(
                          titulo: 'Sube el logo de tu local',
                          descripcion: 'Elige una imagen desde tu dispositivo.',
                          child: _LogoSubido(
                            logoUrl: ServicioImagenes.urlPublica(_logoPath),
                            subiendo: _subiendoLogo,
                            alElegir: () async {
                              setState(() => _subiendoLogo = true);
                              try {
                                final ruta = await elegirRecortarYSubirPortada(
                                  context,
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
                                if (mounted) {
                                  setState(() => _subiendoLogo = false);
                                }
                              }
                            },
                            alQuitar: () => setState(() => _logoPath = null),
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
                        backgroundColor: const Color(0xFF138A5B),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: IndicadorCarga(tamanio: 22),
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
    ),
  );
}

class _PasoFormulario extends StatelessWidget {
  const _PasoFormulario({
    this.icono,
    required this.titulo,
    required this.descripcion,
    required this.child,
  });

  final IconData? icono;
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
        puntaAbajo: compacto,
        child: child,
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 26),
        child: compacto
            ? Column(children: [burbuja, const SizedBox(height: 2), buho])
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
      backgroundLoading: true,
    ),
  );
}

/// Burbuja que agrupa la pregunta y su control de respuesta.
class _BurbujaPregunta extends StatelessWidget {
  const _BurbujaPregunta({
    this.icono,
    required this.titulo,
    required this.descripcion,
    required this.puntaAbajo,
    required this.child,
  });

  final IconData? icono;
  final String titulo;
  final String descripcion;
  final bool puntaAbajo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: puntaAbajo ? 52 : -9,
        top: puntaAbajo ? null : 54,
        bottom: puntaAbajo ? -9 : null,
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
            if (icono != null) ...[
              CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                foregroundColor: const Color(0xFF138A5B),
                child: Icon(icono, size: 22),
              ),
              const SizedBox(height: 16),
            ],
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

/// Imagen elegida por el dueño para identificar su local.
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
        foregroundColor: const Color(0xFF0C6843),
        side: const BorderSide(color: Color(0xFF6F9D76), width: 1.4),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      ),
      icon: subiendo
          ? const SizedBox(
              width: 16,
              height: 16,
              child: IndicadorCarga(tamanio: 16),
            )
          : const Icon(Icons.add_photo_alternate_outlined, size: 19),
      label: Text(subiendo ? 'Subiendo...' : 'Subir imagen del logo'),
    );
  }
}
