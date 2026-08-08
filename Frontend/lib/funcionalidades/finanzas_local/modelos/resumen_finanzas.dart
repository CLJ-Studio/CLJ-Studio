class PuntoVentaDiaria {
  const PuntoVentaDiaria({required this.fecha, required this.ingresos});

  factory PuntoVentaDiaria.desdeMapa(Map<String, dynamic> mapa) =>
      PuntoVentaDiaria(
        fecha: DateTime.parse(mapa['fecha'] as String),
        ingresos: (mapa['ingresos'] as num?)?.toDouble() ?? 0,
      );

  final DateTime fecha;
  final double ingresos;
}

class ResumenFinanzas {
  const ResumenFinanzas({
    required this.ingresosTotales,
    required this.ingresosHoy,
    required this.pedidosCompletados,
    required this.visitasTotales,
    required this.nombreProductoMasVendido,
    required this.emojiProductoMasVendido,
    required this.unidadesProductoMasVendido,
    required this.nombreProductoMasVisto,
    required this.emojiProductoMasVisto,
    required this.vistasProductoMasVisto,
    required this.mejorDia,
    required this.ingresosMejorDia,
    required this.diaMasBajo,
    required this.ingresosDiaMasBajo,
    required this.mejorHora,
    required this.mejorMes,
    required this.diaMasVisitas,
    required this.visitasMejorDia,
    required this.ventasSemana,
  });

  factory ResumenFinanzas.desdeMapa(Map<String, dynamic> mapa) {
    Map<String, dynamic> objeto(String llave) =>
        (mapa[llave] as Map?)?.cast<String, dynamic>() ?? const {};

    final vendido = objeto('producto_mas_vendido');
    final visto = objeto('producto_mas_visto');
    final mejorDia = objeto('mejor_dia');
    final diaBajo = objeto('dia_mas_bajo');
    final hora = objeto('mejor_hora');
    final mes = objeto('mejor_mes');
    final visitas = objeto('dia_mas_visitas');

    return ResumenFinanzas(
      ingresosTotales: (mapa['ingresos_totales'] as num?)?.toDouble() ?? 0,
      ingresosHoy: (mapa['ingresos_hoy'] as num?)?.toDouble() ?? 0,
      pedidosCompletados: (mapa['pedidos_completados'] as num?)?.toInt() ?? 0,
      visitasTotales: (mapa['visitas_totales'] as num?)?.toInt() ?? 0,
      nombreProductoMasVendido:
          (vendido['nombre'] as String?) ?? 'Sin ventas todavía',
      emojiProductoMasVendido: (vendido['emoji'] as String?) ?? '🛍️',
      unidadesProductoMasVendido: (vendido['unidades'] as num?)?.toInt() ?? 0,
      nombreProductoMasVisto:
          (visto['nombre'] as String?) ?? 'Sin publicaciones',
      emojiProductoMasVisto: (visto['emoji'] as String?) ?? '👀',
      vistasProductoMasVisto: (visto['vistas'] as num?)?.toInt() ?? 0,
      mejorDia: DateTime.tryParse((mejorDia['fecha'] as String?) ?? ''),
      ingresosMejorDia: (mejorDia['ingresos'] as num?)?.toDouble() ?? 0,
      diaMasBajo: DateTime.tryParse((diaBajo['fecha'] as String?) ?? ''),
      ingresosDiaMasBajo: (diaBajo['ingresos'] as num?)?.toDouble() ?? 0,
      mejorHora: (hora['hora'] as num?)?.toInt(),
      mejorMes: mes['mes'] as String?,
      diaMasVisitas: DateTime.tryParse((visitas['fecha'] as String?) ?? ''),
      visitasMejorDia: (visitas['vistas'] as num?)?.toInt() ?? 0,
      ventasSemana: ((mapa['ventas_semana'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PuntoVentaDiaria.desdeMapa)
          .toList(),
    );
  }

  final double ingresosTotales;
  final double ingresosHoy;
  final int pedidosCompletados;
  final int visitasTotales;
  final String nombreProductoMasVendido;
  final String emojiProductoMasVendido;
  final int unidadesProductoMasVendido;
  final String nombreProductoMasVisto;
  final String emojiProductoMasVisto;
  final int vistasProductoMasVisto;
  final DateTime? mejorDia;
  final double ingresosMejorDia;
  final DateTime? diaMasBajo;
  final double ingresosDiaMasBajo;
  final int? mejorHora;
  final String? mejorMes;
  final DateTime? diaMasVisitas;
  final int visitasMejorDia;
  final List<PuntoVentaDiaria> ventasSemana;
}
