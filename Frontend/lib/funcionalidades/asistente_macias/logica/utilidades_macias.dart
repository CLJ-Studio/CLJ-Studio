import 'dart:math';

import '../modelos/mensaje_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'lenguaje_macias.dart';
import 'matematica_macias.dart';

// ===========================================================================
// Fechas
// ===========================================================================

/// La hora, los dias y cuanto falta para algo.
///
/// Todo sale del reloj del telefono: nada de internet. Los feriados son los
/// de Bolivia, que es donde se usa la app.
abstract final class FechasMacias {
  static const dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  static const meses = [
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

  static const _numeroDeMes = {
    'enero': 1,
    'ene': 1,
    'febrero': 2,
    'feb': 2,
    'marzo': 3,
    'mar': 3,
    'abril': 4,
    'abr': 4,
    'mayo': 5,
    'may': 5,
    'junio': 6,
    'jun': 6,
    'julio': 7,
    'jul': 7,
    'agosto': 8,
    'ago': 8,
    'septiembre': 9,
    'setiembre': 9,
    'sep': 9,
    'sept': 9,
    'set': 9,
    'octubre': 10,
    'oct': 10,
    'noviembre': 11,
    'nov': 11,
    'diciembre': 12,
    'dic': 12,
  };

  static const _numeroDeDia = {
    'lunes': 1,
    'martes': 2,
    'miercoles': 3,
    'jueves': 4,
    'viernes': 5,
    'sabado': 6,
    'domingo': 7,
  };

  static const _numerosEnPalabras = {
    'un': 1,
    'una': 1,
    'uno': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
    'siete': 7,
    'ocho': 8,
    'nueve': 9,
    'diez': 10,
    'quince': 15,
    'veinte': 20,
    'treinta': 30,
  };

  static DateTime dia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Dias de una fecha a otra, sin que el horario de verano los mueva.
  static int diasEntre(DateTime desde, DateTime hasta) => DateTime.utc(
    hasta.year,
    hasta.month,
    hasta.day,
  ).difference(DateTime.utc(desde.year, desde.month, desde.day)).inDays;

  /// "miércoles 7 de octubre".
  static String larga(DateTime d) =>
      '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}';

  /// Como se diria desde [hoy]: "hoy", "mañana", "el viernes", "el lunes
  /// 2 de noviembre".
  static String relativa(DateTime fecha, DateTime hoy) {
    final n = diasEntre(hoy, fecha);
    if (n == 0) return 'hoy';
    if (n == 1) return 'mañana';
    if (n == 2) return 'pasado mañana';
    if (n == -1) return 'ayer';
    if (n > 0 && n < 7) return 'el ${dias[fecha.weekday - 1]}';
    return 'el ${larga(fecha)}${fecha.year == hoy.year ? '' : ' de ${fecha.year}'}';
  }

  static DateTime _mas(DateTime d, int dias) =>
      DateTime(d.year, d.month, d.day + dias);

  /// La fecha si existe (no hay 31 de junio). Sin año: la proxima vez que
  /// llega desde [hoy].
  static DateTime? _valida(int? anio, int mes, int d, DateTime hoy) {
    if (mes < 1 || mes > 12 || d < 1 || d > 31) return null;
    DateTime? crear(int a) {
      final fecha = DateTime(a, mes, d);
      return fecha.month == mes ? fecha : null;
    }

    if (anio != null) return crear(anio);
    final esteAnio = crear(hoy.year);
    if (esteAnio != null && !esteAnio.isBefore(hoy)) return esteAnio;
    return crear(hoy.year + 1) ?? esteAnio;
  }

  /// La fecha que nombra un texto ya normalizado: "mañana", "el lunes", "el
  /// 15", "15 de noviembre", "en 3 días". Null si no nombra ninguna.
  static DateTime? fechaEn(String limpio, DateTime ahora) {
    final hoy = dia(ahora);
    var t = ' $limpio ';
    // "en la mañana" es una parte del dia, no el dia de mañana.
    for (final parte in [
      ' en la manana ',
      ' de la manana ',
      ' por la manana ',
      ' a la manana ',
      ' en las mananas ',
    ]) {
      t = t.replaceAll(parte, ' ');
    }
    t = t.replaceAll(' esta manana ', ' hoy ');

    final conMes = RegExp(
      r' (\d{1,2}) (?:de )?([a-z]+)(?: (?:de |del )?(\d{4}))? ',
    ).firstMatch(t);
    if (conMes != null) {
      final mes = _numeroDeMes[conMes[2]];
      if (mes != null) {
        final anio = conMes[3] == null ? null : int.parse(conMes[3]!);
        return _valida(anio, mes, int.parse(conMes[1]!), hoy);
      }
    }
    final mesPrimero = RegExp(r' ([a-z]+) (\d{1,2}) ').firstMatch(t);
    if (mesPrimero != null) {
      final mes = _numeroDeMes[mesPrimero[1]];
      if (mes != null) {
        return _valida(null, mes, int.parse(mesPrimero[2]!), hoy);
      }
    }
    if (t.contains(' pasado manana ')) return _mas(hoy, 2);
    if (t.contains(' manana ')) return _mas(hoy, 1);
    if (t.contains(' hoy ')) return hoy;
    if (t.contains(' anteayer ') || t.contains(' antier ')) {
      return _mas(hoy, -2);
    }
    if (t.contains(' ayer ')) return _mas(hoy, -1);

    final dentro = RegExp(
      r' (?:en|dentro de) (\d+|[a-z]+) (dia|dias|semana|semanas) ',
    ).firstMatch(t);
    if (dentro != null) {
      final n = int.tryParse(dentro[1]!) ?? _numerosEnPalabras[dentro[1]];
      if (n != null) {
        return _mas(hoy, dentro[2]!.startsWith('semana') ? n * 7 : n);
      }
    }
    if (RegExp(
      r' (?:la )?(?:proxima|otra|siguiente) semana | la semana que viene ',
    ).hasMatch(t)) {
      return _mas(hoy, 7);
    }
    for (final MapEntry(key: nombre, value: numero) in _numeroDeDia.entries) {
      if (t.contains(' $nombre ')) {
        var faltan = (numero - hoy.weekday) % 7;
        if (faltan == 0) faltan = 7;
        return _mas(hoy, faltan);
      }
    }
    final soloDia = RegExp(r' el (\d{1,2}) ').firstMatch(t);
    if (soloDia != null) {
      final d = int.parse(soloDia[1]!);
      final esteMes = _valida(hoy.year, hoy.month, d, hoy);
      if (esteMes != null && !esteMes.isBefore(hoy)) return esteMes;
      final siguiente = DateTime(hoy.year, hoy.month + 1);
      return _valida(siguiente.year, siguiente.month, d, hoy);
    }
    return null;
  }

  /// Domingo de Pascua (algoritmo de Gauss, en la version de Meeus): de el
  /// salen Carnaval, Semana Santa y Corpus Christi.
  static DateTime pascua(int anio) {
    final a = anio % 19;
    final b = anio ~/ 100;
    final c = anio % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final diaDelMes = (h + l - 7 * m + 114) % 31 + 1;
    return DateTime(anio, mes, diaDelMes);
  }

  /// Fechas que caen siempre el mismo dia. El orden importa: "año nuevo
  /// andino" tiene que ganarle a "año nuevo".
  static const _fijas = <(List<String>, String, int, int)>[
    (
      ['ano nuevo andino', 'ano nuevo aymara', 'willkakuti'],
      'el Año Nuevo Andino',
      6,
      21,
    ),
    (['navidad'], 'Navidad', 12, 25),
    (['nochebuena', 'noche buena'], 'Nochebuena', 12, 24),
    (['ano nuevo'], 'Año Nuevo', 1, 1),
    (['fin de ano'], 'fin de año', 12, 31),
    (
      ['san valentin', 'dia del amor', 'dia de los enamorados'],
      'San Valentín',
      2,
      14,
    ),
    (['dia del estudiante'], 'el Día del Estudiante', 9, 21),
    (
      [
        'aniversario de santa cruz',
        'dia de santa cruz',
        'fiestas de santa cruz',
      ],
      'el aniversario de Santa Cruz',
      9,
      24,
    ),
    (
      ['todos santos', 'dia de los muertos', 'dia de los difuntos'],
      'Todos Santos',
      11,
      1,
    ),
    (['dia de la madre', 'dia de las madres'], 'el Día de la Madre', 5, 27),
    (['dia del padre'], 'el Día del Padre', 3, 19),
    (['dia del maestro', 'dia del profesor'], 'el Día del Maestro', 6, 6),
    (
      [
        'dia de la patria',
        'dia de la independencia',
        'fiestas patrias',
        'independencia de bolivia',
      ],
      'el 6 de agosto',
      8,
      6,
    ),
    (['halloween', 'noche de brujas'], 'Halloween', 10, 31),
    (['dia del trabajo', 'dia del trabajador'], 'el Día del Trabajo', 5, 1),
  ];

  /// Las que dependen de la Pascua: dias desde el domingo de Pascua.
  static const _moviles = <(List<String>, String, int)>[
    (['carnaval', 'carnavales'], 'el lunes de Carnaval', -48),
    (['viernes santo', 'semana santa'], 'Viernes Santo', -2),
    (['domingo de pascua', 'pascua'], 'Pascua', 0),
    (['corpus christi', 'corpus'], 'Corpus Christi', 60),
  ];

  static ({String nombre, DateTime fecha})? festividad(
    String limpio,
    DateTime ahora,
  ) {
    final hoy = dia(ahora);
    final t = ' $limpio ';
    for (final (formas, nombre, mes, d) in _fijas) {
      if (formas.any((f) => t.contains(' $f '))) {
        return (nombre: nombre, fecha: _valida(null, mes, d, hoy)!);
      }
    }
    for (final (formas, nombre, desdePascua) in _moviles) {
      if (formas.any((f) => t.contains(' $f '))) {
        var fecha = _mas(pascua(hoy.year), desdePascua);
        if (fecha.isBefore(hoy)) {
          fecha = _mas(pascua(hoy.year + 1), desdePascua);
        }
        return (nombre: nombre, fecha: fecha);
      }
    }
    return null;
  }

  static const _preguntasHora = {
    'que hora es',
    'que horas son',
    'que hora es ahora',
    'me dices la hora',
    'dime la hora',
    'tienes hora',
    'la hora',
    'hora',
    'sabes que hora es',
    'que hora tienes',
  };
  static const _preguntasHoy = {
    'que dia es hoy',
    'que dia es',
    'que fecha es hoy',
    'que fecha es',
    'fecha de hoy',
    'la fecha',
    'fecha',
    'a cuanto estamos',
    'a cuantos estamos',
    'que dia estamos',
    'hoy que dia es',
    'en que dia estamos',
    'que dia de la semana es',
    'que dia de la semana es hoy',
    'que dia es hoy dia',
  };
  static const _preguntasManana = {
    'que dia es manana',
    'manana que dia es',
    'que fecha es manana',
    'que dia sera manana',
    'manana que fecha es',
  };
  static const _preguntasAyer = {
    'que dia fue ayer',
    'ayer que dia fue',
    'que fecha fue ayer',
  };
  static const _preguntasAnio = {
    'en que ano estamos',
    'que ano es',
    'que ano estamos',
    'en que ano vivimos',
    'que ano es hoy',
  };
  static const _preguntasMes = {
    'en que mes estamos',
    'que mes es',
    'que mes estamos',
  };
  static const _preguntasFinde = {
    'es fin de semana',
    'ya es fin de semana',
    'hoy es fin de semana',
    'ya es finde',
    'es finde',
  };

  static final _faltan = RegExp(
    r'^(?:y )?(?:cuanto|cuantos|cuantas)(?: dias| semanas| tiempo| meses)? '
    r'(?:falta|faltan|queda|quedan) (?:para|pa|hasta)'
    r'(?: que (?:sea|llegue|empiece))? (.+)$',
  );
  static final _cuandoEs = RegExp(
    r'^(?:y )?cuando (?:es|cae|sera|son|empieza|llega|toca) (.+)$',
  );
  static final _queDiaCae = RegExp(
    r'^(?:y )?(?:que dia|en que dia|que dia de la semana) '
    r'(?:cae|caera|sera|fue|es) (.+)$',
  );

  /// La hora, la fecha o cuanto falta para algo. Null si no se pregunto
  /// nada de eso.
  static RespuestaCharla? responder(String limpio, ContextoMacias c) {
    final ahora = c.ahora;
    final hoy = dia(ahora);
    RespuestaCharla dicho(String texto) =>
        RespuestaCharla(texto, intencion: 'util:fecha');

    if (_preguntasHora.contains(limpio)) {
      final minutos = ahora.minute.toString().padLeft(2, '0');
      final tarde = ahora.hour >= 23 || ahora.hour < 5;
      return dicho(
        'Son las ${ahora.hour}:$minutos.'
        '${tarde ? ' Ya es tarde: si estás estudiando, guarda algo de sueño '
                  'para el examen.' : ''}',
      );
    }
    if (_preguntasHoy.contains(limpio)) {
      return dicho('Hoy es ${larga(hoy)} de ${hoy.year}.');
    }
    if (_preguntasManana.contains(limpio)) {
      return dicho('Mañana es ${larga(_mas(hoy, 1))}.');
    }
    if (_preguntasAyer.contains(limpio)) {
      return dicho('Ayer fue ${larga(_mas(hoy, -1))}.');
    }
    if (_preguntasAnio.contains(limpio)) {
      return dicho('Estamos en ${hoy.year}.');
    }
    if (_preguntasMes.contains(limpio)) {
      return dicho('Estamos en ${meses[hoy.month - 1]}.');
    }
    if (_preguntasFinde.contains(limpio)) {
      if (hoy.weekday >= 6) {
        return dicho(
          '¡Sí! Hoy es ${dias[hoy.weekday - 1]}. A descansar (o a estudiar, '
          'tú decides).',
        );
      }
      final faltan = 6 - hoy.weekday;
      return dicho(
        'Todavía no: hoy es ${dias[hoy.weekday - 1]}. '
        '${faltan == 1 ? 'Mañana ya es sábado.' : 'Faltan $faltan días para el sábado.'}',
      );
    }

    final otroLado = _horaEnOtroLado(limpio, ahora);
    if (otroLado != null) return dicho(otroLado);

    final pregunta =
        _faltan.firstMatch(limpio) ??
        _cuandoEs.firstMatch(limpio) ??
        _queDiaCae.firstMatch(limpio);
    if (pregunta == null) return null;
    final objetivo = pregunta[1]!;
    final soloElDia = identical(pregunta.pattern, _queDiaCae);

    // Su cumpleaños: lo sabe si se lo contaron.
    if (RegExp(r'\b(?:mi )?(?:cumpleanos|cumple)\b').hasMatch(objetivo) &&
        !objetivo.contains('tu ')) {
      final memoria = c.memoria;
      if (!memoria.tieneCumple) {
        return dicho(
          'No sé cuándo es tu cumpleaños. Cuéntame, por ejemplo: **mi '
          'cumpleaños es el 5 de mayo**, y me acuerdo.',
        );
      }
      final fecha = _valida(null, memoria.cumpleMes!, memoria.cumpleDia!, hoy)!;
      return dicho(_cuantoFalta('tu cumpleaños', fecha, hoy, soloElDia));
    }

    if (RegExp(r'\b(?:fin de semana|finde)\b').hasMatch(objetivo)) {
      if (hoy.weekday >= 6) return dicho('¡Ya es fin de semana! Disfrútalo.');
      return dicho(
        _cuantoFalta('el sábado', _mas(hoy, 6 - hoy.weekday), hoy, false),
      );
    }

    if (RegExp(r'\b(?:examen|parcial|final|prueba)\b').hasMatch(objetivo)) {
      final proximos = [
        for (final e in c.memoria.examenes)
          if (!e.fecha.isBefore(hoy)) e,
      ];
      if (proximos.isEmpty) {
        return dicho(
          'No me contaste de ningún examen. Dime, por ejemplo: **tengo examen '
          'de cálculo el viernes**, y te ayudo a contar los días.',
        );
      }
      final examen = proximos.first;
      return dicho(_cuantoFalta(examen.nombre, examen.fecha, hoy, soloElDia));
    }

    final fiesta = festividad(objetivo, ahora);
    if (fiesta != null) {
      return dicho(_cuantoFalta(fiesta.nombre, fiesta.fecha, hoy, soloElDia));
    }
    final fecha = fechaEn(objetivo, ahora);
    if (fecha != null) {
      final nombre = 'el ${fecha.day} de ${meses[fecha.month - 1]}';
      return dicho(_cuantoFalta(nombre, fecha, hoy, soloElDia));
    }
    return null;
  }

  static final _horaEn = RegExp(
    r'^(?:y )?(?:que hora es|que horas son|que hora sera|la hora|hora)'
    r'(?: ahora)? en (.+)$',
  );

  /// Cuantos minutos se le suman a la hora universal en cada lugar, y si
  /// cambia en verano: "ue" (Europa), "eeuu", "chile" o "australia".
  static const _husos = <String, (String, int, String)>{
    'bolivia': ('Bolivia', -240, ''),
    'santa cruz': ('Santa Cruz', -240, ''),
    'la paz': ('La Paz', -240, ''),
    'argentina': ('Argentina', -180, ''),
    'buenos aires': ('Buenos Aires', -180, ''),
    'brasil': ('Brasil (Brasilia y São Paulo)', -180, ''),
    'sao paulo': ('São Paulo', -180, ''),
    'paraguay': ('Paraguay', -180, ''),
    'uruguay': ('Uruguay', -180, ''),
    'chile': ('Chile', -240, 'chile'),
    'santiago': ('Santiago de Chile', -240, 'chile'),
    'peru': ('Perú', -300, ''),
    'lima': ('Lima', -300, ''),
    'colombia': ('Colombia', -300, ''),
    'bogota': ('Bogotá', -300, ''),
    'ecuador': ('Ecuador', -300, ''),
    'venezuela': ('Venezuela', -240, ''),
    'panama': ('Panamá', -300, ''),
    'mexico': ('Ciudad de México', -360, ''),
    'estados unidos': ('Nueva York', -300, 'eeuu'),
    'eeuu': ('Nueva York', -300, 'eeuu'),
    'usa': ('Nueva York', -300, 'eeuu'),
    'nueva york': ('Nueva York', -300, 'eeuu'),
    'miami': ('Miami', -300, 'eeuu'),
    'chicago': ('Chicago', -360, 'eeuu'),
    'los angeles': ('Los Ángeles', -480, 'eeuu'),
    'california': ('California', -480, 'eeuu'),
    'canada': ('Toronto', -300, 'eeuu'),
    'toronto': ('Toronto', -300, 'eeuu'),
    'espana': ('España', 60, 'ue'),
    'madrid': ('Madrid', 60, 'ue'),
    'francia': ('Francia', 60, 'ue'),
    'paris': ('París', 60, 'ue'),
    'alemania': ('Alemania', 60, 'ue'),
    'italia': ('Italia', 60, 'ue'),
    'portugal': ('Portugal', 0, 'ue'),
    'inglaterra': ('Inglaterra', 0, 'ue'),
    'londres': ('Londres', 0, 'ue'),
    'reino unido': ('el Reino Unido', 0, 'ue'),
    'rusia': ('Moscú', 180, ''),
    'moscu': ('Moscú', 180, ''),
    'turquia': ('Turquía', 180, ''),
    'dubai': ('Dubái', 240, ''),
    'india': ('India', 330, ''),
    'china': ('China', 480, ''),
    'pekin': ('Pekín', 480, ''),
    'corea': ('Corea del Sur', 540, ''),
    'corea del sur': ('Corea del Sur', 540, ''),
    'seul': ('Seúl', 540, ''),
    'japon': ('Japón', 540, ''),
    'tokio': ('Tokio', 540, ''),
    'australia': ('Sídney', 600, 'australia'),
    'sidney': ('Sídney', 600, 'australia'),
  };

  /// El domingo numero [n] del mes (n = -1: el ultimo).
  static DateTime _domingo(int anio, int mes, int n) {
    if (n > 0) {
      final primero = DateTime.utc(anio, mes, 1);
      final hasta = (DateTime.sunday - primero.weekday) % 7;
      return DateTime.utc(anio, mes, 1 + hasta + 7 * (n - 1));
    }
    final ultimo = DateTime.utc(anio, mes + 1, 0);
    return DateTime.utc(anio, mes, ultimo.day - ultimo.weekday % 7);
  }

  /// Si ese dia rige el horario de verano. Al dia, no a la hora: el dia
  /// del cambio puede fallar por unas horas, y para un chat alcanza.
  static bool _enVerano(String regla, DateTime dia) {
    final a = dia.year;
    bool entre(DateTime desde, DateTime hasta) =>
        !dia.isBefore(desde) && dia.isBefore(hasta);
    return switch (regla) {
      'ue' => entre(_domingo(a, 3, -1), _domingo(a, 10, -1)),
      'eeuu' => entre(_domingo(a, 3, 2), _domingo(a, 11, 1)),
      // En el sur el verano cruza el año nuevo.
      'chile' => !entre(_domingo(a, 4, 1), _domingo(a, 9, 1)),
      'australia' => !entre(_domingo(a, 4, 1), _domingo(a, 10, 1)),
      _ => false,
    };
  }

  /// "¿Qué hora es en Japón?". La hora de aca es la de Bolivia (UTC-4, sin
  /// horario de verano).
  static String? _horaEnOtroLado(String limpio, DateTime ahora) {
    final pedido = _horaEn.firstMatch(limpio);
    if (pedido == null) return null;
    final lugar = pedido[1]!.trim().replaceFirst(
      RegExp(r'^(?:el|la|los) '),
      '',
    );
    final huso = _husos[lugar];
    if (huso == null) {
      return 'De ahí no tengo la hora. Te sé decir la de los países más '
          'conocidos: Japón, España, Estados Unidos, Argentina, China...';
    }
    final (nombre, minutos, regla) = huso;
    final universal = DateTime.utc(
      ahora.year,
      ahora.month,
      ahora.day,
      ahora.hour,
      ahora.minute,
    ).add(const Duration(hours: 4));
    final desfase = minutos + (_enVerano(regla, universal) ? 60 : 0);
    final alla = universal.add(Duration(minutes: desfase));
    final hora = '${alla.hour}:${alla.minute.toString().padLeft(2, '0')}';
    final diferencia = desfase + 240;
    if (diferencia == 0) {
      return 'En $nombre es la misma hora que en Bolivia: las **$hora**.';
    }
    final horas = diferencia.abs() ~/ 60;
    final media = diferencia.abs() % 60 == 30;
    final cuanto = horas == 1 && !media
        ? 'una hora'
        : '$horas horas${media ? ' y media' : ''}';
    final dias = diasEntre(ahora, alla);
    final cuando = dias == 0
        ? ''
        : dias > 0
        ? ' (allá ya es ${larga(alla)})'
        : ' (allá todavía es ${larga(alla)})';
    return 'En $nombre son las **$hora**$cuando: $cuanto '
        '${diferencia > 0 ? 'más' : 'menos'} que en Bolivia.';
  }

  static String _cuantoFalta(
    String nombre,
    DateTime fecha,
    DateTime hoy,
    bool soloElDia,
  ) {
    final n = diasEntre(hoy, fecha);
    final cuando =
        '${larga(fecha)}${fecha.year == hoy.year ? '' : ' de ${fecha.year}'}';
    if (soloElDia) {
      return '${LenguajeMacias.conMayuscula(nombre)} '
          '${n < 0 ? 'cayó' : 'cae'} $cuando.';
    }
    if (n == 0) return '¡${LenguajeMacias.conMayuscula(nombre)} es hoy!';
    if (n == 1) {
      return '¡${LenguajeMacias.conMayuscula(nombre)} es mañana! ($cuando)';
    }
    if (n < 0) {
      return '${LenguajeMacias.conMayuscula(nombre)} ya pasó: fue $cuando.';
    }
    return 'Faltan **$n días** para $nombre: cae $cuando.';
  }
}

// ===========================================================================
// Azar y juegos
// ===========================================================================

/// Monedas, dados, numeros al azar, elegir por ti y algun juego.
abstract final class AzarMacias {
  static const juegos = [
    OpcionMacias(id: 'o:juego_numero', texto: 'Adivina el número'),
    OpcionMacias(id: 'o:juego_ppt', texto: 'Piedra, papel o tijera'),
    OpcionMacias(id: 'o:juego_adivinanza', texto: 'Una adivinanza'),
    OpcionMacias(id: 'o:juego_moneda', texto: 'Lanzar una moneda'),
    OpcionMacias(id: 'o:juego_dado', texto: 'Tirar un dado'),
  ];

  static final _moneda = RegExp(
    r'\b(?:cara o (?:sello|cruz)|(?:sello|cruz) o cara|'
    r'(?:lanza|lanzame|tira|tirame|echa|echame|lanzar|tirar|lanzas|tiras) '
    r'(?:una |la )?moneda|moneda al aire)\b',
  );
  static final _dado = RegExp(
    r'\b(?:lanza|lanzame|tira|tirame|echa|echame|tirar|lanzar|lanzas|tiras) '
    r'(?:un |el |los |(\d|dos|tres|cuatro|cinco) )?dados?\b',
  );
  static final _numeroAzar = RegExp(
    r'\b(?:numero (?:al azar|aleatorio|random|cualquiera)|'
    r'(?:dame|dime|elige|escoge|piensa en|genera|di) (?:un )?numero)\b',
  );
  static final _rango = RegExp(
    r'(?:del|de|entre) (\d+) (?:al|y|a|hasta) (\d+)',
  );
  static final _elegir = RegExp(
    r'^(?:elige|escoge|decide|decidi|elegi|escogeme|eligeme|'
    r'ayudame a (?:elegir|decidir)|que elijo|cual elijo|que escojo)'
    r'(?: tu)?(?: por mi)?(?: entre)? (.+)$',
  );
  static const _iniciarNumero = [
    'adivina el numero',
    'adivina un numero',
    'adivinar un numero',
    'adivinar el numero',
    'juguemos a adivinar',
    'juego de adivinar',
    'adivinar numeros',
  ];
  static const _iniciarPpt = [
    'piedra papel o tijera',
    'piedra papel tijera',
    'piedra papel o tijeras',
    'piedra papel y tijera',
    'cachipun',
    'yan ken po',
    'jankenpo',
  ];
  static const _pedirJuego = {
    'juguemos',
    'juguemos algo',
    'quiero jugar',
    'juega conmigo',
    'jugamos',
    'jugamos algo',
    'un juego',
    'juegos',
    'a que jugamos',
    'que juegos tienes',
    'tienes juegos',
    'vamos a jugar',
    'juego',
  };

  static RespuestaCharla? responder(
    String limpio,
    List<FichaTexto> fichas,
    String original,
    Random azar,
  ) {
    if (_pedirJuego.contains(limpio)) return menuJuegos();
    if (_iniciarNumero.any(limpio.contains)) return numero(azar);
    if (_iniciarPpt.any(limpio.contains)) return ppt();

    if (_moneda.hasMatch(limpio)) return moneda(azar);

    final dado = _dado.firstMatch(limpio);
    if (dado != null) {
      const enPalabras = {'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5};
      final cuantos = int.tryParse(dado[1] ?? '') ?? enPalabras[dado[1]] ?? 1;
      return dados(azar, cuantos.clamp(1, 5));
    }

    if (_numeroAzar.hasMatch(limpio)) {
      var desde = 1;
      var hasta = 100;
      final rango = _rango.firstMatch(limpio);
      if (rango != null) {
        desde = int.parse(rango[1]!);
        hasta = int.parse(rango[2]!);
        if (desde > hasta) (desde, hasta) = (hasta, desde);
        if (hasta - desde > 1000000000) hasta = desde + 1000000000;
      }
      final sale = desde + azar.nextInt(hasta - desde + 1);
      return RespuestaCharla(
        'Del $desde al $hasta... te tocó el **$sale**.',
        intencion: 'util:azar',
      );
    }

    final elegir = _elegir.firstMatch(limpio);
    if (elegir != null) {
      // Las opciones van hasta el final: lo que hay antes es el pedido.
      final pedido = limpio
          .substring(0, limpio.length - elegir[1]!.length)
          .trim();
      final opciones = _opcionesDesde(
        original,
        fichas,
        pedido.split(' ').length,
      );
      if (opciones.length >= 2) {
        final elegida = opciones[azar.nextInt(opciones.length)];
        return RespuestaCharla(
          'Yo me quedo con **$elegida**. Si no te convence, pregúntame de '
          'nuevo (no me ofendo).',
          intencion: 'util:elegir',
        );
      }
    }
    return null;
  }

  /// "pizza, salteña o empanada", tal como se escribio (con su ñ).
  static List<String> _opcionesDesde(
    String original,
    List<FichaTexto> fichas,
    int palabra,
  ) {
    if (palabra < 0 || palabra >= fichas.length) return const [];
    final resto = original.substring(fichas[palabra].inicio);
    return [
      for (final parte in resto.split(
        RegExp(r'\s*(?:,|;|\s+o\s+|\s+u\s+|\s+y\s+|\s+ó\s+)\s*'),
      ))
        if (parte.replaceAll(RegExp(r'[¿?¡!.]'), '').trim() case final limpia
            when limpia.isNotEmpty)
          limpia,
    ];
  }

  static RespuestaCharla menuJuegos() => const RespuestaCharla(
    '¡Dale! ¿A qué jugamos?',
    intencion: 'juego:menu',
    opciones: juegos,
  );

  static RespuestaCharla moneda(Random azar) => RespuestaCharla(
    'La lancé al aire y salió... **${azar.nextBool() ? 'cara' : 'sello'}**.',
    intencion: 'util:moneda',
  );

  static RespuestaCharla dados(Random azar, int cuantos) {
    final salieron = [for (var i = 0; i < cuantos; i++) 1 + azar.nextInt(6)];
    if (cuantos == 1) {
      return RespuestaCharla(
        'Salió un **${salieron.single}**.',
        intencion: 'util:dado',
      );
    }
    final lista = salieron.map((n) => '**$n**').toList();
    final dichos =
        '${lista.sublist(0, lista.length - 1).join(', ')} y ${lista.last}';
    return RespuestaCharla(
      'Salieron $dichos (suman ${salieron.reduce((a, b) => a + b)}).',
      intencion: 'util:dado',
    );
  }

  static RespuestaCharla numero(Random azar) => RespuestaCharla(
    'Pensé un número del 1 al 100. ¿Cuál es? Te digo si es más alto o más '
    'bajo. (Si te rindes, escribe **me rindo**.)',
    intencion: 'juego:numero',
    espera: EsperaNumero(1 + azar.nextInt(100)),
    sugerencias: const [],
  );

  static RespuestaCharla ppt() => const RespuestaCharla(
    '¡Dale! Elige: **piedra**, **papel** o **tijera**.',
    intencion: 'juego:ppt',
    espera: EsperaPpt(),
    sugerencias: [
      OpcionMacias(id: 'o:ppt_piedra', texto: 'Piedra'),
      OpcionMacias(id: 'o:ppt_papel', texto: 'Papel'),
      OpcionMacias(id: 'o:ppt_tijera', texto: 'Tijera'),
    ],
  );

  /// La jugada que hay en un mensaje: piedra, papel o tijera.
  static String? jugadaEn(String limpio) {
    final palabras = limpio.split(' ');
    if (palabras.contains('piedra')) return 'piedra';
    if (palabras.contains('papel')) return 'papel';
    if (palabras.contains('tijera') || palabras.contains('tijeras')) {
      return 'tijera';
    }
    return null;
  }

  static RespuestaCharla jugarPpt(String tuya, Random azar) {
    const jugadas = ['piedra', 'papel', 'tijera'];
    const leGanaA = {'piedra': 'tijera', 'papel': 'piedra', 'tijera': 'papel'};
    final mia = jugadas[azar.nextInt(3)];
    final String final_;
    if (mia == tuya) {
      final_ = '¡Empate! ¿Otra?';
    } else if (leGanaA[tuya] == mia) {
      final_ = '¡Ganaste! ¿La revancha?';
    } else {
      final_ = '¡Gané yo! ¿La revancha?';
    }
    return RespuestaCharla(
      'Yo saqué **$mia**. $final_',
      intencion: 'juego:ppt',
      espera: const EsperaSiNo('ppt'),
    );
  }

  /// Un intento en "adivina el número". La espera sigue mientras no acierte.
  static RespuestaCharla intentoNumero(EsperaNumero juego, int intento) {
    juego.intentos++;
    if (intento == juego.secreto) {
      final veces = juego.intentos == 1
          ? '¡a la primera! Eso fue suerte o telepatía'
          : 'en ${juego.intentos} intentos';
      return RespuestaCharla(
        '¡Sí, era el **${juego.secreto}**! Lo adivinaste $veces. ¿Otra '
        'partida?',
        intencion: 'juego:numero',
        espera: const EsperaSiNo('numero'),
      );
    }
    final pista = intento < juego.secreto ? 'más alto' : 'más bajo';
    return RespuestaCharla(
      'Es **$pista** que $intento.',
      intencion: 'juego:numero',
      espera: juego,
      sugerencias: const [],
    );
  }
}

// ===========================================================================
// Unidades, porcentajes y promedios
// ===========================================================================

class _Unidad {
  const _Unidad(
    this.tipo,
    this.factor,
    this.singular,
    this.plural,
    this.formas,
  );

  /// longitud, masa, tiempo, volumen o temperatura.
  final String tipo;

  /// Cuanto vale una en la unidad base del tipo (metro, kilo, segundo,
  /// litro). En temperatura no se usa.
  final double factor;
  final String singular;
  final String plural;
  final List<String> formas;
}

/// Convierte unidades y hace las cuentas rapidas de todos los dias:
/// porcentajes, descuentos y promedios.
abstract final class CuentasRapidasMacias {
  static const _unidades = [
    _Unidad('longitud', 1000, 'kilómetro', 'kilómetros', [
      'km',
      'kms',
      'kilometro',
      'kilometros',
    ]),
    _Unidad('longitud', 1, 'metro', 'metros', [
      'm',
      'mt',
      'mts',
      'metro',
      'metros',
    ]),
    _Unidad('longitud', .01, 'centímetro', 'centímetros', [
      'cm',
      'cms',
      'centimetro',
      'centimetros',
    ]),
    _Unidad('longitud', .001, 'milímetro', 'milímetros', [
      'mm',
      'milimetro',
      'milimetros',
    ]),
    _Unidad('longitud', 1609.344, 'milla', 'millas', ['milla', 'millas', 'mi']),
    _Unidad('longitud', .3048, 'pie', 'pies', ['pie', 'pies', 'ft']),
    _Unidad('longitud', .0254, 'pulgada', 'pulgadas', [
      'pulgada',
      'pulgadas',
      'plg',
    ]),
    _Unidad('longitud', .9144, 'yarda', 'yardas', ['yarda', 'yardas', 'yd']),
    _Unidad('masa', 1, 'kilo', 'kilos', [
      'kg',
      'kgs',
      'kilo',
      'kilos',
      'kilogramo',
      'kilogramos',
    ]),
    _Unidad('masa', .001, 'gramo', 'gramos', [
      'g',
      'gr',
      'grs',
      'gramo',
      'gramos',
    ]),
    _Unidad('masa', .000001, 'miligramo', 'miligramos', [
      'mg',
      'miligramo',
      'miligramos',
    ]),
    _Unidad('masa', .45359237, 'libra', 'libras', [
      'lb',
      'lbs',
      'libra',
      'libras',
    ]),
    _Unidad('masa', .028349523125, 'onza', 'onzas', ['oz', 'onza', 'onzas']),
    _Unidad('masa', 1000, 'tonelada', 'toneladas', ['tonelada', 'toneladas']),
    _Unidad('tiempo', 1, 'segundo', 'segundos', [
      's',
      'seg',
      'segs',
      'segundo',
      'segundos',
    ]),
    _Unidad('tiempo', 60, 'minuto', 'minutos', [
      'min',
      'mins',
      'minuto',
      'minutos',
    ]),
    _Unidad('tiempo', 3600, 'hora', 'horas', [
      'h',
      'hr',
      'hrs',
      'hora',
      'horas',
    ]),
    _Unidad('tiempo', 86400, 'día', 'días', ['dia', 'dias']),
    _Unidad('tiempo', 604800, 'semana', 'semanas', ['semana', 'semanas']),
    _Unidad('volumen', 1, 'litro', 'litros', [
      'l',
      'lt',
      'lts',
      'litro',
      'litros',
    ]),
    _Unidad('volumen', .001, 'mililitro', 'mililitros', [
      'ml',
      'cc',
      'mililitro',
      'mililitros',
    ]),
    _Unidad('volumen', 3.785411784, 'galón', 'galones', [
      'gal',
      'galon',
      'galones',
    ]),
    _Unidad('temperatura', 0, 'grado Celsius', '°C', [
      'c',
      'celsius',
      'centigrados',
      'grados celsius',
      'grados centigrados',
      'grados',
    ]),
    _Unidad('temperatura', 0, 'grado Fahrenheit', '°F', [
      'f',
      'fahrenheit',
      'grados fahrenheit',
    ]),
    _Unidad('temperatura', 0, 'kelvin', 'K', ['k', 'kelvin', 'kelvins']),
  ];

  /// Todas las formas, de la mas larga a la mas corta: "grados celsius"
  /// tiene que leerse antes que "grados".
  static final _formas = () {
    final todas = [
      for (final unidad in _unidades)
        for (final forma in unidad.formas) (forma, unidad),
    ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return todas;
  }();

  static final _alternativa = _formas.map((f) => RegExp.escape(f.$1)).join('|');

  static final _convertir = RegExp(
    '(-?\\d+(?:\\.\\d+)?) ?($_alternativa) (?:a|en|para|to|=) '
    '(?:cuant[oa]s )?($_alternativa)(?![a-z])',
  );
  static final _cuantos = RegExp(
    'cuant[oa]s ($_alternativa) (?:son|hay en|tiene|equivalen a|equivale a|'
    'caben en|mide|pesa|dura|son en) (-?\\d+(?:\\.\\d+)?) ?($_alternativa)'
    '(?![a-z])',
  );

  /// El texto listo para buscar numeros: minusculas, sin tildes, coma
  /// decimal como punto, "30c" separado en "30 c".
  static String _preparar(String original) {
    var t = original.toLowerCase();
    const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n'};
    tildes.forEach((de, a) => t = t.replaceAll(de, a));
    t = t.replaceAll('°', ' ').replaceAll('º', ' ');
    t = t.replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}');
    t = t.replaceAllMapped(RegExp(r'(\d)([a-z%])'), (m) => '${m[1]} ${m[2]}');
    t = t.replaceAll(RegExp(r'[¿?¡!]'), ' ');
    return ' ${t.replaceAll(RegExp(r'\s+'), ' ').trim()} ';
  }

  static RespuestaCharla? responder(String original) {
    final t = _preparar(original);
    final aprobar = _paraAprobar(t);
    if (aprobar != null) return aprobar;
    if (!RegExp(r'\d').hasMatch(original)) {
      // "¿Cuántos metros tiene un kilómetro?": ese "un" es un 1.
      final conUno = t.replaceFirst(
        RegExp(r' (?:un|una|el|la) (?=[a-z])'),
        ' 1 ',
      );
      return (conUno == t ? null : _conversion(conUno)) ?? _dinero(t);
    }
    return _conversion(t) ??
        _porcentaje(t) ??
        _promedio(original) ??
        _dinero(t);
  }

  static final _cuantoNecesito = RegExp(
    r'\b(?:cuanto|que nota) (?:necesito|me falta|debo sacar|tengo que sacar|'
    r'necesito sacar)\b',
  );
  static final _deNotas = RegExp(
    r'\b(?:aprobar|pasar|final|nota|notas|examen|parcial)\b',
  );

  /// "Saqué 60 en un parcial de 30% y 70 en otro de 30%, ¿cuánto necesito
  /// para aprobar?": lo que hace falta en lo que queda, sobre 100.
  static RespuestaCharla? _paraAprobar(String t) {
    final pregunta = _cuantoNecesito.hasMatch(t) && _deNotas.hasMatch(t);
    final conPorcentajes =
        t.contains('%') && RegExp(r'\bpara (?:aprobar|pasar)\b').hasMatch(t);
    if (!pregunta && !conPorcentajes) return null;
    RespuestaCharla dicho(String texto) =>
        RespuestaCharla(texto, intencion: 'util:aprobar');

    final minima =
        double.tryParse(
          RegExp(
                r'(?:aprueba|aprobar|pasa|pasar) con (\d+(?:\.\d+)?)',
              ).firstMatch(t)?[1] ??
              '',
        ) ??
        51;
    // Cada nota va seguida de lo que vale: "60 ... 30%".
    final numeros = [
      for (final m in RegExp(r'(\d+(?:\.\d+)?)( ?%)?').allMatches(t))
        (valor: double.parse(m[1]!), porcentaje: m[2] != null),
    ];
    final notas = <(double, double)>[];
    double? pendiente;
    for (var i = 0; i < numeros.length; i++) {
      final actual = numeros[i];
      if (actual.porcentaje) {
        // Un porcentaje sin nota delante: lo que falta ("el final vale 40%").
        pendiente = actual.valor;
        continue;
      }
      if (i + 1 < numeros.length && numeros[i + 1].porcentaje) {
        notas.add((actual.valor, numeros[i + 1].valor));
        i++;
      }
    }
    if (notas.isEmpty) {
      if (!pregunta) return null;
      return dicho(
        'Dime tus notas y cuánto vale cada una, y te lo calculo. Por ejemplo: '
        '**saqué 60 en un parcial de 30% y 70 en otro de 30%, ¿cuánto necesito '
        'para aprobar?** (Cuento con que se aprueba con ${_n(minima)} sobre '
        '100; si en tu materia es otra, dímela.)',
      );
    }
    final acumulado = notas.fold(0.0, (suma, n) => suma + n.$1 * n.$2 / 100);
    final usado = notas.fold(0.0, (suma, n) => suma + n.$2);
    final falta = pendiente ?? 100 - usado;
    final redondeado = (acumulado * 100).round() / 100;
    final detalle = [
      for (final (nota, peso) in notas) '${_n(nota)} × ${_n(peso)} %',
    ].join(' + ');
    final llevas =
        'Con lo que llevas: $detalle = **${_n(redondeado)} puntos**.';
    if (acumulado >= minima) {
      return dicho('$llevas ¡Ya pasaste los ${_n(minima)}! Aprobado.');
    }
    if (falta <= 0) {
      return dicho(
        '$llevas No te queda nada en juego para llegar a ${_n(minima)}: habla '
        'con tu profe por una recuperación o segunda instancia.',
      );
    }
    final necesario = ((minima - acumulado) / (falta / 100) * 10).ceil() / 10;
    if (necesario > 100) {
      return dicho(
        '$llevas Para llegar a ${_n(minima)} necesitarías ${_n(necesario)} '
        'sobre 100 en lo que queda (${_n(falta)} %), y eso no alcanza. Habla '
        'con tu profe: puede haber recuperación o segunda instancia.',
      );
    }
    return dicho(
      '$llevas Te queda un ${_n(falta)} % en juego.\n'
      'Para llegar a ${_n(minima)} necesitas **${_n(necesario)}** sobre 100 en '
      'lo que falta.',
    );
  }

  static final _monedas = RegExp(r'\b(?:dolar|dolares|usd|euro|euros)\b');

  /// El tipo de cambio no se sabe sin internet, y en Bolivia el dolar anda
  /// movido. Con la cotizacion que diga la persona, la cuenta si sale.
  static RespuestaCharla? _dinero(String t) {
    if (!_monedas.hasMatch(t)) return null;
    final conTasa = RegExp(
      r'(\d+(?:\.\d+)?) (?:dolares|dolar|usd|euros|euro) (?:a|por|x) '
      r'(\d+(?:\.\d+)?)(?: (?:bs|bolivianos|cada uno))?$',
    ).firstMatch(t.trim());
    if (conTasa != null) {
      final cantidad = double.parse(conTasa[1]!);
      final tasa = double.parse(conTasa[2]!);
      return RespuestaCharla(
        'A ${_n(tasa)} Bs cada uno: ${_n(cantidad)} × ${_n(tasa)} = '
        '**${_n(cantidad * tasa)} Bs**.',
        intencion: 'util:dinero',
      );
    }
    final pide = RegExp(
      r'\b(?:a cuanto esta|cuanto esta|cuanto vale|cuanto cuesta|precio del|'
      r'cotizacion|cambio del|convierte|convertir|pasa|pasame|cuanto es|'
      r'cuanto son|cuantos bolivianos|en bolivianos|a bolivianos|en bs|a bs|'
      r'dolar hoy)\b',
    ).hasMatch(t);
    if (!pide) return null;
    return const RespuestaCharla(
      'No tengo el tipo de cambio de hoy: no uso internet, y el dólar se '
      'mueve. Si me dices a cuánto está, hago la cuenta al toque: por ejemplo, '
      '**100 dólares a 6,96**.',
      intencion: 'util:dinero',
    );
  }

  static _Unidad? _unidad(String forma) {
    for (final (nombre, unidad) in _formas) {
      if (nombre == forma) return unidad;
    }
    return null;
  }

  static RespuestaCharla? _conversion(String t) {
    String? valor;
    String? de;
    String? a;
    final directa = _convertir.firstMatch(t);
    if (directa != null) {
      valor = directa[1];
      de = directa[2];
      a = directa[3];
    } else {
      final pregunta = _cuantos.firstMatch(t);
      if (pregunta == null) return null;
      a = pregunta[1];
      valor = pregunta[2];
      de = pregunta[3];
    }
    final origen = _unidad(de!);
    final destino = _unidad(a!);
    if (origen == null || destino == null || identical(origen, destino)) {
      return null;
    }
    if (origen.tipo != destino.tipo) {
      return RespuestaCharla(
        'No se puede pasar ${origen.plural} a ${destino.plural}: miden '
        'cosas distintas (${origen.tipo} y ${destino.tipo}).',
        intencion: 'util:unidades',
      );
    }
    final cantidad = double.parse(valor!);
    final resultado = origen.tipo == 'temperatura'
        ? _temperatura(cantidad, origen, destino)
        : cantidad * origen.factor / destino.factor;
    String escrito(double v, _Unidad u) {
      final numero = MatematicaMacias.formatearDecimal(v);
      if (u.tipo == 'temperatura') return '$numero ${u.plural}';
      return '$numero ${v == 1 ? u.singular : u.plural}';
    }

    return RespuestaCharla(
      '**${escrito(cantidad, origen)} = ${escrito(resultado, destino)}**',
      intencion: 'util:unidades',
    );
  }

  static double _temperatura(double valor, _Unidad de, _Unidad a) {
    final celsius = switch (de.plural) {
      '°F' => (valor - 32) * 5 / 9,
      'K' => valor - 273.15,
      _ => valor,
    };
    return switch (a.plural) {
      '°F' => celsius * 9 / 5 + 32,
      'K' => celsius + 273.15,
      _ => celsius,
    };
  }

  static const _numero = r'(\d+(?:\.\d+)?)';
  static const _porCiento = r' ?(?:%|por ?ciento)';

  static String _n(double v) => MatematicaMacias.formatearDecimal(v);

  static RespuestaCharla? _porcentaje(String t) {
    RespuestaCharla dicho(String texto) =>
        RespuestaCharla(texto, intencion: 'util:porcentaje');

    final queParte = RegExp(
      'que porcentaje (?:es|son|representa|representan) $_numero de $_numero',
    ).firstMatch(t);
    if (queParte != null) {
      final parte = double.parse(queParte[1]!);
      final total = double.parse(queParte[2]!);
      if (total == 0) return dicho('Sobre cero no hay porcentaje que valga.');
      return dicho(
        '${_n(parte)} es el **${_n(parte / total * 100)} %** de ${_n(total)}.',
      );
    }
    final precioPrimero = RegExp(
      '$_numero (?:con|menos) (?:un |el )?$_numero$_porCiento',
    ).firstMatch(t);
    final descuentoPrimero = RegExp(
      'descuento (?:del |de )?$_numero$_porCiento (?:a|de|en|sobre) $_numero',
    ).firstMatch(t);
    if (precioPrimero != null || descuentoPrimero != null) {
      final precio = double.parse(
        precioPrimero != null ? precioPrimero[1]! : descuentoPrimero![2]!,
      );
      final porcentaje = double.parse(
        precioPrimero != null ? precioPrimero[2]! : descuentoPrimero![1]!,
      );
      final rebaja = precio * porcentaje / 100;
      return dicho(
        '${_n(precio)} con ${_n(porcentaje)} % de descuento: te rebajan '
        '${_n(rebaja)} y queda en **${_n(precio - rebaja)}**.',
      );
    }
    final aumento = RegExp(
      '$_numero (?:mas|\\+) (?:el |un )?$_numero$_porCiento',
    ).firstMatch(t);
    if (aumento != null) {
      final base = double.parse(aumento[1]!);
      final porcentaje = double.parse(aumento[2]!);
      return dicho(
        '${_n(base)} más el ${_n(porcentaje)} % '
        '(${_n(base * porcentaje / 100)}) da **${_n(base * (1 + porcentaje / 100))}**.',
      );
    }
    final deUn = RegExp('$_numero$_porCiento de $_numero').firstMatch(t);
    if (deUn != null) {
      final porcentaje = double.parse(deUn[1]!);
      final total = double.parse(deUn[2]!);
      return dicho(
        'El ${_n(porcentaje)} % de ${_n(total)} es '
        '**${_n(porcentaje * total / 100)}**.',
      );
    }
    return null;
  }

  /// "promedio de 70, 80 y 95". Aqui la coma casi siempre separa notas, asi
  /// que solo es decimal en "70,5": una coma con una o dos cifras detras.
  static RespuestaCharla? _promedio(String original) {
    final t = original.toLowerCase();
    final pedido = RegExp(
      r'\b(?:promedio|promedia|promediar|media)(?: de| entre| para)?:? '
      r'([\d.\s,;y]+)',
    ).firstMatch(t);
    if (pedido == null) return null;
    final numeros = <double>[];
    for (final ficha in pedido[1]!.split(RegExp(r'\s+y\s+|[\s;]+'))) {
      if (ficha.isEmpty) continue;
      final decimal = RegExp(r'^(\d+),(\d{1,2})$').firstMatch(ficha);
      final partes = decimal != null
          ? ['${decimal[1]}.${decimal[2]}']
          : ficha.split(',');
      for (final parte in partes) {
        final valor = double.tryParse(parte);
        if (valor != null) numeros.add(valor);
      }
    }
    if (numeros.length < 2) return null;
    final suma = numeros.reduce((a, b) => a + b);
    final promedio = suma / numeros.length;
    final redondeado = (promedio * 100).round() / 100;
    final escritos = numeros.map(_n).toList();
    return RespuestaCharla(
      'Promedio: (${escritos.join(' + ')}) / ${numeros.length} = '
      '**${_n(redondeado)}**'
      '${redondeado == promedio ? '' : ' (redondeado a dos decimales)'}',
      intencion: 'util:promedio',
    );
  }
}
