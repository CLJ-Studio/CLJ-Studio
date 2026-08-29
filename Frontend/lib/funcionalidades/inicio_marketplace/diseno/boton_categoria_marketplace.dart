import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../modelos/categoria_marketplace.dart';

/// Botón que hace evidente la categoría actualmente seleccionada.
class BotonCategoriaMarketplace extends StatelessWidget {
  const BotonCategoriaMarketplace({
    required this.categoria,
    required this.seleccionado,
    required this.alPresionar,
    this.compactProgress = 0,
    super.key,
  });
  final CategoriaMarketplace categoria;
  final bool seleccionado;
  final VoidCallback alPresionar;
  final double compactProgress;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esOscuro = tema.brightness == Brightness.dark;
    final tamanio = 48 - (6 * compactProgress);
    final verde = const Color(0xFF474646);

    return Semantics(
      button: true,
      selected: seleccionado,
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: tamanio,
                height: tamanio,
                decoration: BoxDecoration(
                  color: seleccionado
                      ? verde
                      : esOscuro
                      ? tema.colorScheme.surfaceContainerHighest
                      : ConfiguracionTema.cremaSuperficie,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seleccionado
                        ? verde
                        : esOscuro
                        ? const Color(0xFF474646)
                        : ConfiguracionTema.cremaSuperficie,
                  ),
                  boxShadow: seleccionado
                      ? const [
                          BoxShadow(
                            color: Color(0x30474646),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ]
                      : esOscuro
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x12474646),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                ),
                child: Icon(
                  categoria.icono,
                  size: 22,
                  color: seleccionado
                      ? Color(0xFFE6E1D5)
                      : esOscuro
                      ? Color(0xFFE6E1D5)
                      : const Color(0xFF474646),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                categoria.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
                  color: esOscuro ? Color(0xFFE6E1D5) : const Color(0xFF474646),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
