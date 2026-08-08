import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../configuracion_aplicacion/modo_local.dart';
import '../modelos/resumen_finanzas.dart';

class RepositorioFinanzasLocal {
  const RepositorioFinanzasLocal();

  Future<ResumenFinanzas> cargar(String localId) async {
    if (ModoLocal.activo) return ResumenFinanzas.desdeMapa(const {});

    try {
      final respuesta = await Supabase.instance.client
          .rpc<Map<String, dynamic>>(
            'resumen_finanzas_local',
            params: {'p_local': localId},
          );
      return ResumenFinanzas.desdeMapa(respuesta);
    } catch (_) {
      // Compatibilidad inmediata mientras la migracion de analitica llega al
      // servidor: usa las vistas que la app ya tiene disponibles.
      return _cargarSinFuncion(localId);
    }
  }

  Future<ResumenFinanzas> _cargarSinFuncion(String localId) async {
    final cliente = Supabase.instance.client;
    final resultados = await Future.wait<dynamic>([
      cliente
          .from('pedidos_detallados')
          .select()
          .eq('store_id', localId)
          .eq('status', 'entregado'),
      cliente
          .from('products')
          .select('name, emoji, view_count')
          .eq('store_id', localId),
      cliente.from('stores').select('view_count').eq('id', localId).single(),
    ]);

    final pedidos = (resultados[0] as List).cast<Map<String, dynamic>>();
    final productos = (resultados[1] as List).cast<Map<String, dynamic>>();
    final local = (resultados[2] as Map).cast<String, dynamic>();
    final ahora = DateTime.now();

    final ingresosPorDia = <String, double>{};
    final ingresosPorHora = <int, double>{};
    final ingresosPorMes = <String, double>{};
    final unidades = <String, int>{};
    final emojis = <String, String>{};
    var total = 0.0;
    var hoy = 0.0;

    for (final pedido in pedidos) {
      final fecha = DateTime.parse(pedido['created_at'] as String).toLocal();
      final importe = (pedido['total'] as num?)?.toDouble() ?? 0;
      final llaveDia = _fecha(fecha);
      final llaveMes =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      total += importe;
      if (_mismoDia(fecha, ahora)) hoy += importe;
      ingresosPorDia[llaveDia] = (ingresosPorDia[llaveDia] ?? 0) + importe;
      ingresosPorHora[fecha.hour] =
          (ingresosPorHora[fecha.hour] ?? 0) + importe;
      ingresosPorMes[llaveMes] = (ingresosPorMes[llaveMes] ?? 0) + importe;

      for (final item in ((pedido['items'] as List?) ?? const [])) {
        final fila = (item as Map).cast<String, dynamic>();
        final nombre = (fila['product_name'] as String?) ?? 'Producto';
        unidades[nombre] =
            (unidades[nombre] ?? 0) +
            ((fila['quantity'] as num?)?.toInt() ?? 0);
        emojis[nombre] = (fila['product_emoji'] as String?) ?? '🛍️';
      }
    }

    MapEntry<String, double>? extremo(
      Map<String, double> datos, {
      required bool mayor,
    }) {
      if (datos.isEmpty) return null;
      return datos.entries.reduce(
        (a, b) =>
            mayor ? (a.value >= b.value ? a : b) : (a.value <= b.value ? a : b),
      );
    }

    final mejorDia = extremo(ingresosPorDia, mayor: true);
    final diaBajo = extremo(ingresosPorDia, mayor: false);
    final mejorMes = extremo(ingresosPorMes, mayor: true);
    final mejorHora = ingresosPorHora.isEmpty
        ? null
        : ingresosPorHora.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final masVendido = unidades.isEmpty
        ? null
        : unidades.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final masVisto = productos.isEmpty
        ? null
        : productos.reduce(
            (a, b) =>
                ((a['view_count'] as num?)?.toInt() ?? 0) >=
                    ((b['view_count'] as num?)?.toInt() ?? 0)
                ? a
                : b,
          );

    final semana = [
      for (var diasAtras = 6; diasAtras >= 0; diasAtras--)
        DateTime(ahora.year, ahora.month, ahora.day - diasAtras),
    ];

    return ResumenFinanzas.desdeMapa({
      'ingresos_totales': total,
      'ingresos_hoy': hoy,
      'pedidos_completados': pedidos.length,
      'visitas_totales': (local['view_count'] as num?)?.toInt() ?? 0,
      'producto_mas_vendido': masVendido == null
          ? null
          : {
              'nombre': masVendido.key,
              'emoji': emojis[masVendido.key],
              'unidades': masVendido.value,
            },
      'producto_mas_visto': masVisto == null
          ? null
          : {
              'nombre': masVisto['name'],
              'emoji': masVisto['emoji'],
              'vistas': masVisto['view_count'],
            },
      'mejor_dia': mejorDia == null
          ? null
          : {'fecha': mejorDia.key, 'ingresos': mejorDia.value},
      'dia_mas_bajo': diaBajo == null
          ? null
          : {'fecha': diaBajo.key, 'ingresos': diaBajo.value},
      'mejor_hora': mejorHora == null
          ? null
          : {'hora': mejorHora.key, 'ingresos': mejorHora.value},
      'mejor_mes': mejorMes == null
          ? null
          : {'mes': mejorMes.key, 'ingresos': mejorMes.value},
      // El desglose diario de visitas solo existe con la nueva funcion RPC.
      'dia_mas_visitas': null,
      'ventas_semana': [
        for (final dia in semana)
          {'fecha': _fecha(dia), 'ingresos': ingresosPorDia[_fecha(dia)] ?? 0},
      ],
    });
  }

  String _fecha(DateTime fecha) =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
