import 'package:flutter/foundation.dart';

import '../datos/repositorio_pedidos.dart';
import '../modelos/pedido.dart';

/// Carga las compras y ventas del usuario.
class ControladorPedidos extends ChangeNotifier {
  ControladorPedidos(this._repositorio);

  final RepositorioPedidos _repositorio;

  List<Pedido> compras = const [];
  List<Pedido> ventas = const [];
  bool cargando = true;
  String? error;

  /// Ventas pendientes de responder: alimentan el distintivo de la pestaña,
  /// porque es la accion que no puede pasar desapercibida al vendedor.
  int get ventasPorResponder =>
      ventas.where((p) => p.estado == EstadoPedido.solicitado).length;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();

    try {
      // En paralelo: son dos consultas independientes.
      final resultados = await Future.wait([
        _repositorio.misCompras(),
        _repositorio.misVentas(),
      ]);
      compras = resultados[0];
      ventas = resultados[1];
    } catch (_) {
      error = 'No se pudieron cargar tus pedidos.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
