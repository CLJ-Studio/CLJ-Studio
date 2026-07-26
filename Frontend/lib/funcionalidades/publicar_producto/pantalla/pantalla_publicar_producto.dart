import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../../mi_local/logica/controlador_mi_local.dart';
import '../diseno/formulario_publicacion.dart';
import '../logica/controlador_publicacion.dart';

/// Publicación de productos dentro del local del estudiante.
class PantallaPublicarProducto extends StatefulWidget {
  const PantallaPublicarProducto({
    required this.miLocal,
    required this.alCrearLocal,
    super.key,
  });

  final ControladorMiLocal miLocal;
  final VoidCallback alCrearLocal;

  @override
  State<PantallaPublicarProducto> createState() =>
      _PantallaPublicarProductoState();
}

class _PantallaPublicarProductoState extends State<PantallaPublicarProducto> {
  final controlador = ControladorPublicacion();

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.miLocal,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 120),
      child: ContenidoCentrado(
        anchoMaximo: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear publicación',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Text(
              'Comparte productos o servicios con la comunidad UPSA.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (widget.miLocal.cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            // Todo producto pertenece a un local: sin local no hay donde
            // publicarlo, asi que primero hay que abrir uno.
            else if (!widget.miLocal.tieneLocal)
              _SinLocal(alCrearLocal: widget.alCrearLocal)
            else ...[
              _AvisoDestino(nombreLocal: widget.miLocal.nombre!),
              const SizedBox(height: 18),
              FormularioPublicacion(
                controlador: controlador,
                miLocal: widget.miLocal,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Indica en qué local quedará la publicación.
class _AvisoDestino extends StatelessWidget {
  const _AvisoDestino({required this.nombreLocal});

  final String nombreLocal;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F2E8),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.storefront_rounded,
          size: 19,
          color: Color(0xFF5C8A63),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Se publicará en $nombreLocal',
            style: const TextStyle(
              color: Color(0xFF3F6146),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SinLocal extends StatelessWidget {
  const _SinLocal({required this.alCrearLocal});

  final VoidCallback alCrearLocal;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6F5),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 46,
          color: Color(0xFF8B928D),
        ),
        const SizedBox(height: 14),
        Text(
          'Primero abre tu local',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tus productos se publican dentro de tu local para que los '
          'estudiantes sepan a quién le compran.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7B817D), height: 1.4),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: alCrearLocal,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5C8A63),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Abrir mi local'),
        ),
      ],
    ),
  );
}
