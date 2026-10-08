import 'dart:math';

/// Una palabra de lo que se escribio, ya normalizada, y donde estaba.
///
/// Guardar donde estaba permite cortar el texto original sin perder sus
/// tildes ni sus signos: "hola, ¿cuánto es 2+2?" se contesta como
/// "¿cuánto es 2+2?", con el + intacto.
class FichaTexto {
  const FichaTexto(this.normal, this.original, this.inicio, this.fin);

  final String normal;
  final String original;
  final int inicio;
  final int fin;
}

/// Como lee MacIAs lo que se le escribe.
///
/// En un chat nadie escribe como en un examen: sin tildes, con letras de mas
/// ("holaaa"), con abreviaturas ("q", "xq", "tqm"), riendose de mil maneras
/// ("jsjs", "xD"). Todo eso se lleva a una sola forma antes de entenderlo.
abstract final class LenguajeMacias {
  static const _tildes = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };

  /// Minusculas, sin tildes ni signos, espacios simples.
  ///
  /// "¿Cómo PUBLICO algo?!" y "como publico algo" tienen que ser lo mismo. Y
  /// "holaaaa" es "hola", "jajajaja" es "jaja".
  static String normalizar(String texto) {
    final salida = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final sinTilde = _tildes[letra] ?? letra;
      final codigo = sinTilde.codeUnitAt(0);
      final esValida =
          (codigo >= 0x61 && codigo <= 0x7a) ||
          (codigo >= 0x30 && codigo <= 0x39);
      salida.write(esValida ? sinTilde : ' ');
    }
    return salida
        .toString()
        .split(' ')
        .where((palabra) => palabra.isNotEmpty)
        .map(_palabraLimpia)
        .join(' ');
  }

  /// Las palabras del texto original, normalizadas y con su lugar.
  static List<FichaTexto> fichas(String original) => [
    for (final m in _palabra.allMatches(original))
      for (final normal in normalizar(m[0]!).split(' '))
        if (normal.isNotEmpty) FichaTexto(normal, m[0]!, m.start, m.end),
  ];

  static final _palabra = RegExp(r'[\p{L}\p{N}]+', unicode: true);

  /// "jajaja", "jsjsjs", "xD", "lol": todas son la misma risa.
  static final _risa = RegExp(
    r'^(?:a?([jh])[aeiou]+(?:\1[aeiou]+)+\1?|(?:js){2,}j?|x+d+|lol|lmao|lmfao|k{4,})$',
  );

  /// Las pocas palabras que si terminan en doble letra: "poo" (programacion
  /// orientada a objetos), "zoo".
  static const _dobleAlFinal = {'poo', 'zoo'};

  static String _palabraLimpia(String palabra) {
    if (_risa.hasMatch(palabra)) return 'jaja';
    // "mmm", "hmmm": pensando. Sin esto quedaria "m", que es "me".
    if (palabra.length >= 2 && RegExp(r'^h?m+$').hasMatch(palabra)) {
      return 'mmm';
    }
    // Los numeros no se tocan: "1000" no es "10".
    if (RegExp(r'\d').hasMatch(palabra)) return palabra;
    // "holaaaa" -> "hola", "siiii" -> "si".
    var limpia = palabra.replaceAllMapped(
      RegExp(r'([a-z])\1{2,}'),
      (m) => m[1]!,
    );
    // "holaa", "graciass": una vocal o una s doble al final sobra. En
    // castellano casi ninguna palabra termina asi (la e se respeta: "lee").
    // (La s doble no: "Gauss" y "CSS" la llevan de verdad. "graciass" y
    // compania estan en las abreviaturas.)
    final ultima = limpia.isEmpty ? '' : limpia[limpia.length - 1];
    if (limpia.length > 2 &&
        !_dobleAlFinal.contains(limpia) &&
        ultima == limpia[limpia.length - 2] &&
        'aiou'.contains(ultima)) {
      limpia = limpia.substring(0, limpia.length - 1);
    }
    return limpia;
  }

  /// Abreviaturas de chat que cambian el sentido si no se entienden.
  static const abreviaturas = {
    'q': 'que',
    'k': 'que',
    'ke': 'que',
    // "m gustas", "t quiero".
    'm': 'me',
    't': 'te',
    'xq': 'porque',
    'pq': 'porque',
    'porq': 'porque',
    'xk': 'porque',
    'x': 'por',
    'd': 'de',
    'tb': 'tambien',
    'tmb': 'tambien',
    'tbn': 'tambien',
    'pa': 'para',
    'porfa': 'por favor',
    'porfis': 'por favor',
    'xfa': 'por favor',
    'xfavor': 'por favor',
    'plis': 'por favor',
    'pls': 'por favor',
    'plz': 'por favor',
    'ola': 'hola',
    'holi': 'hola',
    'holis': 'hola',
    'wenas': 'buenas',
    'wena': 'buena',
    'wsp': 'whatsapp',
    'wpp': 'whatsapp',
    'whats': 'whatsapp',
    'wasap': 'whatsapp',
    'whatsap': 'whatsapp',
    'guasap': 'whatsapp',
    'notis': 'notificaciones',
    'noti': 'notificacion',
    'cel': 'celular',
    'info': 'informacion',
    'bn': 'bien',
    'dnd': 'donde',
    'cdo': 'cuando',
    'cmo': 'como',
    'tqm': 'te quiero mucho',
    'tkm': 'te quiero mucho',
    'tq': 'te quiero',
    'msj': 'mensaje',
    'msjs': 'mensajes',
    'grax': 'gracias',
    'graciass': 'gracias',
    'buenass': 'buenas',
    'besoss': 'besos',
    'saludoss': 'saludos',
    'grs': 'gracias',
    'grcs': 'gracias',
    'grasias': 'gracias',
    'gracia': 'gracias',
    'grasia': 'gracias',
    'thx': 'gracias',
    'thanks': 'gracias',
    'ty': 'gracias',
    'toy': 'estoy',
    'tas': 'estas',
    'tamos': 'estamos',
    'aki': 'aqui',
    'salu2': 'saludos',
    'dsp': 'despues',
    'desp': 'despues',
    'sip': 'si',
    'sep': 'si',
    'nop': 'no',
    'nel': 'no',
    'nope': 'no',
    'nah': 'no',
    'na': 'no',
    'oki': 'ok',
    'okk': 'ok',
    'okis': 'ok',
    'okey': 'ok',
    'okay': 'ok',
    'oka': 'ok',
    'ntp': 'no te preocupes',
    'nose': 'no se',
    'nse': 'no se',
    'ns': 'no se',
    'bs': 'bolivianos',
    // La d esta al lado de la s: "dabes hacer bife".
    'dabes': 'sabes',
    'profe': 'profesor',
    'uni': 'universidad',
  };

  /// Las palabras del mensaje, con las abreviaturas ya escritas enteras.
  static List<String> palabrasDe(String limpio) => [
    for (final palabra in limpio.split(' '))
      if (palabra.isNotEmpty) ...(abreviaturas[palabra] ?? palabra).split(' '),
  ];

  /// Palabras que no dicen de que se habla: articulos, pronombres, verbos de
  /// todos los dias. Sirven para no proponer temas por un "que" suelto.
  static const vacias = {
    'a',
    'al',
    'algo',
    'alguien',
    'asi',
    'como',
    'con',
    'cual',
    'cuando',
    'cuanto',
    'cuanta',
    'cuantos',
    'cuantas',
    'de',
    'del',
    'donde',
    'el',
    'ella',
    'en',
    'entonces',
    'era',
    'eres',
    'es',
    'esa',
    'ese',
    'eso',
    'esta',
    'estan',
    'este',
    'esto',
    'estoy',
    'fue',
    'ha',
    'hace',
    'hacer',
    'hago',
    'hay',
    'la',
    'las',
    'le',
    'les',
    'lo',
    'los',
    'mas',
    'me',
    'mi',
    'mis',
    'muy',
    'no',
    'nos',
    'o',
    'para',
    'pero',
    'por',
    'porque',
    'pues',
    'puede',
    'puedo',
    'puedes',
    'que',
    'quien',
    'quiero',
    'quieres',
    'sabe',
    'sabes',
    'tienes',
    'se',
    'ser',
    'si',
    'sin',
    'sobre',
    'son',
    'su',
    'sus',
    'tambien',
    'te',
    'tengo',
    'ti',
    'tiene',
    'tu',
    'tus',
    'un',
    'una',
    'uno',
    'unos',
    'unas',
    'y',
    'ya',
    'yo',
  };

  /// Cuanto se parece un mensaje a un tema.
  ///
  /// Cada clave que aparece suma; una frase de dos palabras pesa el doble
  /// que una suelta, porque "borrar cuenta" dice mucho mas que "cuenta". Las
  /// palabras de la frase pueden estar en cualquier orden. Lo que coincide
  /// solo de forma aproximada (con una falta) suma menos.
  static double puntaje(
    List<String> claves,
    List<String> palabras, {
    Set<String> conocidas = const {},
  }) {
    var total = 0.0;
    for (final clave in claves) {
      final partes = clave.split(' ');
      var minimo = 1.0;
      for (final parte in partes) {
        final coincidencia = coincide(parte, palabras, conocidas: conocidas);
        if (coincidencia < minimo) minimo = coincidencia;
        if (minimo == 0) break;
      }
      if (minimo > 0) total += partes.length * minimo;
    }
    return total;
  }

  /// Palabras que empiezan como una clave pero no tienen nada que ver:
  /// "fotocopias" no es "fotos", "comprobar" no es "comprar".
  static const _noSonDeLaClave = {
    'fotocopia',
    'fotocopias',
    'fotocopiar',
    'fotosintesis',
    'compromiso',
    'compromisos',
    'comprension',
    'comprobar',
    'compruebo',
    'comprobante',
    'tallarin',
    'tallarines',
    'publicidad',
    'bloqueo',
    'bloquear',
    'bloqueado',
    'bloqueada',
  };

  /// 1 si alguna palabra es la clave (o empieza con ella, si termina en `*`),
  /// 0.7 si se le parece con una sola letra de diferencia, 0 si no.
  ///
  /// Lo aproximado solo vale en palabras largas: entre palabras cortas una
  /// letra cambia el sentido ("marco" y "marca", "tonto" y "tanto"). Y no
  /// vale para las [conocidas]: "cálculo" es una palabra de verdad, no
  /// "calcula" mal escrito.
  static double coincide(
    String clave,
    List<String> palabras, {
    Set<String> conocidas = const {},
  }) {
    final prefijo = clave.endsWith('*');
    final raiz = prefijo ? clave.substring(0, clave.length - 1) : clave;
    var mejor = 0.0;
    for (final palabra in palabras) {
      // Una clave con * acepta terminaciones ("publicaciones"), no palabras
      // enteras que solo empiezan igual ("fotosintecis" no es "fotos").
      if (prefijo
          ? palabra.startsWith(raiz) &&
                palabra.length - raiz.length <= 7 &&
                !_noSonDeLaClave.contains(palabra)
          : palabra == raiz) {
        return 1;
      }
      if (raiz.length < 6 || palabra.length < 5) continue;
      if (conocidas.contains(palabra)) continue;
      if (prefijo) {
        for (var largo = raiz.length - 1; largo <= raiz.length + 1; largo++) {
          if (largo > palabra.length) break;
          if (distancia(palabra.substring(0, largo), raiz) <= 1) {
            mejor = .7;
          }
        }
      } else if (distancia(palabra, raiz) <= 1) {
        mejor = .7;
      }
    }
    return mejor;
  }

  /// Donde aparece una frase ("no me entiendes") dentro de las palabras,
  /// como rangos [inicio, fin). Una palabra larga escrita con una falta
  /// tambien cuenta.
  static List<(int, int)> buscar(List<String> palabras, String frase) {
    final partes = frase.split(' ');
    final encontradas = <(int, int)>[];
    for (var i = 0; i + partes.length <= palabras.length; i++) {
      var coinciden = true;
      for (var k = 0; k < partes.length; k++) {
        if (!_igual(palabras[i + k], partes[k])) {
          coinciden = false;
          break;
        }
      }
      if (coinciden) encontradas.add((i, i + partes.length));
    }
    return encontradas;
  }

  static bool contiene(List<String> palabras, String frase) =>
      buscar(palabras, frase).isNotEmpty;

  /// Palabras de verdad que estan a una letra de otra que importa: "idioma"
  /// no es "idiota" mal escrito, ni "hombre" es "hambre".
  static const _noSonFaltas = {
    'idioma',
    'idiomas',
    'hombre',
    'hombres',
    'gustan',
    'gusten',
    'titulo',
    'titulos',
  };

  /// Igual, o con una falta de tipeo. Una letra de mas o de menos solo se
  /// perdona en palabras largas, y nunca si es la s final: "gustas" y
  /// "gusta" dicen cosas distintas.
  static bool _igual(String palabra, String parte) {
    if (parte.endsWith('*')) {
      return palabra.startsWith(parte.substring(0, parte.length - 1));
    }
    if (palabra == parte) return true;
    if (parte.length < 6 || palabra.length < 5) return false;
    if (_noSonFaltas.contains(palabra)) return false;
    if (palabra.length != parte.length) {
      if (parte.length < 8) return false;
      if ('${palabra}s' == parte || '${parte}s' == palabra) return false;
    }
    return distancia(palabra, parte) <= 1;
  }

  /// Distancia de edicion con transposiciones: "pulbicar" esta a 1 de
  /// "publicar", porque intercambiar dos letras vecinas es la falta mas
  /// comun al escribir rapido.
  static int distancia(String a, String b) {
    if ((a.length - b.length).abs() > 1) return 2;
    final filas = List.generate(
      a.length + 1,
      (i) => List<int>.filled(b.length + 1, 0),
    );
    for (var i = 0; i <= a.length; i++) {
      filas[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      filas[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final costo = a[i - 1] == b[j - 1] ? 0 : 1;
        var valor = min(
          min(filas[i - 1][j] + 1, filas[i][j - 1] + 1),
          filas[i - 1][j - 1] + costo,
        );
        if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
          valor = min(valor, filas[i - 2][j - 2] + 1);
        }
        filas[i][j] = valor;
      }
    }
    return filas[a.length][b.length];
  }

  /// Lo que dijo la persona, dicho de vuelta: "tengo que comprar mis
  /// fotocopias" queda "tienes que comprar tus fotocopias".
  static String reflejar(String texto) => texto.replaceAllMapped(_palabra, (m) {
    final palabra = m[0]!;
    final reflejo = _reflejos[normalizar(palabra)];
    if (reflejo == null) return palabra;
    final mayuscula = palabra[0] != palabra[0].toLowerCase();
    return mayuscula
        ? reflejo[0].toUpperCase() + reflejo.substring(1)
        : reflejo;
  });

  static const _reflejos = {
    'yo': 'tú',
    'mi': 'tu',
    'mis': 'tus',
    'me': 'te',
    'conmigo': 'contigo',
    'tengo': 'tienes',
    'debo': 'debes',
    'estoy': 'estás',
    'soy': 'eres',
    'voy': 'vas',
    'puedo': 'puedes',
    'quiero': 'quieres',
    'necesito': 'necesitas',
    'hago': 'haces',
    'tenia': 'tenías',
    'mio': 'tuyo',
    'mia': 'tuya',
  };

  /// La primera letra en mayuscula: "salteña" -> "Salteña".
  static String conMayuscula(String texto) =>
      texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);
}
