import '../../inicio_marketplace/modelos/producto_marketplace.dart';

/// Hasta cuándo se ve una publicación en el catálogo.
///
/// Se guarda como `products.expires_at`: nulo es "sin fecha" (en una
/// publicación personal, "hasta que se venda": cuando se entrega la última
/// unidad sale sola). Al vencer, el servidor la saca del catálogo en menos de
/// un minuto y avisa a quien la publicó.
sealed class VigenciaPublicacion {
  const VigenciaPublicacion();

  /// Lo que viene marcado al publicar.
  static const inicial = SinFecha();

  /// La de una publicación que ya existe: nula es sin fecha y, si tiene una,
  /// se conserva tal cual. Editar el nombre no puede moverle la hora.
  static VigenciaPublicacion desde(DateTime? venceEn) =>
      venceEn == null ? const SinFecha() : HastaInstante(venceEn.toLocal());

  /// El instante en que vence, contado desde [ahora]. Null: no vence.
  DateTime? venceEn(DateTime ahora);

  /// Lo que se lee en el selector.
  String etiqueta({required bool esPersonal, required DateTime ahora});

  /// La explicación de abajo: qué va a pasar con la publicación.
  String explicacion({required bool esPersonal, required DateTime ahora});
}

/// Sin fecha: se ve hasta que la retiren. En una personal, hasta que se venda.
final class SinFecha extends VigenciaPublicacion {
  const SinFecha();

  @override
  DateTime? venceEn(DateTime ahora) => null;

  @override
  String etiqueta({required bool esPersonal, required DateTime ahora}) =>
      esPersonal ? 'Hasta que se venda' : 'Sin fecha';

  @override
  String explicacion({required bool esPersonal, required DateTime ahora}) =>
      esPersonal
      ? 'Sale sola cuando se entrega la última unidad.'
      : 'Se ve hasta que la ocultes.';

  @override
  bool operator ==(Object other) => other is SinFecha;

  @override
  int get hashCode => 0;
}

/// Veinticuatro horas desde que se publica.
final class UnDia extends VigenciaPublicacion {
  const UnDia();

  @override
  DateTime venceEn(DateTime ahora) => ahora.add(const Duration(hours: 24));

  @override
  String etiqueta({required bool esPersonal, required DateTime ahora}) =>
      '24 horas';

  @override
  String explicacion({required bool esPersonal, required DateTime ahora}) =>
      'Se deja de ver ${textoHasta(venceEn(ahora), ahora)}.';

  @override
  bool operator ==(Object other) => other is UnDia;

  @override
  int get hashCode => 1;
}

/// Hasta un día y una hora: la entrada para la fiesta del sábado se ve hasta
/// que empieza la fiesta. Sin hora, hasta el final del día (23:59).
final class HastaDia extends VigenciaPublicacion {
  HastaDia(DateTime dia, {int hora = 23, int minuto = 59})
    : fin = DateTime(dia.year, dia.month, dia.day, hora, minuto);

  /// El instante en que deja de verse.
  final DateTime fin;

  @override
  DateTime venceEn(DateTime ahora) => fin;

  @override
  String etiqueta({required bool esPersonal, required DateTime ahora}) =>
      'Hasta ${textoHasta(fin, ahora)}';

  @override
  String explicacion({required bool esPersonal, required DateTime ahora}) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dias = DateTime(fin.year, fin.month, fin.day).difference(hoy).inDays;
    // Hoy a una hora que ya paso, o el formulario quedo abierto de un dia
    // para el otro.
    if (!fin.isAfter(ahora)) {
      return dias == 0
          ? 'Esa hora ya pasó: elige otra.'
          : 'Esa fecha ya pasó: elige otra.';
    }
    final del = switch (dias) {
      0 => 'de hoy',
      1 => 'de mañana',
      _ => 'del ${_fecha(fin)}',
    };
    return 'Se ve hasta las ${_hora(fin)} $del.';
  }

  @override
  bool operator ==(Object other) => other is HastaDia && other.fin == fin;

  @override
  int get hashCode => fin.hashCode;
}

/// La fecha exacta que ya tenía una publicación: editarla no se la cambia.
final class HastaInstante extends VigenciaPublicacion {
  const HastaInstante(this.instante);

  final DateTime instante;

  @override
  DateTime venceEn(DateTime ahora) => instante;

  @override
  String etiqueta({required bool esPersonal, required DateTime ahora}) =>
      instante.isAfter(ahora)
      ? 'Hasta ${textoHasta(instante, ahora)}'
      : 'Venció ${textoHasta(instante, ahora)}';

  @override
  String explicacion({required bool esPersonal, required DateTime ahora}) =>
      instante.isAfter(ahora)
      ? 'Se deja de ver ${textoHasta(instante, ahora)}.'
      : 'Ya no se ve en el catálogo. Elige otra opción para que vuelva.';

  @override
  bool operator ==(Object other) =>
      other is HastaInstante && other.instante == instante;

  @override
  int get hashCode => instante.hashCode;
}

const _diasSemana = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _hora(DateTime momento) =>
    '${momento.hour.toString().padLeft(2, '0')}:'
    '${momento.minute.toString().padLeft(2, '0')}';

/// "sábado 21 de noviembre", sin artículo ni hora.
String _fecha(DateTime momento) =>
    '${_diasSemana[momento.weekday - 1]} ${momento.day} de '
    '${_meses[momento.month - 1]}';

/// "hoy a las 18:30", "mañana a las 14:37", "el sábado 22 de noviembre" o
/// "el martes 25 de noviembre a las 10:00". La hora solo se dice si no es el
/// final del día: "hasta el sábado" ya se entiende que es hasta la noche.
String textoHasta(DateTime momento, DateTime ahora) {
  final local = momento.toLocal();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(local.year, local.month, local.day);
  final diferencia = dia.difference(hoy).inDays;
  final finDelDia = local.hour == 23 && local.minute == 59;

  if (diferencia == 0) return finDelDia ? 'hoy' : 'hoy a las ${_hora(local)}';
  if (diferencia == 1) {
    return finDelDia ? 'mañana' : 'mañana a las ${_hora(local)}';
  }
  if (diferencia == -1) return 'ayer';

  final fecha = 'el ${_fecha(local)}';
  return finDelDia ? fecha : '$fecha a las ${_hora(local)}';
}

const _diasCortos = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Lo mismo en corto, para una etiqueta: "hoy 18:30", "mañana", "sáb 22 nov".
String textoHastaCorto(DateTime momento, DateTime ahora) {
  final local = momento.toLocal();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final diferencia = DateTime(
    local.year,
    local.month,
    local.day,
  ).difference(hoy).inDays;
  final hora = local.hour == 23 && local.minute == 59 ? '' : ' ${_hora(local)}';
  return switch (diferencia) {
    0 => 'hoy$hora',
    1 => 'mañana$hora',
    _ =>
      '${_diasCortos[local.weekday - 1]} ${local.day} '
          '${_mesesCortos[local.month - 1]}$hora',
  };
}

/// Para guardarla en el borrador: null (sin fecha), `un_dia` o
/// `hasta:2026-11-21T20:00:00.000`.
String? vigenciaATexto(VigenciaPublicacion vigencia) => switch (vigencia) {
  SinFecha() => null,
  UnDia() => 'un_dia',
  HastaDia(:final fin) => 'hasta:${fin.toIso8601String()}',
  HastaInstante(:final instante) => 'hasta:${instante.toIso8601String()}',
};

/// La que se guardó en el borrador, tal cual. Si la fecha ya pasó no se
/// cambia por otra a escondidas: el formulario lo dice y no deja publicar.
VigenciaPublicacion vigenciaDesdeTexto(String? texto) {
  if (texto == 'un_dia') return const UnDia();
  if (texto != null && texto.startsWith('hasta:')) {
    final fin = DateTime.tryParse(texto.substring('hasta:'.length));
    if (fin != null) return HastaDia(fin, hora: fin.hour, minuto: fin.minute);
  }
  return const SinFecha();
}

/// Lo que ve quien la publicó junto a cada publicación suya: si se vendió,
/// si venció, si la ocultó, o hasta cuándo se ve. Null: se ve, sin fecha.
String? estadoParaDueno(ProductoMarketplace producto, DateTime ahora) {
  if (producto.vendida) return 'VENDIDA';
  if (!producto.disponible && producto.vencidaA(ahora)) return 'VENCIDA';
  if (!producto.disponible) return 'OCULTA';
  final venceEn = producto.venceEn;
  if (venceEn == null) return null;
  return 'HASTA ${textoHastaCorto(venceEn, ahora).toUpperCase()}';
}
