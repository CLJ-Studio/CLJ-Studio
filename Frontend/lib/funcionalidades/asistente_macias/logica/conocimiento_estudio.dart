import 'conocimiento_macias.dart';

/// Lo que MacIAs sabe de las materias: algebra, calculo integral y C++.
///
/// Esta escrito con palabras propias, no copiado de ningun libro: los libros
/// de referencia (el Baldor, los de calculo, la documentacion de C++) tienen
/// derechos de autor, y la app es publica. Lo que se toma de ellos es el
/// orden de los temas, que es como se ensenan en clase.
///
/// Cada ejemplo esta verificado. Un error aqui no es un detalle: alguien lo
/// va a copiar en un examen.
///
/// Las formulas usan solo simbolos que tiene la letra de la app (Nunito): ²,
/// ³, √, ±, ∫, π. Los exponentes con letras van como x^n, porque los
/// superindices de letras no estan en la fuente y en la web se verian con
/// otra letra.
abstract final class ConocimientoEstudio {
  static const algebra = [
    'a_productos_notables',
    'a_factorizacion',
    'a_factor_comun',
    'a_diferencia_cuadrados',
    'a_trinomio_cuadrado',
    'a_trinomios',
    'a_cubos',
    'a_ecuaciones_lineales',
    'a_sistemas',
    'a_cuadratica',
    'a_exponentes',
    'a_logaritmos',
    'a_fracciones',
    'a_progresiones',
    'a_binomio_newton',
  ];

  static const calculo = [
    'c_integral',
    'c_inmediatas',
    'c_sustitucion',
    'c_partes',
    'c_trigonometricas',
    'c_sustitucion_trig',
    'c_fracciones_parciales',
    'c_definida',
    'c_area',
    'c_volumen',
    'c_impropias',
  ];

  static const cpp = [
    'p_hola',
    'p_tipos',
    'p_entrada_salida',
    'p_condicionales',
    'p_bucles',
    'p_funciones',
    'p_arreglos',
    'p_strings',
    'p_punteros',
    'p_memoria',
    'p_clases',
    'p_herencia',
    'p_stl',
    'p_archivos',
    'p_errores',
  ];

  static final temas = <TemaMacias>[
    ..._algebra,
    ..._calculo,
    ..._cpp,
    TemaMacias(
      id: 'calculadora',
      pregunta: 'Calculadora y ecuaciones',
      claves: [
        'calculadora',
        'calcular',
        'calcula',
        'resolver ecuaciones',
        'resuelve',
        'resolver',
        'resolveme',
        'hacer calculos',
        'calculos',
      ],
      respuesta: (c) =>
          'Hago cuentas y resuelvo ecuaciones, con los pasos. Prueba, por '
          'ejemplo:\n'
          '• **calcula (3 + 4) * 2^3**\n'
          '• **resuelve x^2 - 5x + 6 = 0** (hasta grado 4, si tiene raíces '
          'racionales)\n'
          '• **derivada de x^3 + 2x** o **integral de x^2 de 0 a 2**\n'
          '• **factoriza x^2 - 9** o **desarrolla (x + 2)^3**\n'
          '• **15% de 200** o **promedio de 70, 80 y 95**\n'
          '• **5 km a millas** o **30 grados a fahrenheit**\n\n'
          'Usa ^ para potencias y raiz() para la raíz cuadrada. También '
          'entiendo sen, cos, tan, ln, log y pi, y cuentas dictadas como '
          '"2 más 3 al cuadrado".',
      relacionados: ['a_cuadratica', 'a_ecuaciones_lineales'],
    ),
  ];

  // =====================================================================
  // Algebra
  // =====================================================================
  static final _algebra = <TemaMacias>[
    TemaMacias(
      id: 'a_productos_notables',
      pregunta: 'Productos notables',
      claves: [
        'productos notables',
        'producto notable',
        'binomio al cuadrado',
        'cuadrado de un binomio',
        'binomios conjugados',
        'binomio conjugado',
        'cubo de un binomio',
        'suma por diferencia',
      ],
      respuesta: (c) =>
          'Son multiplicaciones que se escriben de memoria, sin hacer la '
          'distributiva:\n'
          '• (a + b)² = a² + 2ab + b²\n'
          '• (a − b)² = a² − 2ab + b²\n'
          '• (a + b)(a − b) = a² − b²\n'
          '• (a + b)³ = a³ + 3a²b + 3ab² + b³\n'
          '• (a − b)³ = a³ − 3a²b + 3ab² − b³\n'
          '• (x + a)(x + b) = x² + (a + b)x + ab\n\n'
          'Ejemplo: (2x + 3)² = 4x² + 12x + 9',
      ampliacion: (c) =>
          'Otro: (3a − 5b)². El primero al cuadrado (9a²), menos el doble del '
          'primero por el segundo (2 · 3a · 5b = 30ab), más el segundo al '
          'cuadrado (25b²):\n'
          '(3a − 5b)² = 9a² − 30ab + 25b²\n\n'
          'Y uno de binomios conjugados: (x + 7)(x − 7) = x² − 49',
      relacionados: ['a_factorizacion', 'a_binomio_newton'],
    ),
    TemaMacias(
      id: 'a_factorizacion',
      pregunta: 'Los casos de factorización',
      claves: [
        'factorizacion',
        'factorizar',
        'factoriza',
        'factorizo',
        'casos de factorizacion',
        'caso de factorizacion',
      ],
      respuesta: (c) =>
          'Factorizar es escribir una expresión como una multiplicación. Los '
          'casos clásicos, en el orden en que conviene probarlos:\n'
          '1. Factor común: ax + ay = a(x + y)\n'
          '2. Factor común por agrupación\n'
          '3. Trinomio cuadrado perfecto: a² + 2ab + b² = (a + b)²\n'
          '4. Diferencia de cuadrados: a² − b² = (a + b)(a − b)\n'
          '5. Trinomio cuadrado perfecto por adición y sustracción\n'
          '6. Trinomio de la forma x² + bx + c\n'
          '7. Trinomio de la forma ax² + bx + c\n'
          '8. Cubo perfecto de binomios\n'
          '9. Suma o diferencia de cubos\n'
          '10. Suma o diferencia de potencias impares iguales\n\n'
          'Regla de oro: empieza siempre buscando un factor común.',
      ampliacion: (c) =>
          'Un ejemplo que usa dos casos seguidos:\n'
          '3x² − 12\n'
          '= 3(x² − 4)   (factor común)\n'
          '= 3(x + 2)(x − 2)   (diferencia de cuadrados)\n\n'
          'Factorizar "del todo" significa seguir hasta que ningún factor se '
          'pueda separar más.',
      relacionados: ['a_factor_comun', 'a_diferencia_cuadrados', 'a_trinomios'],
    ),
    TemaMacias(
      id: 'a_factor_comun',
      pregunta: 'Factor común y agrupación',
      claves: [
        'factor comun',
        'sacar factor',
        'agrupacion',
        'agrupar terminos',
        'factor comun por agrupacion',
      ],
      respuesta: (c) =>
          'Buscas lo que se repite en todos los términos (el número más '
          'grande que los divide y cada letra con su menor exponente) y lo '
          'sacas:\n'
          '6x³ − 9x² = 3x²(2x − 3)\n\n'
          'Por agrupación, cuando no hay nada común a todos:\n'
          'ax + bx + ay + by\n'
          '= x(a + b) + y(a + b)\n'
          '= (a + b)(x + y)',
      ampliacion: (c) =>
          'Otro de agrupación, con signos:\n'
          'x³ + 2x² − 3x − 6\n'
          '= x²(x + 2) − 3(x + 2)\n'
          '= (x + 2)(x² − 3)\n\n'
          'Comprueba multiplicando: x³ − 3x + 2x² − 6, que es lo mismo.',
      relacionados: ['a_factorizacion', 'a_trinomios'],
    ),
    TemaMacias(
      id: 'a_diferencia_cuadrados',
      pregunta: 'Diferencia de cuadrados',
      claves: [
        'diferencia de cuadrados',
        'diferencia cuadrados',
        'cuadrado menos cuadrado',
      ],
      respuesta: (c) =>
          'Dos cuadrados restándose se separan en suma por diferencia de sus '
          'raíces:\n'
          'a² − b² = (a + b)(a − b)\n\n'
          'Ejemplos:\n'
          '• x² − 25 = (x + 5)(x − 5)\n'
          '• 4m² − 9n² = (2m + 3n)(2m − 3n)\n'
          '• x⁴ − 16 = (x² + 4)(x + 2)(x − 2)\n\n'
          'Ojo: una suma de cuadrados, a² + b², no se factoriza con números '
          'reales.',
      ampliacion: (c) =>
          'Uno con fracciones: x² − 1/9 = (x + 1/3)(x − 1/3)\n\n'
          'Y uno que esconde la diferencia de cuadrados: (a + 1)² − 4 = '
          '(a + 1 + 2)(a + 1 − 2) = (a + 3)(a − 1)',
      relacionados: ['a_factorizacion', 'a_trinomio_cuadrado'],
    ),
    TemaMacias(
      id: 'a_trinomio_cuadrado',
      pregunta: 'Trinomio cuadrado perfecto',
      claves: ['trinomio cuadrado perfecto', 'cuadrado perfecto', 'tcp'],
      respuesta: (c) =>
          'Es el desarrollo de un binomio al cuadrado. Se reconoce porque el '
          'primer y el último término son cuadrados, y el del medio es el '
          'doble del producto de sus raíces:\n'
          'a² + 2ab + b² = (a + b)²\n\n'
          'Ejemplo: x² + 10x + 25. Las raíces son x y 5, y 2 · x · 5 = 10x. '
          'Entonces es (x + 5)².\n'
          'Otro: 9y² − 12y + 4 = (3y − 2)²',
      ampliacion: (c) =>
          'Si el del medio no coincide, no es cuadrado perfecto. Por ejemplo, '
          'x² + 6x + 4: las raíces son x y 2, pero 2 · x · 2 = 4x, no 6x. Ese '
          'se resuelve de otra forma (ecuación de segundo grado o completando '
          'el cuadrado).',
      relacionados: ['a_productos_notables', 'a_diferencia_cuadrados'],
    ),
    TemaMacias(
      id: 'a_trinomios',
      pregunta: 'Trinomios x² + bx + c y ax² + bx + c',
      claves: [
        'trinomio',
        'trinomios',
        'dos numeros que sumen',
        'sumen y multipliquen',
        'x2 bx c',
      ],
      respuesta: (c) =>
          'Para **x² + bx + c**, busca dos números que **multiplicados den '
          'c** y **sumados den b**:\n'
          '• x² + 7x + 12: 3 y 4 (3 · 4 = 12, 3 + 4 = 7), así que es '
          '(x + 3)(x + 4)\n'
          '• x² − x − 6: −3 y 2, así que es (x − 3)(x + 2)\n\n'
          'Para **ax² + bx + c**, multiplica a · c, busca dos números que den '
          'ese producto y sumen b, y separa el término del medio:\n'
          '6x² + 7x + 2 (a · c = 12, los números son 3 y 4)\n'
          '= 6x² + 3x + 4x + 2\n'
          '= 3x(2x + 1) + 2(2x + 1)\n'
          '= (2x + 1)(3x + 2)',
      ampliacion: (c) =>
          'Si no encuentras los dos números, puede que no tenga raíces '
          'enteras. Ahí usa la fórmula general: escríbeme la ecuación (por '
          'ejemplo **resuelve x^2 + 3x - 1 = 0**) y la resuelvo con los '
          'pasos.',
      relacionados: ['a_factorizacion', 'a_cuadratica'],
    ),
    TemaMacias(
      id: 'a_cubos',
      pregunta: 'Suma y diferencia de cubos',
      claves: ['suma de cubos', 'diferencia de cubos', 'cubos'],
      respuesta: (c) =>
          'a³ + b³ = (a + b)(a² − ab + b²)\n'
          'a³ − b³ = (a − b)(a² + ab + b²)\n\n'
          'Ejemplos:\n'
          '• x³ + 8 = (x + 2)(x² − 2x + 4)\n'
          '• 27m³ − 1 = (3m − 1)(9m² + 3m + 1)\n\n'
          'Truco para los signos: el binomio lleva el mismo signo que la '
          'expresión, y el término del medio del trinomio, el contrario.',
      ampliacion: (c) =>
          'Otro: 8x³ − 125y³. Las raíces cúbicas son 2x y 5y:\n'
          '8x³ − 125y³ = (2x − 5y)(4x² + 10xy + 25y²)',
      relacionados: ['a_factorizacion', 'a_productos_notables'],
    ),
    TemaMacias(
      id: 'a_ecuaciones_lineales',
      pregunta: 'Ecuaciones de primer grado',
      claves: [
        'ecuacion de primer grado',
        'ecuaciones de primer grado',
        'ecuacion lineal',
        'ecuaciones lineales',
        'primer grado',
        'despejar',
        'despeje',
      ],
      respuesta: (c) =>
          'La idea es dejar la x sola, haciendo lo mismo a los dos lados:\n'
          '1. Quita paréntesis y denominadores.\n'
          '2. Junta las x de un lado y los números del otro.\n'
          '3. Divide entre lo que acompaña a la x.\n\n'
          'Ejemplo: 3(x − 2) = x + 4\n'
          '3x − 6 = x + 4\n'
          '2x = 10\n'
          'x = 5\n\n'
          'Comprueba siempre: 3(5 − 2) = 9 y 5 + 4 = 9.\n'
          'También la resuelvo yo: escribe **resuelve 3(x-2) = x+4**.',
      ampliacion: (c) =>
          'Una con fracciones: x/2 + x/3 = 5\n'
          'Multiplica todo por 6 (el mcm de 2 y 3): 3x + 2x = 30\n'
          '5x = 30\n'
          'x = 6',
      relacionados: ['a_sistemas', 'calculadora'],
    ),
    TemaMacias(
      id: 'a_sistemas',
      pregunta: 'Sistemas de ecuaciones 2×2',
      claves: [
        'sistema de ecuaciones',
        'sistemas de ecuaciones',
        'dos incognitas',
        'metodo de igualacion',
        'metodo de sustitucion',
        'metodo de reduccion',
        'igualacion',
        'reduccion',
        'eliminacion',
        'cramer',
      ],
      respuesta: (c) =>
          'Tres métodos para dos ecuaciones con dos incógnitas:\n'
          '• **Reducción**: multiplicas para que una letra quede con '
          'coeficientes opuestos y sumas las ecuaciones.\n'
          '• **Sustitución**: despejas una letra y la reemplazas en la otra.\n'
          '• **Igualación**: despejas la misma letra en las dos e igualas.\n\n'
          'Ejemplo por reducción:\n'
          'x + y = 10\n'
          'x − y = 2\n'
          'Sumando: 2x = 12, así que x = 6, y entonces y = 4.\n\n'
          'Si no tiene solución, las rectas son paralelas; si tiene '
          'infinitas, son la misma recta.',
      ampliacion: (c) =>
          'Uno por sustitución:\n'
          '2x + y = 7\n'
          'x − y = 2\n'
          'De la segunda: x = y + 2. En la primera: 2(y + 2) + y = 7, '
          'o sea 3y + 4 = 7, y = 1. Entonces x = 3.',
      relacionados: ['a_ecuaciones_lineales', 'a_cuadratica'],
    ),
    TemaMacias(
      id: 'a_cuadratica',
      pregunta: 'Ecuación de segundo grado',
      claves: [
        'ecuacion de segundo grado',
        'ecuaciones de segundo grado',
        'segundo grado',
        'cuadratica',
        'cuadraticas',
        'formula general',
        'discriminante',
        'chicharronera',
      ],
      respuesta: (c) =>
          'Para ax² + bx + c = 0:\n'
          'x = (−b ± √(b² − 4ac)) / 2a\n\n'
          'El discriminante Δ = b² − 4ac dice qué esperar:\n'
          '• Δ > 0: dos soluciones reales distintas.\n'
          '• Δ = 0: una solución doble.\n'
          '• Δ < 0: no hay soluciones reales (son complejas).\n\n'
          'Ejemplo: x² − 5x + 6 = 0. Δ = 25 − 24 = 1, entonces '
          'x = (5 ± 1)/2: x = 3 o x = 2.\n'
          'Escríbeme **resuelve x^2 - 5x + 6 = 0** y la resuelvo paso a paso.',
      ampliacion: (c) =>
          'Cuando falta un término es más corto:\n'
          '• Sin c: 2x² − 6x = 0, factor común 2x(x − 3) = 0, así que '
          'x = 0 o x = 3.\n'
          '• Sin b: x² − 49 = 0, x² = 49, así que x = 7 o x = −7.',
      relacionados: ['a_trinomios', 'calculadora'],
    ),
    TemaMacias(
      id: 'a_exponentes',
      pregunta: 'Leyes de exponentes y radicales',
      claves: [
        'exponente*',
        'potencia*',
        'radical*',
        'raiz',
        'raices',
        'leyes de los exponentes',
      ],
      respuesta: (c) =>
          '• a^m · a^n = a^(m+n)\n'
          '• a^m / a^n = a^(m−n)\n'
          '• (a^m)^n = a^(m·n)\n'
          '• (ab)^n = a^n · b^n\n'
          '• a^0 = 1 (si a ≠ 0)\n'
          '• a^(−n) = 1 / a^n\n'
          '• a^(m/n) es la raíz n-ésima de a^m\n\n'
          'Ejemplo: (2x³)² · x^(−4) = 4x⁶ · x^(−4) = 4x²\n'
          'Radicales: √12 = √(4 · 3) = 2√3',
      ampliacion: (c) =>
          'Para racionalizar, multiplicas arriba y abajo para sacar la raíz '
          'del denominador:\n'
          '6 / √3 = 6√3 / 3 = 2√3\n'
          '1 / (√5 − 1) = (√5 + 1) / (5 − 1) = (√5 + 1) / 4',
      relacionados: ['a_logaritmos', 'a_productos_notables'],
    ),
    TemaMacias(
      id: 'a_logaritmos',
      pregunta: 'Logaritmos',
      claves: [
        'logaritmo*',
        'log',
        'ln',
        'logaritmica',
        'exponencial',
        'ecuacion exponencial',
      ],
      respuesta: (c) =>
          'log_b(x) = y significa b^y = x. Por ejemplo, log₂(8) = 3 porque '
          '2³ = 8.\n\n'
          'Propiedades:\n'
          '• log(a · b) = log a + log b\n'
          '• log(a / b) = log a − log b\n'
          '• log(a^n) = n · log a\n'
          '• log_b(b) = 1 y log_b(1) = 0\n'
          '• Cambio de base: log_b(x) = ln(x) / ln(b)\n\n'
          'Ejemplo: 2^x = 32, entonces x = log₂(32) = 5.',
      ampliacion: (c) =>
          'Una que necesita propiedades: log(x) + log(x − 3) = 1 (base 10)\n'
          'log(x(x − 3)) = 1, así que x² − 3x = 10\n'
          'x² − 3x − 10 = 0, que da x = 5 o x = −2.\n'
          'Pero x = −2 no sirve (no hay logaritmo de un negativo): **x = 5**.',
      relacionados: ['a_exponentes', 'a_cuadratica'],
    ),
    TemaMacias(
      id: 'a_fracciones',
      pregunta: 'Fracciones algebraicas',
      claves: [
        'fracciones algebraicas',
        'fraccion algebraica',
        'simplificar fraccion',
        'simplificar fracciones',
        'simplificar',
        'mcd',
        'mcm',
        'minimo comun multiplo',
        'maximo comun divisor',
      ],
      respuesta: (c) =>
          'Para simplificar, factoriza arriba y abajo y cancela lo que se '
          'repite:\n'
          '(x² − 9) / (x² + 3x) = (x + 3)(x − 3) / [x(x + 3)] = (x − 3) / x\n\n'
          'Para sumar o restar, usa el mínimo común múltiplo de los '
          'denominadores:\n'
          '1/x + 1/(x + 1) = [(x + 1) + x] / [x(x + 1)] = (2x + 1) / '
          '[x(x + 1)]\n\n'
          'Ojo: solo se cancelan factores (cosas que multiplican), nunca '
          'términos que suman.',
      ampliacion: (c) =>
          'El error más común: (x + 2) / 2 no es x + 1. El 2 de abajo divide '
          'a todo lo de arriba: (x + 2) / 2 = x/2 + 1.',
      relacionados: ['a_factorizacion', 'c_fracciones_parciales'],
    ),
    TemaMacias(
      id: 'a_progresiones',
      pregunta: 'Progresiones aritméticas y geométricas',
      claves: [
        'progresion*',
        'sucesion*',
        'aritmetica',
        'geometrica',
        'termino general',
        'razon',
        'diferencia comun',
      ],
      respuesta: (c) =>
          '**Aritmética** (se suma siempre lo mismo, d):\n'
          'a_n = a₁ + (n − 1) · d\n'
          'Suma de n términos: S_n = n · (a₁ + a_n) / 2\n'
          'Ejemplo: 3, 7, 11, 15… con d = 4, el décimo es 3 + 9 · 4 = 39.\n\n'
          '**Geométrica** (se multiplica siempre por lo mismo, r):\n'
          'a_n = a₁ · r^(n−1)\n'
          'Suma de n términos: S_n = a₁ · (r^n − 1) / (r − 1)\n'
          'Ejemplo: 2, 6, 18, 54… con r = 3, el sexto es 2 · 3⁵ = 486.',
      ampliacion: (c) =>
          'La suma de 1 + 2 + 3 + … + 100 es aritmética con a₁ = 1 y '
          'a_n = 100: S = 100 · (1 + 100) / 2 = 5050. Es la cuenta famosa '
          'que hizo Gauss de niño.',
      relacionados: ['a_binomio_newton', 'a_exponentes'],
    ),
    TemaMacias(
      id: 'a_binomio_newton',
      pregunta: 'Binomio de Newton',
      claves: [
        'binomio de newton',
        'newton',
        'triangulo de pascal',
        'pascal',
        'coeficientes binomiales',
        'combinatoria',
        'combinaciones',
      ],
      respuesta: (c) =>
          '(a + b)^n se desarrolla con los coeficientes del triángulo de '
          'Pascal:\n'
          'n = 2: 1 2 1\n'
          'n = 3: 1 3 3 1\n'
          'n = 4: 1 4 6 4 1\n'
          'n = 5: 1 5 10 10 5 1\n\n'
          'Ejemplo: (x + 2)⁴ = x⁴ + 8x³ + 24x² + 32x + 16\n'
          '(los coeficientes 1, 4, 6, 4, 1 multiplicados por 1, 2, 4, 8, 16).\n\n'
          'El término k (contando desde 0) es C(n, k) · a^(n−k) · b^k.',
      ampliacion: (c) =>
          'Con resta, los signos se alternan:\n'
          '(x − 1)³ = x³ − 3x² + 3x − 1\n\n'
          'Y C(n, k) = n! / (k! · (n − k)!). Por ejemplo, C(5, 2) = 120 / '
          '(2 · 6) = 10.',
      relacionados: ['a_productos_notables', 'a_progresiones'],
    ),
  ];

  // =====================================================================
  // Calculo integral
  // =====================================================================
  static final _calculo = <TemaMacias>[
    TemaMacias(
      id: 'c_integral',
      pregunta: '¿Qué es una integral?',
      claves: [
        'que es una integral',
        'integral',
        'integrales',
        'integrar',
        'integro',
        'antiderivada',
        'primitiva',
        'constante de integracion',
      ],
      respuesta: (c) =>
          'Integrar es lo contrario de derivar: buscas una función F cuya '
          'derivada sea f.\n'
          '∫ f(x) dx = F(x) + C, porque F′(x) = f(x)\n\n'
          'La **C** (constante de integración) va siempre en la integral '
          'indefinida: al derivar, cualquier constante desaparece.\n'
          'Ejemplo: ∫ 2x dx = x² + C, porque la derivada de x² es 2x.\n\n'
          'La integral definida, en cambio, da un número: el área (con signo) '
          'bajo la curva entre dos límites.',
      ampliacion: (c) =>
          'Para comprobar una integral, deriva el resultado: tiene que darte '
          'lo que estaba adentro. Por ejemplo, ∫ cos x dx = sen x + C, y la '
          'derivada de sen x es cos x.',
      relacionados: ['c_inmediatas', 'c_definida'],
    ),
    TemaMacias(
      id: 'c_inmediatas',
      pregunta: 'Integrales inmediatas',
      claves: [
        'integrales inmediatas',
        'integral inmediata',
        'tabla de integrales',
        'formulas de integracion',
        'formulario',
        'integrales basicas',
      ],
      respuesta: (c) =>
          'Las que conviene saber de memoria:\n'
          '• ∫ x^n dx = x^(n+1) / (n + 1) + C   (n ≠ −1)\n'
          '• ∫ 1/x dx = ln|x| + C\n'
          '• ∫ e^x dx = e^x + C\n'
          '• ∫ a^x dx = a^x / ln a + C\n'
          '• ∫ sen x dx = −cos x + C\n'
          '• ∫ cos x dx = sen x + C\n'
          '• ∫ sec² x dx = tan x + C\n'
          '• ∫ 1/(1 + x²) dx = arctan x + C\n'
          '• ∫ 1/√(1 − x²) dx = arcsen x + C\n\n'
          'Ejemplo: ∫ (3x² − 4x + 5) dx = x³ − 2x² + 5x + C',
      ampliacion: (c) =>
          'Con raíces, pásalas a potencia primero:\n'
          '∫ √x dx = ∫ x^(1/2) dx = x^(3/2) / (3/2) + C = (2/3) x^(3/2) + C\n'
          '∫ 1/x² dx = ∫ x^(−2) dx = −1/x + C',
      relacionados: ['c_sustitucion', 'c_partes'],
    ),
    TemaMacias(
      id: 'c_sustitucion',
      pregunta: 'Integración por sustitución',
      claves: [
        'integracion por sustitucion',
        'por sustitucion',
        'cambio de variable',
        'sustitucion',
        'u du',
      ],
      respuesta: (c) =>
          'Sirve cuando dentro de la integral hay una función y su derivada '
          '(o casi).\n'
          '1. Elige u (lo de adentro).\n'
          '2. Calcula du.\n'
          '3. Reescribe todo en u, integra y vuelve a x.\n\n'
          'Ejemplo: ∫ 2x · cos(x²) dx\n'
          'u = x², du = 2x dx\n'
          '∫ cos u du = sen u + C = sen(x²) + C',
      ampliacion: (c) =>
          'Otro, con un número que falta: ∫ x / (x² + 1) dx\n'
          'u = x² + 1, du = 2x dx, así que x dx = du/2\n'
          '(1/2) ∫ du/u = (1/2) ln(x² + 1) + C',
      relacionados: ['c_partes', 'c_inmediatas'],
    ),
    TemaMacias(
      id: 'c_partes',
      pregunta: 'Integración por partes',
      claves: [
        'por partes',
        'integracion por partes',
        'u dv',
        'udv',
        'ilate',
        'liate',
      ],
      respuesta: (c) =>
          '∫ u dv = u · v − ∫ v du\n\n'
          'Para elegir u, usa el orden **ILATE**: Inversas trigonométricas, '
          'Logaritmos, Algebraicas, Trigonométricas, Exponenciales. La que '
          'aparece primero en esa lista es u.\n\n'
          'Ejemplo: ∫ x · e^x dx\n'
          'u = x, du = dx; dv = e^x dx, v = e^x\n'
          '= x · e^x − ∫ e^x dx = x · e^x − e^x + C',
      ampliacion: (c) =>
          'Uno clásico: ∫ ln x dx\n'
          'u = ln x, du = dx/x; dv = dx, v = x\n'
          '= x · ln x − ∫ x · (1/x) dx = x · ln x − x + C',
      relacionados: ['c_sustitucion', 'c_trigonometricas'],
    ),
    TemaMacias(
      id: 'c_trigonometricas',
      pregunta: 'Integrales trigonométricas',
      claves: [
        'integrales trigonometricas',
        'integral trigonometrica',
        'potencias de seno',
        'potencias de coseno',
        'seno al cuadrado',
        'coseno al cuadrado',
        'identidades',
      ],
      respuesta: (c) =>
          'Con potencias de seno y coseno:\n'
          '• Si una potencia es impar, separa un factor y usa '
          'sen² x + cos² x = 1:\n'
          '∫ sen³ x dx = ∫ (1 − cos² x) · sen x dx = −cos x + cos³ x / 3 + C\n\n'
          '• Si las dos son pares, baja el grado con:\n'
          'sen² x = (1 − cos 2x) / 2\n'
          'cos² x = (1 + cos 2x) / 2\n'
          '∫ cos² x dx = x/2 + sen(2x)/4 + C',
      ampliacion: (c) =>
          '∫ sen x · cos x dx tiene un atajo: con u = sen x, du = cos x dx, '
          'da sen² x / 2 + C.',
      relacionados: ['c_sustitucion_trig', 'c_partes'],
    ),
    TemaMacias(
      id: 'c_sustitucion_trig',
      pregunta: 'Sustitución trigonométrica',
      claves: [
        'sustitucion trigonometrica',
        'raiz de a2 menos x2',
        'raiz cuadrada de a2',
      ],
      respuesta: (c) =>
          'Cuando aparece una de estas raíces:\n'
          '• √(a² − x²): x = a · sen t\n'
          '• √(a² + x²): x = a · tan t\n'
          '• √(x² − a²): x = a · sec t\n\n'
          'La raíz se simplifica con una identidad (por ejemplo, '
          'a² − a² sen² t = a² cos² t). Al final vuelves a x dibujando el '
          'triángulo rectángulo.\n\n'
          'Ejemplo: ∫ dx / √(4 − x²), con x = 2 sen t:\n'
          '∫ dt = t + C = arcsen(x/2) + C',
      ampliacion: (c) =>
          'Con tangente: ∫ dx / (x² + 9), con x = 3 tan t, '
          'dx = 3 sec² t dt:\n'
          '∫ 3 sec² t / (9 sec² t) dt = t/3 + C = (1/3) arctan(x/3) + C',
      relacionados: ['c_trigonometricas', 'c_fracciones_parciales'],
    ),
    TemaMacias(
      id: 'c_fracciones_parciales',
      pregunta: 'Fracciones parciales',
      claves: [
        'fracciones parciales',
        'fracciones simples',
        'descomposicion en fracciones',
        'funcion racional',
        'racionales',
      ],
      respuesta: (c) =>
          'Para integrar P(x)/Q(x) cuando el grado de arriba es menor, '
          'separas en fracciones simples según los factores de abajo:\n'
          '• Factor (x − a): A / (x − a)\n'
          '• Factor repetido (x − a)²: A/(x − a) + B/(x − a)²\n'
          '• Cuadrático irreducible: (Ax + B) / (x² + bx + c)\n\n'
          'Ejemplo: ∫ dx / (x² − 1)\n'
          '1 / ((x − 1)(x + 1)) = (1/2)/(x − 1) − (1/2)/(x + 1)\n'
          '= (1/2) ln|x − 1| − (1/2) ln|x + 1| + C\n\n'
          'Si el grado de arriba es mayor o igual, primero divide los '
          'polinomios.',
      ampliacion: (c) =>
          'Para hallar A y B rápido, reemplaza las raíces: en '
          '1 = A(x + 1) + B(x − 1), con x = 1 sale A = 1/2, y con x = −1 sale '
          'B = −1/2.',
      relacionados: ['c_sustitucion', 'a_fracciones'],
    ),
    TemaMacias(
      id: 'c_definida',
      pregunta: 'Integral definida',
      claves: [
        'integral definida',
        'integrales definidas',
        'definida',
        'definidas',
        'teorema fundamental',
        'barrow',
        'regla de barrow',
        'limites de integracion',
      ],
      respuesta: (c) =>
          'Con límites a y b, la integral da un número:\n'
          '∫ de a a b de f(x) dx = F(b) − F(a)\n'
          '(teorema fundamental del cálculo, o regla de Barrow). Aquí no va '
          '+ C.\n\n'
          'Ejemplo: ∫ de 0 a 2 de 3x² dx = [x³] de 0 a 2 = 8 − 0 = 8\n\n'
          'Propiedades útiles:\n'
          '• Invertir los límites cambia el signo.\n'
          '• De a hasta a, vale 0.\n'
          '• Se puede partir: de a a c = (de a a b) + (de b a c).',
      ampliacion: (c) =>
          'Con sustitución en una definida, cambia también los límites: '
          '∫ de 0 a 1 de 2x · e^(x²) dx, con u = x², va de u = 0 a u = 1:\n'
          '∫ de 0 a 1 de e^u du = e − 1 ≈ 1.718',
      relacionados: ['c_area', 'c_integral'],
    ),
    TemaMacias(
      id: 'c_area',
      pregunta: 'Área entre curvas',
      claves: [
        'area entre curvas',
        'area bajo la curva',
        'area',
        'calcular area',
        'region',
      ],
      respuesta: (c) =>
          'Área entre f y g de a a b, con f arriba de g:\n'
          'A = ∫ de a a b de [f(x) − g(x)] dx\n\n'
          'Pasos: busca dónde se cortan (f(x) = g(x)) para tener los '
          'límites, y fíjate cuál va arriba.\n\n'
          'Ejemplo: entre y = x y y = x², que se cortan en 0 y 1:\n'
          'A = ∫ de 0 a 1 de (x − x²) dx = 1/2 − 1/3 = 1/6\n\n'
          'Si la curva cruza el eje x, separa la integral en tramos: lo que '
          'queda debajo del eje suma con signo negativo.',
      ampliacion: (c) =>
          'Área bajo y = sen x de 0 a π: ∫ de 0 a π de sen x dx = '
          '[−cos x] de 0 a π = 1 + 1 = 2.',
      relacionados: ['c_volumen', 'c_definida'],
    ),
    TemaMacias(
      id: 'c_volumen',
      pregunta: 'Volúmenes de revolución',
      claves: [
        'volumen*',
        'solido de revolucion',
        'solidos de revolucion',
        'discos',
        'arandelas',
        'anillos',
        'capas cilindricas',
        'casquetes',
      ],
      respuesta: (c) =>
          'Al girar una región alrededor del eje x:\n'
          '• **Discos**: V = π ∫ de a a b de [f(x)]² dx\n'
          '• **Arandelas** (con hueco): V = π ∫ de a a b de ([R(x)]² − '
          '[r(x)]²) dx\n'
          '• **Capas cilíndricas** (girando alrededor del eje y): '
          'V = 2π ∫ de a a b de x · f(x) dx\n\n'
          'Ejemplo: y = √x de 0 a 4, girando alrededor del eje x:\n'
          'V = π ∫ de 0 a 4 de x dx = π · 16/2 = 8π',
      ampliacion: (c) =>
          'El volumen de una esfera sale con discos: girar y = √(r² − x²) de '
          '−r a r da V = π ∫ (r² − x²) dx = (4/3) π r³.',
      relacionados: ['c_area', 'c_definida'],
    ),
    TemaMacias(
      id: 'c_impropias',
      pregunta: 'Integrales impropias',
      claves: [
        'impropia*',
        'integral impropia',
        'integrales impropias',
        'infinito',
        'converge',
        'diverge',
        'convergencia',
      ],
      respuesta: (c) =>
          'Son las que tienen un límite infinito, o una función que se '
          'dispara dentro del intervalo. Se calculan con un límite:\n'
          '∫ de 1 a ∞ de dx/x² = lím (b tiende a ∞) de [−1/x] de 1 a b '
          '= lím (1 − 1/b) = 1: converge.\n'
          '∫ de 1 a ∞ de dx/x = lím ln b = ∞: diverge.\n\n'
          'Regla rápida: ∫ de 1 a ∞ de dx / x^p converge solo si p > 1.',
      ampliacion: (c) =>
          'Una con la función que se dispara: ∫ de 0 a 1 de dx/√x = '
          'lím (a tiende a 0) de [2√x] de a a 1 = 2: converge, aunque en 0 la '
          'función tienda a infinito.',
      relacionados: ['c_definida', 'c_integral'],
    ),
  ];

  // =====================================================================
  // C++
  // =====================================================================
  static final _cpp = <TemaMacias>[
    TemaMacias(
      id: 'p_hola',
      pregunta: 'Hola mundo y cómo compilar',
      claves: [
        'hola mundo',
        'primer programa',
        'compilar',
        'compilo',
        'compilador',
        'iostream',
        'empezar a programar',
      ],
      respuesta: (c) => r'''El programa más corto que muestra algo:
```
#include <iostream>

int main() {
    std::cout << "Hola mundo\n";
    return 0;
}
```
Para compilarlo y ejecutarlo en la terminal:
```
g++ hola.cpp -o hola
./hola
```
• `#include <iostream>` trae lo necesario para mostrar texto.
• `main` es donde empieza el programa.
• Cada instrucción termina en punto y coma.''',
      ampliacion: (c) =>
          r'''Si escribes `using namespace std;` arriba, te ahorras el `std::`:
```
#include <iostream>
using namespace std;

int main() {
    cout << "Hola" << endl;
}
```
En proyectos grandes se evita, porque mezcla nombres; para ejercicios de clase está bien.''',
      relacionados: ['p_tipos', 'p_entrada_salida'],
    ),
    TemaMacias(
      id: 'p_tipos',
      pregunta: 'Tipos de datos y variables',
      claves: [
        'tipos de datos',
        'tipo de dato',
        'variable*',
        'int',
        'double',
        'float',
        'char',
        'bool',
        'const',
        'auto',
      ],
      respuesta: (c) => r'''Toda variable tiene un tipo:
```
int edad = 20;           // enteros
double promedio = 8.5;   // con decimales
char letra = 'A';        // un caracter
bool aprobado = true;    // verdadero o falso
std::string nombre = "Ana";  // texto (con #include <string>)
auto total = edad * 2;   // el compilador deduce el tipo
const int MAX = 100;     // no se puede cambiar
```
• Dividir dos `int` da un `int`: `7 / 2` vale 3. Usa `7.0 / 2` para obtener 3.5.
• Una variable sin inicializar tiene basura: dale siempre un valor.''',
      ampliacion: (c) => r'''Para convertir entre tipos:
```
int n = 7;
double d = static_cast<double>(n) / 2;   // 3.5
int redondeado = static_cast<int>(3.9);  // 3: corta, no redondea
std::string s = std::to_string(42);      // "42"
int m = std::stoi("123");                // 123
```''',
      relacionados: ['p_entrada_salida', 'p_condicionales'],
    ),
    TemaMacias(
      id: 'p_entrada_salida',
      pregunta: 'Leer y mostrar datos (cin y cout)',
      claves: [
        'cin',
        'cout',
        'getline',
        'leer datos',
        'leer por teclado',
        'imprimir',
        'mostrar en pantalla',
        'entrada y salida',
      ],
      respuesta: (c) => r'''```
#include <iostream>
#include <string>
using namespace std;

int main() {
    int edad;
    cout << "Edad: ";
    cin >> edad;

    string nombre;
    cin.ignore();          // descarta el Enter que quedó
    getline(cin, nombre);  // lee la línea completa, con espacios
    cout << "Hola " << nombre << ", tienes " << edad << endl;
}
```
• `cin >>` lee hasta el primer espacio; `getline` lee la línea entera.
• Si usas `cin >>` y después `getline`, pon `cin.ignore()` en medio.''',
      ampliacion: (c) => r'''Para mostrar decimales con formato:
```
#include <iomanip>
cout << fixed << setprecision(2) << 3.14159;   // 3.14
```''',
      relacionados: ['p_tipos', 'p_strings'],
    ),
    TemaMacias(
      id: 'p_condicionales',
      pregunta: 'Condicionales (if, else, switch)',
      claves: ['if', 'else', 'condicional*', 'switch', 'case', 'ternario'],
      respuesta: (c) => r'''```
if (nota >= 51) {
    cout << "Aprobado";
} else {
    cout << "Reprobado";
}

switch (opcion) {
    case 1: cout << "Uno"; break;
    case 2: cout << "Dos"; break;
    default: cout << "Otra";
}
```
• Compara con `==`. Con un solo `=` estás asignando, y el `if` casi siempre da verdadero.
• Sin `break`, el `switch` sigue con el caso de abajo.
• Varias condiciones: `&&` (y), `||` (o), `!` (no).''',
      ampliacion: (c) =>
          r'''El operador ternario es un if corto que devuelve un valor:
```
string estado = (nota >= 51) ? "Aprobado" : "Reprobado";
```''',
      relacionados: ['p_bucles', 'p_errores'],
    ),
    TemaMacias(
      id: 'p_bucles',
      pregunta: 'Bucles (for, while, do-while)',
      claves: [
        'bucle*',
        'ciclo*',
        'for',
        'while',
        'do while',
        'iterar',
        'loop',
      ],
      respuesta: (c) => r'''```
for (int i = 1; i <= 5; i++) {
    cout << i << " ";        // 1 2 3 4 5
}

int n = 10;
while (n > 0) {
    n -= 3;                  // mientras se cumpla
}

int opcion;
do {
    cin >> opcion;           // se ejecuta al menos una vez
} while (opcion != 0);
```
• `for`: cuando sabes cuántas veces.
• `while`: mientras se cumpla una condición.
• `do-while`: tiene que ejecutarse al menos una vez (los menús).
• `break` sale del bucle; `continue` salta a la siguiente vuelta.''',
      ampliacion: (c) => r'''Un clásico de clase, sumar los pares del 1 al 100:
```
int suma = 0;
for (int i = 2; i <= 100; i += 2) {
    suma += i;
}
cout << suma;   // 2550
```''',
      relacionados: ['p_arreglos', 'p_condicionales'],
    ),
    TemaMacias(
      id: 'p_funciones',
      pregunta: 'Funciones',
      claves: [
        'funcion*',
        'parametro*',
        'return',
        'sobrecarga',
        'por referencia',
        'por valor',
        'prototipo',
        'recursion',
        'recursividad',
      ],
      respuesta: (c) => r'''```
int sumar(int a, int b) {      // devuelve un int
    return a + b;
}

void duplicar(int& x) {        // por referencia: cambia el original
    x = x * 2;
}

double area(double r, double pi = 3.1416) {  // valor por defecto
    return pi * r * r;
}
```
• Por valor (`int x`) la función trabaja con una copia; por referencia (`int& x`), con la variable original.
• Puedes tener varias funciones con el mismo nombre si cambian los parámetros (sobrecarga).
• Si la usas antes de definirla, declara su prototipo arriba: `int sumar(int, int);`''',
      ampliacion: (c) =>
          r'''Una función recursiva se llama a sí misma; siempre necesita un caso base:
```
int factorial(int n) {
    if (n <= 1) return 1;      // caso base
    return n * factorial(n - 1);
}
// factorial(5) = 120
```''',
      relacionados: ['p_punteros', 'p_clases'],
    ),
    TemaMacias(
      id: 'p_arreglos',
      pregunta: 'Arreglos y vectores',
      claves: [
        'arreglo*',
        'array*',
        'vector*',
        'matriz',
        'matrices',
        'push back',
      ],
      respuesta: (c) => r'''```
int notas[5] = {80, 75, 90, 60, 85};  // tamaño fijo
cout << notas[0];                     // el primero está en la posición 0

#include <vector>
std::vector<int> v = {3, 1, 2};
v.push_back(10);                      // crece solo
for (int x : v) cout << x << " ";     // recorrer
cout << v.size();                     // 4
```
• Los índices van de 0 a tamaño − 1. Salirte (`notas[5]`) es un error que no siempre avisa.
• Prefiere `std::vector`: sabe su tamaño y crece cuando hace falta.''',
      ampliacion: (c) => r'''Una matriz con vectores:
```
int filas = 3, columnas = 4;
std::vector<std::vector<int>> m(filas, std::vector<int>(columnas, 0));
m[1][2] = 7;   // fila 1, columna 2
```''',
      relacionados: ['p_stl', 'p_bucles'],
    ),
    TemaMacias(
      id: 'p_strings',
      pregunta: 'Cadenas de texto (string)',
      claves: ['string*', 'cadena*', 'substr', 'concatenar', 'texto en c'],
      respuesta: (c) => r'''```
#include <string>
std::string s = "Hola";
s += " mundo";                 // concatenar
cout << s.length();            // 10
cout << s[0];                  // 'H'
cout << s.substr(0, 4);        // "Hola"
size_t pos = s.find("mundo");  // 5, o string::npos si no está
```
• Compara textos con `==` (con `string`, no con `char*`).
• Para leer una línea con espacios usa `getline(cin, s)`.''',
      ampliacion: (c) =>
          r'''Recorrer un string letra por letra, por ejemplo para contar vocales:
```
int vocales = 0;
for (char c : s) {
    if (std::string("aeiouAEIOU").find(c) != std::string::npos) {
        vocales++;
    }
}
```''',
      relacionados: ['p_entrada_salida', 'p_arreglos'],
    ),
    TemaMacias(
      id: 'p_punteros',
      pregunta: 'Punteros y referencias',
      claves: [
        'puntero*',
        'referencia*',
        'direccion de memoria',
        'nullptr',
        'asterisco',
      ],
      respuesta: (c) => r'''```
int x = 5;
int* p = &x;      // p guarda la dirección de x
cout << *p;       // 5: el valor al que apunta
*p = 8;           // ahora x vale 8

int& r = x;       // r es otro nombre para x
r = 10;           // x vale 10

int* nada = nullptr;  // un puntero que no apunta a nada
```
• `&` delante de una variable da su dirección; `*` delante de un puntero da el valor.
• Nunca uses un puntero sin inicializar, ni uno a algo que ya se borró: de ahí salen los segmentation fault.''',
      ampliacion: (c) => r'''Un puntero también recorre un arreglo:
```
int a[3] = {10, 20, 30};
int* p = a;          // apunta al primero
cout << *(p + 1);    // 20
```''',
      relacionados: ['p_memoria', 'p_funciones'],
    ),
    TemaMacias(
      id: 'p_memoria',
      pregunta: 'Memoria dinámica (new y delete)',
      claves: [
        'memoria dinamica',
        'new',
        'delete',
        'malloc',
        'puntero inteligente',
        'punteros inteligentes',
        'unique ptr',
        'shared ptr',
        'fuga de memoria',
      ],
      respuesta: (c) => r'''```
int n = 5;
int* a = new int[n];   // reservas memoria mientras corre el programa
a[0] = 1;
delete[] a;            // y la liberas tú

#include <memory>
auto p = std::make_unique<int>(42);   // se libera solo
```
• Cada `new` necesita su `delete` (y `new[]` su `delete[]`). Si te olvidas, hay fuga de memoria.
• En C++ moderno usa `std::vector`, `std::unique_ptr` o `std::shared_ptr`, y casi nunca necesitas `delete`.''',
      relacionados: ['p_punteros', 'p_clases'],
    ),
    TemaMacias(
      id: 'p_clases',
      pregunta: 'Clases y objetos',
      claves: [
        'clase*',
        'objeto*',
        'constructor*',
        'poo',
        'programacion orientada a objetos',
        'orientada a objetos',
        'atributo*',
        'encapsulamiento',
        'private',
        'public',
      ],
      respuesta: (c) => r'''```
class Cuenta {
private:
    double saldo;              // solo la clase lo toca
public:
    Cuenta(double inicial) : saldo(inicial) {}  // constructor

    void depositar(double monto) {
        if (monto > 0) saldo += monto;
    }
    double verSaldo() const { return saldo; }
};

Cuenta c(100);
c.depositar(50);
cout << c.verSaldo();   // 150
```
• `private` oculta los datos; `public` es lo que se usa desde afuera.
• El constructor se llama como la clase y no devuelve nada.
• `const` al final de un método promete que no cambia el objeto.''',
      relacionados: ['p_herencia', 'p_funciones'],
    ),
    TemaMacias(
      id: 'p_herencia',
      pregunta: 'Herencia y polimorfismo',
      claves: [
        'herencia',
        'heredar',
        'polimorfismo',
        'virtual',
        'override',
        'clase base',
        'clase derivada',
        'abstracta',
      ],
      respuesta: (c) => r'''```
class Figura {
public:
    virtual double area() const = 0;   // método virtual puro
    virtual ~Figura() = default;
};

class Circulo : public Figura {
    double r;
public:
    Circulo(double r) : r(r) {}
    double area() const override { return 3.1416 * r * r; }
};

std::vector<std::unique_ptr<Figura>> figuras;
figuras.push_back(std::make_unique<Circulo>(2));
for (auto& f : figuras) cout << f->area();  // usa el de Circulo
```
• `virtual` hace que se llame la versión de la clase hija.
• Con un método `= 0` la clase es abstracta: no se puede crear un objeto de ella.
• Si una clase se usa por herencia, dale un destructor `virtual`.''',
      relacionados: ['p_clases', 'p_memoria'],
    ),
    TemaMacias(
      id: 'p_stl',
      pregunta: 'Algoritmos y contenedores de la STL',
      claves: [
        'stl',
        'sort',
        'ordenar vector',
        'ordenar un vector',
        'find',
        'accumulate',
        'algorithm',
        'algoritmos',
        'map',
        'set',
        'biblioteca estandar',
      ],
      respuesta: (c) => r'''```
#include <algorithm>
#include <numeric>
#include <map>
std::vector<int> v = {5, 2, 8, 1};

std::sort(v.begin(), v.end());                      // 1 2 5 8
auto it = std::find(v.begin(), v.end(), 8);         // busca el 8
int suma = std::accumulate(v.begin(), v.end(), 0);  // 16
int mayor = *std::max_element(v.begin(), v.end());  // 8

std::map<std::string, int> edades;
edades["Ana"] = 20;                                 // clave y valor
```
• Casi todo lo que harías con un `for` ya existe en `<algorithm>`.
• De mayor a menor: `std::sort(v.begin(), v.end(), std::greater<int>());`''',
      relacionados: ['p_arreglos', 'p_archivos'],
    ),
    TemaMacias(
      id: 'p_archivos',
      pregunta: 'Leer y escribir archivos',
      claves: [
        'archivo*',
        'fichero*',
        'fstream',
        'ifstream',
        'ofstream',
        'txt',
      ],
      respuesta: (c) => r'''```
#include <fstream>
#include <string>

std::ofstream salida("notas.txt");     // crea o sobrescribe
salida << "Ana 85\n";
salida.close();

std::ifstream entrada("notas.txt");
std::string nombre;
int nota;
while (entrada >> nombre >> nota) {    // lee hasta que no haya más
    std::cout << nombre << ": " << nota << "\n";
}
```
• Para agregar al final sin borrar: `std::ofstream f("notas.txt", std::ios::app);`
• Comprueba que se abrió: `if (!entrada) { ... }`
• Mejor `while (entrada >> dato)` que `while (!entrada.eof())`: eof se entera tarde.''',
      relacionados: ['p_strings', 'p_stl'],
    ),
    TemaMacias(
      id: 'p_errores',
      pregunta: 'Errores típicos en C++',
      claves: [
        'segmentation fault',
        'segfault',
        'core dumped',
        'no compila',
        'undefined reference',
        'punto y coma',
        'error de compilacion',
        'error en c',
        'depurar',
        'debug',
      ],
      respuesta: (c) =>
          '• **Falta un punto y coma**: el error suele marcar la línea '
          'siguiente; mira la de arriba.\n'
          '• **`=` en vez de `==`** dentro de un `if`: asigna en lugar de '
          'comparar.\n'
          '• **Segmentation fault**: leíste o escribiste memoria que no es '
          'tuya (índice fuera de rango, puntero nulo o ya liberado).\n'
          '• **undefined reference**: declaraste una función pero falta su '
          'definición, o no compilaste ese archivo.\n'
          '• **Dividir enteros**: `5 / 2` da 2, no 2.5.\n'
          '• **Variables sin inicializar**: tienen basura; dales un valor al '
          'declararlas.\n\n'
          'Compila con `g++ -Wall -Wextra` para que el compilador te avise '
          'de más cosas.',
      relacionados: ['p_punteros', 'p_condicionales'],
    ),
  ];
}
