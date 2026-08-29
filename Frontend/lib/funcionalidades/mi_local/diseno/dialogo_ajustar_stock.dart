import 'package:flutter/material.dart';

import '../../inicio_marketplace/modelos/producto_marketplace.dart';
import '../datos/repositorio_mi_local.dart';

/// Ajusta cuántas unidades quedan, y nada más.
///
/// Existe porque lo que más se hace no es editar una publicación: es corregir
/// el stock después de vender en persona. Para eso había que abrir el diálogo
/// completo —nombre, precio, descripción, fotos— y arriesgarse a tocar algo
/// sin querer, solo para bajar un número.
///
/// Los botones de más y menos van primero porque el caso normal es "vendí una
/// y me queda una menos". Escribir la cantidad exacta queda para cuando se
/// vendieron cinco de golpe.
Future<bool> mostrarDialogoAjustarStock(
  BuildContext context,
  ProductoMarketplace producto,
) async {
  final cambiado = await showDialog<bool>(
    context: context,
    builder: (_) => _DialogoAjustarStock(producto: producto),
  );
  return cambiado ?? false;
}

class _DialogoAjustarStock extends StatefulWidget {
  const _DialogoAjustarStock({required this.producto});

  final ProductoMarketplace producto;

  @override
  State<_DialogoAjustarStock> createState() => _DialogoAjustarStockState();
}

class _DialogoAjustarStockState extends State<_DialogoAjustarStock> {
  static const _repositorio = RepositorioMiLocal();

  late int _cantidad = widget.producto.stock;
  late final _campo = TextEditingController(text: '$_cantidad');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  /// Nunca baja de cero: la base tiene un `check` que lo rechazaría, y es
  /// mejor que el botón simplemente no responda a que salte un error.
  void _mover(int delta) {
    final nueva = (_cantidad + delta).clamp(0, 9999);
    setState(() {
      _cantidad = nueva;
      _campo.text = '$nueva';
    });
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _repositorio.cambiarStock(widget.producto.id, _cantidad);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo guardar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinCambios = _cantidad == widget.producto.stock;

    return AlertDialog(
      title: const Text('Unidades disponibles'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.producto.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BotonPaso(
                icono: Icons.remove_rounded,
                alPresionar: _guardando || _cantidad == 0
                    ? null
                    : () => _mover(-1),
              ),
              Expanded(
                child: TextField(
                  controller: _campo,
                  enabled: !_guardando,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (valor) {
                    final leido = int.tryParse(valor);
                    if (leido != null) {
                      setState(() => _cantidad = leido.clamp(0, 9999));
                    }
                  },
                ),
              ),
              _BotonPaso(
                icono: Icons.add_rounded,
                alPresionar: _guardando ? null : () => _mover(1),
              ),
            ],
          ),
          if (_cantidad == 0) ...[
            const SizedBox(height: 10),
            const Text(
              'En cero deja de poder pedirse, pero la publicación sigue '
              'visible.',
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFAE7960), fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando || sinCambios ? null : _guardar,
          child: Text(_guardando ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}

class _BotonPaso extends StatelessWidget {
  const _BotonPaso({required this.icono, required this.alPresionar});

  final IconData icono;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: alPresionar,
    icon: Icon(icono),
    iconSize: 26,
  );
}
