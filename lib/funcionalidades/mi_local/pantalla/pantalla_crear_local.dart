import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../logica/controlador_mi_local.dart';

/// Flujo guiado de tres pasos para registrar un local.
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
  final _paginas = PageController();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  var _pagina = 0;
  var _logo = '🍽️';

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
    _ => true,
  };

  void _continuar() {
    if (!_puedeContinuar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _pagina == 0
                ? 'Escribe un nombre de al menos 3 caracteres.'
                : 'Cuéntanos un poco más sobre tu local.',
          ),
        ),
      );
      return;
    }
    if (_pagina < 2) {
      _paginas.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    widget.controlador.crearLocal(
      nuevoNombre: _nombre.text,
      nuevaDescripcion: _descripcion.text,
      nuevoLogo: _logo,
    );
    Navigator.of(context).pop();
    widget.alCompletar();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6F3),
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
                    3,
                    (indice) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 5,
                        margin: EdgeInsets.only(right: indice == 2 ? 0 : 8),
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
                        icono: Icons.auto_awesome_rounded,
                        titulo: 'Elige tu logo',
                        descripcion:
                            'Selecciona la identidad que representará tu local.',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final logo in _logos)
                              InkWell(
                                onTap: () => setState(() => _logo = logo),
                                borderRadius: BorderRadius.circular(22),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
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
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Text(
                                    logo,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
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
                    onPressed: _continuar,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5C8A63),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                    child: Text(_pagina == 2 ? 'Crear mi local' : 'Continuar'),
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
          border: Border.all(color: const Color(0xFFE8ECE8)),
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
              backgroundColor: const Color(0xFFE7F2E8),
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
