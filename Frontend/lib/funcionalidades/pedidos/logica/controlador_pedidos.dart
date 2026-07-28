import 'package:flutter/foundation.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
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

  /// Un pedido nuevo o una respuesta del vendedor deben aparecer sin que
  /// nadie recargue: es la pantalla donde mas se nota la espera.
  late final _escucha = EscuchaTabla(
    tabla: 'orders',
    alCambiar: _recargarEnSilencio,
  );

  void iniciarTiempoReal() {
    if (!ModoLocal.activo) _escucha.iniciar();
  }

  @override
  void dispose() {
    _escucha.detener();
    super.dispose();
  }

  /// Cancela y refresca. Devuelve el motivo si el servidor lo rechaza.
  Future<String?> cancelar(String pedidoId) async {
    if (ModoLocal.activo) {
      compras = compras.where((pedido) => pedido.id != pedidoId).toList();
      notifyListeners();
      return null;
    }
    try {
      await _repositorio.cancelar(pedidoId);
      await _recargarEnSilencio();
      return null;
    } catch (fallo) {
      // El vendedor pudo aceptarlo justo antes: no es un error de la app.
      return fallo.toString().contains('ESTADO_INVALIDO')
          ? 'El pedido ya cambió de estado.'
          : 'No se pudo cancelar el pedido.';
    }
  }

  /// Refresca sin el indicador de carga, para no parpadear la lista.
  Future<void> _recargarEnSilencio() async {
    if (ModoLocal.activo) return;
    try {
      final resultados = await Future.wait([
        _repositorio.misCompras(),
        _repositorio.misVentas(),
      ]);
      compras = resultados[0];
      ventas = resultados[1];
      notifyListeners();
    } catch (_) {
      // Se reintenta en el siguiente evento o sondeo.
    }
  }

  Future<void> cargar() async {
    if (ModoLocal.activo) {
      compras = const [];
      ventas = const [];
      cargando = false;
      error = null;
      notifyListeners();
      return;
    }
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
