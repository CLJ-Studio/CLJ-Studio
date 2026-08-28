import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import '../datos/repositorio_chat_pedido.dart';
import '../datos/repositorio_pedidos.dart';
import '../modelos/pedido.dart';

/// Carga las compras y ventas del usuario.
class ControladorPedidos extends ChangeNotifier {
  ControladorPedidos(this._repositorio);

  final RepositorioPedidos _repositorio;

  static const _chat = RepositorioChatPedido();

  List<Pedido> compras = const [];
  List<Pedido> ventas = const [];

  /// Mensajes sin leer por pedido. Alimenta el distintivo de cada tarjeta.
  Map<String, int> sinLeer = const {};

  int mensajesSinLeerDe(String pedidoId) => sinLeer[pedidoId] ?? 0;
  bool cargando = true;
  String? error;

  /// Ventas pendientes de responder: alimentan el distintivo de la pestaña,
  /// porque es la accion que no puede pasar desapercibida al vendedor.
  ///
  /// Cuentan tambien las entregas que el comprador dio por hechas y esperan
  /// la palabra del vendedor: es igual de suya que aceptar el pedido.
  int get ventasPorResponder => ventas
      .where(
        (p) =>
            p.estado == EstadoPedido.solicitado ||
            p.meTocaConfirmar(_miId()) ||
            mensajesSinLeerDe(p.id) > 0,
      )
      .length;

  /// Compras esperando que yo confirme que recibi.
  ///
  /// Este es el recordatorio que pidio el usuario: vive en la pantalla, no en
  /// una notificacion repetida.
  int get comprasPorConfirmar => compras
      .where((p) => p.meTocaConfirmar(_miId()) || mensajesSinLeerDe(p.id) > 0)
      .length;

  /// Se lee cada vez y no se cachea: el controlador sobrevive al cambio de
  /// sesion y un id guardado dejaria contando lo de la cuenta anterior.
  String? _miId() =>
      ModoLocal.activo ? null : Supabase.instance.client.auth.currentUser?.id;

  /// Un pedido nuevo o una respuesta del vendedor deben aparecer sin que
  /// nadie recargue: es la pantalla donde mas se nota la espera.
  late final _escucha = EscuchaTabla(
    tabla: 'orders',
    alCambiar: _recargarEnSilencio,
  );

  /// Un mensaje nuevo tiene que encender el distintivo sin que nadie recargue.
  late final _escuchaMensajes = EscuchaTabla(
    tabla: 'mensajes_pedido',
    alCambiar: _recargarEnSilencio,
  );

  void iniciarTiempoReal() {
    if (ModoLocal.activo) return;
    _escucha.iniciar();
    _escuchaMensajes.iniciar();
  }

  @override
  void dispose() {
    _escucha.detener();
    _escuchaMensajes.detener();
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
      final (nuevasCompras, nuevasVentas, nuevosSinLeer) = await (
        _repositorio.misCompras(),
        _repositorio.misVentas(),
        _chat.sinLeerPorPedido(),
      ).wait;
      compras = nuevasCompras;
      ventas = nuevasVentas;
      sinLeer = nuevosSinLeer;
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
      // En paralelo: son consultas independientes entre si.
      final (nuevasCompras, nuevasVentas, nuevosSinLeer) = await (
        _repositorio.misCompras(),
        _repositorio.misVentas(),
        _chat.sinLeerPorPedido(),
      ).wait;
      compras = nuevasCompras;
      ventas = nuevasVentas;
      sinLeer = nuevosSinLeer;
    } catch (_) {
      error = 'No se pudieron cargar tus pedidos.';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
