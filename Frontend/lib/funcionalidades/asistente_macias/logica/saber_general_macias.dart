import 'conversacion_macias.dart';

/// Un poco de cultura general: lo que mas se pregunta para "probar" a un
/// asistente.
///
/// Son datos que no cambian (capitales, planetas, constantes). Lo que si
/// cambia, como quien gobierna o quien gano el ultimo partido, no esta a
/// proposito: MacIAs no tiene internet, y un dato viejo dicho con seguridad
/// es peor que un "no sé".
abstract final class SaberGeneralMacias {
  static const _capitales = {
    'argentina': ('Argentina', 'Buenos Aires'),
    'brasil': ('Brasil', 'Brasilia'),
    'chile': ('Chile', 'Santiago'),
    'colombia': ('Colombia', 'Bogotá'),
    'ecuador': ('Ecuador', 'Quito'),
    'paraguay': ('Paraguay', 'Asunción'),
    'peru': ('Perú', 'Lima'),
    'uruguay': ('Uruguay', 'Montevideo'),
    'venezuela': ('Venezuela', 'Caracas'),
    'guyana': ('Guyana', 'Georgetown'),
    'surinam': ('Surinam', 'Paramaribo'),
    'mexico': ('México', 'Ciudad de México'),
    'guatemala': ('Guatemala', 'Ciudad de Guatemala'),
    'belice': ('Belice', 'Belmopán'),
    'honduras': ('Honduras', 'Tegucigalpa'),
    'el salvador': ('El Salvador', 'San Salvador'),
    'nicaragua': ('Nicaragua', 'Managua'),
    'costa rica': ('Costa Rica', 'San José'),
    'panama': ('Panamá', 'Ciudad de Panamá'),
    'cuba': ('Cuba', 'La Habana'),
    'republica dominicana': ('República Dominicana', 'Santo Domingo'),
    'haiti': ('Haití', 'Puerto Príncipe'),
    'jamaica': ('Jamaica', 'Kingston'),
    'estados unidos': ('Estados Unidos', 'Washington D. C.'),
    'eeuu': ('Estados Unidos', 'Washington D. C.'),
    'usa': ('Estados Unidos', 'Washington D. C.'),
    'canada': ('Canadá', 'Ottawa'),
    'espana': ('España', 'Madrid'),
    'francia': ('Francia', 'París'),
    'alemania': ('Alemania', 'Berlín'),
    'italia': ('Italia', 'Roma'),
    'portugal': ('Portugal', 'Lisboa'),
    'reino unido': ('el Reino Unido', 'Londres'),
    'inglaterra': ('Inglaterra', 'Londres'),
    'irlanda': ('Irlanda', 'Dublín'),
    'paises bajos': ('los Países Bajos', 'Ámsterdam'),
    'holanda': ('los Países Bajos', 'Ámsterdam'),
    'belgica': ('Bélgica', 'Bruselas'),
    'suiza': ('Suiza', 'Berna'),
    'austria': ('Austria', 'Viena'),
    'grecia': ('Grecia', 'Atenas'),
    'rusia': ('Rusia', 'Moscú'),
    'ucrania': ('Ucrania', 'Kiev'),
    'polonia': ('Polonia', 'Varsovia'),
    'suecia': ('Suecia', 'Estocolmo'),
    'noruega': ('Noruega', 'Oslo'),
    'dinamarca': ('Dinamarca', 'Copenhague'),
    'finlandia': ('Finlandia', 'Helsinki'),
    'islandia': ('Islandia', 'Reikiavik'),
    'republica checa': ('la República Checa', 'Praga'),
    'chequia': ('Chequia', 'Praga'),
    'hungria': ('Hungría', 'Budapest'),
    'rumania': ('Rumania', 'Bucarest'),
    'croacia': ('Croacia', 'Zagreb'),
    'serbia': ('Serbia', 'Belgrado'),
    'bulgaria': ('Bulgaria', 'Sofía'),
    'turquia': ('Turquía', 'Ankara'),
    'china': ('China', 'Pekín'),
    'japon': ('Japón', 'Tokio'),
    'corea del sur': ('Corea del Sur', 'Seúl'),
    'corea del norte': ('Corea del Norte', 'Pionyang'),
    'india': ('India', 'Nueva Delhi'),
    'pakistan': ('Pakistán', 'Islamabad'),
    'filipinas': ('Filipinas', 'Manila'),
    'tailandia': ('Tailandia', 'Bangkok'),
    'vietnam': ('Vietnam', 'Hanói'),
    'malasia': ('Malasia', 'Kuala Lumpur'),
    'singapur': ('Singapur', 'Singapur'),
    'arabia saudita': ('Arabia Saudita', 'Riad'),
    'iran': ('Irán', 'Teherán'),
    'irak': ('Irak', 'Bagdad'),
    'emiratos arabes unidos': ('los Emiratos Árabes Unidos', 'Abu Dabi'),
    'qatar': ('Catar', 'Doha'),
    'catar': ('Catar', 'Doha'),
    'nepal': ('Nepal', 'Katmandú'),
    'afganistan': ('Afganistán', 'Kabul'),
    'mongolia': ('Mongolia', 'Ulán Bator'),
    'egipto': ('Egipto', 'El Cairo'),
    'marruecos': ('Marruecos', 'Rabat'),
    'nigeria': ('Nigeria', 'Abuya'),
    'kenia': ('Kenia', 'Nairobi'),
    'etiopia': ('Etiopía', 'Adís Abeba'),
    'argelia': ('Argelia', 'Argel'),
    'ghana': ('Ghana', 'Acra'),
    'senegal': ('Senegal', 'Dakar'),
    'angola': ('Angola', 'Luanda'),
    'australia': ('Australia', 'Canberra'),
    'nueva zelanda': ('Nueva Zelanda', 'Wellington'),
  };

  /// Departamentos de Bolivia con su capital.
  static const _departamentos = {
    'santa cruz': ('Santa Cruz', 'Santa Cruz de la Sierra'),
    'la paz': ('La Paz', 'La Paz'),
    'cochabamba': ('Cochabamba', 'Cochabamba'),
    'chuquisaca': ('Chuquisaca', 'Sucre'),
    'oruro': ('Oruro', 'Oruro'),
    'potosi': ('Potosí', 'Potosí'),
    'tarija': ('Tarija', 'Tarija'),
    'beni': ('Beni', 'Trinidad'),
    'pando': ('Pando', 'Cobija'),
  };

  static final _capital = RegExp(r'\bcapital (?:de |del )?([a-z ]+?)\s*$');

  /// Fechas de la historia que se preguntan en el colegio y en la U.
  static const _historia = {
    'segunda guerra mundial':
        'La **Segunda Guerra Mundial** fue de 1939 a 1945.',
    'primera guerra mundial':
        'La **Primera Guerra Mundial** fue de 1914 a 1918.',
    'guerra del chaco':
        'La **Guerra del Chaco** enfrentó a Bolivia y Paraguay de 1932 a 1935.',
    'guerra del pacifico':
        'La **Guerra del Pacífico** fue de 1879 a 1884: Bolivia y Perú contra '
        'Chile. Ahí Bolivia perdió su salida al mar.',
    'revolucion francesa':
        'La **Revolución Francesa** empezó en 1789, con la toma de la '
        'Bastilla.',
    'llegada a la luna':
        'El ser humano llegó a la **Luna** el 20 de julio de 1969, con el '
        'Apolo 11. Neil Armstrong fue el primero en pisarla.',
    'llegada del hombre a la luna':
        'El ser humano llegó a la **Luna** el 20 de julio de 1969, con el '
        'Apolo 11. Neil Armstrong fue el primero en pisarla.',
    'caida del muro de berlin':
        'El **Muro de Berlín** cayó el 9 de noviembre de 1989.',
    'muro de berlin':
        'El **Muro de Berlín** dividió la ciudad de 1961 a 1989, cuando cayó.',
    'revolucion de 1952':
        'La **Revolución de 1952** en Bolivia trajo el voto universal, la '
        'reforma agraria y la nacionalización de las minas.',
  };

  /// "la paz" y "el salvador" llevan el articulo en el nombre; "la india" o
  /// "el peru", no. Se prueba primero entero y despues sin el articulo.
  static (String, String)? _buscar(
    Map<String, (String, String)> lugares,
    String nombre,
  ) =>
      lugares[nombre] ??
      lugares[nombre.replaceFirst(RegExp(r'^(?:la|el|los|las) '), '')];

  static RespuestaCharla? responder(String limpio) {
    RespuestaCharla dicho(String texto) =>
        RespuestaCharla(texto, intencion: 'saber:general');
    final t = ' $limpio ';
    bool dice(List<String> frases) => frases.any((f) => t.contains(' $f '));

    final capital = _capital.firstMatch(limpio);
    if (capital != null) {
      final lugar = capital[1]!.trim();
      if (lugar == 'bolivia') {
        return dicho(
          'Bolivia tiene dos: **Sucre** es la capital constitucional y **La '
          'Paz** es la sede de gobierno.',
        );
      }
      final departamento = _buscar(_departamentos, lugar);
      final pais = _buscar(_capitales, lugar);
      if (pais != null) {
        return dicho('La capital de ${pais.$1} es **${pais.$2}**.');
      }
      if (departamento != null) {
        return dicho(
          'La capital del departamento de ${departamento.$1} es '
          '**${departamento.$2}**.',
        );
      }
      if (lugar == 'el mundo' || lugar == 'mundo') {
        return dicho(
          'El mundo no tiene capital. Aunque para mí es Santa Cruz.',
        );
      }
    }

    if (dice([
      'departamentos de bolivia',
      'departamentos tiene bolivia',
      'cuantos departamentos',
    ])) {
      final lista = _departamentos.values
          .map((d) => '• ${d.$1}: ${d.$2}')
          .join('\n');
      return dicho(
        'Bolivia tiene **9 departamentos**, cada uno con su capital:\n$lista',
      );
    }
    if (dice(['moneda de bolivia', 'moneda boliviana'])) {
      return dicho('El **boliviano** (Bs).');
    }
    if (dice([
      'idioma oficial de bolivia',
      'idiomas oficiales de bolivia',
      'idiomas de bolivia',
      'idiomas se hablan en bolivia',
    ])) {
      return dicho(
        'Bolivia tiene **37 idiomas oficiales**: el castellano y 36 lenguas '
        'indígenas, como el quechua, el aymara y el guaraní.',
      );
    }
    if (dice([
      'independencia de bolivia',
      'cuando se independizo bolivia',
      'fundacion de bolivia',
    ])) {
      return dicho('Bolivia se independizó el **6 de agosto de 1825**.');
    }
    if (dice(['salar de uyuni', 'salar mas grande'])) {
      return dicho(
        'El **Salar de Uyuni**, en Potosí, es el desierto de sal más grande '
        'del mundo.',
      );
    }
    if (dice(['lago titicaca', 'lago navegable mas alto'])) {
      return dicho(
        'El **Titicaca**, entre Bolivia y Perú, es el lago navegable más '
        'alto del mundo: está a unos 3800 metros sobre el nivel del mar.',
      );
    }
    if (dice([
      'presidente de bolivia',
      'presidenta de bolivia',
      'quien gobierna bolivia',
      'presidente actual',
    ])) {
      return dicho(
        'No te lo voy a decir de memoria: no tengo internet ni noticias al '
        'día, y eso cambia. Búscalo en una fuente actualizada.',
      );
    }

    // ------------------------------------------------------- sistema solar
    if (dice([
      'planetas del sistema solar',
      'cuantos planetas',
      'cuales son los planetas',
      'los planetas',
      'nombres de los planetas',
    ])) {
      return dicho(
        'Son **8**, del más cercano al Sol al más lejano: Mercurio, Venus, '
        'la Tierra, Marte, Júpiter, Saturno, Urano y Neptuno. (Plutón pasó '
        'a ser planeta enano en 2006.)',
      );
    }
    if (dice(['planeta mas grande'])) {
      return dicho('**Júpiter**: le entrarían más de mil Tierras.');
    }
    if (dice(['planeta mas pequeno', 'planeta mas chico'])) {
      return dicho('**Mercurio**, que además es el más cercano al Sol.');
    }
    if (dice(['planeta mas cercano al sol'])) return dicho('**Mercurio**.');
    if (dice(['planeta mas lejano', 'planeta mas alejado'])) {
      return dicho('**Neptuno**.');
    }
    if (dice(['planeta rojo'])) return dicho('**Marte**.');
    if (dice(['planeta mas caliente'])) {
      return dicho(
        '**Venus**, aunque Mercurio esté más cerca del Sol: su atmósfera '
        'atrapa el calor.',
      );
    }

    // ---------------------------------------------------------- constantes
    if (dice(['velocidad de la luz'])) {
      return dicho(
        'En el vacío, **299 792 458 m/s**: unos 300 000 km por segundo.',
      );
    }
    if (dice([
      'aceleracion de la gravedad',
      'valor de la gravedad',
      'cuanto vale la gravedad',
      'cuanto es la gravedad',
      'gravedad de la tierra',
    ])) {
      return dicho('En la Tierra, unos **9,81 m/s²**.');
    }
    if (dice(['numero de avogadro', 'constante de avogadro'])) {
      return dicho('**6,022 × 10^23** partículas por mol.');
    }
    if (dice(['cuanto vale pi', 'valor de pi', 'numero pi', 'que es pi'])) {
      return dicho(
        'π ≈ **3,14159265358979**. Es la razón entre la circunferencia de un '
        'círculo y su diámetro, y sus decimales no se acaban nunca.',
      );
    }
    if (dice(['numero e', 'valor de e', 'cuanto vale e', 'numero de euler'])) {
      return dicho(
        'e ≈ **2,71828182845905**, la base de los logaritmos naturales (ln).',
      );
    }
    if (dice(['numero aureo', 'proporcion aurea', 'numero de oro'])) {
      return dicho('φ = (1 + √5) / 2 ≈ **1,6180339887**.');
    }

    // ------------------------------------------------------------- tiempo
    if (dice(['cuantos dias tiene un ano', 'cuantos dias tiene el ano'])) {
      return dicho('**365**, y 366 en los años bisiestos.');
    }
    final diasDelMes = RegExp(
      r'cuantos dias (?:tiene|trae) (?:el mes de |el mes |el |un )?([a-z]+)$',
    ).firstMatch(limpio);
    if (diasDelMes != null) {
      final mes = diasDelMes[1]!;
      if (mes == 'febrero') {
        return dicho(
          '**28**, y **29** en los años bisiestos (uno de cada cuatro, más o '
          'menos).',
        );
      }
      if (const {
        'abril',
        'junio',
        'septiembre',
        'setiembre',
        'noviembre',
      }.contains(mes)) {
        return dicho('**30** días.');
      }
      if (const {
        'enero',
        'marzo',
        'mayo',
        'julio',
        'agosto',
        'octubre',
        'diciembre',
      }.contains(mes)) {
        return dicho('**31** días.');
      }
      if (mes == 'mes') {
        return dicho(
          'Depende: 30 o 31, y febrero 28 (29 en los años bisiestos). Truco: '
          'cuenta con los nudillos de la mano; los nudillos son de 31.',
        );
      }
    }
    if (dice(['cuantos meses tiene un ano', 'cuantos meses tiene el ano'])) {
      return dicho('**12**.');
    }
    if (dice([
      'cuantas semanas tiene un ano',
      'cuantas semanas tiene el ano',
    ])) {
      return dicho('**52 semanas** y un día (dos, si el año es bisiesto).');
    }
    if (dice(['cuantas horas tiene un dia', 'cuantas horas tiene el dia'])) {
      return dicho('**24**.');
    }
    if (dice(['cuantos minutos tiene una hora'])) return dicho('**60**.');
    if (dice(['cuantos minutos tiene un dia'])) return dicho('**1440**.');
    if (dice(['cuantos segundos tiene un minuto'])) return dicho('**60**.');
    if (dice(['cuantos segundos tiene una hora'])) return dicho('**3600**.');
    if (dice(['cuantos segundos tiene un dia'])) return dicho('**86 400**.');

    final bisiesto = RegExp(
      r'(?:(\d{4}) (?:es|fue|sera) bisiesto|bisiesto (?:el )?(?:ano )?(\d{4}))',
    ).firstMatch(limpio);
    if (bisiesto != null) {
      final anio = int.parse(bisiesto[1] ?? bisiesto[2]!);
      final es = anio % 4 == 0 && (anio % 100 != 0 || anio % 400 == 0);
      return dicho(
        es
            ? 'Sí, **$anio** es bisiesto: febrero tiene 29 días.'
            : 'No, **$anio** no es bisiesto.',
      );
    }

    // ------------------------------------------------------------ records
    if (dice(['oceano mas grande'])) return dicho('El **Pacífico**.');
    if (dice(['pais mas grande', 'pais mas grande del mundo'])) {
      return dicho('**Rusia**, por lejos.');
    }
    if (dice(['continente mas grande'])) return dicho('**Asia**.');
    if (dice([
      'montana mas alta',
      'monte mas alto',
      'cerro mas alto del mundo',
    ])) {
      return dicho(
        'El **Everest**, con unos 8849 metros. En Bolivia, el más alto es el '
        'Sajama, con unos 6542.',
      );
    }
    if (dice([
      'pais mas poblado',
      'pais con mas gente',
      'pais con mas habitantes',
    ])) {
      return dicho('**India**, que en 2023 pasó a China.');
    }
    if (dice(['everest', 'cuanto mide el everest'])) {
      return dicho(
        'El **Everest** mide unos **8849 metros**: el más alto del mundo.',
      );
    }
    if (dice([
      'descubrio america',
      'descubrimiento de america',
      'quien llego a america',
    ])) {
      return dicho(
        '**Cristóbal Colón** llegó a América en **1492**. Eso sí, acá ya '
        'vivían millones de personas desde mucho antes.',
      );
    }
    if (dice(['animal mas rapido'])) {
      return dicho(
        'En picada, el **halcón peregrino** (más de 300 km/h). En tierra, el '
        '**guepardo**.',
      );
    }
    if (dice(['animal mas grande'])) return dicho('La **ballena azul**.');
    if (dice(['hueso mas largo'])) return dicho('El **fémur**.');
    if (dice(['cuantos huesos'])) {
      return dicho(
        'Un adulto tiene **206 huesos**. Un bebé nace con unos 300, que se van '
        'uniendo al crecer.',
      );
    }
    if (dice(['cuantos dientes'])) {
      return dicho(
        'Un adulto tiene **32 dientes** (contando las muelas del juicio); un '
        'niño, 20 de leche.',
      );
    }

    // ----------------------------------------------------------- por que
    if (dice(['cielo es azul', 'cielo azul'])) {
      return dicho(
        'Porque la luz del Sol trae todos los colores, y el aire desvía mucho '
        'más el azul que el rojo: ese azul rebotado nos llega de todas partes. '
        'Al atardecer la luz cruza más aire y gana el naranja.',
      );
    }
    if (dice(['mar es salado', 'agua del mar es salada'])) {
      return dicho(
        'Porque los ríos arrastran sales de las rocas hasta el mar, y cuando el '
        'agua se evapora, la sal se queda.',
      );
    }
    if (dice([
      'por que hay estaciones',
      'por que existen las estaciones',
      'estaciones del ano',
    ])) {
      return dicho(
        'Por la inclinación del eje de la Tierra (unos 23,5°): durante el año, '
        'cada hemisferio recibe el Sol más directo o más inclinado. No es por '
        'la distancia al Sol.',
      );
    }
    if (dice(['aviones vuelan', 'vuela un avion', 'avion vuela'])) {
      return dicho(
        'Por la forma de las alas: al avanzar, desvían el aire hacia abajo, y '
        'la diferencia de presión entre arriba y abajo del ala empuja el avión '
        'hacia arriba. Se llama sustentación.',
      );
    }
    if (dice(['arcoiris', 'arco iris'])) {
      return dicho(
        'Las gotas de lluvia separan la luz del Sol en sus colores, como un '
        'prisma. Por eso sale cuando hay sol y lluvia a la vez, con el Sol a '
        'tu espalda.',
      );
    }

    // ------------------------------------------------------------ historia
    final historia = RegExp(
      r'(?:cuando|en que ano) (?:fue|empezo|comenzo|termino|paso|ocurrio|'
      r'llego|cayo|se hizo) (?:la |el |los |las )?(.+)$|'
      r'^(?:que fue|que es) (?:la |el )?(.+)$',
    ).firstMatch(limpio);
    if (historia != null) {
      final evento = (historia[1] ?? historia[2])!.trim();
      final texto = _historia[evento];
      if (texto != null) return dicho(texto);
    }
    if (dice(['rio mas largo'])) {
      return dicho(
        'Se discute entre el **Nilo** y el **Amazonas**: depende de dónde se '
        'mida que empieza cada uno.',
      );
    }
    return null;
  }
}
