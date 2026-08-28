import 'package:flutter/material.dart';

import '../../../elementos_compartidos/estados_aplicacion/indicador_carga.dart';
import '../../../elementos_compartidos/estructuras_aplicacion/contenido_centrado.dart';
import '../datos/repositorio_finanzas_local.dart';
import '../modelos/resumen_finanzas.dart';

class PantallaFinanzasLocal extends StatefulWidget {
  const PantallaFinanzasLocal({required this.localId, super.key});

  final String localId;

  @override
  State<PantallaFinanzasLocal> createState() => _PantallaFinanzasLocalState();
}

class _PantallaFinanzasLocalState extends State<PantallaFinanzasLocal> {
  static const _repositorio = RepositorioFinanzasLocal();
  late Future<ResumenFinanzas> _resumen = _cargar();

  Future<ResumenFinanzas> _cargar() => _repositorio.cargar(widget.localId);

  Future<void> _actualizar() async {
    final nueva = _cargar();
    setState(() => _resumen = nueva);
    await nueva;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F5F2),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF3F5F2),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Mis finanzas',
        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -.5),
      ),
    ),
    body: FutureBuilder<ResumenFinanzas>(
      future: _resumen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: IndicadorCarga());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ErrorFinanzas(alReintentar: _actualizar);
        }
        return RefreshIndicator.adaptive(
          onRefresh: _actualizar,
          color: const Color(0xFF138A5B),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              ContenidoCentrado(
                anchoMaximo: 760,
                child: _ContenidoFinanzas(resumen: snapshot.data!),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ContenidoFinanzas extends StatelessWidget {
  const _ContenidoFinanzas({required this.resumen});

  final ResumenFinanzas resumen;

  String _dinero(double valor) => 'Bs ${valor.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _TarjetaBalance(resumen: resumen),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _MetricaCompacta(
              icono: Icons.today_rounded,
              etiqueta: 'Ventas de hoy',
              valor: _dinero(resumen.ingresosHoy),
              color: const Color(0xFF138A5B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricaCompacta(
              icono: Icons.receipt_long_rounded,
              etiqueta: 'Completados',
              valor: '${resumen.pedidosCompletados}',
              color: const Color(0xFF3F79A8),
            ),
          ),
        ],
      ),
      const SizedBox(height: 26),
      const _TituloSeccion(
        titulo: 'Últimos 7 días',
        subtitulo: 'Ingresos por ventas completadas',
      ),
      const SizedBox(height: 12),
      _GraficoSemanal(datos: resumen.ventasSemana),
      const SizedBox(height: 26),
      const _TituloSeccion(
        titulo: 'Lo que mejor funciona',
        subtitulo: 'Productos y momentos destacados',
      ),
      const SizedBox(height: 12),
      _TarjetaProducto(
        emoji: resumen.emojiProductoMasVendido,
        etiqueta: 'Más vendido',
        nombre: resumen.nombreProductoMasVendido,
        detalle: '${resumen.unidadesProductoMasVendido} unidades',
        color: const Color(0xFF138A5B),
      ),
      const SizedBox(height: 10),
      _TarjetaProducto(
        emoji: resumen.emojiProductoMasVisto,
        etiqueta: 'Más visto',
        nombre: resumen.nombreProductoMasVisto,
        detalle: '${resumen.vistasProductoMasVisto} vistas',
        color: const Color(0xFF6B70B5),
      ),
      const SizedBox(height: 12),
      _CuadriculaRendimiento(resumen: resumen),
      const SizedBox(height: 26),
      const _TituloSeccion(
        titulo: 'Visibilidad',
        subtitulo: 'Cómo están descubriendo tu local',
      ),
      const SizedBox(height: 12),
      _TarjetaVisitas(resumen: resumen),
    ],
  );
}

class _TarjetaBalance extends StatelessWidget {
  const _TarjetaBalance({required this.resumen});

  final ResumenFinanzas resumen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF183D2B), Color(0xFF3F7550)],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x333F7550),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned(
          right: -28,
          top: -42,
          child: _CirculoDecorativo(tamanio: 126, color: Color(0x225FD081)),
        ),
        const Positioned(
          right: 30,
          bottom: -46,
          child: _CirculoDecorativo(tamanio: 92, color: Color(0x22FFFFFF)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'INGRESOS TOTALES',
                    style: TextStyle(
                      color: Color(0xBFFFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Bs ${resumen.ingresosTotales.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ventas entregadas · ${resumen.pedidosCompletados} pedidos',
              style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 12.5),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CirculoDecorativo extends StatelessWidget {
  const _CirculoDecorativo({required this.tamanio, required this.color});
  final double tamanio;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: tamanio,
    height: tamanio,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _MetricaCompacta extends StatelessWidget {
  const _MetricaCompacta({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x0D000000)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: color, size: 23),
        const SizedBox(height: 14),
        Text(
          valor,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const SizedBox(height: 3),
        Text(
          etiqueta,
          style: const TextStyle(color: Color(0xFF7A817C), fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.titulo, required this.subtitulo});
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titulo,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitulo,
        style: const TextStyle(color: Color(0xFF858B87), fontSize: 12.5),
      ),
    ],
  );
}

class _GraficoSemanal extends StatelessWidget {
  const _GraficoSemanal({required this.datos});
  final List<PuntoVentaDiaria> datos;

  static const _dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final maximo = datos.fold<double>(
      0,
      (m, d) => d.ingresos > m ? d.ingresos : m,
    );
    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: datos.isEmpty
          ? const Center(child: Text('Aún no hay ventas para mostrar'))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final punto in datos)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (punto.ingresos > 0)
                            Text(
                              punto.ingresos.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Color(0xFF138A5B),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const SizedBox(height: 5),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: maximo == 0
                                ? 8
                                : 112 * (punto.ingresos / maximo).clamp(.07, 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF138A5B), Color(0xFF9AB9A0)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            _dias[punto.fecha.weekday - 1],
                            style: const TextStyle(
                              color: Color(0xFF727975),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  const _TarjetaProducto({
    required this.emoji,
    required this.etiqueta,
    required this.nombre,
    required this.detalle,
    required this.color,
  });
  final String emoji;
  final String etiqueta;
  final String nombre;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 25)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          detalle,
          style: const TextStyle(
            color: Color(0xFF6F7671),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CuadriculaRendimiento extends StatelessWidget {
  const _CuadriculaRendimiento({required this.resumen});
  final ResumenFinanzas resumen;

  String _fecha(DateTime? fecha) => fecha == null
      ? 'Sin datos'
      : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}';

  String _mes(String? valor) {
    if (valor == null) return 'Sin datos';
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final partes = valor.split('-');
    final numero = int.tryParse(partes.last) ?? 0;
    return numero > 0 && numero <= 12 ? meses[numero - 1] : valor;
  }

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.42,
    children: [
      _DatoRendimiento(
        icono: Icons.calendar_month_rounded,
        etiqueta: 'Mejor día',
        valor: _fecha(resumen.mejorDia),
        detalle: 'Bs ${resumen.ingresosMejorDia.toStringAsFixed(0)}',
      ),
      _DatoRendimiento(
        icono: Icons.schedule_rounded,
        etiqueta: 'Mejor hora',
        valor: resumen.mejorHora == null
            ? 'Sin datos'
            : '${resumen.mejorHora.toString().padLeft(2, '0')}:00',
        detalle: 'Mayor ingreso',
      ),
      _DatoRendimiento(
        icono: Icons.date_range_rounded,
        etiqueta: 'Mejor mes',
        valor: _mes(resumen.mejorMes),
        detalle: 'Récord mensual',
      ),
      _DatoRendimiento(
        icono: Icons.south_east_rounded,
        etiqueta: 'Día más bajo',
        valor: _fecha(resumen.diaMasBajo),
        detalle: 'Bs ${resumen.ingresosDiaMasBajo.toStringAsFixed(0)}',
      ),
    ],
  );
}

class _DatoRendimiento extends StatelessWidget {
  const _DatoRendimiento({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.detalle,
  });
  final IconData icono;
  final String etiqueta;
  final String valor;
  final String detalle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icono, color: const Color(0xFF138A5B), size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                etiqueta,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF777E79),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text(
          detalle,
          style: const TextStyle(color: Color(0xFF929793), fontSize: 10),
        ),
      ],
    ),
  );
}

class _TarjetaVisitas extends StatelessWidget {
  const _TarjetaVisitas({required this.resumen});
  final ResumenFinanzas resumen;

  @override
  Widget build(BuildContext context) {
    final fecha = resumen.diaMasVisitas;
    final fechaTexto = fecha == null
        ? 'Todavía sin historial diario'
        : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} · ${resumen.visitasMejorDia} visitas';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF202E3B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0x223FA8D0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility_rounded,
              color: Color(0xFF78C3DF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${resumen.visitasTotales} visitas totales',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mejor día: $fechaTexto',
                  style: const TextStyle(
                    color: Color(0xAFFFFFFF),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorFinanzas extends StatelessWidget {
  const _ErrorFinanzas({required this.alReintentar});
  final Future<void> Function() alReintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.query_stats_rounded,
            size: 48,
            color: Color(0xFF138A5B),
          ),
          const SizedBox(height: 14),
          const Text('No pudimos cargar tus finanzas.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: alReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
