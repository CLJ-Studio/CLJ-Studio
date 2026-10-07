import 'dart:math' as math;

/// Cuentas y ecuaciones para MacIAs.
///
/// Todo lo exacto se hace con fracciones de enteros grandes, no con
/// decimales: "x = 7/3" es la respuesta que espera un profesor, y
/// "x = 2.3333333333333335" no. Los decimales aparecen solo como apoyo (≈).
abstract final class MatematicaMacias {
  /// Si el mensaje es una cuenta o una ecuacion, la respuesta ya escrita.
  ///
  /// Null si no lo es: el mensaje sigue su camino normal. [pedido] dice si
  /// la persona lo anuncio ("calcula", "resuelve"); sin eso, solo se toma
  /// como cuenta algo que sea claramente matematico, para no robarle a la
  /// conversacion un "2 pedidos" cualquiera.
  static String? responder(String mensaje) {
    final operacion = _operacion(mensaje);
    if (operacion != null) return operacion;
    final (pedido: pedido, resto: resto) = _quitarPedido(mensaje.trim());
    if (resto.isEmpty) return null;

    final preparado = _preparar(resto);
    if (!RegExp(r'\d').hasMatch(preparado)) return null;
    if (preparado.contains('=')) {
      if (!pedido && !_pareceEcuacion(preparado)) return null;
      return resolverEcuacion(preparado);
    }
    // Sin igual no hay incognita: "3x4" o "3 x 4" es tres por cuatro.
    final cuenta = preparado.replaceAllMapped(
      RegExp(r'(\d)\s*x\s*(?=\d)'),
      (m) => '${m[1]}*',
    );
    if (!pedido && !_pareceCuenta(cuenta)) return null;
    if (_fichasSinFallar(cuenta).any((f) => f.tipo == _TipoFicha.incognita)) {
      return pedido
          ? 'Para resolver, escríbela con su signo igual. Por ejemplo: '
                '**resuelve 2x + 3 = 11**'
          : null;
    }
    return calcular(cuenta, anunciado: pedido);
  }

  static List<_Ficha> _fichasSinFallar(String texto) {
    try {
      return _fichas(texto);
    } on FormatException {
      return const [];
    }
  }

  // ------------------------------------------------------------ cuentas
  static String? calcular(String expresion, {bool anunciado = true}) {
    try {
      final lector = _Lector(_fichas(expresion));
      final valor = lector.numero();
      lector.terminar();
      final escrita = _mostrarExpresion(expresion);
      if (valor.isInfinite) {
        return 'No se puede dividir entre cero, ni siquiera en el Baldor.';
      }
      if (valor.isNaN) {
        return 'Eso no tiene resultado en los números reales (por ejemplo, '
            'la raíz de un negativo o el logaritmo de cero).';
      }
      final grados = lector.usoGrados
          ? '\nLos ángulos los tomé en grados. Si eran radianes, escríbelos '
                'con pi, por ejemplo sen(pi/6).'
          : '';
      return '$escrita = **${formatearDecimal(valor)}**$grados';
    } on FormatException {
      return anunciado
          ? 'No pude leer esa cuenta. Usa + − * / ^ y paréntesis, por ejemplo: '
                '**calcula (3 + 4) * 2^3**'
          : null;
    }
  }

  // ---------------------------------------------------------- ecuaciones
  static String resolverEcuacion(String ecuacion) {
    final lados = ecuacion.split('=');
    if (lados.length != 2 || lados.any((lado) => lado.trim().isEmpty)) {
      return 'Escribe una sola igualdad, por ejemplo: **resuelve 2x + 3 = 11**';
    }
    final Polinomio izquierda;
    final Polinomio derecha;
    try {
      izquierda = _Lector(_fichas(lados[0])).polinomioCompleto();
      derecha = _Lector(_fichas(lados[1])).polinomioCompleto();
    } on _GradoAlto {
      return 'Resuelvo ecuaciones hasta grado 4 (las de grado 3 y 4, si se '
          'pueden factorizar). Esa tiene grado mayor: prueba factorizarla '
          'primero (te explico cómo si escribes **factorización**).';
    } on FormatException {
      return 'No pude leer esa ecuación. Usa x como incógnita, ^ para '
          'potencias y * si hace falta, por ejemplo: '
          '**resuelve x^2 - 5x + 6 = 0**';
    }

    final p = izquierda - derecha;
    if (p.grado > 2) {
      return _porFactores(
        '${_mostrarExpresion(lados[0])} = ${_mostrarExpresion(lados[1])}',
        p,
      );
    }
    final a = p[2], b = p[1], c = p[0];
    final enunciado =
        '${_mostrarExpresion(lados[0])} = '
        '${_mostrarExpresion(lados[1])}';

    if (a.esCero && b.esCero) {
      return c.esCero
          ? '$enunciado\nLos dos lados son iguales para cualquier valor: es '
                'una identidad. **Toda x es solución.**'
          : '$enunciado\nAl ordenar queda ${c.texto} = 0, que es falso. '
                '**No tiene solución.**';
    }

    if (a.esCero) {
      final x = -c / b;
      // Con enteros se lee mejor: x/2 + 1 = 4 queda x − 6 = 0.
      final escala = Racional.entero(_mcm(b.denominador, c.denominador));
      var eb = (b * escala).numerador;
      var ec = (c * escala).numerador;
      final comun = eb.gcd(ec);
      if (comun > BigInt.one) {
        eb ~/= comun;
        ec ~/= comun;
      }
      if (eb.isNegative) {
        eb = -eb;
        ec = -ec;
      }
      // Si cambio algo al pasar a enteros se dice: si no, aparece un
      // "x − 4" que nadie escribio.
      final simplificada = Racional.entero(eb) != b || Racional.entero(ec) != c;
      final ordenada = Polinomio([
        Racional.entero(ec),
        Racional.entero(eb),
      ]).texto;
      final despeje = eb == BigInt.one
          ? 'x = ${_entero(-ec)}'
          : 'x = ${_entero(-ec)} / $eb';
      return '**Ecuación de primer grado**\n'
          '$enunciado\n'
          '${simplificada ? 'Ordenada y simplificada' : 'Ordenada'}: '
          '$ordenada = 0\n'
          'Despejas x: $despeje\n'
          '**x = ${x.textoConDecimal}**';
    }
    return _cuadratica(enunciado, a, b, c);
  }

  static String _cuadratica(
    String enunciado,
    Racional a,
    Racional b,
    Racional c,
  ) {
    // Con enteros se lee mejor y el discriminante queda exacto.
    final escala = Racional.entero(
      _mcm(_mcm(a.denominador, b.denominador), c.denominador),
    );
    var ea = (a * escala).numerador;
    var eb = (b * escala).numerador;
    var ec = (c * escala).numerador;
    // Tambien sin un factor comun que solo agranda los numeros.
    final comun = ea.gcd(eb).gcd(ec);
    if (comun > BigInt.one) {
      ea ~/= comun;
      eb ~/= comun;
      ec ~/= comun;
    }
    if (ea.isNegative) {
      ea = -ea;
      eb = -eb;
      ec = -ec;
    }
    final ordenada = Polinomio([
      Racional.entero(ec),
      Racional.entero(eb),
      Racional.entero(ea),
    ]).texto;
    final delta = eb * eb - BigInt.from(4) * ea * ec;
    final dosA = BigInt.two * ea;
    final pasos = StringBuffer()
      ..writeln('**Ecuación de segundo grado**')
      ..writeln(enunciado)
      ..writeln('Ordenada: $ordenada = 0')
      ..writeln('a = ${_entero(ea)}, b = ${_entero(eb)}, c = ${_entero(ec)}')
      ..writeln(
        'Discriminante: Δ = b² − 4ac = ${eb * eb} − '
        '${_enParentesis(BigInt.from(4) * ea * ec)} = ${_entero(delta)}',
      );

    if (delta.isNegative) {
      final (fuera, dentro) = _simplificarRaiz(-delta);
      var real = -eb;
      var imaginaria = fuera;
      var denominador = dosA;
      final divisor = real.gcd(imaginaria).gcd(denominador);
      if (divisor > BigInt.one) {
        real ~/= divisor;
        imaginaria ~/= divisor;
        denominador ~/= divisor;
      }
      final parteImaginaria =
          '${imaginaria == BigInt.one ? '' : imaginaria}i'
          '${dentro == BigInt.one ? '' : '√$dentro'}';
      final arriba = real == BigInt.zero
          ? '±$parteImaginaria'
          : '${_entero(real)} ± $parteImaginaria';
      final exacta = denominador == BigInt.one
          ? arriba
          : '($arriba) / $denominador';
      final aproximadaReal = -eb.toDouble() / dosA.toDouble();
      final aproximadaImaginaria =
          math.sqrt((-delta).toDouble()) / dosA.toDouble();
      final hayAproximacion = dentro != BigInt.one || denominador != BigInt.one;
      pasos
        ..writeln('Como Δ < 0, **no tiene soluciones reales.**')
        ..write('En los números complejos: x = $exacta');
      if (hayAproximacion) {
        pasos.write(
          '  (≈ ${formatearDecimal(aproximadaReal)} ± '
          '${formatearDecimal(aproximadaImaginaria)}i)',
        );
      }
      return pasos.toString();
    }

    if (delta == BigInt.zero) {
      final x = Racional(-eb, dosA);
      pasos
        ..writeln('Como Δ = 0, hay una sola solución (doble):')
        ..writeln('x = −b / 2a = ${_entero(-eb)} / $dosA')
        ..write('**x = ${x.textoConDecimal}**');
      if (ea == BigInt.one && x.esEntero) {
        pasos.write('\nFactorizada: (${_binomio(x)})² = 0');
      }
      return pasos.toString();
    }

    final (fuera, dentro) = _simplificarRaiz(delta);
    if (dentro == BigInt.one) {
      // Δ es un cuadrado perfecto: soluciones exactas, sin raices.
      final x1 = Racional(-eb + fuera, dosA);
      final x2 = Racional(-eb - fuera, dosA);
      pasos
        ..writeln('x = (−b ± √Δ) / 2a = (${_entero(-eb)} ± $fuera) / $dosA')
        ..write('**x₁ = ${x1.textoConDecimal}, x₂ = ${x2.textoConDecimal}**');
      if (ea == BigInt.one && x1.esEntero && x2.esEntero) {
        pasos.write('\nFactorizada: (${_binomio(x1)})(${_binomio(x2)}) = 0');
      }
      return pasos.toString();
    }

    // Raiz que no es exacta: se deja simplificada y con su aproximacion.
    var numeradorFuera = -eb;
    var coeficiente = fuera;
    var denominador = dosA;
    final divisor = numeradorFuera.gcd(coeficiente).gcd(denominador);
    if (divisor > BigInt.one) {
      numeradorFuera ~/= divisor;
      coeficiente ~/= divisor;
      denominador ~/= divisor;
    }
    final raiz = '${coeficiente == BigInt.one ? '' : coeficiente}√$dentro';
    final arriba = numeradorFuera == BigInt.zero
        ? '±$raiz'
        : '${_entero(numeradorFuera)} ± $raiz';
    final exacta = denominador == BigInt.one
        ? arriba
        : '($arriba) / $denominador';
    final raizDelta = math.sqrt(delta.toDouble());
    final x1 = (-eb.toDouble() + raizDelta) / dosA.toDouble();
    final x2 = (-eb.toDouble() - raizDelta) / dosA.toDouble();
    pasos
      ..writeln('x = (−b ± √Δ) / 2a = (${_entero(-eb)} ± √$delta) / $dosA')
      ..writeln('**x = $exacta**')
      ..write('x₁ ≈ ${formatearDecimal(x1)}, x₂ ≈ ${formatearDecimal(x2)}');
    return pasos.toString();
  }

  /// "x − 3" para la raiz 3: el factor que la produce.
  static String _binomio(Racional raiz) {
    if (raiz.esCero) return 'x';
    return raiz.numerador.isNegative
        ? 'x + ${(-raiz).texto}'
        : 'x − ${raiz.texto}';
  }

  /// √n = afuera·√adentro, con adentro sin cuadrados: √12 = 2√3.
  static (BigInt, BigInt) _simplificarRaiz(BigInt n) {
    var afuera = BigInt.one;
    var adentro = n;
    var factor = BigInt.two;
    while (factor * factor <= adentro) {
      final cuadrado = factor * factor;
      while (adentro % cuadrado == BigInt.zero) {
        adentro ~/= cuadrado;
        afuera *= factor;
      }
      factor += BigInt.one;
      // Numeros enormes: no vale la pena seguir buscando a mano.
      if (factor > BigInt.from(100000)) break;
    }
    return (afuera, adentro);
  }

  static BigInt _mcm(BigInt a, BigInt b) => a ~/ a.gcd(b) * b;

  /// "−5" con el menos de verdad.
  static String _entero(BigInt n) => n.isNegative ? '−${-n}' : '$n';

  /// "(−5)" si es negativo, para que no queden dos signos pegados.
  static String _enParentesis(BigInt n) =>
      n.isNegative ? '(${_entero(n)})' : '$n';

  // ------------------------------------------ operaciones con polinomios
  static const _prefijoOperacion =
      r'^(?:(?:cual es|cuanto es|cuanto da|dime|me das|me dices|calcula|'
      r'calculame|halla|hallame|encuentra|saca|sacame|resuelve|resuelveme|'
      r'haz|hazme|necesito|quiero|ayudame con|ayudame a)\s+)?'
      r'(?:la |el |una |un )?';

  static final _derivar = RegExp(
    '$_prefijoOperacion(?:derivada|derivadas|deriva|derivar|derivame|derive)'
    r'(?: de| del)?(?: la funcion| la expresion| el polinomio)?\s+(.+)$',
  );
  static final _integrar = RegExp(
    '$_prefijoOperacion(?:integral|integra|integrar|integrame|integre|'
    r'antiderivada|primitiva)(?: indefinida| definida)?(?: de| del)?'
    r'(?: la funcion| la expresion| el polinomio)?\s+(.+)$',
  );
  static final _factorizar = RegExp(
    '$_prefijoOperacion(?:factoriza|factorizar|factorizame|factorice|'
    r'factorizacion de|factorizacion del|descompon|descomponer)\s+(.+)$',
  );
  static final _expandir = RegExp(
    '$_prefijoOperacion(?:expande|expandir|expandeme|desarrolla|desarrollar|'
    r'desarrollame|multiplica|multiplicar|simplifica|simplificar|reduce|'
    r'reducir)\s+(.+)$',
  );

  /// Lo que se puede pedir sobre un polinomio: derivarlo, integrarlo,
  /// factorizarlo o desarrollarlo.
  static String? _operacion(String mensaje) {
    final t = _sinTildes(mensaje.trim().toLowerCase())
        .replaceAll('∫', ' integral ')
        .replaceAll(RegExp(r'^[¿¡\s]+|[?!.\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // "Derivada" e "integral" tambien son temas: "integral definida" se
    // explica, no se calcula. Solo es cuenta si lo que sigue es una
    // expresion.
    final derivar = _derivar.firstMatch(t);
    if (derivar != null) {
      final expresion = _soloExpresion(derivar[1]!);
      return _pareceExpresion(expresion) ? _derivada(expresion) : null;
    }
    final integrar = _integrar.firstMatch(t);
    if (integrar != null) {
      final sinLimites = _soloExpresion(
        integrar[1]!.replaceAll(
          RegExp(r'\b(?:de|del|desde|entre|a|hasta|y)\b'),
          ' ',
        ),
      );
      return _pareceExpresion(sinLimites) ? _integral(integrar[1]!) : null;
    }
    // "Factoriza" y "simplifica" tambien se dicen fuera de matematicas:
    // solo se toman si lo que sigue parece una expresion.
    final factorizar = _factorizar.firstMatch(t);
    if (factorizar != null) {
      final expresion = _soloExpresion(factorizar[1]!);
      return _pareceExpresion(expresion) ? _factorizada(expresion) : null;
    }
    final expandir = _expandir.firstMatch(t);
    if (expandir != null) {
      final expresion = _soloExpresion(expandir[1]!);
      return _pareceExpresion(expresion) ? _expandida(expresion) : null;
    }
    return null;
  }

  /// Sin "f(x) =", sin "dx", sin "respecto a x": la expresion sola.
  static String _soloExpresion(String texto) => texto
      .replaceFirst(RegExp(r'^[:\s]+'), '')
      .replaceFirst(RegExp(r'^[fghy]\s*(?:\(\s*x\s*\))?\s*=\s*'), '')
      .replaceAll(RegExp(r'\s*(?:con )?respecto (?:a|de) x\s*'), ' ')
      .replaceAll(RegExp(r'\s*d\s*x\s*$'), '')
      .trim();

  static bool _pareceExpresion(String texto) {
    if (!RegExp(r'[x\d]').hasMatch(texto)) return false;
    final resto = texto
        .replaceAll(
          RegExp(
            r'\b(?:raiz|sqrt|sen|sin|cos|tan|tg|sec|ln|log|abs|pi|mas|menos|'
            r'por|entre|al cuadrado|al cubo|elevado a la|elevado a)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[x\d\s+\-*/^().,²³√−·×÷e]'), '');
    return resto.isEmpty;
  }

  static Polinomio _polinomio(String expresion) => _Lector(
    _fichas(_preparar(expresion)),
    gradoMaximo: 12,
  ).polinomioCompleto();

  /// Para buscar en las tablas: "sen(x)", "sen x" y "sin x" son lo mismo.
  static String _clave(String expresion) => expresion
      .replaceAll(' ', '')
      .replaceAll('*', '')
      .replaceAll('·', '')
      .replaceAll('(x)', 'x')
      .replaceAll('sin', 'sen')
      .replaceAll('tg', 'tan')
      .replaceAll('sqrt', '√')
      .replaceAll('raiz', '√')
      .replaceAll('²', '^2')
      .replaceAll('e^(x)', 'e^x');

  static const _nombresBasicos = {
    'senx': 'sen(x)',
    'cosx': 'cos(x)',
    'tanx': 'tan(x)',
    'e^x': 'e^x',
    'lnx': 'ln(x)',
    '√x': '√x',
    '1/x': '1/x',
    'sec^2x': 'sec²(x)',
  };
  static const _derivadasBasicas = {
    'senx': 'cos(x)',
    'cosx': '−sen(x)',
    'tanx': 'sec²(x)',
    'e^x': 'e^x',
    'lnx': '1/x',
    '√x': '1 / (2√x)',
    '1/x': '−1/x²',
  };
  static const _integralesBasicas = {
    'senx': '−cos(x) + C',
    'cosx': 'sen(x) + C',
    'tanx': '−ln|cos(x)| + C',
    'e^x': 'e^x + C',
    'lnx': 'x·ln(x) − x + C',
    '√x': '(2/3)x^(3/2) + C',
    '1/x': 'ln|x| + C',
    'sec^2x': 'tan(x) + C',
  };

  static String _derivada(String expresion) {
    if (expresion.isEmpty) {
      return 'Escribe la función, por ejemplo: **derivada de x^3 + 2x**';
    }
    final clave = _clave(expresion);
    final basica = _derivadasBasicas[clave];
    if (basica != null) {
      return '**d/dx ${_nombresBasicos[clave]} = $basica**\n'
          'Es de las derivadas básicas: conviene sabérsela de memoria.';
    }
    final Polinomio p;
    try {
      p = _polinomio(expresion);
    } on _GradoAlto {
      return 'Uf, ese polinomio pasa de grado 12: es demasiado largo para mí.';
    } on FormatException {
      return 'Por ahora derivo polinomios (como **3x^2 + 2x − 5**) y las '
          'funciones básicas: sen, cos, tan, e^x, ln y √x. Esa todavía no.';
    }
    return '**d/dx (${p.texto}) = ${p.derivada.texto}**\n'
        'Término a término: la derivada de a·x^n es a·n·x^(n−1), y la de una '
        'constante es 0.';
  }

  static final _limitesAlFinal = RegExp(
    r'\s(?:de|desde|entre)\s+(-?\d+(?:[.,]\d+)?(?:/\d+)?)\s+(?:a|hasta|y)\s+'
    r'(-?\d+(?:[.,]\d+)?(?:/\d+)?)(?=\s|$)',
  );
  static final _limitesAlPrincipio = RegExp(
    r'^(-?\d+(?:[.,]\d+)?(?:/\d+)?)\s+(?:a|hasta)\s+'
    r'(-?\d+(?:[.,]\d+)?(?:/\d+)?)\s+(?:de\s+)?',
  );

  static Racional _racionalDe(String texto) {
    final limpio = texto.replaceAll(',', '.');
    final partes = limpio.split('/');
    if (partes.length == 2) {
      return Racional.desdeTexto(partes[0]) / Racional.desdeTexto(partes[1]);
    }
    return Racional.desdeTexto(limpio);
  }

  static String _integral(String texto) {
    var expresion = texto;
    Racional? desde;
    Racional? hasta;
    final alPrincipio = _limitesAlPrincipio.firstMatch(texto);
    final alFinal = _limitesAlFinal.firstMatch(' $texto');
    try {
      if (alPrincipio != null) {
        desde = _racionalDe(alPrincipio[1]!);
        hasta = _racionalDe(alPrincipio[2]!);
        expresion = texto.substring(alPrincipio.end);
      } else if (alFinal != null) {
        desde = _racionalDe(alFinal[1]!);
        hasta = _racionalDe(alFinal[2]!);
        expresion = ' $texto'.replaceRange(alFinal.start, alFinal.end, ' ');
      }
    } on FormatException {
      desde = null;
      hasta = null;
    }
    expresion = _soloExpresion(
      expresion.trim().replaceFirst(RegExp(r'^(?:de|del)\s+'), ''),
    );
    if (expresion.isEmpty) {
      return '¿De qué función? Por ejemplo: **integral de x^2** o **integral '
          'de x^2 de 0 a 2**';
    }
    final clave = _clave(expresion);
    final basica = _integralesBasicas[clave];
    if (basica != null && desde == null) {
      return '**∫ ${_nombresBasicos[clave]} dx = $basica**\n'
          'Es de las integrales inmediatas: viene directo de la tabla.';
    }
    final Polinomio p;
    try {
      p = _polinomio(expresion);
    } on _GradoAlto {
      return 'Uf, ese polinomio pasa de grado 12: es demasiado largo para mí.';
    } on FormatException {
      return 'Por ahora integro polinomios (como **3x^2 + 2x**) y las funciones '
          'de la tabla: sen, cos, e^x, 1/x, √x. Esa ya pide un método: mira '
          '**integración por partes** o **sustitución**.';
    }
    final primitiva = p.primitiva;
    if (desde != null && hasta != null) {
      final arriba = primitiva.evaluar(hasta);
      final abajo = primitiva.evaluar(desde);
      final valor = arriba - abajo;
      return '**∫ de ${desde.texto} a ${hasta.texto} de (${p.texto}) dx = '
          '${valor.textoConDecimal}**\n'
          'Primitiva: F(x) = ${primitiva.texto}\n'
          'F(${hasta.texto}) − F(${desde.texto}) = ${arriba.texto} − '
          '${abajo.numerador.isNegative ? '(${abajo.texto})' : abajo.texto} = '
          '${valor.texto}';
    }
    final resultado = primitiva.grado == 0 && primitiva[0].esCero
        ? 'C'
        : '${primitiva.texto} + C';
    return '**∫ (${p.texto}) dx = $resultado**\n'
        'Término a término: ∫ a·x^n dx = a·x^(n+1) / (n+1). Y no te olvides la '
        '+ C.';
  }

  static String _expandida(String expresion) {
    final Polinomio p;
    try {
      p = _polinomio(expresion);
    } on _GradoAlto {
      return 'Uf, eso da un polinomio de grado mayor que 12: es demasiado '
          'largo para mí.';
    } on FormatException {
      return 'Desarrollo expresiones en x, por ejemplo: **desarrolla (x + 2)^3**';
    }
    return '${_mostrarExpresion(expresion)} = **${p.texto}**';
  }

  static String _factorizada(String expresion) {
    final Polinomio p;
    try {
      p = _polinomio(expresion);
    } on _GradoAlto {
      return 'Uf, ese polinomio pasa de grado 12: es demasiado largo para mí.';
    } on FormatException {
      return 'Factorizo polinomios en x, por ejemplo: **factoriza x^2 − 5x + 6**';
    }
    if (p.grado < 1) return 'Eso es un número: no hay nada que factorizar.';
    final f = _factores(p);
    if (f.raices.isEmpty &&
        f.potenciaX == 0 &&
        f.constante == Racional.uno &&
        f.resto != null) {
      return '**${p.texto}** no se puede factorizar con números racionales.'
          '${_notaDelResto(f.resto!)}';
    }
    final notas = [
      if (f.constante != Racional.uno || f.potenciaX > 0)
        'Primero saqué el factor común.',
      if (f.raices.isNotEmpty)
        'Cada raíz r que encontré (probando los divisores del término '
            'independiente) da un factor (x − r).',
      if (f.resto != null) _notaDelResto(f.resto!).trim(),
    ];
    return '**${p.texto} = ${_textoFactores(f)}**\n${notas.join(' ')}';
  }

  static String _notaDelResto(List<BigInt> resto) {
    final escrito = Polinomio([
      for (final c in resto) Racional.entero(c),
    ]).texto;
    if (resto.length == 3) {
      final delta = resto[1] * resto[1] - BigInt.from(4) * resto[2] * resto[0];
      return delta.isNegative
          ? ' El factor $escrito no tiene raíces reales: no se separa más.'
          : ' El factor $escrito tiene raíces irracionales: con números '
                'racionales queda así.';
    }
    return ' El factor $escrito no tiene raíces racionales: con los métodos '
        'del Baldor queda así.';
  }

  /// p = constante · x^potenciaX · (factores lineales) · resto.
  static ({
    Racional constante,
    int potenciaX,
    List<(BigInt, BigInt)> raices,
    List<BigInt>? resto,
  })
  _factores(Polinomio p) {
    var denominador = BigInt.one;
    for (final c in p.coeficientes) {
      denominador = _mcm(denominador, c.denominador);
    }
    final enteros = [
      for (final c in p.coeficientes)
        (c * Racional.entero(denominador)).numerador,
    ];
    var contenido = BigInt.zero;
    for (final e in enteros) {
      contenido = contenido.gcd(e);
    }
    if (enteros.last.isNegative) contenido = -contenido;
    var a = [for (final e in enteros) e ~/ contenido];
    final constante = Racional(contenido, denominador);

    var potenciaX = 0;
    while (a.length > 1 && a.first == BigInt.zero) {
      a = a.sublist(1);
      potenciaX++;
    }
    final raices = <(BigInt, BigInt)>[];
    while (a.length > 2) {
      final raiz = _raizRacional(a);
      if (raiz == null) break;
      raices.add(raiz);
      a = _dividir(a, raiz.$1, raiz.$2);
    }
    if (a.length == 2) {
      // Lo que queda es lineal: a1·x + a0, raiz −a0/a1.
      final divisor = a[0].gcd(a[1]);
      raices.add((-a[0] ~/ divisor, a[1] ~/ divisor));
      a = [BigInt.one];
    }
    raices.sort(
      (x, y) =>
          Racional(x.$1, x.$2).valor.compareTo(Racional(y.$1, y.$2).valor),
    );
    return (
      constante: constante,
      potenciaX: potenciaX,
      raices: raices,
      resto: a.length > 2 ? a : null,
    );
  }

  static (BigInt, BigInt)? _raizRacional(List<BigInt> a) {
    for (final q in _divisores(a.last.abs())) {
      for (final candidato in _divisores(a.first.abs())) {
        for (final p in [candidato, -candidato]) {
          if (p.gcd(q) != BigInt.one) continue;
          if (_anula(a, p, q)) return (p, q);
        }
      }
    }
    return null;
  }

  /// Si p/q es raiz: a_n·p^n + a_(n−1)·p^(n−1)·q + ... + a_0·q^n = 0.
  static bool _anula(List<BigInt> a, BigInt p, BigInt q) {
    final n = a.length - 1;
    var suma = a[n];
    var potenciaQ = BigInt.one;
    for (var i = n - 1; i >= 0; i--) {
      potenciaQ *= q;
      suma = suma * p + a[i] * potenciaQ;
    }
    return suma == BigInt.zero;
  }

  /// a ÷ (q·x − p), sabiendo que divide exacto.
  static List<BigInt> _dividir(List<BigInt> a, BigInt p, BigInt q) {
    final n = a.length - 1;
    final s = List<BigInt>.filled(n, BigInt.zero);
    s[n - 1] = a[n] ~/ q;
    for (var k = n - 1; k >= 1; k--) {
      s[k - 1] = (a[k] + p * s[k]) ~/ q;
    }
    return s;
  }

  static List<BigInt> _divisores(BigInt n) {
    if (n == BigInt.zero) return [BigInt.one];
    final chicos = <BigInt>[];
    final grandes = <BigInt>[];
    var d = BigInt.one;
    // Numeros enormes: no vale la pena seguir buscando.
    final tope = BigInt.from(1000000);
    while (d * d <= n && d <= tope) {
      if (n % d == BigInt.zero) {
        chicos.add(d);
        if (d * d != n) grandes.add(n ~/ d);
      }
      d += BigInt.one;
    }
    return [...chicos, ...grandes.reversed];
  }

  static String _lineal(BigInt p, BigInt q) {
    final x = q == BigInt.one ? 'x' : '${q}x';
    if (p == BigInt.zero) return x;
    return p.isNegative ? '$x + ${-p}' : '$x − $p';
  }

  static String _exponente(int n) => switch (n) {
    1 => '',
    2 => '²',
    3 => '³',
    _ => '^$n',
  };

  static String _textoFactores(
    ({
      Racional constante,
      int potenciaX,
      List<(BigInt, BigInt)> raices,
      List<BigInt>? resto,
    })
    f,
  ) {
    final partes = StringBuffer();
    final c = f.constante;
    if (c == -Racional.uno) {
      partes.write('−');
    } else if (c != Racional.uno) {
      partes.write(c.esEntero ? c.texto : '(${c.texto})');
    }
    if (f.potenciaX > 0) partes.write('x${_exponente(f.potenciaX)}');
    final veces = <String, int>{};
    for (final (p, q) in f.raices) {
      final factor = _lineal(p, q);
      veces[factor] = (veces[factor] ?? 0) + 1;
    }
    veces.forEach((factor, n) => partes.write('($factor)${_exponente(n)}'));
    if (f.resto != null) {
      partes.write(
        '(${Polinomio([for (final e in f.resto!) Racional.entero(e)]).texto})',
      );
    }
    return partes.toString();
  }

  /// Ecuaciones de grado 3 y 4: se resuelven si se pueden factorizar.
  static String _porFactores(String enunciado, Polinomio p) {
    final f = _factores(p);
    final soluciones = <String>[];
    void agregar(String solucion) {
      if (!soluciones.contains(solucion)) soluciones.add(solucion);
    }

    if (f.potenciaX > 0) agregar('0');
    for (final (raizP, raizQ) in f.raices) {
      agregar(Racional(raizP, raizQ).texto);
    }
    final ordenada = Polinomio([
      for (final c in p.coeficientes) c / f.constante,
    ]).texto;
    final pasos = StringBuffer()
      ..writeln('**Ecuación de grado ${p.grado}**')
      ..writeln(enunciado)
      ..writeln('Ordenada: $ordenada = 0');
    if (f.resto != null && f.resto!.length > 3) {
      return '${pasos}No tiene raíces racionales, así que no la puedo resolver '
          'exacta con los métodos del Baldor. Con un método numérico (como el '
          'de Newton) se aproxima.';
    }
    if (f.resto != null) {
      final r = f.resto!;
      _raicesCuadratica(r[2], r[1], r[0]).forEach(agregar);
    }
    final factorizada = _textoFactores((
      constante: Racional.uno,
      potenciaX: f.potenciaX,
      raices: f.raices,
      resto: f.resto,
    ));
    pasos
      ..writeln('Factorizada: $factorizada = 0')
      ..writeln('Cada factor igualado a cero da una solución:')
      ..write('**Soluciones: ${soluciones.map((s) => 'x = $s').join(', ')}**');
    return pasos.toString();
  }

  /// Las raices exactas de a·x² + b·x + c, ya escritas.
  static List<String> _raicesCuadratica(BigInt a, BigInt b, BigInt c) {
    final delta = b * b - BigInt.from(4) * a * c;
    final dosA = BigInt.two * a;
    if (delta == BigInt.zero) return [Racional(-b, dosA).texto];
    final (fuera, dentro) = _simplificarRaiz(delta.abs());
    if (!delta.isNegative && dentro == BigInt.one) {
      return [
        Racional(-b + fuera, dosA).texto,
        Racional(-b - fuera, dosA).texto,
      ];
    }
    var real = -b;
    var coeficiente = fuera;
    var denominador = dosA;
    final divisor = real.gcd(coeficiente).gcd(denominador);
    if (divisor > BigInt.one) {
      real ~/= divisor;
      coeficiente ~/= divisor;
      denominador ~/= divisor;
    }
    if (denominador.isNegative) {
      real = -real;
      denominador = -denominador;
    }
    final raiz =
        '${coeficiente == BigInt.one ? '' : coeficiente}'
        '${delta.isNegative ? 'i' : ''}'
        '${dentro == BigInt.one ? '' : '√$dentro'}';
    final arriba = real == BigInt.zero ? '±$raiz' : '${_entero(real)} ± $raiz';
    return [denominador == BigInt.one ? arriba : '($arriba) / $denominador'];
  }

  // -------------------------------------------------------- reconocer
  static const _pedidos = [
    'calcula',
    'calcular',
    'calculame',
    'cuanto es',
    'cuanto da',
    'cuanto vale',
    'cuanto sale',
    'resultado de',
    'resuelve',
    'resuelveme',
    'resolver',
    'resuelva',
    'despeja',
  ];

  static ({bool pedido, String resto}) _quitarPedido(String mensaje) {
    final sinSignos = mensaje.replaceFirst(RegExp(r'^[¿¡\s]+'), '');
    final minusculas = _sinTildes(sinSignos.toLowerCase());
    for (final pedido in _pedidos) {
      if (minusculas.startsWith('$pedido ') ||
          minusculas.startsWith('$pedido:')) {
        var resto = sinSignos.substring(pedido.length).trim();
        resto = resto
            .replaceFirst(RegExp(r'^(:|la ecuaci[oó]n|esto|esta)\s*'), '')
            .trim();
        return (pedido: true, resto: resto.replaceAll(RegExp(r'[?¿!¡]'), ''));
      }
    }
    return (pedido: false, resto: sinSignos.replaceAll(RegExp(r'[?¿!¡]'), ''));
  }

  static String _sinTildes(String texto) => texto
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  /// Pasa a una forma unica lo que se escribe de muchas maneras.
  static String _preparar(String texto) {
    var t = texto.toLowerCase();
    const reemplazos = {
      '×': '*',
      '·': '*',
      '÷': '/',
      '−': '-',
      '–': '-',
      '²': '^2',
      '³': '^3',
      'π': 'pi',
      '√': ' raiz ',
    };
    reemplazos.forEach((de, a) => t = t.replaceAll(de, a));
    // "2 más 3 al cuadrado", "10 entre 4": como se dicta una cuenta.
    t = ' ${_sinTildes(t)} ';
    const enPalabras = {
      ' raiz cuadrada de ': ' raiz ',
      ' la raiz de ': ' raiz ',
      ' raiz de ': ' raiz ',
      ' al cuadrado ': '^2 ',
      ' al cubo ': '^3 ',
      ' elevado a la ': '^',
      ' elevado a ': '^',
      ' dividido entre ': ' / ',
      ' dividido por ': ' / ',
      ' dividido ': ' / ',
      ' entre ': ' / ',
      ' mas ': ' + ',
      ' menos ': ' - ',
      ' por ': ' * ',
    };
    enPalabras.forEach((de, a) {
      while (t.contains(de)) {
        t = t.replaceAll(de, a);
      }
    });
    // Coma decimal: "3,5" es tres y medio.
    t = t.replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}');
    return t.trim();
  }

  static final _caracteresDeCuenta = RegExp(r'^[\d\s+\-*/^().,]+$');
  static final _palabrasDeCuenta = RegExp(
    r'\b(raiz|sqrt|sen|sin|cos|tan|tg|ln|log|abs|pi)\b',
  );

  /// "2+2", "(3*4)/2", "raiz(16)": sin anunciarlo, solo si es claramente
  /// una cuenta y tiene al menos una operacion.
  static bool _pareceCuenta(String texto) {
    final sinFunciones = texto.replaceAll(_palabrasDeCuenta, ' ');
    if (!_caracteresDeCuenta.hasMatch(sinFunciones)) return false;
    if (!RegExp(r'\d').hasMatch(texto)) return false;
    final tieneOperacion =
        RegExp(r'[+*/^]|\d\s*-|\)\s*-').hasMatch(texto) ||
        _palabrasDeCuenta.hasMatch(texto);
    return tieneOperacion;
  }

  /// "2x + 3 = 7" sin decir "resuelve": numeros, x y operaciones nada mas.
  static bool _pareceEcuacion(String texto) {
    if (!texto.contains('x')) return false;
    return RegExp(r'^[\dx\s+\-*/^().,=]+$').hasMatch(texto);
  }

  /// La cuenta como la escribio la persona, pero prolija: con espacios y
  /// los signos de verdad.
  static String _mostrarExpresion(String texto) => texto
      .trim()
      .replaceAll(RegExp(r'raiz\s*'), '√')
      .replaceAll('*', ' · ')
      .replaceAll('-', ' − ')
      .replaceAll('+', ' + ')
      .replaceAll('^2', '²')
      .replaceAll('^3', '³')
      .replaceAll('( ', '(')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^ − '), '−')
      .replaceAll('( − ', '(−')
      .replaceAll('^ − ', '^−')
      .trim();

  /// Hasta diez cifras significativas, sin ceros de mas: 0.1 + 0.2 da 0.3,
  /// no 0.30000000000000004.
  static String formatearDecimal(double valor) {
    final texto = _decimalSinSigno(valor.abs());
    return valor < 0 && texto != '0' ? '−$texto' : texto;
  }

  static String _decimalSinSigno(double valor) {
    if (valor == valor.roundToDouble() && valor < 1e15) {
      return valor.round().toString();
    }
    var texto = valor.toStringAsPrecision(10);
    if (texto.contains('e')) {
      final [mantisa, exponente] = texto.split('e');
      final limpia = mantisa.contains('.')
          ? mantisa
                .replaceFirst(RegExp(r'0+$'), '')
                .replaceFirst(RegExp(r'\.$'), '')
          : mantisa;
      final signo = exponente.replaceFirst('+', '').replaceFirst('-', '−');
      return '$limpia × 10^$signo';
    }
    if (texto.contains('.')) {
      texto = texto.replaceFirst(RegExp(r'0+$'), '');
      texto = texto.replaceFirst(RegExp(r'\.$'), '');
    }
    return texto;
  }

  // ------------------------------------------------------------- fichas
  static List<_Ficha> _fichas(String texto) {
    final fichas = <_Ficha>[];
    var i = 0;
    while (i < texto.length) {
      final c = texto[i];
      if (c.trim().isEmpty) {
        i++;
        continue;
      }
      if (RegExp(r'[\d.]').hasMatch(c)) {
        final inicio = i;
        while (i < texto.length && RegExp(r'[\d.]').hasMatch(texto[i])) {
          i++;
        }
        final numero = texto.substring(inicio, i);
        if ('.'.allMatches(numero).length > 1 || numero == '.') {
          throw const FormatException('numero mal escrito');
        }
        fichas.add(_Ficha(_TipoFicha.numero, numero));
        continue;
      }
      if (RegExp(r'[a-z]').hasMatch(c)) {
        final inicio = i;
        while (i < texto.length && RegExp(r'[a-z]').hasMatch(texto[i])) {
          i++;
        }
        fichas.addAll(_palabra(texto.substring(inicio, i)));
        continue;
      }
      if ('+-*/^()'.contains(c)) {
        fichas.add(_Ficha(_TipoFicha.signo, c));
        i++;
        continue;
      }
      throw FormatException('caracter inesperado: $c');
    }
    return _conMultiplicacionImplicita(fichas);
  }

  static const _funciones = {
    'raiz',
    'sqrt',
    'sen',
    'sin',
    'cos',
    'tan',
    'tg',
    'ln',
    'log',
    'abs',
  };

  /// "2x" ya viene separado; "xx" o "pix" no: se parten en lo conocido.
  static List<_Ficha> _palabra(String palabra) {
    if (_funciones.contains(palabra)) {
      return [_Ficha(_TipoFicha.funcion, palabra)];
    }
    if (palabra == 'pi' || palabra == 'e') {
      return [_Ficha(_TipoFicha.constante, palabra)];
    }
    if (palabra == 'x') return [const _Ficha(_TipoFicha.incognita, 'x')];
    // "xpi", "2pix": se intenta leer de izquierda a derecha.
    final partes = <_Ficha>[];
    var resto = palabra;
    while (resto.isNotEmpty) {
      if (resto.startsWith('pi')) {
        partes.add(const _Ficha(_TipoFicha.constante, 'pi'));
        resto = resto.substring(2);
      } else if (resto.startsWith('x')) {
        partes.add(const _Ficha(_TipoFicha.incognita, 'x'));
        resto = resto.substring(1);
      } else {
        throw FormatException('palabra desconocida: $palabra');
      }
    }
    return partes;
  }

  /// 2x, 3(x+1), (x+1)(x-1), 2pi: se multiplica aunque no haya signo.
  static List<_Ficha> _conMultiplicacionImplicita(List<_Ficha> fichas) {
    final salida = <_Ficha>[];
    for (final ficha in fichas) {
      if (salida.isNotEmpty) {
        final anterior = salida.last;
        final terminaValor =
            anterior.tipo == _TipoFicha.numero ||
            anterior.tipo == _TipoFicha.constante ||
            anterior.tipo == _TipoFicha.incognita ||
            anterior.texto == ')';
        final empiezaValor =
            ficha.tipo == _TipoFicha.numero ||
            ficha.tipo == _TipoFicha.constante ||
            ficha.tipo == _TipoFicha.incognita ||
            ficha.tipo == _TipoFicha.funcion ||
            ficha.texto == '(';
        if (terminaValor && empiezaValor) {
          salida.add(const _Ficha(_TipoFicha.signo, '*'));
        }
      }
      salida.add(ficha);
    }
    return salida;
  }
}

enum _TipoFicha { numero, signo, funcion, constante, incognita }

class _Ficha {
  const _Ficha(this.tipo, this.texto);
  final _TipoFicha tipo;
  final String texto;
}

class _GradoAlto implements Exception {}

/// Lee una cuenta o un polinomio con la gramatica de siempre:
///
///     suma     := producto (('+' | '-') producto)*
///     producto := signo (('*' | '/') signo)*
///     signo    := ('-' | '+') signo | potencia
///     potencia := base ('^' signo)?
///     base     := numero | constante | x | funcion base | '(' suma ')'
///
/// Asi "-2^2" es -4 y "2^-1" es 0.5, como en cualquier calculadora.
class _Lector {
  _Lector(this.fichas, {this.gradoMaximo = 4});

  final List<_Ficha> fichas;

  /// Para ecuaciones alcanza con grado 4. Para derivar o desarrollar se
  /// permite mas.
  final int gradoMaximo;
  var _i = 0;

  /// Si alguna funcion trigonometrica tomo su angulo en grados.
  bool usoGrados = false;

  _Ficha? get _actual => _i < fichas.length ? fichas[_i] : null;

  bool _es(String texto) => _actual?.texto == texto;

  void terminar() {
    if (_i != fichas.length) throw const FormatException('sobra algo');
  }

  // ------------------------------------------------------------ numeros
  double numero() => _sumaNumero();

  double _sumaNumero() {
    var valor = _productoNumero();
    while (_es('+') || _es('-')) {
      final suma = _actual!.texto == '+';
      _i++;
      final otro = _productoNumero();
      valor = suma ? valor + otro : valor - otro;
    }
    return valor;
  }

  double _productoNumero() {
    var valor = _signoNumero();
    while (_es('*') || _es('/')) {
      final por = _actual!.texto == '*';
      _i++;
      final otro = _signoNumero();
      valor = por ? valor * otro : valor / otro;
    }
    return valor;
  }

  double _signoNumero() {
    if (_es('-')) {
      _i++;
      return -_signoNumero();
    }
    if (_es('+')) {
      _i++;
      return _signoNumero();
    }
    return _potenciaNumero();
  }

  double _potenciaNumero() {
    final base = _baseNumero();
    if (_es('^')) {
      _i++;
      final exponente = _signoNumero();
      return math.pow(base, exponente).toDouble();
    }
    return base;
  }

  double _baseNumero() {
    final ficha = _actual;
    if (ficha == null) throw const FormatException('falta un numero');
    switch (ficha.tipo) {
      case _TipoFicha.numero:
        _i++;
        return double.parse(ficha.texto);
      case _TipoFicha.constante:
        _i++;
        return ficha.texto == 'pi' ? math.pi : math.e;
      case _TipoFicha.funcion:
        _i++;
        final inicio = _i;
        final argumento = _es('(') ? _parentesisNumero() : _potenciaNumero();
        final conPi = fichas
            .sublist(inicio, _i)
            .any((f) => f.tipo == _TipoFicha.constante && f.texto == 'pi');
        return _aplicar(ficha.texto, argumento, enRadianes: conPi);
      case _TipoFicha.signo when ficha.texto == '(':
        return _parentesisNumero();
      default:
        throw FormatException('no esperaba ${ficha.texto}');
    }
  }

  double _parentesisNumero() {
    _i++;
    final valor = _sumaNumero();
    if (!_es(')')) throw const FormatException('falta un parentesis');
    _i++;
    return valor;
  }

  double _aplicar(String funcion, double x, {required bool enRadianes}) {
    double angulo() {
      if (enRadianes) return x;
      usoGrados = true;
      return x * math.pi / 180;
    }

    double trigonometrica(double Function(double) f) {
      final valor = f(angulo());
      // sen(180) no es 1.2e-16: es cero.
      return valor.abs() < 1e-12 ? 0 : valor;
    }

    return switch (funcion) {
      'raiz' || 'sqrt' => x < 0 ? double.nan : math.sqrt(x),
      'sen' || 'sin' => trigonometrica(math.sin),
      'cos' => trigonometrica(math.cos),
      'tan' || 'tg' => trigonometrica(math.tan),
      'ln' => x <= 0 ? double.nan : math.log(x),
      'log' => x <= 0 ? double.nan : math.log(x) / math.ln10,
      'abs' => x.abs(),
      _ => throw FormatException('funcion desconocida: $funcion'),
    };
  }

  // -------------------------------------------------------- polinomios
  Polinomio polinomioCompleto() {
    final valor = _sumaPolinomio();
    terminar();
    return valor;
  }

  Polinomio _sumaPolinomio() {
    var valor = _productoPolinomio();
    while (_es('+') || _es('-')) {
      final suma = _actual!.texto == '+';
      _i++;
      final otro = _productoPolinomio();
      valor = suma ? valor + otro : valor - otro;
    }
    return valor;
  }

  Polinomio _productoPolinomio() {
    var valor = _signoPolinomio();
    while (_es('*') || _es('/')) {
      final por = _actual!.texto == '*';
      _i++;
      final otro = _signoPolinomio();
      if (por) {
        valor = valor * otro;
      } else {
        if (otro.grado > 0) {
          throw const FormatException('division entre x');
        }
        if (otro[0].esCero) throw const FormatException('division entre cero');
        valor = valor.porNumero(Racional.uno / otro[0]);
      }
      if (valor.grado > gradoMaximo) throw _GradoAlto();
    }
    return valor;
  }

  Polinomio _signoPolinomio() {
    if (_es('-')) {
      _i++;
      return -_signoPolinomio();
    }
    if (_es('+')) {
      _i++;
      return _signoPolinomio();
    }
    return _potenciaPolinomio();
  }

  Polinomio _potenciaPolinomio() {
    final base = _basePolinomio();
    if (!_es('^')) return base;
    _i++;
    final exponente = _signoPolinomio();
    if (exponente.grado > 0 || !exponente[0].esEntero) {
      throw const FormatException('exponente no entero');
    }
    if (exponente[0].numerador.abs() > BigInt.from(64)) {
      throw const FormatException('exponente demasiado grande');
    }
    final n = exponente[0].numerador.toInt();
    if (n < 0) {
      if (base.grado > 0) throw const FormatException('x en el denominador');
      if (base[0].esCero) throw const FormatException('cero a la negativa');
      return Polinomio([_potencia(Racional.uno / base[0], -n)]);
    }
    if (n * math.max(base.grado, 1) > gradoMaximo && base.grado > 0) {
      throw _GradoAlto();
    }
    var resultado = Polinomio([Racional.uno]);
    for (var k = 0; k < n; k++) {
      resultado = resultado * base;
    }
    return resultado;
  }

  Racional _potencia(Racional base, int n) {
    var resultado = Racional.uno;
    for (var k = 0; k < n; k++) {
      resultado = resultado * base;
    }
    return resultado;
  }

  Polinomio _basePolinomio() {
    final ficha = _actual;
    if (ficha == null) throw const FormatException('falta un termino');
    switch (ficha.tipo) {
      case _TipoFicha.numero:
        _i++;
        return Polinomio([Racional.desdeTexto(ficha.texto)]);
      case _TipoFicha.incognita:
        _i++;
        return Polinomio([Racional.cero, Racional.uno]);
      case _TipoFicha.signo when ficha.texto == '(':
        _i++;
        final valor = _sumaPolinomio();
        if (!_es(')')) throw const FormatException('falta un parentesis');
        _i++;
        return valor;
      default:
        // pi, e y las funciones no tienen forma exacta en fracciones.
        throw const FormatException('solo numeros exactos y x');
    }
  }
}

/// Una fraccion exacta, siempre simplificada y con el signo arriba.
class Racional {
  factory Racional(BigInt numerador, BigInt denominador) {
    if (denominador == BigInt.zero) {
      throw const FormatException('division entre cero');
    }
    if (denominador.isNegative) {
      numerador = -numerador;
      denominador = -denominador;
    }
    final divisor = numerador.gcd(denominador);
    return Racional._(
      numerador ~/ (divisor == BigInt.zero ? BigInt.one : divisor),
      denominador ~/ (divisor == BigInt.zero ? BigInt.one : divisor),
    );
  }

  const Racional._(this.numerador, this.denominador);

  factory Racional.entero(BigInt valor) => Racional._(valor, BigInt.one);

  /// "2.5" es 5/2 exacto, no el 2.5 de coma flotante.
  factory Racional.desdeTexto(String texto) {
    final partes = texto.split('.');
    if (partes.length == 1) return Racional.entero(BigInt.parse(texto));
    final decimales = partes[1];
    final denominador = BigInt.from(10).pow(decimales.length);
    final numerador = BigInt.parse(
      '${partes[0].isEmpty ? '0' : partes[0]}$decimales',
    );
    return Racional(numerador, denominador);
  }

  static final cero = Racional._(BigInt.zero, BigInt.one);
  static final uno = Racional._(BigInt.one, BigInt.one);

  final BigInt numerador;
  final BigInt denominador;

  bool get esCero => numerador == BigInt.zero;
  bool get esEntero => denominador == BigInt.one;
  double get valor => numerador / denominador;

  Racional operator +(Racional otro) => Racional(
    numerador * otro.denominador + otro.numerador * denominador,
    denominador * otro.denominador,
  );
  Racional operator -(Racional otro) => this + -otro;
  Racional operator -() => Racional._(-numerador, denominador);
  Racional operator *(Racional otro) =>
      Racional(numerador * otro.numerador, denominador * otro.denominador);
  Racional operator /(Racional otro) =>
      Racional(numerador * otro.denominador, denominador * otro.numerador);

  @override
  bool operator ==(Object other) =>
      other is Racional &&
      other.numerador == numerador &&
      other.denominador == denominador;

  @override
  int get hashCode => Object.hash(numerador, denominador);

  /// "7/3", "−2", "0". Con el menos de verdad, no el guion.
  String get texto {
    final signo = numerador.isNegative ? '−' : '';
    final arriba = numerador.abs();
    return esEntero ? '$signo$arriba' : '$signo$arriba/$denominador';
  }

  /// "7/3 ≈ 2.333" cuando la fraccion sola no se entiende de un vistazo.
  String get textoConDecimal =>
      esEntero ? texto : '$texto ≈ ${MatematicaMacias.formatearDecimal(valor)}';
}

/// Un polinomio en x con coeficientes exactos: coeficientes[k] va con x^k.
class Polinomio {
  Polinomio(List<Racional> coeficientes)
    : coeficientes = _sinCerosArriba(coeficientes);

  final List<Racional> coeficientes;

  static List<Racional> _sinCerosArriba(List<Racional> lista) {
    final copia = [...lista];
    while (copia.length > 1 && copia.last.esCero) {
      copia.removeLast();
    }
    return copia.isEmpty ? [Racional.cero] : copia;
  }

  int get grado => coeficientes.length - 1;

  Racional operator [](int k) =>
      k < coeficientes.length ? coeficientes[k] : Racional.cero;

  Polinomio operator +(Polinomio otro) => Polinomio([
    for (var k = 0; k <= math.max(grado, otro.grado); k++) this[k] + otro[k],
  ]);

  Polinomio operator -(Polinomio otro) => this + -otro;

  Polinomio operator -() => Polinomio([for (final c in coeficientes) -c]);

  Polinomio operator *(Polinomio otro) {
    final resultado = List.filled(grado + otro.grado + 1, Racional.cero);
    for (var i = 0; i <= grado; i++) {
      for (var j = 0; j <= otro.grado; j++) {
        resultado[i + j] = resultado[i + j] + this[i] * otro[j];
      }
    }
    return Polinomio(resultado);
  }

  Polinomio porNumero(Racional numero) =>
      Polinomio([for (final c in coeficientes) c * numero]);

  /// Termino a termino: a·x^n pasa a ser a·n·x^(n−1).
  Polinomio get derivada => Polinomio([
    for (var k = 1; k <= grado; k++) this[k] * Racional.entero(BigInt.from(k)),
  ]);

  /// Una primitiva, sin la constante: a·x^n pasa a ser a·x^(n+1)/(n+1).
  Polinomio get primitiva => Polinomio([
    Racional.cero,
    for (var k = 0; k <= grado; k++)
      this[k] / Racional.entero(BigInt.from(k + 1)),
  ]);

  Racional evaluar(Racional x) {
    var resultado = Racional.cero;
    for (var k = grado; k >= 0; k--) {
      resultado = resultado * x + this[k];
    }
    return resultado;
  }

  /// "x² − 5x + 6", de la potencia mas alta a la mas baja.
  String get texto {
    final terminos = <String>[];
    for (var k = grado; k >= 0; k--) {
      final c = this[k];
      if (c.esCero) continue;
      final negativo = c.numerador.isNegative;
      final valor = negativo ? -c : c;
      final letra = switch (k) {
        0 => '',
        1 => 'x',
        2 => 'x²',
        3 => 'x³',
        _ => 'x^$k',
      };
      final numero = valor == Racional.uno && k > 0
          ? ''
          : valor.esEntero || k == 0
          ? valor.texto
          : '(${valor.texto})';
      final termino = '$numero$letra';
      if (terminos.isEmpty) {
        terminos.add(negativo ? '−$termino' : termino);
      } else {
        terminos.add(negativo ? '− $termino' : '+ $termino');
      }
    }
    return terminos.isEmpty ? '0' : terminos.join(' ');
  }
}
