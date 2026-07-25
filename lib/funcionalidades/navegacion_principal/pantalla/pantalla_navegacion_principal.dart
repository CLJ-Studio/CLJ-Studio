import 'package:flutter/material.dart';

import '../logica/controlador_navegacion_principal.dart';

/// Presenta las secciones con una navegación nativa y ligera.
class PantallaNavegacionPrincipal extends StatelessWidget {
  const PantallaNavegacionPrincipal({
    required this.controlador,
    required this.pantallas,
    required this.mostrarMiLocal,
    super.key,
  });

  final ControladorNavegacionPrincipal controlador;
  final List<Widget> pantallas;
  final bool mostrarMiLocal;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controlador,
    builder: (_, _) => Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _PantallasPerezosas(
          indice: controlador.indice,
          pantallas: pantallas,
        ),
      ),
      bottomNavigationBar: _BarraLigera(
        indice: controlador.indice,
        mostrarMiLocal: mostrarMiLocal,
        alSeleccionar: controlador.seleccionarIndice,
      ),
    ),
  );
}

/// Construye cada sección solo cuando se visita y luego conserva su estado.
class _PantallasPerezosas extends StatefulWidget {
  const _PantallasPerezosas({required this.indice, required this.pantallas});

  final int indice;
  final List<Widget> pantallas;

  @override
  State<_PantallasPerezosas> createState() => _PantallasPerezosasState();
}

class _PantallasPerezosasState extends State<_PantallasPerezosas> {
  late final Set<int> _visitadas = {widget.indice};

  @override
  void didUpdateWidget(covariant _PantallasPerezosas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visitadas.add(widget.indice);
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: widget.indice,
    children: [
      for (var i = 0; i < widget.pantallas.length; i++)
        if (_visitadas.contains(i))
          widget.pantallas[i]
        else
          const SizedBox.shrink(),
    ],
  );
}

/// Cápsula deslizante sin blur, shaders ni filtros costosos.
class _BarraLigera extends StatelessWidget {
  const _BarraLigera({
    required this.indice,
    required this.mostrarMiLocal,
    required this.alSeleccionar,
  });

  final int indice;
  final bool mostrarMiLocal;
  final ValueChanged<int> alSeleccionar;

  List<(IconData, IconData, String)> get destinos => [
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Locales'),
    (Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Publicar'),
    if (mostrarMiLocal)
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Tu local'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Configuración'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final items = destinos;
          final anchoItem = restricciones.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                left: indice * anchoItem + 4,
                top: 5,
                width: anchoItem - 8,
                height: 64,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2EA),
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
    final color = activo ? const Color(0xFF739376) : const Color(0xFF7C7D7E);
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
