import 'package:flutter/material.dart';

import '../logica/controlador_navegacion_principal.dart';

/// Presenta las secciones con una navegación nativa y ligera.
class PantallaNavegacionPrincipal extends StatelessWidget {
  const PantallaNavegacionPrincipal({
    required this.controlador,
    required this.pantallas,
    required this.encabezadoExploracion,
    super.key,
  });

  final ControladorNavegacionPrincipal controlador;
  final List<Widget> pantallas;
  final Widget encabezadoExploracion;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (_, _) => Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _PantallasDeslizables(
                indice: controlador.indice,
                pantallas: pantallas,
                alDeslizar: controlador.seleccionarIndice,
                reservarEncabezadoEnPrimeras: true,
              ),
            ),
            if (controlador.indice <= 1)
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: encabezadoExploracion,
              ),
          ],
        ),
      ),
      bottomNavigationBar: _BarraLigera(
        indice: controlador.indice,
        alSeleccionar: controlador.seleccionarIndice,
      ),
    ),
  );
}

/// Secciones navegables con el dedo, además de con la barra inferior.
///
/// Cada sección se construye solo la primera vez que se visita y luego
/// conserva su estado (posición del scroll, texto escrito), igual que hacía
/// el IndexedStack anterior.
class _PantallasDeslizables extends StatefulWidget {
  const _PantallasDeslizables({
    required this.indice,
    required this.pantallas,
    required this.alDeslizar,
    required this.reservarEncabezadoEnPrimeras,
  });

  final int indice;
  final List<Widget> pantallas;
  final ValueChanged<int> alDeslizar;
  final bool reservarEncabezadoEnPrimeras;

  @override
  State<_PantallasDeslizables> createState() => _PantallasDeslizablesState();
}

class _PantallasDeslizablesState extends State<_PantallasDeslizables> {
  late final _paginas = PageController(initialPage: widget.indice);

  @override
  void didUpdateWidget(covariant _PantallasDeslizables anterior) {
    super.didUpdateWidget(anterior);

    // El cambio vino de la barra inferior: se acompaña con la animacion.
    // Si vino del propio deslizamiento, la pagina ya esta donde toca.
    if (widget.indice != anterior.indice &&
        _paginas.hasClients &&
        _paginas.page?.round() != widget.indice) {
      final cambioDentroDeInicioYLocales =
          widget.indice <= 1 && anterior.indice <= 1;
      final cambioEntrePantallasCompletas =
          widget.indice > 1 && anterior.indice > 1;

      if (cambioDentroDeInicioYLocales || cambioEntrePantallasCompletas) {
        _paginas.animateToPage(
          widget.indice,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // Al entrar o salir de Inicio/Locales no se anima el PageView:
        // el encabezado y la pantalla cambian juntos, sin huecos oscuros,
        // compresión, desplazamiento vertical ni desapariciones intermedias.
        _paginas.jumpToPage(widget.indice);
      }
    }
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _paginas,
    onPageChanged: widget.alDeslizar,
    itemCount: widget.pantallas.length,
    itemBuilder: (_, indice) {
      final pantalla = widget.pantallas[indice];
      if (widget.reservarEncabezadoEnPrimeras && indice <= 1) {
        // El espacio pertenece a cada página y nunca cambia durante la
        // transición. Así, al abrir Publicar no se comprime Inicio/Locales.
        return Padding(
          padding: const EdgeInsets.only(top: 234),
          child: pantalla,
        );
      }
      return pantalla;
    },
  );
}

/// Cápsula deslizante sin blur, shaders ni filtros costosos.
class _BarraLigera extends StatelessWidget {
  const _BarraLigera({required this.indice, required this.alSeleccionar});

  final int indice;
  final ValueChanged<int> alSeleccionar;

  // El orden debe coincidir con la lista `pantallas` de ArbolNavegacionPrincipal.
  // Pedidos no vive aqui: se abre desde el encabezado del inicio y desde
  // Configuracion, para que la barra no acumule botones.
  List<(IconData, IconData, String)> get destinos => [
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Locales'),
    (Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Publicar'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Configuración'),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          // Del tema: fija en gris claro, la barra quedaba blanca flotando
          // sobre el fondo oscuro.
          color: esOscuro ? const Color(0xFF303230) : Colors.white,
          borderRadius: BorderRadius.circular(38),
          border: Border.all(
            color: esOscuro ? const Color(0xFF484A48) : const Color(0xFFE1E1E1),
          ),
          boxShadow: [
            BoxShadow(
              color: esOscuro
                  ? const Color(0x40000000)
                  : const Color(0x33000000),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final items = destinos;
            final anchoItem = restricciones.maxWidth / items.length;
            // Un unico margen para los cuatro lados. Antes iban por separado
            // (4 a los costados, 5 arriba, alto fijo) y la capsula quedaba
            // descuadrada respecto al icono.
            const margen = 5.0;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutBack,
                  left: indice * anchoItem + margen,
                  top: margen,
                  width: anchoItem - margen * 2,
                  height: restricciones.maxHeight - margen * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: esOscuro
                          ? tema.colorScheme.primary.withValues(alpha: .18)
                          : Colors.black,
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _DestinoBarra(
                          icono: items[i].$1,
                          iconoActivo: items[i].$2,
                          etiqueta: items[i].$3,
                          activo: indice == i,
                          alPresionar: () => alSeleccionar(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DestinoBarra extends StatelessWidget {
  const _DestinoBarra({
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
    required this.activo,
    required this.alPresionar,
  });

  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  final bool activo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final color = esOscuro
        ? activo
              ? tema.colorScheme.primary
              : Colors.white
        : activo
        ? Colors.white
        : Colors.black;
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: activo ? 1.08 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: Icon(activo ? iconoActivo : icono, color: color, size: 25),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: color,
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(etiqueta, maxLines: 1),
          ),
        ],
      ),
    );
  }
}
