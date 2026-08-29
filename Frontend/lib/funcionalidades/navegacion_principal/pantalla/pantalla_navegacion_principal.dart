import 'dart:async';

import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/navegacion/bloqueo_deslizamiento_principal.dart';
import '../logica/controlador_navegacion_principal.dart';

/// Presenta las secciones con una navegación nativa y ligera.
class PantallaNavegacionPrincipal extends StatelessWidget {
  const PantallaNavegacionPrincipal({
    required this.controlador,
    required this.pantallas,
    super.key,
  });

  final ControladorNavegacionPrincipal controlador;
  final List<Widget> pantallas;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (_, _) {
      final ocultarBarra = controlador.indice == 2;

      return Scaffold(
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
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BarraAnimadaPublicar(
          ocultar: ocultarBarra,
          child: _BarraLigera(
            indice: controlador.indice,
            alSeleccionar: controlador.seleccionarIndice,
          ),
        ),
      );
    },
  );
}

/// Deja entrar primero a Publicar y después retira la navegación inferior.
/// Al salir, la barra reaparece sin espera para acompañar el deslizamiento.
class _BarraAnimadaPublicar extends StatefulWidget {
  const _BarraAnimadaPublicar({required this.ocultar, required this.child});

  final bool ocultar;
  final Widget child;

  @override
  State<_BarraAnimadaPublicar> createState() => _BarraAnimadaPublicarState();
}

class _BarraAnimadaPublicarState extends State<_BarraAnimadaPublicar> {
  Timer? _espera;
  late bool _oculta;

  @override
  void initState() {
    super.initState();
    _oculta = widget.ocultar;
  }

  @override
  void didUpdateWidget(covariant _BarraAnimadaPublicar anterior) {
    super.didUpdateWidget(anterior);
    if (widget.ocultar == anterior.ocultar) return;

    _espera?.cancel();
    if (widget.ocultar) {
      _espera = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _oculta = true);
      });
    } else if (_oculta) {
      setState(() => _oculta = false);
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: _oculta,
    child: AnimatedSlide(
      offset: _oculta ? const Offset(0, 1.18) : Offset.zero,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: _oculta ? 0 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: widget.child,
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
  });

  final int indice;
  final List<Widget> pantallas;
  final ValueChanged<int> alDeslizar;

  @override
  State<_PantallasDeslizables> createState() => _PantallasDeslizablesState();
}

class _PantallasDeslizablesState extends State<_PantallasDeslizables> {
  late final _paginas = PageController(initialPage: widget.indice);
  bool _deslizamientoBloqueado = false;

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
  Widget build(BuildContext context) =>
      NotificationListener<BloqueoDeslizamientoPrincipal>(
        onNotification: (notificacion) {
          if (_deslizamientoBloqueado != notificacion.bloqueado) {
            setState(() => _deslizamientoBloqueado = notificacion.bloqueado);
          }
          return true;
        },
        child: PageView.builder(
          controller: _paginas,
          physics: _deslizamientoBloqueado
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: widget.alDeslizar,
          itemCount: widget.pantallas.length,
          itemBuilder: (_, indice) => widget.pantallas[indice],
        ),
      );
}

/// Cápsula deslizante sin blur, shaders ni filtros costosos.
class _BarraLigera extends StatelessWidget {
  const _BarraLigera({required this.indice, required this.alSeleccionar});

  final int indice;
  final ValueChanged<int> alSeleccionar;

  // El orden debe coincidir con la lista `pantallas` de ArbolNavegacionPrincipal.
  // Pedidos no vive aqui: se abre desde el encabezado del inicio y desde
  // Perfil, para que la barra no acumule botones.
  List<(IconData, IconData, String)> get destinos => [
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Locales'),
    (Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Publicar'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              // Del tema: fija en gris claro, la barra quedaba blanca flotando
              // sobre el fondo oscuro.
              color: esOscuro
                  ? const Color(0xFF474646)
                  : ConfiguracionTema.cremaSuperficie,
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: esOscuro
                    ? const Color(0xFF969A82)
                    : const Color(0xFFBBBCA7),
              ),
              boxShadow: [
                BoxShadow(
                  color: esOscuro
                      ? const Color(0x40474646)
                      : const Color(0x33474646),
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
                          color: ConfiguracionTema.naranjaCoral,
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
    final colorTexto = activo
        ? ConfiguracionTema.azulNoche
        : esOscuro
        ? Color(0xFFE6E1D5)
        : Color(0xFF474646);
    final colorIcono = activo ? ConfiguracionTema.blancoSuave : colorTexto;
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
            child: Icon(
              activo ? iconoActivo : icono,
              color: colorIcono,
              size: 25,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: colorTexto,
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
