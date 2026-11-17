import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../diseno/campus_collapsing_header.dart';
import '../diseno/esqueleto_inicio_marketplace.dart';

/// Conserva la búsqueda y la navegación normales mientras cargan las tarjetas
/// de productos.
class PantallaEsqueletoInicioMarketplace extends StatelessWidget {
  const PantallaEsqueletoInicioMarketplace({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = SesionUsuario.instancia;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CampusFixedHeader(
              nombre: sesion.primerNombre,
              avatarUrl: sesion.perfil?.avatarUrl,
              categorias: const [],
              categoriaId: 'todas',
              alBuscar: (_) {},
              alSeleccionarCategoria: (_) {},
              alAbrirCarrito: () {},
              alAbrirPedidos: () {},
              mostrarCategorias: false,
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14, 16, 14, 24),
                child: EsqueletoInicioMarketplace(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BarraNavegacionNormal(),
    );
  }
}

class _BarraNavegacionNormal extends StatelessWidget {
  const _BarraNavegacionNormal();

  static const _destinos = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.storefront_outlined, Icons.storefront_rounded, 'Locales'),
    (Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Publicar'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: ConfiguracionTema.cremaSuperficie,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: const Color(0xFFBBBCA7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33474646),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _destinos.length; i++)
                Expanded(
                  child: Container(
                    height: 66,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? ConfiguracionTema.naranjaCoral
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == 0 ? _destinos[i].$2 : _destinos[i].$1,
                          size: 24,
                          color: i == 0 ? Colors.white : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _destinos[i].$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: i == 0
                                ? ConfiguracionTema.azulNoche
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
