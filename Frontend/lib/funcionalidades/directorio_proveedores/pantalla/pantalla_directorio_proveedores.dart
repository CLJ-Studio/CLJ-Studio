import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../elementos_compartidos/estados_aplicacion/estado_vacio.dart';
import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../datos/repositorio_directorio.dart';
import '../diseno/tarjeta_proveedor.dart';
import '../modelos/proveedor_upsa.dart';

/// Los emprendimientos de estudiantes y egresados que se ofrecen a la UPSA.
///
/// Lo pidio la incubadora de empresas de la universidad: saber que
/// proveedores hay dentro de su propia comunidad. Solo lo abren las cuentas
/// de la UPSA y los admins; el servidor rechaza a cualquier otro.
class PantallaDirectorioProveedores extends StatefulWidget {
  const PantallaDirectorioProveedores({
    this.repositorio = const RepositorioDirectorio(),
    this.abrirLocal,
    this.abrirWhatsapp,
    super.key,
  });

  final RepositorioDirectorio repositorio;

  /// Para las pruebas. En la app, "Ver local" abre el detalle del local.
  final Future<void> Function(BuildContext contexto, String localId)?
  abrirLocal;

  /// Para las pruebas. En la app, abre el chat de WhatsApp.
  final Future<bool> Function(Uri enlace)? abrirWhatsapp;

  @override
  State<PantallaDirectorioProveedores> createState() =>
      _PantallaDirectorioProveedoresState();
}

/// Que proveedores se muestran: todos, solo un tipo o una categoria.
enum _Tipo { todos, egresados, estudiantes }

class _PantallaDirectorioProveedoresState
    extends State<PantallaDirectorioProveedores> {
  List<ProveedorUpsa>? _proveedores;
  bool _fallo = false;
  String _busqueda = '';
  _Tipo _tipo = _Tipo.todos;
  String? _categoriaId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _fallo = false);
    try {
      final proveedores = await widget.repositorio.cargar();
      if (mounted) setState(() => _proveedores = proveedores);
    } catch (_) {
      if (mounted) setState(() => _fallo = true);
    }
  }

  bool _pasa(ProveedorUpsa proveedor) {
    final tipo = switch (_tipo) {
      _Tipo.todos => true,
      _Tipo.egresados => proveedor.esEgresado,
      _Tipo.estudiantes => !proveedor.esEgresado,
    };
    return tipo &&
        (_categoriaId == null || proveedor.categoriaId == _categoriaId) &&
        proveedor.coincideCon(_busqueda);
  }

  /// Las categorias que de verdad hay, de la mas comun a la menos.
  List<(String, String)> _categorias(List<ProveedorUpsa> proveedores) {
    final cuantos = <String, int>{};
    final nombres = <String, String>{};
    for (final proveedor in proveedores) {
      cuantos.update(proveedor.categoriaId, (n) => n + 1, ifAbsent: () => 1);
      nombres[proveedor.categoriaId] = proveedor.categoria;
    }
    final ids = cuantos.keys.toList()
      ..sort((a, b) => cuantos[b]!.compareTo(cuantos[a]!));
    return [for (final id in ids) (id, nombres[id]!)];
  }

  void _avisar(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _contactar(ProveedorUpsa proveedor) async {
    final enlace = proveedor.enlaceWhatsapp;
    if (enlace == null) return;
    final abrir =
        widget.abrirWhatsapp ??
        (Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
    if (!await abrir(enlace) && mounted) _avisar('No se pudo abrir WhatsApp.');
  }

  Future<void> _verLocal(ProveedorUpsa proveedor) async {
    final abrir = widget.abrirLocal;
    if (abrir != null) return abrir(context, proveedor.localId);
    try {
      final local = await const RepositorioInicioMarketplace().obtenerLocal(
        proveedor.localId,
      );
      if (!mounted) return;
      if (local == null) {
        _avisar('Este local ya no está disponible.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleLocal(local: local),
        ),
      );
    } catch (_) {
      if (mounted) _avisar('No se pudo abrir el local.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Directorio de proveedores',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: _cuerpo(context),
  );

  Widget _cuerpo(BuildContext context) {
    if (_fallo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46),
              const SizedBox(height: 12),
              const Text(
                'No se pudo cargar el directorio.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final proveedores = _proveedores;
    if (proveedores == null) return const Center(child: IndicadorCarga());

    final visibles = proveedores.where(_pasa).toList(growable: false);
    final apagado = Theme.of(context).textTheme.bodyMedium?.color;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Text(
                'Emprendimientos de estudiantes y egresados de la UPSA que '
                'ofrecen sus productos y servicios a la universidad.',
                style: TextStyle(color: apagado, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (valor) => setState(() => _busqueda = valor),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar: catering, diseño, impresiones…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _Filtros(
                tipo: _tipo,
                categoriaId: _categoriaId,
                categorias: _categorias(proveedores),
                alElegirTipo: (tipo) => setState(() => _tipo = tipo),
                alElegirCategoria: (id) => setState(() => _categoriaId = id),
              ),
              const SizedBox(height: 14),
              if (proveedores.isEmpty)
                const _SinProveedores()
              else if (visibles.isEmpty)
                const EstadoVacio(
                  mensaje: 'Ningún proveedor coincide con tu búsqueda.',
                )
              else ...[
                Text(
                  visibles.length == 1
                      ? '1 emprendimiento'
                      : '${visibles.length} emprendimientos',
                  style: TextStyle(
                    color: apagado,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final proveedor in visibles) ...[
                  TarjetaProveedor(
                    proveedor: proveedor,
                    alContactar: proveedor.enlaceWhatsapp == null
                        ? null
                        : () => _contactar(proveedor),
                    alVerLocal: () => _verLocal(proveedor),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.tipo,
    required this.categoriaId,
    required this.categorias,
    required this.alElegirTipo,
    required this.alElegirCategoria,
  });

  final _Tipo tipo;
  final String? categoriaId;
  final List<(String, String)> categorias;
  final ValueChanged<_Tipo> alElegirTipo;
  final ValueChanged<String?> alElegirCategoria;

  @override
  Widget build(BuildContext context) {
    Widget chip(
      String texto, {
      required bool elegido,
      required VoidCallback alTocar,
    }) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: elegido,
        onSelected: (_) => alTocar(),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            'Todos',
            elegido: tipo == _Tipo.todos && categoriaId == null,
            alTocar: () {
              alElegirTipo(_Tipo.todos);
              alElegirCategoria(null);
            },
          ),
          chip(
            'Egresados',
            elegido: tipo == _Tipo.egresados,
            alTocar: () => alElegirTipo(
              tipo == _Tipo.egresados ? _Tipo.todos : _Tipo.egresados,
            ),
          ),
          chip(
            'Estudiantes',
            elegido: tipo == _Tipo.estudiantes,
            alTocar: () => alElegirTipo(
              tipo == _Tipo.estudiantes ? _Tipo.todos : _Tipo.estudiantes,
            ),
          ),
          for (final (id, nombre) in categorias)
            chip(
              nombre,
              elegido: categoriaId == id,
              alTocar: () => alElegirCategoria(categoriaId == id ? null : id),
            ),
        ],
      ),
    );
  }
}

/// Todavia nadie se ofrecio: que se entienda que no es un error.
class _SinProveedores extends StatelessWidget {
  const _SinProveedores();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
    child: Column(
      children: [
        const Icon(Icons.storefront_outlined, size: 48),
        const SizedBox(height: 12),
        Text(
          'Todavía no hay emprendimientos en el directorio. Aparecen aquí '
          'cuando su dueño activa "Aparecer en el directorio de la UPSA" en '
          'su local.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
