import '../modelos/mensaje_macias.dart';
import 'memoria_macias.dart';

/// Lo que MacIAs dejo preguntado: el proximo mensaje se lee primero como la
/// respuesta a eso.
///
/// Sin esto, a "¿y tú, cómo estás?" le seguia un "bien" que no se entendia,
/// y a "¿algo más?" un "no" que caia en "no te entendí". Una persona sabe
/// que pregunto; MacIAs tambien tiene que saberlo.
sealed class EsperaMacias {
  const EsperaMacias();
}

/// Pregunto "¿y tú, qué tal?".
final class EsperaAnimo extends EsperaMacias {
  const EsperaAnimo();
}

/// Pregunto "¿a ti te gusta?".
final class EsperaGusto extends EsperaMacias {
  const EsperaGusto(this.cosa);
  final String cosa;
}

/// Pregunto "¿y el tuyo?" despues de decir su favorito.
final class EsperaFavorito extends EsperaMacias {
  const EsperaFavorito(this.categoria);
  final String categoria;
}

/// Pregunto algo que se contesta con si o no. [para] dice que hacer con el
/// si: `persona`, `algo_mas`, `otro_chiste`, `repaso:<seccion>`...
final class EsperaSiNo extends EsperaMacias {
  const EsperaSiNo(this.para);
  final String para;
}

/// Esta jugando a adivinar un numero.
final class EsperaNumero extends EsperaMacias {
  EsperaNumero(this.secreto, {this.intentos = 0});
  final int secreto;
  int intentos;
}

/// Dijo "piedra, papel o tijera": falta la jugada.
final class EsperaPpt extends EsperaMacias {
  const EsperaPpt();
}

/// Conto una adivinanza: falta la respuesta.
final class EsperaAdivinanza extends EsperaMacias {
  const EsperaAdivinanza(this.respuestas, this.solucion);

  /// Palabras normalizadas que cuentan como acierto.
  final List<String> respuestas;
  final String solucion;
}

/// Pregunto como le fue en un examen.
final class EsperaComoTeFue extends EsperaMacias {
  const EsperaComoTeFue(this.examen);
  final ExamenMacias examen;
}

/// Le contaron de un examen sin fecha: pregunto cuando es.
final class EsperaFechaExamen extends EsperaMacias {
  const EsperaFechaExamen(this.materia, {this.tipo = 'examen'});
  final String materia;
  final String tipo;
}

/// Pregunto que paso, despues de que la persona dijo que estaba mal.
final class EsperaDesahogo extends EsperaMacias {
  const EsperaDesahogo();
}

/// Pregunto que estudia.
final class EsperaCarrera extends EsperaMacias {
  const EsperaCarrera();
}

/// Lo que contesta la charla, y lo que deja preguntado.
class RespuestaCharla {
  const RespuestaCharla(
    this.texto, {
    required this.intencion,
    this.espera,
    this.opciones = const [],
    this.acciones = const [],
    this.sugerencias,
  });

  final String texto;

  /// Que se entendio, como `charla:insulto` o `util:fecha`. Sirve para las
  /// pruebas y para saber que se entendio sin leer el texto.
  final String intencion;
  final EsperaMacias? espera;
  final List<OpcionMacias> opciones;
  final List<AccionMacias> acciones;

  /// Los atajos de abajo. Null: los de siempre.
  final List<OpcionMacias>? sugerencias;

  /// La misma respuesta con algo dicho antes: "¡Hola, Ana! " + respuesta.
  RespuestaCharla conPrefijo(String prefijo) => RespuestaCharla(
    '$prefijo$texto',
    intencion: intencion,
    espera: espera,
    opciones: opciones,
    acciones: acciones,
    sugerencias: sugerencias,
  );
}
