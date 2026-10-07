import 'dart:math';

import '../modelos/mensaje_macias.dart';
import 'charla_macias.dart';
import 'conocimiento_macias.dart';
import 'matematica_macias.dart';
import 'memoria_macias.dart';

/// Entiende lo que se le escribe a MacIAs y decide que contestar.
///
/// NO ES UNA IA GENERATIVA. No manda nada a ningun servidor y no inventa:
/// cada respuesta esta escrita a mano (ver `ConocimientoMacias`), y las
/// cuentas se hacen de verdad (ver `MatematicaMacias`). Un asistente
/// "verificado" que alucina una funcion que no existe hace mas dano que no
/// tener asistente.
///
/// Lo que si hace es entender como escribe la gente: sin tildes, con faltas,
/// con abreviaturas de chat, con un "hola" adelante o con un numero suelto
/// que se refiere a la ultima lista que vio. Y se acuerda: de la persona
/// (nombre, carrera, gustos) y de lo que se estaba hablando.
///
/// El orden de las preguntas importa, y es a proposito: primero lo que no
/// admite dudas (un numero, una cuenta, una orden), despues lo que la persona
/// cuenta de si, despues lo que MacIAs sabe de la app y las materias, y solo
/// al final la charla. Lo que ya sabe tiene prioridad sobre conversar.
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

  /// Si MacIAs pregunto "¿a ti te gusta?", sobre que.
  String? _preguntaPorGusto;

  /// Cuantas veces seguidas no se entendio. A la segunda se ofrece una
  /// persona: insistir con lo mismo solo frustra.
  int _sinEntender = 0;

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
    final c = _nuevoContexto();
    final conocido = !memoria.vacia && memoria.nombre != null;
    return _conMenu(
      [
        BurbujaMacias(
          conocido
              ? '¡${c.saludoDelMomento}, ${c.nombre}! Qué bueno verte de '
                    'nuevo.'
              : '¡${c.saludoDelMomento}, ${c.nombre}! Soy **MacIAs**, el '
                    'asistente virtual de U market.',
        ),
      ],
      'Te ayudo con la app y también a estudiar: álgebra, cálculo integral y '
      'C++. Hago cuentas y resuelvo ecuaciones.\n'
      '**Escribe el número de la opción, tócala o pregúntame con tus '
      'palabras:**',
    );
  }

  /// Algo que la persona escribio con sus palabras.
  RespuestaMacias escribir(String texto) {
    final original = texto.trim();
    if (original.contains('👍')) return _sirvio();
    if (original.contains('👎')) return _noSirvio();

    final limpio = normalizar(original);

    // La respuesta a "¿a ti te gusta?" se espera una sola vez.
    final pendiente = _preguntaPorGusto;
    _preguntaPorGusto = null;
    if (pendiente != null) {
      final siNo = CharlaMacias.respuestaSiNo(limpio);
      if (siNo != null) return _anotarGusto(pendiente, siNo);
    }

    if (limpio.isEmpty) {
      return _simple('¿Me lo cuentas con palabras? Así te entiendo mejor.');
    }

    final numero = int.tryParse(limpio);
    if (numero != null) return _porNumero(numero);

    final cuenta = MatematicaMacias.responder(original);
    if (cuenta != null) return _cuenta(cuenta);

    final (saludo: saludo, resto: palabras) = _quitarSaludo(palabrasDe(limpio));
    if (palabras.isEmpty) return saludo ? _saludo() : _noEntendi();
    final junto = palabras.join(' ');

    final orden = _orden(junto);
    if (orden != null) return orden;

    final cuidado = CharlaMacias.cuidado(junto);
    if (cuidado != null) {
      return RespuestaMacias(
        [BurbujaMacias(cuidado)],
        sugerencias: const [chipPersona],
      );
    }

    final dato = _datoPersonal(original, junto);
    if (dato != null) return dato;

    final cortesia = _cortesia(palabras);
    if (cortesia != null) return cortesia;

    final sabido = _porSeccion(palabras) ?? _porTemas(palabras);
    if (sabido != null) return saludo ? _conSaludo(sabido) : sabido;

    final c = _nuevoContexto();
    final charla = CharlaMacias.responder(junto, c, modoMeme: memoria.modoMeme);
    if (charla != null) {
      _sinEntender = 0;
      _preguntaPorGusto = charla.preguntaPorGusto;
      final respuesta = _simple(charla.texto);
      return saludo ? _conSaludo(respuesta) : respuesta;
    }
    return _noEntendi();
  }

  /// Algo que la persona toco: una linea de una lista o un atajo.
  RespuestaMacias elegir(OpcionMacias opcion) {
    _preguntaPorGusto = null;
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
          case 'meme':
            return _modoMeme(!memoria.modoMeme);
        }
    }
    return _noEntendi();
  }

  RespuestaMacias menu() {
    _seccionActual = null;
    _ultimoFueSeccion = false;
    final c = _nuevoContexto();
    final entrada = c.alguna(const [
      'Este es el menú:',
      'Aquí tienes todo lo que sé:',
      'Vamos al menú:',
    ]);
    return _conMenu(
      const [],
      '$entrada\n**Escribe el número de la opción o tócala:**',
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

  // ============================================================= respuestas
  RespuestaMacias _abrirSeccion(SeccionMacias seccion) {
    _sinEntender = 0;
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
    return RespuestaMacias([
      BurbujaMacias(
        '${seccion.intro}\n**Escribe el número o toca una opción:**',
        opciones: opciones,
      ),
    ], sugerencias: _sugerenciasBase);
  }

  /// Una linea de una seccion: un tema, otra seccion o una orden.
  OpcionMacias _opcionDe(String entrada) {
    if (entrada == ConocimientoMacias.ordenMeme) {
      return OpcionMacias(
        id: ConocimientoMacias.ordenMeme,
        texto: memoria.modoMeme
            ? 'Desactivar el modo meme'
            : 'Activar el modo meme',
      );
    }
    if (entrada.startsWith('s:')) {
      return ConocimientoMacias.seccion(entrada.substring(2))!.comoOpcion;
    }
    return ConocimientoMacias.tema(entrada)!.comoOpcion;
  }

  RespuestaMacias _responderTema(TemaMacias tema) {
    _sinEntender = 0;
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
  /// el menu. En modo meme, con su broma.
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

    final cierre = c.alguna(const [
      '¿Te ayudo con algo más?',
      '¿Quieres saber algo más?',
      '¿Algo más en lo que te ayude?',
    ]);
    final broma = memoria.modoMeme
        ? '${CharlaMacias.meme(ConocimientoMacias.areaDe(tema.id), c)}\n\n'
        : '';
    return RespuestaMacias(
      [respuesta, BurbujaMacias('$broma$cierre', opciones: opciones)],
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
      return RespuestaMacias([
        BurbujaMacias(
          'Es lo más concreto que tengo sobre "${tema.pregunta}". Quizá te '
          'sirva uno de estos temas, o alguien del equipo:',
          opciones: opciones,
        ),
      ], sugerencias: _sugerenciasBase);
    }
    return _conSeguimiento(tema, BurbujaMacias(ampliacion(c)), c);
  }

  RespuestaMacias _cuenta(String resultado) {
    _sinEntender = 0;
    _ultimoTema = 'calculadora';
    final c = _nuevoContexto();
    return RespuestaMacias(
      [
        BurbujaMacias(
          memoria.modoMeme
              ? '$resultado\n\n${CharlaMacias.meme('algebra', c)}'
              : resultado,
        ),
      ],
      sugerencias: const [chipMenu, chipMaterias],
    );
  }

  RespuestaMacias _porNumero(int numero) {
    if (numero >= 1 && numero <= _vigentes.length) {
      return elegir(_vigentes[numero - 1]);
    }
    return RespuestaMacias([
      BurbujaMacias(
        'No tengo la opción $numero. Elige un número del 1 al '
        '${_vigentes.length}, o escribe **menú** para ver todo.',
        opciones: _vigentes,
      ),
    ], sugerencias: _sugerenciasBase);
  }

  RespuestaMacias _saludo() {
    final c = _nuevoContexto();
    final entrada = c.alguna([
      '¡Hola de nuevo, ${c.nombre}! ¿En qué te ayudo?',
      '¡${c.saludoDelMomento}, ${c.nombre}! Dime qué necesitas.',
    ]);
    return _conMenu(
      const [],
      '$entrada\n**Escribe el número de la opción o tócala:**',
    );
  }

  /// "Hola, ¿cómo publico?": se contesta la pregunta, sin ignorar el saludo.
  RespuestaMacias _conSaludo(RespuestaMacias respuesta) {
    final c = _nuevoContexto();
    final primera = respuesta.burbujas.first;
    return RespuestaMacias(
      [
        BurbujaMacias(
          '¡Hola, ${c.nombre}! ${primera.texto}',
          opciones: primera.opciones,
          acciones: primera.acciones,
        ),
        ...respuesta.burbujas.skip(1),
      ],
      sugerencias: respuesta.sugerencias,
      temaId: respuesta.temaId,
    );
  }

  RespuestaMacias _sirvio() {
    final c = _nuevoContexto();
    return _simple(
      c.alguna([
        'Genial, ${c.nombre}. Me alegra haberte ayudado.',
        'Bien. Para eso estoy.',
      ]),
    );
  }

  RespuestaMacias _noSirvio() {
    final opciones = [
      ConocimientoMacias.tema(ConocimientoMacias.humano)!.comoOpcion,
      _opcionMenu,
    ];
    _vigentes = opciones;
    return RespuestaMacias([
      BurbujaMacias(
        'Gracias por decírmelo. Prueba explicándomelo con otras palabras, o '
        'habla con una persona del equipo:',
        opciones: opciones,
      ),
    ], sugerencias: _sugerenciasBase);
  }

  RespuestaMacias _noEntendi() {
    _sinEntender++;
    final c = _nuevoContexto();
    final inicio = memoria.modoMeme
        ? c.alguna(const [
            'Eso no está ni en el Baldor.',
            'Me dejaste en segmentation fault.',
            'Esa me agarró sin la + C.',
          ])
        : c.alguna(const [
            'No tengo una respuesta para eso todavía.',
            'Esa todavía no me la sé.',
            'Creo que no te entendí bien.',
          ]);
    if (_sinEntender >= 2) {
      final opciones = [
        ConocimientoMacias.tema(ConocimientoMacias.humano)!.comoOpcion,
        _opcionMenu,
      ];
      _vigentes = opciones;
      return RespuestaMacias([
        BurbujaMacias(
          '$inicio\nSi quieres, te paso con una persona del equipo:',
          opciones: opciones,
        ),
      ], sugerencias: _sugerenciasBase);
    }
    return _simple(
      '$inicio\nPuedo ayudarte con la app, con álgebra, cálculo o C++, o '
      'hacer cuentas. Escribe **menú** para ver todo.',
    );
  }

  RespuestaMacias _modoMeme(bool prender) {
    memoria.modoMeme = prender;
    return _simple(
      prender
          ? 'Modo meme activado. Respondo igual de bien, pero con más calle. '
                'Para volver al modo serio, escribe **modo serio**.'
          : 'Modo meme desactivado. Volvemos a la seriedad.',
    );
  }

  RespuestaMacias _simple(String texto) =>
      RespuestaMacias([BurbujaMacias(texto)], sugerencias: _sugerenciasBase);

  RespuestaMacias _conMenu(List<BurbujaMacias> antes, String texto) {
    _vigentes = ConocimientoMacias.menuPrincipal;
    return RespuestaMacias(
      [...antes, BurbujaMacias(texto, opciones: _vigentes)],
      sugerencias: const [chipMaterias, chipPersona],
    );
  }

  ContextoMacias _nuevoContexto() {
    final base = contexto();
    return ContextoMacias(
      nombre: memoria.nombre ?? base.nombre,
      ahora: base.ahora,
      version: base.version,
      esWeb: base.esWeb,
      sorteo: _azar.nextInt(1 << 20),
      memoria: memoria,
    );
  }

  // ================================================================ memoria
  /// Lo que la persona cuenta de si, o pregunta sobre lo que se le conto.
  RespuestaMacias? _datoPersonal(String original, String junto) {
    if (_olvidar.any(junto.contains)) {
      memoria.olvidar();
      return _simple(
        'Listo, olvidé lo que sabía de ti. Si quieres, cuéntame de nuevo.',
      );
    }

    final nombre = CharlaMacias.nombreEn(original);
    if (nombre != null) {
      if (_groserias.any(normalizar(nombre).contains)) {
        return _simple('Prefiero llamarte por tu nombre de verdad.');
      }
      memoria.nombre = nombre;
      return _simple(
        'Mucho gusto, $nombre. Desde ahora te llamo así. Lo guardo solo en '
        'este teléfono.',
      );
    }

    final carrera = CharlaMacias.carreraEn(junto);
    if (carrera != null) {
      memoria.carrera = carrera;
      final ingenieria = carrera.startsWith('Ingeniería');
      return _simple(
        'Anotado: estudias $carrera. '
        '${ingenieria ? 'Si te toca cálculo o C++, aquí estoy.' : 'Si te toca álgebra, aquí estoy.'}',
      );
    }

    final gusto = CharlaMacias.gustoEn(junto);
    if (gusto != null) return _anotarGusto(gusto.cosa, gusto.gusta);

    final c = _nuevoContexto();
    if (_preguntasNombre.contains(junto)) {
      return _simple(
        memoria.nombre != null
            ? 'Te llamas ${memoria.nombre}.'
            : 'Según tu perfil, te llamas ${c.nombre}. Si prefieres que te '
                  'diga de otra forma, escribe **me llamo** y tu nombre.',
      );
    }
    if (_preguntasCarrera.contains(junto)) {
      return _simple(
        memoria.carrera != null
            ? 'Estudias ${memoria.carrera}.'
            : 'Todavía no me lo dijiste. Escribe, por ejemplo, **estudio '
                  'sistemas**.',
      );
    }
    if (_preguntasGustos.contains(junto)) {
      return _simple(
        memoria.gustos.isEmpty
            ? 'Todavía no me contaste. Escribe, por ejemplo, **me gusta la '
                  'pizza**.'
            : 'Me dijiste que te gusta: ${memoria.gustos.join(', ')}.',
      );
    }
    if (_pedidosDeAmpliar.contains(junto) && _ultimoTema != null) {
      return _ampliar();
    }
    return null;
  }

  RespuestaMacias _anotarGusto(String cosa, bool gusta) {
    if (gusta) {
      memoria.anotarGusto(cosa);
    } else {
      memoria.anotarDisgusto(cosa);
    }
    return _simple(
      gusta
          ? 'Anotado: te gusta $cosa. Me lo voy a acordar.'
          : 'Anotado: no te gusta $cosa. No te lo voy a recomendar.',
    );
  }

  static const _olvidar = [
    'olvida lo que sabes',
    'olvidate de mi',
    'olvida todo',
    'borra lo que sabes',
    'borra mi memoria',
    'olvida mi nombre',
  ];
  static const _preguntasNombre = {
    'como me llamo',
    'sabes como me llamo',
    'cual es mi nombre',
    'sabes mi nombre',
    'te acuerdas de mi nombre',
  };
  static const _preguntasCarrera = {
    'que estudio',
    'que carrera estudio',
    'cual es mi carrera',
    'sabes que estudio',
    'sabes mi carrera',
  };
  static const _preguntasGustos = {
    'que me gusta',
    'sabes que me gusta',
    'que cosas me gustan',
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
    'mas',
  };

  // ============================================================ comprension
  static const _ordenesMenu = {
    'menu',
    'menu principal',
    'el menu',
    'ver menu',
    'inicio',
    'opciones',
    'ver opciones',
    'empezar',
    'principal',
  };
  static const _ordenesVolver = {'volver', 'atras', 'regresar', 'anterior'};
  static const _prenderMeme = {
    'modo meme',
    'activa modo meme',
    'activar modo meme',
    'activa el modo meme',
    'activar el modo meme',
    'prende el modo meme',
    'prende modo meme',
    'modo meme on',
  };
  static const _apagarMeme = {
    'modo serio',
    'desactiva modo meme',
    'desactivar modo meme',
    'desactiva el modo meme',
    'desactivar el modo meme',
    'apaga el modo meme',
    'apaga modo meme',
    'quita el modo meme',
    'modo meme off',
    'sin memes',
  };

  RespuestaMacias? _orden(String junto) {
    if (_ordenesMenu.contains(junto)) return menu();
    if (_ordenesVolver.contains(junto)) return volver();
    if (_prenderMeme.contains(junto)) return _modoMeme(true);
    if (_apagarMeme.contains(junto)) return _modoMeme(false);
    return null;
  }

  static const _saludos = {
    'hola',
    'holaa',
    'holi',
    'holis',
    'hey',
    'hello',
    'buenas',
    'buenos',
    'buen',
    'saludos',
  };
  static const _momentos = {
    'dia',
    'dias',
    'tarde',
    'tardes',
    'noche',
    'noches',
  };

  /// Quita el saludo del principio: "hola buenas tardes como publico" queda
  /// en "como publico", y se recuerda que hubo saludo.
  static ({bool saludo, List<String> resto}) _quitarSaludo(
    List<String> palabras,
  ) {
    var i = 0;
    var saludo = false;
    while (i < palabras.length) {
      final palabra = palabras[i];
      // "hola mundo" es el primer programa de C++, no un saludo.
      final esHolaMundo =
          palabra == 'hola' &&
          i + 1 < palabras.length &&
          palabras[i + 1] == 'mundo';
      if (_saludos.contains(palabra) && !esHolaMundo) {
        saludo = true;
        i++;
      } else if (saludo && _momentos.contains(palabra)) {
        i++;
      } else if (saludo &&
          palabra == 'que' &&
          i + 1 < palabras.length &&
          palabras[i + 1] == 'tal') {
        i += 2;
      } else if (palabra == 'macias' && i == 0 && palabras.length > 1) {
        // "MacIAs, ¿cómo publico?": lo llama por su nombre.
        i++;
      } else {
        break;
      }
    }
    return (saludo: saludo, resto: palabras.sublist(i));
  }

  static const _gracias = {'gracias', 'grax', 'agradezco', 'agradecido'};
  static const _acuerdo = {
    'ok',
    'okey',
    'okay',
    'vale',
    'listo',
    'dale',
    'genial',
    'perfecto',
    'excelente',
    'buenisimo',
    'buenisima',
    'joya',
    'entendido',
    'entendi',
    'bien',
    'super',
    'chevere',
    'claro',
    'si',
    'muy',
  };
  static const _despedidas = {'chau', 'chao', 'adios', 'bye', 'byebye'};
  static const _frasesDespedida = [
    'nos vemos',
    'hasta luego',
    'hasta pronto',
    'hasta manana',
  ];
  static const _groserias = {
    'tonto',
    'tonta',
    'idiota',
    'estupido',
    'estupida',
    'inutil',
    'basura',
    'pesimo',
    'pesima',
    'malisimo',
    'malisima',
  };
  static const _charlaCorta = {
    'como estas',
    'como te va',
    'como andas',
    'que tal',
    'todo bien',
    'que haces',
  };

  /// Gracias, chau, un "ok" suelto, una groseria o un "¿cómo estás?". Solo
  /// en mensajes cortos: "gracias, ¿y cómo publico?" es una pregunta.
  RespuestaMacias? _cortesia(List<String> palabras) {
    if (palabras.length > 5) return null;
    final c = _nuevoContexto();
    final junto = palabras.join(' ');

    if (palabras.any(_groserias.contains)) {
      return _simple(
        'Ouch. Sigo aquí para ayudarte, ${c.nombre}. ¿Probamos de nuevo? '
        'Escribe tu pregunta o elige una opción.',
      );
    }
    if (palabras.any(_despedidas.contains) ||
        _frasesDespedida.any(junto.contains)) {
      return RespuestaMacias(
        [
          BurbujaMacias(
            c.alguna([
              '¡Hasta pronto, ${c.nombre}! Aquí estaré cuando me necesites.',
              '¡Chau, ${c.nombre}! Que te vaya muy bien en el campus.',
            ]),
          ),
        ],
        sugerencias: const [chipMenu],
      );
    }
    if (palabras.any(_gracias.contains)) {
      return _simple(
        c.alguna([
          'De nada, ${c.nombre}. ¿Te ayudo con algo más?',
          'Para eso estoy. Si necesitas algo más, aquí sigo.',
          'Un gusto ayudarte, ${c.nombre}.',
        ]),
      );
    }
    if (_charlaCorta.contains(junto)) {
      return _simple(
        memoria.modoMeme
            ? 'Aquí, respondiendo más rápido que el WiFi de la U. ¿Y tú, qué '
                  'necesitas?'
            : 'Muy bien, gracias por preguntar. ¿En qué te ayudo?',
      );
    }
    if (palabras.every(_acuerdo.contains)) {
      return _simple('Perfecto. ¿Algo más en lo que te ayude?');
    }
    return null;
  }

  /// "pedidos", "mi cuenta", "algebra": una palabra que nombra una seccion
  /// entera.
  RespuestaMacias? _porSeccion(List<String> palabras) {
    if (palabras.length > 3) return null;
    final junto = palabras.join(' ');
    for (final seccion in ConocimientoMacias.secciones) {
      if (seccion.claves.contains(junto)) return _abrirSeccion(seccion);
    }
    return null;
  }

  /// Menos que esto no alcanza para decidir: una sola palabra parecida.
  static const _umbral = 0.7;

  /// Que tan cerca tiene que estar el segundo para preguntar en vez de
  /// adivinar.
  static const _empate = .85;

  /// Lo que suma estar hablando de lo mismo: despues de un tema de C++,
  /// "¿y los punteros?" es de C++ antes que de cualquier otra cosa.
  static const _contexto = .25;

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
            final base = puntaje(tema.claves, palabras);
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
    _sinEntender = 0;
    return RespuestaMacias([
      BurbujaMacias('¿Cuál de estas buscas?', opciones: opciones),
    ], sugerencias: _sugerenciasBase);
  }

  // ================================================================== texto
  /// Minusculas, sin tildes ni signos, espacios simples.
  ///
  /// "¿Cómo PUBLICO algo?!" y "como publico algo" tienen que ser lo mismo:
  /// en un chat nadie escribe con tildes.
  static String normalizar(String texto) {
    const tildes = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final salida = StringBuffer();
    for (final letra in texto.toLowerCase().split('')) {
      final sinTilde = tildes[letra] ?? letra;
      final codigo = sinTilde.codeUnitAt(0);
      final esValida =
          (codigo >= 0x61 && codigo <= 0x7a) ||
          (codigo >= 0x30 && codigo <= 0x39);
      salida.write(esValida ? sinTilde : ' ');
    }
    return salida.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Abreviaturas de chat que cambian el sentido si no se entienden.
  static const _abreviaturas = {
    'q': 'que',
    'k': 'que',
    'xq': 'porque',
    'pq': 'porque',
    'porq': 'porque',
    'x': 'por',
    'tb': 'tambien',
    'tmb': 'tambien',
    'pa': 'para',
    'porfa': 'por favor',
    'xfa': 'por favor',
    'ola': 'hola',
    'wsp': 'whatsapp',
    'wpp': 'whatsapp',
    'whats': 'whatsapp',
    'wasap': 'whatsapp',
    'notis': 'notificaciones',
    'noti': 'notificacion',
    'cel': 'celular',
    'info': 'informacion',
  };

  static List<String> palabrasDe(String limpio) => [
    for (final palabra in limpio.split(' '))
      if (palabra.isNotEmpty) ...(_abreviaturas[palabra] ?? palabra).split(' '),
  ];

  /// Cuanto se parece un mensaje a un tema.
  ///
  /// Cada clave que aparece suma; una frase de dos palabras pesa el doble
  /// que una suelta, porque "borrar cuenta" dice mucho mas que "cuenta". Las
  /// palabras de la frase pueden estar en cualquier orden. Lo que coincide
  /// solo de forma aproximada (con una falta) suma menos.
  static double puntaje(List<String> claves, List<String> palabras) {
    var total = 0.0;
    for (final clave in claves) {
      final partes = clave.split(' ');
      var minimo = 1.0;
      for (final parte in partes) {
        final coincidencia = _coincide(parte, palabras);
        if (coincidencia < minimo) minimo = coincidencia;
        if (minimo == 0) break;
      }
      if (minimo > 0) total += partes.length * minimo;
    }
    return total;
  }

  /// 1 si alguna palabra es la clave (o empieza con ella, si termina en `*`),
  /// 0.7 si se le parece con una sola letra de diferencia, 0 si no.
  ///
  /// Lo aproximado solo vale en palabras largas: entre palabras cortas una
  /// letra cambia el sentido ("marco" y "marca").
  static double _coincide(String clave, List<String> palabras) {
    final prefijo = clave.endsWith('*');
    final raiz = prefijo ? clave.substring(0, clave.length - 1) : clave;
    var mejor = 0.0;
    for (final palabra in palabras) {
      if (prefijo ? palabra.startsWith(raiz) : palabra == raiz) return 1;
      if (raiz.length < 6 || palabra.length < 5) continue;
      if (prefijo) {
        for (var largo = raiz.length - 1; largo <= raiz.length + 1; largo++) {
          if (largo > palabra.length) break;
          if (_distancia(palabra.substring(0, largo), raiz) <= 1) {
            mejor = .7;
          }
        }
      } else if (_distancia(palabra, raiz) <= 1) {
        mejor = .7;
      }
    }
    return mejor;
  }

  /// Distancia de edicion con transposiciones: "pulbicar" esta a 1 de
  /// "publicar", porque intercambiar dos letras vecinas es la falta mas
  /// comun al escribir rapido.
  static int _distancia(String a, String b) {
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
}
