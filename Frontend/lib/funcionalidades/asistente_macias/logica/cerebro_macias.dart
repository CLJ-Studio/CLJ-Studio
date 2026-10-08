import 'dart:math';

import '../modelos/mensaje_macias.dart';
import 'charla_macias.dart';
import 'conocimiento_macias.dart';
import 'conversacion_macias.dart';
import 'ejercicios_macias.dart';
import 'enciclopedia_macias.dart';
import 'lenguaje_macias.dart';
import 'matematica_macias.dart';
import 'memoria_macias.dart';
import 'saber_general_macias.dart';
import 'universidad_macias.dart';
import 'utilidades_macias.dart';

/// Un mensaje listo para entender: el texto como llego, sus palabras
/// normalizadas y donde estaba cada una.
class _Mensaje {
  _Mensaje(this.original, this.fichas)
    : limpio = fichas.map((f) => f.normal).join(' '),
      todas = LenguajeMacias.palabrasDe(fichas.map((f) => f.normal).join(' ')),
      palabras = CharlaMacias.sinPalabrotas(
        LenguajeMacias.palabrasDe(fichas.map((f) => f.normal).join(' ')),
      ).palabras;

  factory _Mensaje.de(String original) =>
      _Mensaje(original, LenguajeMacias.fichas(original));

  final String original;
  final List<FichaTexto> fichas;

  /// Normalizado, una palabra por ficha.
  final String limpio;

  /// Con las abreviaturas escritas enteras, palabrotas incluidas: "bot de
  /// mierda" es un insulto, y para saberlo hay que leerlo entero.
  final List<String> todas;

  /// Con las abreviaturas escritas enteras y sin palabrotas: "no entiendo
  /// ni mierda de cálculo" es una pregunta de cálculo.
  final List<String> palabras;

  String get junto => palabras.join(' ');
}

/// Entiende lo que se le escribe a MacIAs y decide que contestar.
///
/// NO ES UNA IA GENERATIVA. No manda nada a ningun servidor y no inventa:
/// cada respuesta esta escrita a mano (ver `ConocimientoMacias` y
/// `CharlaMacias`), y las cuentas se hacen de verdad (ver
/// `MatematicaMacias`). Un asistente "verificado" que alucina una funcion
/// que no existe hace mas dano que no tener asistente.
///
/// Lo que si hace es entender como escribe la gente: sin tildes, con faltas,
/// con abreviaturas de chat, con un "hola" adelante o con un numero suelto
/// que se refiere a la ultima lista que vio. Y se acuerda: de la persona
/// (nombre, carrera, gustos, examenes, lo que pidio recordar) y de lo que
/// se estaba hablando, incluida la ultima pregunta que hizo MacIAs.
///
/// El orden de las preguntas importa, y es a proposito: primero lo que no
/// admite dudas (una crisis, la respuesta a lo que MacIAs pregunto, un
/// numero, una cuenta), despues la charla que ocupa todo el mensaje, despues
/// lo que la persona cuenta de si, despues lo que MacIAs sabe de la app y
/// las materias, y solo al final la charla suelta. Lo que ya sabe tiene
/// prioridad sobre conversar.
class CerebroMacias {
  CerebroMacias({required this.contexto, MemoriaMacias? memoria, Random? azar})
    : memoria = memoria ?? MemoriaMacias(),
      _azar = azar ?? Random();

  /// Quien habla y cuando: se pide de nuevo en cada respuesta, porque la
  /// conversacion puede durar de la tarde a la noche.
  final ContextoMacias Function() contexto;

  /// Lo que se sabe de la persona. Lo guarda el controlador.
  final MemoriaMacias memoria;

  final Random _azar;

  /// La ultima lista numerada que se mostro: a ella se refiere un numero.
  List<OpcionMacias> _vigentes = ConocimientoMacias.menuPrincipal;

  /// La seccion que se estaba mirando, para "volver".
  String? _seccionActual;

  /// Si lo ultimo fue abrir una seccion (y no responder un tema dentro de
  /// ella): "volver" sube un nivel mas.
  bool _ultimoFueSeccion = false;

  /// El ultimo tema respondido: a el se refieren "otro ejemplo" o "no
  /// entendí".
  String? _ultimoTema;

  /// Lo que MacIAs dejo preguntado.
  EsperaMacias? _espera;

  /// Cuantas veces seguidas no se entendio. A la segunda se ofrece una
  /// persona: insistir con lo mismo solo frustra.
  int _sinEntender = 0;

  RespuestaMacias? _ultimaRespuesta;
  String? _ultimaIntencion;

  /// Lo ultimo que dijo, para no repetir frases.
  final _recientes = <String>[];

  // ------------------------------------------------------------- opciones
  static const _opcionMenu = OpcionMacias(
    id: 'o:menu',
    texto: 'Menú principal',
  );
  static const chipMenu = OpcionMacias(id: 'o:menu', texto: 'Menú');
  static const chipPersona = OpcionMacias(
    id: 't:${ConocimientoMacias.humano}',
    texto: 'Hablar con una persona',
  );
  static const chipMaterias = OpcionMacias(id: 's:extra', texto: 'Materias');
  static const chipSirvio = OpcionMacias(id: 'o:util', texto: 'Me sirvió');
  static const chipNoSirvio = OpcionMacias(
    id: 'o:no_util',
    texto: 'No me sirvió',
  );
  static const chipOtroEjemplo = OpcionMacias(
    id: 'o:ampliar',
    texto: 'Otro ejemplo',
  );

  static const _sugerenciasBase = [chipMenu, chipMaterias, chipPersona];

  /// La ultima lista numerada que se mostro. Solo para pruebas.
  List<OpcionMacias> get opcionesVigentes => List.unmodifiable(_vigentes);

  /// Lo que MacIAs dejo preguntado. Solo para pruebas.
  EsperaMacias? get espera => _espera;

  /// Al reabrir una conversacion guardada: los numeros vuelven a referirse
  /// a la ultima lista que se ve en pantalla.
  void retomar(List<OpcionMacias> ultimaLista) {
    if (ultimaLista.isNotEmpty) _vigentes = ultimaLista;
  }

  // =============================================================== entradas
  /// Lo primero que dice MacIAs en una conversacion nueva.
  RespuestaMacias bienvenida() {
    _sinEntender = 0;
    _seccionActual = null;
    _ultimoTema = null;
    _espera = null;
    final c = _nuevoContexto();
    final saludo = memoria.nombre != null
        ? '¡Hola de nuevo, ${c.nombre}! Qué bueno verte por acá.'
        : '¡${c.saludoDelMomento}, ${c.nombre}! Soy **MacIAs**, el asistente '
              'de U market.';
    final novedad = _novedad(c);
    final espera = _espera;
    final respuesta = _conMenu(
      [BurbujaMacias(novedad == null ? saludo : '$saludo\n\n$novedad')],
      'Te ayudo con la app y también a estudiar: álgebra, cálculo integral y '
      'C++. Hago cuentas, resuelvo ecuaciones y charlamos de lo que '
      'quieras.\n'
      '**Toca una opción, escribe su número o pregúntame con tus palabras:**',
      intencion: 'bienvenida',
    );
    _espera = espera;
    return _recordar(respuesta);
  }

  /// Al volver a una conversacion guardada: si hay algo que decir (un
  /// cumpleaños, un examen, un recordatorio), MacIAs lo dice primero.
  RespuestaMacias? alVolver() {
    final novedad = _novedad(_nuevoContexto());
    if (novedad == null) return null;
    return _recordar(
      RespuestaMacias(
        [BurbujaMacias(novedad)],
        sugerencias: _sugerenciasBase,
        intencion: 'memoria:novedad',
      ),
    );
  }

  /// Algo que la persona escribio con sus palabras.
  RespuestaMacias escribir(String texto) {
    final respuesta = _entender(texto.trim());
    if (respuesta.intencion != 'no_entendi') _sinEntender = 0;
    return _recordar(respuesta);
  }

  /// Algo que la persona toco: una linea de una lista o un atajo.
  RespuestaMacias elegir(OpcionMacias opcion) {
    _sinEntender = 0;
    return _recordar(_elegir(opcion));
  }

  RespuestaMacias _elegir(OpcionMacias opcion) {
    _espera = null;
    final c = _nuevoContexto();
    final separador = opcion.id.indexOf(':');
    final tipo = separador < 0 ? '' : opcion.id.substring(0, separador);
    final valor = separador < 0
        ? opcion.id
        : opcion.id.substring(separador + 1);
    switch (tipo) {
      case 's':
        final seccion = ConocimientoMacias.seccion(valor);
        if (seccion != null) return _abrirSeccion(seccion);
      case 't':
        final tema = ConocimientoMacias.tema(valor);
        if (tema != null) return _responderTema(tema);
      case 'o':
        switch (valor) {
          case 'menu':
            return menu();
          case 'volver':
            return volver();
          case 'util':
            return _sirvio();
          case 'no_util':
            return _noSirvio();
          case 'ampliar':
            return _ampliar();
          case 'juegos':
            return _deCharla(AzarMacias.menuJuegos());
          case 'juego_numero':
            return _deCharla(AzarMacias.numero(_azar));
          case 'juego_ppt':
            return _deCharla(AzarMacias.ppt());
          case 'juego_adivinanza':
            return _deCharla(CharlaMacias.adivinanza(c));
          case 'juego_moneda':
            return _deCharla(AzarMacias.moneda(_azar));
          case 'juego_dado':
            return _deCharla(AzarMacias.dados(_azar, 1));
          case 'ppt_piedra' || 'ppt_papel' || 'ppt_tijera':
            return _deCharla(AzarMacias.jugarPpt(valor.substring(4), _azar));
          case 'meme':
            // De una conversacion guardada cuando existia el modo meme.
            return _deCharla(
              const RespuestaCharla(
                'El modo meme se jubiló: ahora hablo así, relajado, todo el '
                'tiempo. Si quieres reírte, pídeme un **chiste**.',
                intencion: 'charla:meme',
              ),
            );
        }
    }
    return menu();
  }

  RespuestaMacias menu() {
    _seccionActual = null;
    _ultimoFueSeccion = false;
    final c = _nuevoContexto();
    final entrada = c.alguna(const [
      'Aquí tienes todo:',
      '¡Dale! Esto es lo que sé:',
      'Vamos al menú:',
    ]);
    return _conMenu(
      const [],
      '$entrada\n**Toca una opción o escribe su número:**',
      intencion: 'menu',
    );
  }

  RespuestaMacias volver() {
    final actual = _seccionActual == null
        ? null
        : ConocimientoMacias.seccion(_seccionActual!);
    if (actual == null) return menu();
    // Desde un tema se vuelve a su seccion; desde una seccion, a la de
    // arriba.
    if (_ultimoFueSeccion) {
      final padre = actual.padre == null
          ? null
          : ConocimientoMacias.seccion(actual.padre!);
      return padre == null ? menu() : _abrirSeccion(padre);
    }
    return _abrirSeccion(actual);
  }

  // ============================================================ entender
  RespuestaMacias _entender(String original) {
    final espera = _espera;
    _espera = null;
    final c = _nuevoContexto();
    final limpio = LenguajeMacias.normalizar(original);

    // Lo primero, siempre: aunque este a mitad de un juego.
    final cuidado = CharlaMacias.cuidado(limpio);
    if (cuidado != null) {
      return RespuestaMacias(
        [BurbujaMacias(cuidado)],
        sugerencias: const [chipPersona],
        intencion: 'cuidado',
      );
    }
    if (limpio.isEmpty) return _sinPalabras(original, c);

    final m = _Mensaje.de(original);
    if (m.palabras.isEmpty) return _deCharla(CharlaMacias.soloPalabrotas(c));

    if (espera != null) {
      final respuesta = _atenderEspera(espera, m, c);
      if (respuesta != null) return respuesta;
    }

    final numero = int.tryParse(m.limpio);
    if (numero != null) return _porNumero(numero);

    final cuenta = _cuentas(m.original);
    if (cuenta != null) return cuenta;

    final inapropiado = CharlaMacias.inapropiado(m.palabras, c);
    if (inapropiado != null) return _deCharla(inapropiado);

    final memoriaPedida = _sobreLaMemoria(m, c);
    if (memoriaPedida != null) return memoriaPedida;

    // "¿Qué?", "¿cómo?" sueltos: no se entendio lo ultimo que dijo MacIAs.
    if (_soloInterrogativo.contains(m.junto)) {
      return _social(
        const RespuestaCharla('', intencion: 'charla:confusion'),
        c,
      );
    }

    // Todo el mensaje es charla: "jaja ok", "hola, ¿cómo estás?", "cállate".
    final social = CharlaMacias.social(m.todas, c);
    if (social != null) return _social(social, c);

    // "Hola, ¿cómo publico?", "gracias! y ¿cómo pago?": se contesta lo que
    // va despues, sin ignorar lo de adelante.
    final (resto: resto, saludo: saludo, gracias: gracias) = _quitarPrefijos(m);
    final RespuestaMacias respuesta;
    if (resto.palabras.isEmpty) {
      respuesta = _deCharla(
        const RespuestaCharla('¿Sí? Dime nomás.', intencion: 'charla:atencion'),
      );
    } else {
      final contenido = _contenido(
        resto,
        c,
        espera,
        recortado: !identical(resto, m),
      );
      // "Gracias por escucharme", "gracias por la info": es un gracias,
      // aunque lo de despues no sea una pregunta.
      if (contenido == null &&
          gracias &&
          resto.palabras.first == 'por' &&
          resto.palabras.length <= 5) {
        return _social(CharlaMacias.social(const ['gracias'], c)!, c);
      }
      respuesta = contenido ?? _noEntendi(resto, c);
    }
    // "Hola, me llamo Carla": el saludo ya va con el nombre nuevo.
    if (saludo &&
        (respuesta.intencion == 'memoria:nombre' ||
            respuesta.intencion == 'memoria:varios')) {
      return _conPrefijo(respuesta, '¡Hola! ');
    }
    if (saludo) return _conPrefijo(respuesta, '¡Hola, ${c.nombre}! ');
    if (gracias) return _conPrefijo(respuesta, '¡De nada! ');
    return respuesta;
  }

  RespuestaMacias? _contenido(
    _Mensaje m,
    ContextoMacias c,
    EsperaMacias? espera, {
    required bool recortado,
  }) {
    final junto = m.junto;
    final orden = _orden(junto);
    if (orden != null) return orden;

    if (recortado) {
      final cuenta = _cuentas(m.original);
      if (cuenta != null) return cuenta;
    }

    final dato = _datoPersonal(m, c);
    if (dato != null) return dato;

    // Despues de "¿quieres contarme?", lo que cuente se escucha antes que
    // buscarle un tema de la app.
    if (espera is EsperaDesahogo &&
        !CharlaMacias.esPregunta(m.original, m.limpio)) {
      final animo = CharlaMacias.animoEnFrase(m.palabras, c);
      return _deCharla(animo ?? CharlaMacias.desahogo(c));
    }

    final util =
        FechasMacias.responder(junto, c) ??
        AzarMacias.responder(m.limpio, m.fichas, m.original, _azar) ??
        SaberGeneralMacias.responder(junto);
    if (util != null) return _deCharla(util);

    final antes = CharlaMacias.antesDeLosTemas(junto, c);
    if (antes != null) return _social(antes, c);

    // La U: tramites, el campus, los profes. Va antes que los temas: "el
    // wifi de la U" no es una pregunta de la app.
    final universidad = UniversidadMacias.responder(junto, c);
    if (universidad != null) return _deCharla(universidad);

    // "Factorial en C++", "programa que diga si es primo".
    final ejercicio = EjerciciosMacias.responder(junto);
    if (ejercicio != null) {
      _seccionActual = 'cpp';
      return _deCharla(ejercicio, sugerencias: const [chipMaterias, chipMenu]);
    }

    // "¿Qué significa PIB?", "¿dónde queda Samaipata?": una pregunta de
    // definicion que la enciclopedia sabe va antes que los temas de la app,
    // que solo compartirian una palabra suelta ("significa", "dónde queda").
    final definicion = EnciclopediaMacias.responder(
      junto,
      c,
      soloPreguntas: true,
    );
    if (definicion != null) return _deCharla(definicion);

    final sabido = _porSeccion(m.palabras) ?? _porTemas(m.palabras);
    if (sabido != null) return sabido;

    final enciclopedia = EnciclopediaMacias.responder(junto, c);
    if (enciclopedia != null) return _deCharla(enciclopedia);

    final charla =
        CharlaMacias.despuesDeLosTemas(junto, c) ??
        CharlaMacias.animoEnFrase(m.palabras, c) ??
        CharlaMacias.socialEnFrase(m.todas, c);
    if (charla != null) return _social(charla, c);

    if (_pareceTecleo(m.palabras)) {
      return _deCharla(
        const RespuestaCharla(
          '¿Se te cayó el teléfono en el teclado? Jaja. Escríbeme tu duda '
          'cuando quieras.',
          intencion: 'charla:tecleo',
        ),
      );
    }
    return null;
  }

  RespuestaMacias? _cuentas(String original) {
    final rapida = CuentasRapidasMacias.responder(original);
    if (rapida != null) {
      _ultimoTema = 'calculadora';
      return _deCharla(rapida, sugerencias: const [chipMenu, chipMaterias]);
    }
    final cuenta = MatematicaMacias.responder(original);
    if (cuenta != null) return _cuenta(cuenta);
    return null;
  }

  // ============================================================== esperas
  RespuestaMacias? _atenderEspera(
    EsperaMacias espera,
    _Mensaje m,
    ContextoMacias c,
  ) {
    switch (espera) {
      case EsperaNumero():
        final numero = RegExp(r'\b(\d{1,4})\b').firstMatch(m.limpio);
        if (numero != null) {
          return _deCharla(
            AzarMacias.intentoNumero(espera, int.parse(numero[1]!)),
          );
        }
        if (_seRinde(m)) {
          return _deCharla(
            RespuestaCharla(
              'Era el **${espera.secreto}**. ¡La próxima sale! ¿Otra '
              'partida?',
              intencion: 'juego:numero',
              espera: const EsperaSiNo('numero'),
            ),
          );
        }
        return null;
      case EsperaPpt():
        final jugada = AzarMacias.jugadaEn(m.limpio);
        if (jugada == null) return null;
        return _deCharla(AzarMacias.jugarPpt(jugada, _azar));
      case EsperaAdivinanza(:final respuestas, :final solucion):
        if (_seRinde(m)) {
          return _deCharla(
            RespuestaCharla(
              'Era **$solucion**. ¿Otra?',
              intencion: 'juego:adivinanza',
              espera: const EsperaSiNo('adivinanza'),
            ),
          );
        }
        if (respuestas.any(m.palabras.contains)) {
          return _deCharla(
            RespuestaCharla(
              '¡Correcto! Era **$solucion**. ¿Otra?',
              intencion: 'juego:adivinanza',
              espera: const EsperaSiNo('adivinanza'),
            ),
          );
        }
        if (m.palabras.length <= 4 &&
            !CharlaMacias.esPregunta(m.original, m.limpio)) {
          return _deCharla(
            RespuestaCharla(
              'Mmm, no. Era **$solucion**. ¿Otra?',
              intencion: 'juego:adivinanza',
              espera: const EsperaSiNo('adivinanza'),
            ),
          );
        }
        return null;
      case EsperaGusto(:final cosa):
        final siNo = CharlaMacias.respuestaSiNo(m.limpio);
        if (siNo == null) return null;
        return _anotarGusto(CharlaMacias.conTildes(cosa), siNo);
      case EsperaFavorito(:final categoria):
        if (m.palabras.length > 6 ||
            CharlaMacias.esPregunta(m.original, m.limpio)) {
          return null;
        }
        if (CharlaMacias.respuestaSiNo(m.limpio) == false) {
          return _simple('Tranqui, otro día me cuentas.');
        }
        final cosa = CharlaMacias.loQueDijo(m.limpio, m.fichas, m.original);
        if (cosa.isEmpty) return null;
        memoria.anotarFavorito(categoria, cosa);
        return _simple(
          'Anotado: tu ${CharlaMacias.nombreCategoria(categoria)} '
          'favorit${CharlaMacias.esMasculina(categoria) ? 'o' : 'a'} es '
          '$cosa. Buen gusto.',
          intencion: 'memoria:favorito',
        );
      case EsperaSiNo(:final para):
        // A "¿algo más?" despues de un chiste, "otro" es otro chiste, no
        // un "sí, otra cosa".
        if (para == 'algo_mas' &&
            _ultimoTema != null &&
            _pedidosDeAmpliar.contains(m.junto)) {
          return _ampliar();
        }
        final siNo = CharlaMacias.respuestaSiNo(m.limpio);
        if (siNo == null) return null;
        return _siNo(para, siNo, c);
      case EsperaAnimo():
        final animo = CharlaMacias.respuestaAnimo(m.palabras, c);
        return animo == null ? null : _social(animo, c);
      case EsperaComoTeFue(:final examen):
        examen.preguntado = true;
        return _comoTeFue(m, examen, c);
      case EsperaFechaExamen(:final materia, :final tipo):
        final fecha = FechasMacias.fechaEn(m.junto, c.ahora);
        if (fecha == null) return null;
        return _anotarExamen(materia, fecha, c, tipo: tipo);
      case EsperaCarrera():
        final carrera = MemoriaMacias.carreraDe(m.junto);
        if (carrera == null) return null;
        memoria.carrera = carrera;
        return _simple(
          'Anotado: estudias $carrera.',
          intencion: 'memoria:carrera',
        );
      case EsperaDesahogo():
        // Se atiende mas tarde: si lo que cuenta es una pregunta de la app,
        // primero va la pregunta.
        return null;
    }
  }

  static const _soloInterrogativo = {
    'que',
    'como',
    'cual',
    'quien',
    'y',
    'y que',
    'que que',
    'como que',
  };

  static const _rendirse = {
    'me rindo',
    'rindo',
    'me rendi',
    'no se',
    'ni idea',
    'dime',
    'dimelo',
    'cual es',
    'cual era',
    'que es',
    'ya no',
    'salir',
    'basta',
    'no juego',
    'ya no quiero jugar',
    'no quiero jugar',
  };

  static bool _seRinde(_Mensaje m) => _rendirse.contains(m.junto);

  RespuestaMacias _siNo(String para, bool si, ContextoMacias c) {
    if (para.startsWith('repaso:')) {
      final seccion = ConocimientoMacias.seccion(para.substring(7));
      if (si && seccion != null) return _abrirSeccion(seccion);
      return _simple(
        c.alguna(const [
          'Dale. ¡Mucha suerte igual!',
          'Ok. Si después quieres repasar, aquí estoy.',
        ]),
        intencion: 'charla:negacion',
      );
    }
    switch (para) {
      case 'persona':
        if (si) {
          return _responderTema(
            ConocimientoMacias.tema(ConocimientoMacias.humano)!,
          );
        }
        return _simple(
          'Dale, sigamos. ¿Qué necesitas?',
          intencion: 'charla:negacion',
        );
      case 'algo_mas':
        return si
            ? _simple(
                c.alguna(const [
                  '¡Dale! ¿Qué necesitas?',
                  'Claro, pregunta nomás.',
                ]),
                intencion: 'charla:acuerdo',
              )
            : _simple(
                c.alguna(const [
                  '¡Listo! Cualquier cosa, me escribes.',
                  'Perfecto. Aquí estaré.',
                ]),
                intencion: 'charla:negacion',
              );
      case 'otro_chiste':
        if (si) return _responderTema(ConocimientoMacias.tema('chiste')!);
      case 'numero':
        if (si) return _deCharla(AzarMacias.numero(_azar));
        return _simple(
          'Dale. Cuando quieras, la revancha.',
          intencion: 'juego:fin',
        );
      case 'ppt':
        if (si) return _deCharla(AzarMacias.ppt());
        return _simple('Dale. Buena partida.', intencion: 'juego:fin');
      case 'adivinanza':
        if (si) return _deCharla(CharlaMacias.adivinanza(c));
        return _simple('Ok. ¡Buena esa!', intencion: 'juego:fin');
    }
    return _simple('¡Listo!', intencion: 'charla:acuerdo');
  }

  RespuestaMacias? _comoTeFue(
    _Mensaje m,
    ExamenMacias examen,
    ContextoMacias c,
  ) {
    final t = ' ${m.junto} ';
    bool dice(List<String> frases) => frases.any((f) => t.contains(' $f '));
    if (dice([
      'no lo di',
      'no lo rendi',
      'lo movieron',
      'lo postergaron',
      'lo pasaron',
      'se suspendio',
      'lo cambiaron',
      'todavia no lo doy',
      'aun no',
      'todavia no',
    ])) {
      _espera = EsperaFechaExamen(examen.materia, tipo: examen.tipo);
      return _simple(
        'Ah, ¿lo movieron? Dime la nueva fecha y te la recuerdo.',
        intencion: 'memoria:examen',
      );
    }
    if (dice([
      'mal',
      'muy mal',
      'pesimo',
      'fatal',
      'horrible',
      'reprobe',
      'me aplazaron',
      'aplace',
      'jale',
      'me jalaron',
      'perdi',
      'no me fue bien',
    ])) {
      return _deCharla(
        RespuestaCharla(
          'Pucha, lo siento, ${c.nombre}. Una nota no te define, y se puede '
          'recuperar. Si quieres, repasamos juntos:',
          intencion: 'charla:reprobe',
          opciones: _materiasComoOpciones,
        ),
      );
    }
    if (dice([
      'bien',
      'muy bien',
      'super bien',
      'genial',
      'excelente',
      'de lujo',
      'aprobe',
      'pase',
      'saque 100',
      'perfecto',
      'increible',
    ])) {
      return _simple(
        '¡Felicidades, ${c.nombre}! Sabía que te iba a ir bien. Eso se '
        'celebra.',
        intencion: 'charla:aprobe',
      );
    }
    if (dice([
      'mas o menos',
      'normal',
      'ahi',
      'regular',
      'no se',
      'no se todavia',
      'no me dieron la nota',
      'espero que bien',
      'ojala',
    ])) {
      return _simple(
        'Cruzamos los dedos. Cuando sepas la nota, me cuentas.',
        intencion: 'charla:animo',
      );
    }
    return null;
  }

  static const _materiasComoOpciones = [
    OpcionMacias(id: 's:algebra', texto: 'Álgebra'),
    OpcionMacias(id: 's:calculo', texto: 'Cálculo integral'),
    OpcionMacias(id: 's:cpp', texto: 'Programación en C++'),
  ];

  // ============================================================== charla
  /// Lo que se contesta si preguntan lo mismo dos veces seguidas: una
  /// persona se da cuenta, y repetir otra frase del mismo saco delata al
  /// robot.
  static const _repetidas = {
    'charla:que_haces': [
      'Jaja, lo mismo que hace un ratito: aquí nomás. ¿Y tú?',
      'Sigo igual, jaja. ¿Por? ¿Pasó algo?',
    ],
    'charla:como_estas': [
      'Igual de bien que hace un rato, jaja. ¿Y tú?',
      'Bien todavía, jaja. ¿Todo bien contigo?',
    ],
    'charla:saludo': [
      '¡Hola otra vez! Jaja, ¿qué pasó?',
      'Holaa de nuevo. Dime.',
    ],
    'charla:presencia': ['Sí, sigo aquí, jaja. Dime.', 'Aquí sigo, no me fui.'],
    'charla:gracias': ['De nada, de nada, jaja.', 'Jaja, ya, de nada.'],
    'charla:risa': ['Jajaja.', 'Jaja, sí que te dio risa.'],
    'charla:insulto': [
      'Ya, ya, entendí, jaja. ¿Qué buscabas?',
      'Jaja, ok, me lo merezco. ¿Qué necesitabas?',
    ],
    'charla:elogio': [
      'Jaja, ya me lo dijiste, pero me encanta escucharlo.',
      'Ya, me vas a hacer creérmela.',
    ],
  };

  RespuestaMacias _social(RespuestaCharla r, ContextoMacias c) {
    final repetida = _repetidas[r.intencion];
    if (repetida != null && r.intencion == _ultimaIntencion) {
      return _deCharla(
        RespuestaCharla(
          c.alguna(repetida),
          intencion: r.intencion,
          espera: r.espera,
        ),
      );
    }
    switch (r.intencion) {
      case 'charla:repetir':
        final ultima = _ultimaRespuesta;
        if (ultima == null) {
          return _simple(
            'Todavía no te dije nada para repetir. ¿En qué te ayudo?',
            intencion: 'charla:repetir',
          );
        }
        return RespuestaMacias(
          [const BurbujaMacias('Claro, te lo repito:'), ...ultima.burbujas],
          sugerencias: ultima.sugerencias,
          temaId: ultima.temaId,
          intencion: 'charla:repetir',
        );
      case 'charla:confusion':
        if (_ultimoTema != null) return _ampliar();
        return _simple(
          '¿Qué parte no quedó clara? Pregúntame de nuevo con otras palabras y '
          'lo intento mejor.',
          intencion: 'charla:confusion',
        );
      case 'charla:ayuda':
        return _conMenu(
          const [],
          '${r.texto}\n**Toca una opción o escribe su número:**',
          intencion: 'charla:ayuda',
        );
      case 'charla:risa':
        if (_ultimoTema == 'chiste') {
          return _deCharla(
            RespuestaCharla(
              '${r.texto} ¿Otro?',
              intencion: r.intencion,
              espera: const EsperaSiNo('otro_chiste'),
              opciones: const [
                OpcionMacias(id: 't:chiste', texto: 'Otro chiste'),
              ],
            ),
          );
        }
      case 'charla:aprobe' || 'charla:reprobe':
        _marcarExamenContestado(c);
    }
    return _deCharla(r);
  }

  RespuestaMacias _deCharla(
    RespuestaCharla r, {
    List<OpcionMacias>? sugerencias,
  }) {
    _espera = r.espera;
    if (r.opciones.isNotEmpty) _vigentes = r.opciones;
    return RespuestaMacias(
      [BurbujaMacias(r.texto, opciones: r.opciones, acciones: r.acciones)],
      sugerencias: r.sugerencias ?? sugerencias ?? _sugerenciasBase,
      intencion: r.intencion,
    );
  }

  /// Solo emojis o signos: tambien dicen algo.
  RespuestaMacias _sinPalabras(String original, ContextoMacias c) {
    final usados = original.runes.toSet();
    bool tiene(String emojis) => emojis.runes.any(usados.contains);
    RespuestaMacias dicho(String texto, {EsperaMacias? espera}) => _deCharla(
      RespuestaCharla(texto, intencion: 'charla:emoji', espera: espera),
    );

    if (tiene('👍👌✅🙌💪')) return _sirvio();
    if (tiene('👎')) return _noSirvio();
    if (tiene('😂🤣😆😅😄😁😹💀')) {
      return dicho(
        c.alguna(const ['Jaja, ¿verdad?', 'Me alegra sacarte una risa.']),
      );
    }
    if (tiene('❤😍🥰😘💕💖💗💓💞♥😻')) return dicho('¡Aww! Gracias.');
    if (tiene('😢😭😞😔☹🙁😿💔')) {
      return dicho(
        '¿Todo bien? Si quieres contarme, aquí estoy.',
        espera: const EsperaDesahogo(),
      );
    }
    if (tiene('😡😠🤬')) {
      return dicho('Uy, ¿qué pasó? Cuéntame.', espera: const EsperaDesahogo());
    }
    if (tiene('🤔🧐')) return dicho('¿Te quedó alguna duda? Pregúntame nomás.');
    if (tiene('🙏')) return dicho('¡De nada! Para eso estoy.');
    if (tiene('👋')) return dicho('¡Hola, ${c.nombre}! ¿En qué te ayudo?');
    if (tiene('🔥😎🤩')) return dicho('¡Así me gusta!');
    if (tiene('🤡')) return dicho('Jaja, ¿yo? Bueno, a veces.');
    if (tiene('👀')) return dicho('Jaja, ¿qué miras? Pregúntame algo.');
    if (original.contains('?')) {
      return dicho('¿Qué duda tienes? Pregunta nomás.');
    }
    if (original.contains('...') || original.contains('…')) {
      return dicho('¿Sigues ahí? Escribe cuando quieras.');
    }
    return dicho('¡Lindo! Pero mejor escríbeme con palabras, así te entiendo.');
  }

  static bool _pareceTecleo(List<String> palabras) {
    if (palabras.length != 1) return false;
    final palabra = palabras.single;
    if (palabra.length < 4 || RegExp(r'\d').hasMatch(palabra)) return false;
    const filas = [
      'asdf',
      'sdfg',
      'dfgh',
      'fghj',
      'ghjk',
      'hjkl',
      'qwer',
      'wert',
      'erty',
      'rtyu',
      'tyui',
      'zxcv',
      'xcvb',
      'cvbn',
    ];
    return filas.any(palabra.contains) || !RegExp('[aeiou]').hasMatch(palabra);
  }

  // ============================================================= memoria
  /// Lo que la persona cuenta de si, o pregunta sobre lo que se le conto.
  /// Ordenes sobre la memoria ("olvida todo", "ya lo hice") y preguntas
  /// sobre lo que recuerda ("¿qué me gusta?"). Van antes que la charla: "ya
  /// lo hice" no es un "ya", y "me gusta" en "¿qué me gusta?" no es un
  /// elogio.
  RespuestaMacias? _sobreLaMemoria(_Mensaje m, ContextoMacias c) {
    final junto = m.junto;
    if (_olvidar.any(junto.contains)) {
      memoria.olvidar();
      return _simple(
        'Listo, olvidé todo lo que sabía de ti. Si quieres, cuéntame de nuevo.',
        intencion: 'memoria:olvidar',
      );
    }
    if (_borrarNotas.any(junto.contains) ||
        (memoria.notas.isNotEmpty && _yaLoHice.contains(junto))) {
      if (memoria.notas.isEmpty) {
        return _simple(
          'No tenía nada anotado para recordarte.',
          intencion: 'memoria:notas',
        );
      }
      memoria.notas.clear();
      return _simple(
        '¡Bien ahí! Borré tus recordatorios.',
        intencion: 'memoria:notas',
      );
    }
    return _loQueRecuerda(junto, c);
  }

  RespuestaMacias? _datoPersonal(_Mensaje m, ContextoMacias c) {
    final varios = _variosDatos(m);
    if (varios != null) return varios;

    final junto = m.junto;
    final nombre =
        CharlaMacias.nombreEn(m.original) ??
        CharlaMacias.nombreSoyEn(m.limpio, m.original);
    if (nombre != null) {
      if (_groserias.any(LenguajeMacias.normalizar(nombre).contains)) {
        return _simple(
          'Prefiero llamarte por tu nombre de verdad.',
          intencion: 'memoria:nombre',
        );
      }
      memoria.nombre = nombre;
      return _simple(
        'Mucho gusto, $nombre. Desde ahora te llamo así. Lo guardo solo en '
        'este teléfono.',
        intencion: 'memoria:nombre',
      );
    }

    final carrera = CharlaMacias.carreraEn(junto);
    if (carrera != null) {
      memoria.carrera = carrera;
      return _simple(
        'Anotado: estudias $carrera. ${_ayudaPara(carrera)}',
        intencion: 'memoria:carrera',
      );
    }

    final cumple = CharlaMacias.cumpleEn(junto, c.ahora);
    if (cumple != null) return _anotarCumple(cumple, c);

    final edad = CharlaMacias.edadEn(junto);
    if (edad != null) {
      memoria.edad = edad;
      return _simple(
        'Anotado: tienes $edad años. Me lo voy a acordar.',
        intencion: 'memoria:edad',
      );
    }

    final examen = CharlaMacias.examenEn(
      m.limpio,
      m.fichas,
      m.original,
      c.ahora,
    );
    if (examen != null) {
      return _anotarExamen(examen.materia, examen.fecha, c, tipo: examen.tipo);
    }

    final nota = CharlaMacias.notaEn(m.limpio, m.fichas, m.original);
    if (nota != null) {
      memoria.anotarNota(nota);
      return _simple(
        'Anotado: $nota. Te lo recuerdo la próxima vez que abras el chat.',
        intencion: 'memoria:nota',
      );
    }

    final persona = CharlaMacias.personaEn(m.limpio, m.fichas, m.original);
    if (persona != null) {
      memoria.personas[persona.rol] = persona.nombre;
      final rol = CharlaMacias.nombreRol(persona.rol);
      final texto = CharlaMacias.mascotas.contains(persona.rol)
          ? '¡Qué buen nombre para un $rol! Saludos a ${persona.nombre}. '
                'Ya me lo anoté.'
          : 'Anotado: tu $rol se llama ${persona.nombre}. Lo guardo solo en '
                'este teléfono.';
      return _simple(texto, intencion: 'memoria:persona');
    }

    final trabajo = CharlaMacias.trabajoEn(m.limpio, m.fichas, m.original);
    if (trabajo != null) {
      memoria.trabajo = trabajo;
      return _simple(
        'Anotado: trabajas $trabajo. Trabajar y estudiar a la vez no es poca '
        'cosa: aquí estoy para hacerte el estudio más corto.',
        intencion: 'memoria:trabajo',
      );
    }

    final favorito = CharlaMacias.favoritoEn(m.limpio, m.fichas, m.original);
    if (favorito != null) {
      memoria.anotarFavorito(favorito.categoria, favorito.cosa);
      return _simple(
        'Anotado: tu ${CharlaMacias.nombreCategoria(favorito.categoria)} '
        'favorit${CharlaMacias.esMasculina(favorito.categoria) ? 'o' : 'a'} '
        'es ${favorito.cosa}. Buen gusto.',
        intencion: 'memoria:favorito',
      );
    }

    final ciudad = CharlaMacias.ciudadEn(junto);
    if (ciudad != null) {
      memoria.ciudad = ciudad;
      return _simple(_sobreCiudad(ciudad), intencion: 'memoria:ciudad');
    }

    final gusto = CharlaMacias.gustoEn(m.limpio, m.fichas, m.original);
    if (gusto != null) {
      // "Me gusta la pizza y odio el brócoli": son dos cosas.
      final partes = gusto.cosa.split(
        RegExp(
          r',? (?:y|pero) (?:odio|detesto|no me gusta|no me gustan) ',
          caseSensitive: false,
        ),
      );
      if (gusto.gusta && partes.length == 2) {
        final si = CharlaMacias.conTildes(partes[0].trim());
        final no = CharlaMacias.conTildes(partes[1].trim());
        memoria
          ..anotarGusto(si)
          ..anotarDisgusto(no);
        return _simple(
          'Anotado: te gusta $si y no te gusta $no. Me lo voy a acordar.',
          intencion: 'memoria:gusto',
        );
      }
      return _anotarGusto(CharlaMacias.conTildes(gusto.cosa), gusto.gusta);
    }

    final recuerdo = _loQueRecuerda(junto, c);
    if (recuerdo != null) return recuerdo;

    // "Otro más" despues de un piropo es otro piropo.
    if (_pedidosDeOtro.contains(junto) ||
        junto == 'otra vez' ||
        junto == 'de nuevo') {
      final otro = _otroDeLoMismo(c);
      if (otro != null) return otro;
    }
    if (_pedidosDeAmpliar.contains(junto) && _ultimoTema != null) {
      return _ampliar();
    }
    if (_pedidosDeOtro.contains(junto)) {
      final opciones = [
        ConocimientoMacias.tema('chiste')!.comoOpcion,
        ConocimientoMacias.tema('dato_curioso')!.comoOpcion,
        const OpcionMacias(id: 'o:juego_adivinanza', texto: 'Una adivinanza'),
      ];
      return _deCharla(
        RespuestaCharla(
          '¿Otro qué? Elige:',
          intencion: 'charla:otro',
          opciones: opciones,
        ),
      );
    }
    return null;
  }

  static const _pedidosDeOtro = {
    'otro',
    'otra',
    'otro mas',
    'otra mas',
    'uno mas',
    'una mas',
    'dame otro',
    'dame otra',
    'otro por favor',
    'otra por favor',
    'y otro',
    'y otra',
    'cuentame otro',
    'cuentame otra',
    'dime otro',
    'dime otra',
  };

  /// Lo mismo que se acaba de pedir, pero otro: un piropo, una adivinanza.
  RespuestaMacias? _otroDeLoMismo(ContextoMacias c) {
    switch (_ultimaIntencion) {
      case 'charla:piropo':
        return _deCharla(CharlaMacias.piropo(c));
      case 'juego:adivinanza':
        return _deCharla(CharlaMacias.adivinanza(c));
      case 'charla:trabalenguas' || 'charla:poema' || 'charla:motivacion':
        final pedido = switch (_ultimaIntencion) {
          'charla:trabalenguas' => 'trabalenguas',
          'charla:poema' => 'poema',
          _ => 'motivame',
        };
        return _social(CharlaMacias.antesDeLosTemas(pedido, c)!, c);
      case 'charla:chiste_malo':
        return _responderTema(ConocimientoMacias.tema('chiste')!);
    }
    return null;
  }

  /// "Soy Jotade, me gusta el fútbol": varias cosas de una vez. Solo si hay
  /// al menos dos; con una sola, sigue el camino de siempre.
  RespuestaMacias? _variosDatos(_Mensaje m) {
    final partes = m.original.split(
      RegExp(
        r'\s*[,;]\s*|[.!]\s+|\s+y\s+(?=(?:me|mi|soy|estudio|tengo|odio|amo|'
        r'vivo|trabajo)\b)',
        caseSensitive: false,
      ),
    );
    if (partes.length < 2) return null;
    final datos = [
      for (final parte in partes)
        if (parte.trim().isNotEmpty) ?_unDato(_Mensaje.de(parte.trim())),
    ];
    if (datos.length < 2) return null;
    for (final (_, anotar) in datos) {
      anotar();
    }
    return _simple(
      'Anotado: ${_lista([for (final (dicho, _) in datos) dicho])}. Me lo '
      'voy a acordar.',
      intencion: 'memoria:varios',
    );
  }

  /// Un dato suelto y como anotarlo, sin anotarlo todavia.
  (String, void Function())? _unDato(_Mensaje m) {
    final nombre =
        CharlaMacias.nombreEn(m.original) ??
        CharlaMacias.nombreSoyEn(m.limpio, m.original);
    if (nombre != null &&
        !_groserias.any(LenguajeMacias.normalizar(nombre).contains)) {
      return ('te llamo $nombre', () => memoria.nombre = nombre);
    }
    final carrera = CharlaMacias.carreraEn(m.junto);
    if (carrera != null) {
      return ('estudias $carrera', () => memoria.carrera = carrera);
    }
    final edad = CharlaMacias.edadEn(m.junto);
    if (edad != null) return ('tienes $edad años', () => memoria.edad = edad);
    final ciudad = CharlaMacias.ciudadEn(m.junto);
    if (ciudad != null) {
      return ('eres de $ciudad', () => memoria.ciudad = ciudad);
    }
    final gusto = CharlaMacias.gustoEn(m.limpio, m.fichas, m.original);
    if (gusto != null) {
      final cosa = CharlaMacias.conTildes(gusto.cosa);
      final n =
          RegExp(
            r'^(?:los|las|unos|unas) ',
          ).hasMatch(LenguajeMacias.normalizar(cosa))
          ? 'n'
          : '';
      return gusto.gusta
          ? ('te gusta$n $cosa', () => memoria.anotarGusto(cosa))
          : ('no te gusta$n $cosa', () => memoria.anotarDisgusto(cosa));
    }
    return null;
  }

  RespuestaMacias? _loQueRecuerda(String junto, ContextoMacias c) {
    if (_quienSoy.contains(junto)) {
      final carrera = memoria.carrera;
      return _simple(
        'Eres **${c.nombre}**.${carrera != null ? ' Estudias $carrera.' : ''}'
        '${memoria.vacia ? ' Si me cuentas más de ti, me acuerdo.' : ' Escribe **qué sabes de mí** y te cuento todo lo que me acuerdo.'}',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_adivinaNombre.contains(junto)) {
      return _simple(
        memoria.nombre != null
            ? '¡${memoria.nombre}! Fácil: me lo dijiste tú.'
            : '¿${c.nombre}? Jaja, hice trampa: lo vi en tu perfil.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_adivinaEdad.contains(junto)) {
      return _simple(
        memoria.edad != null
            ? 'Tienes ${memoria.edad}. No adiviné: me lo dijiste tú.'
            : 'Mmm... ¿20? Jaja, no tengo forma de saberlo. Si me dices, me '
                  'acuerdo: **tengo 20 años**.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasNombre.contains(junto)) {
      return _simple(
        memoria.nombre != null
            ? 'Te llamas ${memoria.nombre}.'
            : 'Según tu perfil, te llamas ${c.nombre}. Si prefieres que te '
                  'diga de otra forma, escribe **me llamo** y tu nombre.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasCarrera.contains(junto)) {
      if (memoria.carrera == null) _espera = const EsperaCarrera();
      return _simple(
        memoria.carrera != null
            ? 'Estudias ${memoria.carrera}.'
            : 'Todavía no me lo dijiste. ¿Qué estudias?',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasGustos.contains(junto)) {
      return _simple(
        memoria.gustos.isEmpty
            ? 'Todavía no me contaste. Escribe, por ejemplo, **me gusta la '
                  'pizza**.'
            : 'Me dijiste que te gusta: ${_lista(memoria.gustos)}.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasEdad.contains(junto)) {
      return _simple(
        memoria.edad != null
            ? 'Tienes ${memoria.edad} años (me lo dijiste tú).'
            : 'No me lo dijiste. Si quieres, cuéntame: **tengo 20 años**.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasCumple.contains(junto)) {
      if (!memoria.tieneCumple) {
        return _simple(
          'No me lo dijiste. Cuéntame, por ejemplo: **mi cumpleaños es el 5 '
          'de mayo**.',
          intencion: 'memoria:recuerdo',
        );
      }
      return _simple(
        'Tu cumpleaños es el ${memoria.cumpleDia} de '
        '${FechasMacias.meses[memoria.cumpleMes! - 1]}. ¡No me olvido!',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasCiudad.contains(junto)) {
      return _simple(
        memoria.ciudad != null
            ? 'Eres de ${memoria.ciudad}.'
            : 'No me lo dijiste. Cuéntame: **soy de Cochabamba**, por ejemplo.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasNotas.contains(junto)) {
      return _simple(
        memoria.notas.isEmpty
            ? 'No me pediste que te recuerde nada. Prueba: **recuérdame '
                  'comprar fotocopias**.'
            : 'Me pediste que te recuerde: ${_lista(memoria.notas)}.',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasExamenes.contains(junto)) {
      final hoy = FechasMacias.dia(c.ahora);
      final proximos = [
        for (final e in memoria.examenes)
          if (!e.fecha.isBefore(hoy)) e,
      ];
      return _simple(
        proximos.isEmpty
            ? 'No tengo anotado ningún examen. Cuéntame, por ejemplo: **tengo '
                  'examen de cálculo el viernes**.'
            : 'Tienes ${_lista([for (final e in proximos) '${e.nombre} ${FechasMacias.relativa(e.fecha, hoy)}'])}.',
        intencion: 'memoria:recuerdo',
      );
    }
    final rol = CharlaMacias.preguntaPersona(junto);
    if (rol != null) {
      final nombre = memoria.personas[rol];
      return _simple(
        nombre != null
            ? 'Se llama $nombre.'
            : 'No me lo dijiste. Cuéntame: **mi ${CharlaMacias.nombreRol(rol)} '
                  'se llama...**',
        intencion: 'memoria:recuerdo',
      );
    }
    if (_preguntasTrabajo.contains(junto)) {
      return _simple(
        memoria.trabajo != null
            ? 'Trabajas ${memoria.trabajo}.'
            : 'No me lo dijiste. Si quieres, cuéntame: **trabajo en una '
                  'tienda**, por ejemplo.',
        intencion: 'memoria:recuerdo',
      );
    }
    final categoria = CharlaMacias.preguntaFavorito(junto);
    if (categoria != null) {
      final cosa = memoria.favoritos[categoria];
      final nombre = CharlaMacias.nombreCategoria(categoria);
      final o = CharlaMacias.esMasculina(categoria) ? 'o' : 'a';
      return _simple(
        cosa != null
            ? 'Tu $nombre favorit$o es $cosa.'
            : 'No me lo dijiste. Cuéntame: **mi $nombre favorit$o es...**',
        intencion: 'memoria:recuerdo',
      );
    }
    return null;
  }

  RespuestaMacias _anotarGusto(String cosa, bool gusta) {
    if (gusta) {
      memoria.anotarGusto(cosa);
    } else {
      memoria.anotarDisgusto(cosa);
    }
    // "Los gatos": te gustan, y no te los voy a recomendar.
    final articulo = RegExp(
      r'^(los|las|unos|unas) ',
    ).firstMatch(LenguajeMacias.normalizar(cosa))?[1];
    final n = articulo == null ? '' : 'n';
    final pronombre = switch (articulo) {
      'los' || 'unos' => 'los',
      'las' || 'unas' => 'las',
      _ => 'lo',
    };
    return _simple(
      gusta
          ? 'Anotado: te gusta$n $cosa. Me lo voy a acordar.'
          : 'Anotado: no te gusta$n $cosa. No te $pronombre voy a recomendar.',
      intencion: 'memoria:gusto',
    );
  }

  RespuestaMacias _anotarCumple(
    ({int mes, int dia, int? anio}) cumple,
    ContextoMacias c,
  ) {
    memoria
      ..cumpleMes = cumple.mes
      ..cumpleDia = cumple.dia;
    final hoy = FechasMacias.dia(c.ahora);
    if (cumple.anio != null) {
      final yaCumplio =
          hoy.month > cumple.mes ||
          (hoy.month == cumple.mes && hoy.day >= cumple.dia);
      final edad = hoy.year - cumple.anio! - (yaCumplio ? 0 : 1);
      if (edad >= 14 && edad <= 80) memoria.edad = edad;
    }
    if (cumple.mes == hoy.month && cumple.dia == hoy.day) {
      memoria.cumpleFelicitado = hoy.year;
      return _simple(
        '¡Feliz cumpleaños, ${c.nombre}! Que la pases increíble. Ya lo anoté '
        'para saludarte el próximo año.',
        intencion: 'memoria:cumple',
      );
    }
    var proximo = DateTime(hoy.year, cumple.mes, cumple.dia);
    if (proximo.isBefore(hoy)) {
      proximo = DateTime(hoy.year + 1, cumple.mes, cumple.dia);
    }
    final faltan = FechasMacias.diasEntre(hoy, proximo);
    return _simple(
      'Anotado: tu cumpleaños es el ${cumple.dia} de '
      '${FechasMacias.meses[cumple.mes - 1]}. '
      '${faltan == 1 ? '¡Es mañana!' : 'Faltan $faltan días, y ese día te saludo.'}',
      intencion: 'memoria:cumple',
    );
  }

  RespuestaMacias _anotarExamen(
    String materia,
    DateTime? fecha,
    ContextoMacias c, {
    String tipo = 'examen',
  }) {
    final nombre = ExamenMacias.nombrar(tipo, materia);
    if (fecha == null) {
      _espera = EsperaFechaExamen(materia, tipo: tipo);
      return _simple(
        '¡Suerte con $nombre! ¿Cuándo es? Dime, por ejemplo: **mañana**, '
        '**el lunes** o **el 15 de noviembre**, y te lo recuerdo.',
        intencion: 'memoria:examen',
      );
    }
    final hoy = FechasMacias.dia(c.ahora);
    final dias = FechasMacias.diasEntre(hoy, fecha);
    final examen = ExamenMacias(materia: materia, fecha: fecha, tipo: tipo);
    if (dias < 0) {
      examen.preguntado = true;
      memoria.anotarExamen(examen);
      _espera = EsperaComoTeFue(examen);
      return _simple('¿Y cómo te fue en $nombre?', intencion: 'memoria:examen');
    }
    if (dias <= 1) examen.avisado = ExamenMacias.diaTexto(hoy);
    memoria.anotarExamen(examen);
    final cuando = FechasMacias.relativa(fecha, hoy);
    final aviso = switch (dias) {
      0 => '¡Mucha suerte! Respira, que tú puedes.',
      1 => 'Hoy toca repasar y dormir bien.',
      _ =>
        'Faltan $dias días: si estudias un poquito cada día, llegas sobrado.',
    };
    final texto =
        'Anotado: tienes $nombre $cuando'
        '${dias >= 2 && dias < 7 ? ' (${FechasMacias.larga(fecha)})' : ''}. '
        '$aviso';
    final seccion = _seccionDeMateria(materia);
    if (seccion == null) return _simple(texto, intencion: 'memoria:examen');
    _espera = EsperaSiNo('repaso:${seccion.id}');
    final opciones = [
      OpcionMacias(id: 's:${seccion.id}', texto: 'Repasar ${seccion.titulo}'),
    ];
    _vigentes = opciones;
    return RespuestaMacias(
      [BurbujaMacias('$texto ¿Repasamos un rato?', opciones: opciones)],
      sugerencias: _sugerenciasBase,
      intencion: 'memoria:examen',
    );
  }

  void _marcarExamenContestado(ContextoMacias c) {
    final hoy = FechasMacias.dia(c.ahora);
    for (final examen in memoria.examenes.reversed) {
      if (!examen.fecha.isAfter(hoy) && !examen.preguntado) {
        examen.preguntado = true;
        return;
      }
    }
  }

  static SeccionMacias? _seccionDeMateria(String materia) {
    final t = ' ${LenguajeMacias.normalizar(materia)} ';
    if (t.contains(' algebra ')) return ConocimientoMacias.seccion('algebra');
    if (t.contains(' calculo ')) return ConocimientoMacias.seccion('calculo');
    if (t.contains(' c ') ||
        t.contains(' cpp ') ||
        t.contains(' programacion ')) {
      return ConocimientoMacias.seccion('cpp');
    }
    return null;
  }

  /// Con que puede dar una mano segun la carrera: a Derecho no se le ofrece
  /// C++.
  static String _ayudaPara(String carrera) {
    if (carrera.startsWith('Ingeniería') &&
        !const {
          'Ingeniería Comercial',
          'Ingeniería Económica',
          'Ingeniería Financiera',
        }.contains(carrera)) {
      return 'Si te toca cálculo o C++, aquí estoy.';
    }
    if (const {
      'Ingeniería Comercial',
      'Ingeniería Económica',
      'Ingeniería Financiera',
      'Administración de Empresas',
      'Auditoría y Finanzas',
      'Comercio Internacional',
      'Arquitectura',
    }.contains(carrera)) {
      return 'Si te toca álgebra o cálculo, aquí estoy.';
    }
    return '¡Buena carrera! Si necesitas una mano con algo, aquí estoy.';
  }

  static String _sobreCiudad(String ciudad) => switch (ciudad) {
    'Santa Cruz' => '¡Camba de corazón! Anotado: eres de Santa Cruz.',
    'La Paz' || 'El Alto' =>
      'Anotado: eres de $ciudad. ¿Ya te acostumbraste al calor de acá?',
    'Cochabamba' => 'Anotado: eres de Cochabamba, tierra del buen comer.',
    'Sucre' => 'Anotado: eres de Sucre, la capital constitucional.',
    'Tarija' => 'Anotado: eres de Tarija. ¡Chapaco!',
    _ => 'Anotado: eres de $ciudad.',
  };

  /// Lo que MacIAs tiene para decir apenas se abre el chat: un cumpleaños,
  /// un examen, una nota. Una sola cosa por vez, y cada una una sola vez.
  String? _novedad(ContextoMacias c) {
    final hoy = FechasMacias.dia(c.ahora);
    final hoyTexto = ExamenMacias.diaTexto(hoy);
    if (memoria.tieneCumple &&
        memoria.cumpleMes == hoy.month &&
        memoria.cumpleDia == hoy.day &&
        memoria.cumpleFelicitado != hoy.year) {
      memoria.cumpleFelicitado = hoy.year;
      return '¡Feliz cumpleaños, ${c.nombre}! Que tengas un día increíble. Y '
          'si alguien del campus vende tortas, hoy es el día.';
    }
    for (final examen in memoria.examenes) {
      final dias = FechasMacias.diasEntre(hoy, examen.fecha);
      if ((dias == 0 || dias == 1) && examen.avisado != hoyTexto) {
        examen.avisado = hoyTexto;
        final seccion = _seccionDeMateria(examen.materia);
        if (seccion != null) _espera = EsperaSiNo('repaso:${seccion.id}');
        final repaso = seccion == null
            ? ''
            : ' ¿Un repaso rápido de ${seccion.titulo}?';
        return dias == 0
            ? '¡Hoy es ${examen.nombre}! Mucha suerte, ${c.nombre}. Respira, '
                  'que tú puedes.$repaso'
            : 'Mañana es ${examen.nombre}. Hoy toca repasar y dormir '
                  'bien.$repaso';
      }
    }
    for (final examen in memoria.examenes) {
      final dias = FechasMacias.diasEntre(examen.fecha, hoy);
      if (dias >= 1 && dias <= 10 && !examen.preguntado) {
        examen.preguntado = true;
        _espera = EsperaComoTeFue(examen);
        return '¿Cómo te fue en ${examen.nombre}, ${c.nombre}?';
      }
    }
    if (memoria.notas.isNotEmpty && memoria.notasRecordadas != hoyTexto) {
      memoria.notasRecordadas = hoyTexto;
      return 'Por cierto, me pediste que te recuerde: '
          '${_lista(memoria.notas)}.';
    }
    return null;
  }

  /// "a", "a y b", "a, b y c".
  static String _lista(List<String> cosas) {
    if (cosas.length <= 1) return cosas.join();
    return '${cosas.sublist(0, cosas.length - 1).join(', ')} y ${cosas.last}';
  }

  static const _olvidar = [
    'olvida lo que sabes',
    'olvidate de mi',
    'olvida todo',
    'borra lo que sabes',
    'borra mi memoria',
    'olvida mi nombre',
  ];
  static const _borrarNotas = [
    'borra mis notas',
    'borra las notas',
    'borra mis recordatorios',
    'borra los recordatorios',
    'olvida mis notas',
    'olvida los recordatorios',
    'borrar recordatorios',
    'borrar notas',
  ];
  static const _yaLoHice = {
    'ya lo hice',
    'listo ya lo hice',
    'ya esta',
    'ya lo compre',
    'hecho',
  };
  static const _groserias = {
    'tonto',
    'tonta',
    'idiota',
    'estupido',
    'estupida',
    'inutil',
    'basura',
    'pendejo',
    'pendeja',
    'puto',
    'puta',
    'mierda',
    'cojudo',
    'huevon',
    'boludo',
    'imbecil',
  };
  static const _quienSoy = {
    'quien soy',
    'quien soy yo',
    'sabes quien soy',
    'sabes quien soy yo',
    'te acuerdas quien soy',
    'te acuerdas de quien soy',
  };
  static const _adivinaNombre = {
    'adivina mi nombre',
    'adivina como me llamo',
    'a que no sabes como me llamo',
  };
  static const _adivinaEdad = {
    'cuantos anos crees que tengo',
    'adivina mi edad',
    'adivina cuantos anos tengo',
    'que edad crees que tengo',
    'cuantos anos me das',
    'que edad me das',
    'cuantos anos parezco',
  };
  static const _preguntasNombre = {
    'como me llamo',
    'sabes como me llamo',
    'cual es mi nombre',
    'sabes mi nombre',
    'te acuerdas de mi nombre',
    'te acuerdas como me llamo',
  };
  static const _preguntasCarrera = {
    'que estudio',
    'que carrera estudio',
    'cual es mi carrera',
    'sabes que estudio',
    'sabes mi carrera',
    'te acuerdas que estudio',
  };
  static const _preguntasGustos = {
    'que me gusta',
    'sabes que me gusta',
    'que cosas me gustan',
    'te acuerdas que me gusta',
  };
  static const _preguntasEdad = {
    'cuantos anos tengo',
    'que edad tengo',
    'sabes mi edad',
    'sabes cuantos anos tengo',
  };
  static const _preguntasCumple = {
    'cuando es mi cumpleanos',
    'cuando es mi cumple',
    'cuando cumplo anos',
    'cuando cumplo',
    'sabes cuando es mi cumpleanos',
    'te acuerdas de mi cumpleanos',
  };
  static const _preguntasCiudad = {
    'de donde soy',
    'sabes de donde soy',
    'te acuerdas de donde soy',
  };
  static const _preguntasNotas = {
    'que te pedi que recordaras',
    'que te pedi que me recordaras',
    'que te pedi',
    'mis notas',
    'mis recordatorios',
    'recordatorios',
    'que tengo que hacer',
    'que tenia que hacer',
    'que me recuerdas',
    'que anotaste',
    'que tienes anotado',
  };
  static const _preguntasTrabajo = {
    'donde trabajo',
    'de que trabajo',
    'en que trabajo',
    'sabes donde trabajo',
    'te acuerdas donde trabajo',
  };
  static const _preguntasExamenes = {
    'cuando es mi examen',
    'mis examenes',
    'que examenes tengo',
    'cuando tengo examen',
    'tengo examenes',
    'cuando son mis examenes',
  };
  static const _pedidosDeAmpliar = {
    'otro ejemplo',
    'dame otro ejemplo',
    'dame un ejemplo',
    'un ejemplo',
    'ejemplo',
    'explicame mas',
    'explica mas',
    'explicame mejor',
    'mas detalle',
    'mas detalles',
    'no entendi',
    'no le entendi',
    'no entiendo',
    'como asi',
    'otro',
    'otra',
    'otro mas',
    'otra mas',
    'uno mas',
    'una mas',
    'dame otro',
    'dame otra',
    'otra vez',
    'mas',
    'sigue',
    'y',
  };

  // ============================================================ respuestas
  RespuestaMacias _abrirSeccion(SeccionMacias seccion) {
    _seccionActual = seccion.id;
    _ultimoFueSeccion = true;
    final padre = seccion.padre == null
        ? null
        : ConocimientoMacias.seccion(seccion.padre!);
    final opciones = [
      for (final entrada in seccion.temas) _opcionDe(entrada),
      if (padre != null)
        OpcionMacias(id: 's:${padre.id}', texto: 'Volver a ${padre.titulo}'),
      _opcionMenu,
    ];
    _vigentes = opciones;
    return RespuestaMacias(
      [
        BurbujaMacias(
          '${seccion.intro}\n**Toca una opción o escribe su número:**',
          opciones: opciones,
        ),
      ],
      sugerencias: _sugerenciasBase,
      intencion: 'seccion:${seccion.id}',
    );
  }

  /// Una linea de una seccion: un tema, otra seccion o una orden.
  OpcionMacias _opcionDe(String entrada) {
    if (entrada == ConocimientoMacias.ordenJuegos) {
      return const OpcionMacias(id: 'o:juegos', texto: 'Juguemos algo');
    }
    if (entrada.startsWith('s:')) {
      return ConocimientoMacias.seccion(entrada.substring(2))!.comoOpcion;
    }
    return ConocimientoMacias.tema(entrada)!.comoOpcion;
  }

  RespuestaMacias _responderTema(TemaMacias tema) {
    _ultimoTema = tema.id;
    _ultimoFueSeccion = false;
    final c = _nuevoContexto();
    final seccion = ConocimientoMacias.seccionDe(tema.id);
    if (seccion != null) _seccionActual = seccion.id;
    return _conSeguimiento(
      tema,
      BurbujaMacias(tema.respuesta(c), acciones: tema.acciones),
      c,
    );
  }

  /// La respuesta, y abajo que mas se puede ver: temas parecidos, volver y
  /// el menu.
  RespuestaMacias _conSeguimiento(
    TemaMacias tema,
    BurbujaMacias respuesta,
    ContextoMacias c,
  ) {
    final seccion = ConocimientoMacias.seccionDe(tema.id);
    final opciones = [
      for (final id in tema.relacionados)
        if (id == tema.id)
          // Un tema que se puede pedir otra vez, como un chiste.
          OpcionMacias(id: 't:$id', texto: 'Otro más')
        else if (ConocimientoMacias.tema(id) case final relacionado?
            when relacionado.enMenu)
          relacionado.comoOpcion,
      if (seccion != null)
        OpcionMacias(id: 'o:volver', texto: 'Volver a ${seccion.titulo}'),
      _opcionMenu,
    ];
    _vigentes = opciones;
    _espera = const EsperaSiNo('algo_mas');

    final cierre = c.alguna(const [
      '¿Algo más?',
      '¿Te ayudo con otra cosa?',
      '¿Qué más necesitas?',
    ]);
    return RespuestaMacias(
      [respuesta, BurbujaMacias(cierre, opciones: opciones)],
      sugerencias: tema.id == ConocimientoMacias.humano
          ? const [chipMenu]
          : [
              if (tema.ampliacion != null) chipOtroEjemplo,
              chipSirvio,
              chipNoSirvio,
              chipMenu,
            ],
      temaId: tema.id,
    );
  }

  /// "Otro ejemplo", "explícame más": sobre el ultimo tema.
  RespuestaMacias _ampliar() {
    final tema = _ultimoTema == null
        ? null
        : ConocimientoMacias.tema(_ultimoTema!);
    if (tema == null) {
      return _simple(
        '¿Sobre qué tema? Pregúntame algo y después te doy más ejemplos.',
      );
    }
    // Un chiste o un dato curioso: "otro" es otro igual.
    if (tema.relacionados.contains(tema.id)) return _responderTema(tema);
    final c = _nuevoContexto();
    final ampliacion = tema.ampliacion;
    if (ampliacion == null) {
      final opciones = [
        for (final id in tema.relacionados)
          if (ConocimientoMacias.tema(id) case final relacionado?
              when relacionado.enMenu && id != tema.id)
            relacionado.comoOpcion,
        ConocimientoMacias.tema(ConocimientoMacias.humano)!.comoOpcion,
        _opcionMenu,
      ];
      _vigentes = opciones;
      return RespuestaMacias(
        [
          BurbujaMacias(
            'Es lo más concreto que tengo sobre "${tema.pregunta}". Quizá te '
            'sirva uno de estos temas, o alguien del equipo:',
            opciones: opciones,
          ),
        ],
        sugerencias: _sugerenciasBase,
        temaId: tema.id,
      );
    }
    _ultimoFueSeccion = false;
    return _conSeguimiento(tema, BurbujaMacias(ampliacion(c)), c);
  }

  RespuestaMacias _cuenta(String resultado) {
    _ultimoTema = 'calculadora';
    return RespuestaMacias(
      [BurbujaMacias(resultado)],
      sugerencias: const [chipMenu, chipMaterias],
      intencion: 'cuenta',
    );
  }

  RespuestaMacias _porNumero(int numero) {
    if (numero >= 1 && numero <= _vigentes.length) {
      return _elegir(_vigentes[numero - 1]);
    }
    return RespuestaMacias(
      [
        BurbujaMacias(
          'No tengo la opción $numero. Elige del 1 al ${_vigentes.length}, o '
          'escribe **menú** para ver todo.',
          opciones: _vigentes,
        ),
      ],
      sugerencias: _sugerenciasBase,
      intencion: 'numero_fuera',
    );
  }

  RespuestaMacias _conPrefijo(RespuestaMacias respuesta, String prefijo) {
    final primera = respuesta.burbujas.first;
    return RespuestaMacias(
      [
        BurbujaMacias(
          '$prefijo${primera.texto}',
          opciones: primera.opciones,
          acciones: primera.acciones,
        ),
        ...respuesta.burbujas.skip(1),
      ],
      sugerencias: respuesta.sugerencias,
      temaId: respuesta.temaId,
      intencion: respuesta.intencion,
    );
  }

  RespuestaMacias _sirvio() {
    final c = _nuevoContexto();
    return _simple(
      c.alguna([
        '¡Bien! Para eso estoy.',
        '¡Genial, ${c.nombre}! Me alegra haberte ayudado.',
      ]),
      intencion: 'sirvio',
    );
  }

  RespuestaMacias _noSirvio() {
    final opciones = [
      ConocimientoMacias.tema(ConocimientoMacias.humano)!.comoOpcion,
      _opcionMenu,
    ];
    _vigentes = opciones;
    return RespuestaMacias(
      [
        BurbujaMacias(
          'Pucha, perdón. Dime con otras palabras qué buscas, o habla con '
          'alguien del equipo:',
          opciones: opciones,
        ),
      ],
      sugerencias: _sugerenciasBase,
      intencion: 'no_sirvio',
    );
  }

  /// Cuando nada encaja. Antes que "no entendí", se intenta ser util: temas
  /// que se parecen, o al menos decir de que no se sabe.
  RespuestaMacias _noEntendi(_Mensaje m, ContextoMacias c) {
    // "¿Quién ganó el mundial?": decir de que no se sabe es mas honesto que
    // ofrecer un tema que solo comparte una palabra.
    final tema = CharlaMacias.esPregunta(m.original, m.limpio)
        ? CharlaMacias.temaDesconocido(m.limpio, m.fichas, m.original)
        : null;
    final candidatos = _parecidos(m.palabras);
    final parecidos =
        tema != null && candidatos.isNotEmpty && candidatos.first.$2 < 1.5
        ? const <(TemaMacias, double)>[]
        : candidatos;
    if (parecidos.isNotEmpty) {
      final opciones = [
        for (final (parecido, _) in parecidos) parecido.comoOpcion,
        _opcionMenu,
      ];
      _vigentes = opciones;
      return RespuestaMacias(
        [
          BurbujaMacias(
            c.alguna(const [
              'Mmm, no sé si te entendí. ¿Buscas alguna de estas?',
              'Creo que va por acá. ¿Es alguna de estas?',
            ]),
            opciones: opciones,
          ),
        ],
        sugerencias: _sugerenciasBase,
        intencion: 'parecidos',
      );
    }

    // Corto y sin la lista de lo que sabe: eso, en vez de ayudar, suena a
    // folleto.
    if (tema != null) {
      return _simple(
        c.alguna([
          'Uf, de "$tema" no sé mucho, la verdad.',
          '"$tema"... esa se me escapa, la verdad.',
          'De "$tema" todavía no sé nada, perdón.',
        ]),
        intencion: 'desconocido',
      );
    }
    _sinEntender++;
    if (_sinEntender >= 2) {
      final opciones = [
        ConocimientoMacias.tema(ConocimientoMacias.humano)!.comoOpcion,
        _opcionMenu,
      ];
      _vigentes = opciones;
      _espera = const EsperaSiNo('persona');
      return RespuestaMacias(
        [
          BurbujaMacias(
            'Sigo sin entenderte, perdón. ¿Me lo repites de otra forma? Si '
            'prefieres, te paso con alguien del equipo.',
            opciones: opciones,
          ),
        ],
        sugerencias: _sugerenciasBase,
        intencion: 'no_entendi',
      );
    }
    return _simple(
      c.alguna(const [
        'No te entendí bien, ¿me lo repites?',
        'Perdón, no te entendí bien. ¿Podrías repetirlo?',
        'Mmm, no te entendí. ¿Me lo dices de otra forma?',
      ]),
      intencion: 'no_entendi',
    );
  }

  /// Temas que comparten alguna palabra importante con el mensaje, aunque
  /// no alcancen para contestar directo: "borrar" puede ser borrar la
  /// cuenta, el local o una publicacion.
  List<(TemaMacias, double)> _parecidos(List<String> palabras) {
    final utiles = [
      for (final p in palabras)
        if (p.length >= 5 && !LenguajeMacias.vacias.contains(p)) p,
    ];
    if (utiles.isEmpty) return const [];
    final puntajes = <(TemaMacias, double, int)>[];
    for (final (i, tema) in ConocimientoMacias.temas.indexed) {
      final partes = {
        for (final clave in tema.claves)
          for (final parte in clave.split(' '))
            if (!LenguajeMacias.vacias.contains(parte.replaceAll('*', '')))
              parte,
      };
      var total = 0.0;
      for (final palabra in utiles) {
        var mejor = 0.0;
        for (final parte in partes) {
          final coincidencia = LenguajeMacias.coincide(parte, [palabra]);
          if (coincidencia > mejor) mejor = coincidencia;
          if (mejor == 1) break;
        }
        total += mejor;
      }
      if (total >= 1) puntajes.add((tema, total, i));
    }
    puntajes.sort((a, b) {
      final porPuntos = b.$2.compareTo(a.$2);
      return porPuntos != 0 ? porPuntos : a.$3.compareTo(b.$3);
    });
    return [for (final (tema, puntos, _) in puntajes.take(3)) (tema, puntos)];
  }

  RespuestaMacias _simple(String texto, {String? intencion}) => RespuestaMacias(
    [BurbujaMacias(texto)],
    sugerencias: _sugerenciasBase,
    intencion: intencion,
  );

  RespuestaMacias _conMenu(
    List<BurbujaMacias> antes,
    String texto, {
    String? intencion,
  }) {
    _vigentes = ConocimientoMacias.menuPrincipal;
    return RespuestaMacias(
      [...antes, BurbujaMacias(texto, opciones: _vigentes)],
      sugerencias: const [chipMaterias, chipPersona],
      intencion: intencion,
    );
  }

  RespuestaMacias _recordar(RespuestaMacias respuesta) {
    if (respuesta.intencion != 'charla:repetir') _ultimaRespuesta = respuesta;
    _ultimaIntencion = respuesta.intencion ?? 'tema:${respuesta.temaId}';
    for (final burbuja in respuesta.burbujas) {
      _recientes.add(burbuja.texto);
    }
    while (_recientes.length > 30) {
      _recientes.removeAt(0);
    }
    return respuesta;
  }

  /// Lo ultimo que se entendio. Solo para pruebas.
  String? get ultimaIntencion => _ultimaIntencion;

  ContextoMacias _nuevoContexto() {
    final base = contexto();
    return ContextoMacias(
      nombre: memoria.nombre ?? base.nombre,
      ahora: base.ahora,
      version: base.version,
      esWeb: base.esWeb,
      sorteo: _azar.nextInt(1 << 20),
      memoria: memoria,
      recientes: List.unmodifiable(_recientes),
    );
  }

  // ============================================================ comprension
  static const _ordenesMenu = {
    'menu',
    'menu principal',
    'el menu',
    'ver menu',
    'ver el menu',
    'mostrar menu',
    'muestrame el menu',
    'inicio',
    'opciones',
    'ver opciones',
    'que opciones hay',
    'que opciones tienes',
    'empezar',
    'principal',
  };
  static const _ordenesVolver = {
    'volver',
    'atras',
    'regresar',
    'anterior',
    'vuelve',
    'volvamos',
  };

  RespuestaMacias? _orden(String junto) {
    if (_ordenesMenu.contains(junto)) return menu();
    if (_ordenesVolver.contains(junto)) return volver();
    return null;
  }

  /// Lo que puede ir adelante de la pregunta de verdad.
  static const _prefijos = {
    'hola': 'saludo',
    'buenas': 'saludo',
    'buenos dias': 'saludo',
    'buen dia': 'saludo',
    'buenas tardes': 'saludo',
    'buenas noches': 'saludo',
    'hey': 'saludo',
    'hi': 'saludo',
    'hello': 'saludo',
    'saludos': 'saludo',
    'ey': 'saludo',
    'epa': 'saludo',
    'alo': 'saludo',
    'que tal': 'saludo',
    'gracias': 'gracias',
    'muchas gracias': 'gracias',
    'mil gracias': 'gracias',
    'ok gracias': 'gracias',
    'thank you': 'gracias',
    'macias': 'relleno',
    'oye': 'relleno',
    'oiga': 'relleno',
    'mira': 'relleno',
    'una pregunta': 'relleno',
    'tengo una pregunta': 'relleno',
    'otra pregunta': 'relleno',
    'una duda': 'relleno',
    'tengo una duda': 'relleno',
    'una consulta': 'relleno',
    'consulta': 'relleno',
    'pregunta': 'relleno',
    'disculpa': 'relleno',
    'perdon': 'relleno',
    'por favor': 'relleno',
    'ok': 'relleno',
    'dale': 'relleno',
    'bueno': 'relleno',
    'ya': 'relleno',
    'listo': 'relleno',
    'jaja': 'relleno',
    'entonces': 'relleno',
    'y': 'relleno',
    'pero': 'relleno',
    'ah': 'relleno',
    'eh': 'relleno',
    'che': 'relleno',
    'bro': 'relleno',
    'amigo': 'relleno',
    'amiga': 'relleno',
    'otra cosa': 'relleno',
    'una cosa': 'relleno',
  };

  ({_Mensaje resto, bool saludo, bool gracias}) _quitarPrefijos(_Mensaje m) {
    final normales = [
      for (final f in m.fichas) LenguajeMacias.palabrasDe(f.normal).join(' '),
    ];
    var i = 0;
    var saludo = false;
    var gracias = false;
    seguir:
    while (i < normales.length) {
      // "hola mundo" es el primer programa de C++, no un saludo.
      if (normales[i] == 'hola' &&
          i + 1 < normales.length &&
          normales[i + 1] == 'mundo') {
        break;
      }
      // "¿Qué tal es la carrera?" pregunta algo, no saluda.
      if (normales[i] == 'que' &&
          i + 2 < normales.length &&
          normales[i + 1] == 'tal' &&
          const {
            'es',
            'son',
            'esta',
            'estan',
            'seria',
            'fue',
          }.contains(normales[i + 2])) {
        break;
      }
      for (var largo = 3; largo >= 1; largo--) {
        if (i + largo > normales.length) continue;
        final tipo = _prefijos[normales.sublist(i, i + largo).join(' ')];
        if (tipo == null) continue;
        if (tipo == 'saludo') saludo = true;
        if (tipo == 'gracias') gracias = true;
        i += largo;
        continue seguir;
      }
      break;
    }
    if (i == 0) return (resto: m, saludo: false, gracias: false);
    final resto = i >= m.fichas.length
        ? _Mensaje('', const [])
        : _Mensaje.de(m.original.substring(m.fichas[i].inicio));
    return (resto: resto, saludo: saludo, gracias: gracias);
  }

  /// "pedidos", "mi cuenta", "algebra": una palabra que nombra una seccion
  /// entera.
  RespuestaMacias? _porSeccion(List<String> palabras) {
    if (palabras.length > 6) return null;
    final junto = palabras.join(' ');
    if (palabras.length <= 3) {
      for (final seccion in ConocimientoMacias.secciones) {
        if (seccion.claves.contains(junto)) return _abrirSeccion(seccion);
      }
    }
    // "Ayuda con cálculo", "quiero repasar álgebra": una materia se abre
    // aunque venga con relleno alrededor.
    final nucleo = [
      for (final p in palabras)
        if (!_rellenoDeMateria.contains(p)) p,
    ].join(' ');
    if (nucleo.isEmpty || nucleo == junto) return null;
    for (final seccion in ConocimientoMacias.secciones) {
      if (seccion.padre == 'extra' && seccion.claves.contains(nucleo)) {
        return _abrirSeccion(seccion);
      }
    }
    return null;
  }

  static const _rellenoDeMateria = {
    'ayuda',
    'ayudame',
    'con',
    'de',
    'del',
    'sobre',
    'en',
    'quiero',
    'quisiera',
    'aprender',
    'estudiar',
    'repasar',
    'repasemos',
    'practicar',
    'explicame',
    'explica',
    'ensename',
    'hablame',
    'dime',
    'temas',
    'tema',
    'materia',
    'clase',
    'clases',
    'el',
    'la',
    'los',
    'las',
    'mi',
    'me',
    'necesito',
    'un',
    'poco',
    'algo',
    'por',
    'favor',
    'ver',
    'vamos',
    'a',
    'podemos',
    'no',
    'entiendo',
  };

  /// Menos que esto no alcanza para decidir: una sola palabra parecida.
  static const _umbral = 0.7;

  /// Que tan cerca tiene que estar el segundo para preguntar en vez de
  /// adivinar.
  static const _empate = .85;

  /// Lo que suma estar hablando de lo mismo: despues de un tema de C++,
  /// "¿y los punteros?" es de C++ antes que de cualquier otra cosa.
  static const _contexto = .25;

  /// Las palabras que aparecen enteras en alguna clave: esas no se
  /// corrigen. "Cálculo" es una palabra de verdad, no "calcula" mal escrito.
  static final Set<String> _conocidas = {
    for (final tema in ConocimientoMacias.temas)
      for (final clave in tema.claves)
        for (final parte in clave.split(' '))
          if (!parte.endsWith('*')) parte,
    for (final seccion in ConocimientoMacias.secciones)
      for (final clave in seccion.claves) ...clave.split(' '),
  };

  RespuestaMacias? _porTemas(List<String> palabras) {
    final temas = ConocimientoMacias.temas;
    final seccionActual = _seccionActual == null
        ? null
        : ConocimientoMacias.seccion(_seccionActual!);
    final puntajes = <(TemaMacias, double)>[
      for (final tema in temas)
        (
          tema,
          () {
            final base = LenguajeMacias.puntaje(
              tema.claves,
              palabras,
              conocidas: _conocidas,
            );
            final enContexto =
                base > 0 && (seccionActual?.temas.contains(tema.id) ?? false);
            return enContexto ? base + _contexto : base;
          }(),
        ),
    ];
    // Ante un empate gana el que esta antes en la lista: primero la app,
    // despues las materias. Asi lo que ya se sabe de la app tiene prioridad,
    // y la respuesta no cambia de una vez a otra.
    final orden = {for (final (i, tema) in temas.indexed) tema: i};
    puntajes.sort((a, b) {
      final porPuntos = b.$2.compareTo(a.$2);
      return porPuntos != 0 ? porPuntos : orden[a.$1]!.compareTo(orden[b.$1]!);
    });

    final (mejor, puntos) = puntajes.first;
    if (puntos < _umbral) return null;

    final parecidos = [
      for (final (tema, otros) in puntajes.skip(1).take(2))
        if (otros >= _umbral && otros >= puntos * _empate) tema,
    ];
    if (parecidos.isEmpty) return _responderTema(mejor);

    final opciones = [
      mejor.comoOpcion,
      for (final tema in parecidos) tema.comoOpcion,
      _opcionMenu,
    ];
    _vigentes = opciones;
    return RespuestaMacias(
      [BurbujaMacias('¿Cuál de estas buscas?', opciones: opciones)],
      sugerencias: _sugerenciasBase,
      intencion: 'empate',
    );
  }

  // ================================================================== texto
  /// Ver `LenguajeMacias.normalizar`.
  static String normalizar(String texto) => LenguajeMacias.normalizar(texto);

  /// Ver `LenguajeMacias.palabrasDe`.
  static List<String> palabrasDe(String limpio) =>
      LenguajeMacias.palabrasDe(limpio);

  /// Ver `LenguajeMacias.puntaje`.
  static double puntaje(List<String> claves, List<String> palabras) =>
      LenguajeMacias.puntaje(claves, palabras);
}
