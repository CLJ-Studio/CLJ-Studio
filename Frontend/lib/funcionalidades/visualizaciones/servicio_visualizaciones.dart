import 'package:supabase_flutter/supabase_flutter.dart';

import '../../configuracion_aplicacion/modo_local.dart';

abstract final class ServicioVisualizaciones {
  static Future<int> registrarProducto(String productoId) async {
    if (ModoLocal.activo) return 0;
    final total = await Supabase.instance.client.rpc<int>(
      'registrar_vista_producto',
      params: {'p_producto': productoId},
    );
    return total;
  }

  static Future<int> registrarLocal(String localId) async {
    if (ModoLocal.activo) return 0;
    final total = await Supabase.instance.client.rpc<int>(
      'registrar_vista_local',
      params: {'p_local': localId},
    );
    return total;
  }
}
