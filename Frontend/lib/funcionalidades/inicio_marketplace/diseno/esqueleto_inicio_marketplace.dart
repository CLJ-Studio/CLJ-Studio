import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/titulo_seccion.dart';
import '../../../elementos_compartidos/estados_aplicacion/esqueleto_carga.dart';
import '../../../elementos_compartidos/imagenes/foto_producto.dart';
import '../modelos/publicidad.dart';

/// Conserva la forma real del inicio mientras llegan productos y anuncios.
/// La búsqueda y la barra inferior se dibujan aparte y permanecen normales.
class EsqueletoInicioMarketplace extends StatelessWidget {
  const EsqueletoInicioMarketplace({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        aspectRatio: UbicacionPublicidad.bannerPrincipal.proporcion,
        child: const EsqueletoCarga(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
      const SizedBox(height: 18),
      const TituloSeccion('Los mejores del campus'),
      const SizedBox(height: 6),
      SizedBox(
        height: 238,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) =>
              const SizedBox(width: 224, child: _TarjetaLocalEsqueleto()),
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) =>
              const SizedBox(width: 270, child: _TarjetaPatrocinioEsqueleto()),
        ),
      ),
      const SizedBox(height: 26),
      const _EscaparatePromocionEsqueleto(),
      const SizedBox(height: 28),
      const TituloSeccion('Descubre algo nuevo'),
      const SizedBox(height: 10),
      const _CuadriculaProductosEsqueleto(),
    ],
  );
}

/// Mantiene las dimensiones del carrusel real de locales (224 × 238).
class _TarjetaLocalEsqueleto extends StatelessWidget {
  const _TarjetaLocalEsqueleto();

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 158,
          width: double.infinity,
          child: EsqueletoCarga(borderRadius: BorderRadius.zero),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 138,
                  height: 14,
                  child: EsqueletoCarga(
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const SizedBox(
                      width: 74,
                      height: 11,
                      child: EsqueletoCarga(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 36,
                      height: 11,
                      child: EsqueletoCarga(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Los anuncios de empresa usan una pieza apaisada de 270 × 104.
class _TarjetaPatrocinioEsqueleto extends StatelessWidget {
  const _TarjetaPatrocinioEsqueleto();

  @override
  Widget build(BuildContext context) => const Material(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(18)),
    clipBehavior: Clip.antiAlias,
    child: EsqueletoCarga(borderRadius: BorderRadius.zero),
  );
}

/// Copia el panel morado del escaparate popular y el tamaño de sus tarjetas.
class _EscaparatePromocionEsqueleto extends StatelessWidget {
  const _EscaparatePromocionEsqueleto();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 20, 0, 18),
    decoration: BoxDecoration(
      color: ConfiguracionTema.moradoPromocional,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(100),
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 22,
                      decoration: BoxDecoration(
                        color: ConfiguracionTema.crema,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(
                      width: 220,
                      height: 50,
                      child: EsqueletoCarga(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(
                width: 54,
                height: 26,
                child: EsqueletoCarga(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 164 / proporcionFotoProducto + 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => const SizedBox(
              width: 164,
              child: _TarjetaProductoEsqueleto(
                superficieSuave: false,
                mostrarAcciones: true,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// La tarjeta conserva la foto 4:3, la superficie, el texto y las acciones
/// que usa una publicación real. El alto del grid sigue la misma fórmula.
class _CuadriculaProductosEsqueleto extends StatelessWidget {
  const _CuadriculaProductosEsqueleto();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const separacion = 10.0;
      const anchoMinimo = 150.0;
      final columnas =
          ((constraints.maxWidth + separacion) / (anchoMinimo + separacion))
              .floor()
              .clamp(1, 5);
      final anchoTarjeta =
          (constraints.maxWidth - separacion * (columnas - 1)) / columnas;
      final escala = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
      final altoTexto = 90 * escala;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: columnas * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnas,
          crossAxisSpacing: separacion,
          mainAxisSpacing: separacion,
          childAspectRatio:
              anchoTarjeta /
              (anchoTarjeta / proporcionFotoProducto + altoTexto),
        ),
        itemBuilder: (_, _) => const _TarjetaProductoEsqueleto(
          superficieSuave: true,
          mostrarAcciones: false,
        ),
      );
    },
  );
}

class _TarjetaProductoEsqueleto extends StatelessWidget {
  const _TarjetaProductoEsqueleto({
    required this.superficieSuave,
    required this.mostrarAcciones,
  });

  final bool superficieSuave;
  final bool mostrarAcciones;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).brightness == Brightness.dark
        ? ConfiguracionTema.grafito
        : superficieSuave
        ? const Color(0xFFF5F4F0)
        : Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AspectRatio(
          aspectRatio: proporcionFotoProducto,
          child: EsqueletoCarga(borderRadius: BorderRadius.zero),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 118,
                  height: 13,
                  child: EsqueletoCarga(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 74,
                  height: 12,
                  child: EsqueletoCarga(borderRadius: BorderRadius.circular(6)),
                ),
                if (mostrarAcciones) ...[
                  const SizedBox(height: 3),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: EsqueletoCarga(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                          ),
                        ),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: EsqueletoCarga(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
