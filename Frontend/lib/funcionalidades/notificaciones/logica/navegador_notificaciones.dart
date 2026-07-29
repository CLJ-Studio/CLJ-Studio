import 'package:flutter/material.dart';

import '../../inicio_marketplace/datos/repositorio_inicio_marketplace.dart';
import '../../inicio_marketplace/modelos/local_universitario.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_local.dart';
import '../../locales_universitarios/pantalla/pantalla_detalle_producto.dart';
import '../../pedidos/pantalla/pantalla_detalle_pedido.dart';

/// Resuelve a dónde lleva un aviso y navega hasta ahí.
///
/// Los dos caminos que puede tomar una notificación terminan aquí: tocarla
/// dentro de la lista in-app, o abrirla desde el aviso del sistema
/// operativo (que llega como parámetros en la URL al arrancar de nuevo).
/// Antes cada camino resolvía el local o la publicación por su cuenta y
/// solo el de la lista llegaba a completarse.
abstract final class NavegadorNotificaciones {
  static Future<void> abrir(
    BuildContext context, {
    String? pedidoId,
    String? localId,
    String? productoId,
  }) async {
    if (pedidoId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetallePedido(pedidoId: pedidoId),
        ),
      );
      return;
    }

    // El local y la publicacion viajan como referencia, asi que hay que
    // resolverlos antes de poder abrirlos.
    const repositorio = RepositorioInicioMarketplace();

    if (productoId != null) {
      final publicacion = await repositorio.obtenerPublicacion(productoId);
      if (!context.mounted) return;
      if (publicacion?.local case final LocalUniversitario local) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PantallaDetalleProducto(producto: publicacion!, local: local),
          ),
        );
      } else {
        _avisarNoDisponible(context);
      }
      return;
    }

    if (localId != null) {
      final local = await repositorio.obtenerLocal(localId);
      if (!context.mounted) return;
      if (local == null) {
        _avisarNoDisponible(context);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PantallaDetalleLocal(local: local),
        ),
      );
    }
  }

  /// Lo que anunciaba el aviso pudo borrarse o cerrarse desde que llegó.
  static void _avisarNoDisponible(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esto ya no está disponible.')),
    );
  }
}
