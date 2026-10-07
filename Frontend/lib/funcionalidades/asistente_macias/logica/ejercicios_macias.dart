import 'conversacion_macias.dart';

/// Los ejercicios de programacion que siempre toman en la U, resueltos en
/// C++ y explicados en dos lineas.
///
/// Solo se contestan si el mensaje habla de programar ("en C++", "un
/// programa que...", "el codigo para..."): "¿cómo sumo dos números?" a secas
/// es una pregunta de matematica, no de C++.
abstract final class EjerciciosMacias {
  static final _deProgramar = RegExp(
    r' (?:c|cpp|programa|programar|programo|programacion|codigo|algoritmo|'
    r'pseudocodigo|funcion|ejercicio de programacion) ',
  );

  static RespuestaCharla? responder(String limpio) {
    final t = ' $limpio ';
    if (!_deProgramar.hasMatch(t)) return null;
    for (final (claves, titulo, codigo) in _ejercicios) {
      if (claves.any((clave) => t.contains(' $clave '))) {
        return RespuestaCharla(
          '**$titulo** en C++:\n$codigo',
          intencion: 'estudio:ejercicio',
        );
      }
    }
    return null;
  }

  /// En orden: lo mas especifico primero. "Ordenar de menor a mayor" no es
  /// "el mayor de tres".
  static const _ejercicios = <(List<String>, String, String)>[
    (
      ['del 1 al', 'de 1 a n', 'primeros n', 'sumatoria', 'suma de 1 a'],
      'Sumar del 1 al n',
      r'''```
int n;
cin >> n;
long long suma = 0;
for (int i = 1; i <= n; i++) {
    suma += i;
}
cout << "Suma: " << suma;
```
• Gauss lo hacía sin bucle: 1 + 2 + … + n = n · (n + 1) / 2.
• `long long` para que no se desborde con n grandes.''',
    ),
    (
      [
        'mayor de un arreglo',
        'mayor del arreglo',
        'maximo de un arreglo',
        'mayor de un vector',
        'mayor de un array',
        'mayor elemento',
      ],
      'El mayor de un arreglo',
      r'''```
int v[] = {4, 9, 2, 7};
int n = 4;
int mayor = v[0];
for (int i = 1; i < n; i++) {
    if (v[i] > mayor) mayor = v[i];
}
cout << "El mayor es " << mayor;
```
• Se supone que el primero es el mayor y se corrige si aparece otro más grande.
• Con `vector<int>`: `*max_element(v.begin(), v.end())`, de `<algorithm>`.''',
    ),
    (
      [
        'ordenar un arreglo',
        'ordenar arreglo',
        'ordenar numeros',
        'ordenar de menor a mayor',
        'ordenar de mayor a menor',
        'burbuja',
        'bubble sort',
        'metodo de ordenamiento',
        'ordenamiento',
      ],
      'Ordenar (método burbuja)',
      r'''```
int v[] = {5, 2, 9, 1, 7};
int n = 5;
for (int i = 0; i < n - 1; i++) {
    for (int j = 0; j < n - 1 - i; j++) {
        if (v[j] > v[j + 1]) {
            int aux = v[j];
            v[j] = v[j + 1];
            v[j + 1] = aux;
        }
    }
}
// queda: 1 2 5 7 9
```
• En cada vuelta, el más grande "burbujea" hasta el final.
• Fuera de clase se usa `sort(v, v + n);` de `<algorithm>`: más rápido y en una línea.''',
    ),
    (
      ['par o impar', 'es par', 'numero par', 'numeros pares', 'impar'],
      'Par o impar',
      r'''```
int n;
cin >> n;
if (n % 2 == 0) {
    cout << n << " es par";
} else {
    cout << n << " es impar";
}
```
• `%` da el resto de la división: si al dividir entre 2 sobra 0, es par.
• Funciona también con negativos.''',
    ),
    (
      [
        'mayor de tres',
        'mayor de 3',
        'mayor de dos',
        'mayor de 2',
        'numero mayor',
        'el mayor',
        'mayor entre',
        'menor de tres',
        'el menor',
        'mayor y menor',
      ],
      'El mayor de tres números',
      r'''```
int a, b, c;
cin >> a >> b >> c;
int mayor = a;
if (b > mayor) mayor = b;
if (c > mayor) mayor = c;
cout << "El mayor es " << mayor;
```
• La idea: suponer que el primero es el mayor y corregir si aparece uno más grande. Sirve para cualquier cantidad.
• Para el menor, lo mismo con `<`. Con `<algorithm>`: `max({a, b, c})`.''',
    ),
    (
      ['factorial'],
      'Factorial',
      r'''```
int n;
cin >> n;
long long factorial = 1;
for (int i = 2; i <= n; i++) {
    factorial *= i;
}
cout << n << "! = " << factorial;
```
• `long long` porque crece rapidísimo: 13! ya no entra en un `int` (y hasta 20! entra en `long long`).
• 0! = 1, y el bucle lo respeta: no entra y queda en 1.''',
    ),
    (
      ['fibonacci', 'fibo'],
      'Fibonacci',
      r'''```
int n;
cin >> n;
long long a = 0, b = 1;
for (int i = 0; i < n; i++) {
    cout << a << " ";
    long long siguiente = a + b;
    a = b;
    b = siguiente;
}
```
• Muestra los primeros n términos: 0 1 1 2 3 5 8…
• Cada término es la suma de los dos anteriores. La versión recursiva es más corta, pero muchísimo más lenta.''',
    ),
    (
      ['es primo', 'numero primo', 'numeros primos', 'primos', 'primo o no'],
      'Número primo',
      r'''```
bool esPrimo(int n) {
    if (n < 2) return false;
    for (int i = 2; i * i <= n; i++) {
        if (n % i == 0) return false;
    }
    return true;
}

int main() {
    int n;
    cin >> n;
    cout << (esPrimo(n) ? "Es primo" : "No es primo");
}
```
• Basta probar divisores hasta la raíz de n: si tuviera uno más grande, también tendría uno más chico.
• El 1 no es primo, y el 2 es el único primo par.''',
    ),
    (
      ['tabla de multiplicar', 'tablas de multiplicar', 'tabla del'],
      'Tabla de multiplicar',
      r'''```
int n;
cout << "Que tabla? ";
cin >> n;
for (int i = 1; i <= 10; i++) {
    cout << n << " x " << i << " = " << n * i << endl;
}
```
• Para todas las tablas del 1 al 10, mete este `for` dentro de otro que recorra n.''',
    ),
    (
      [
        'promedio',
        'promedio de notas',
        'promediar',
        'notas de un curso',
        'notas de los alumnos',
      ],
      'Promedio de notas',
      r'''```
int cantidad;
cout << "Cuantas notas? ";
cin >> cantidad;
double suma = 0;
for (int i = 0; i < cantidad; i++) {
    double nota;
    cin >> nota;
    suma += nota;
}
if (cantidad > 0) {
    double promedio = suma / cantidad;
    cout << "Promedio: " << promedio;
    if (promedio >= 51) cout << " (aprobado)";
}
```
• `suma` es `double` para que la división no corte los decimales.
• Revisa que `cantidad` no sea 0 antes de dividir.''',
    ),
    (
      [
        'invertir',
        'invertir un numero',
        'numero al reves',
        'al reves',
        'palindromo',
        'capicua',
      ],
      'Invertir un número',
      r'''```
int n;
cin >> n;
int original = n, invertido = 0;
while (n > 0) {
    invertido = invertido * 10 + n % 10;   // agrega la última cifra
    n /= 10;                                // y la quita
}
cout << "Al reves: " << invertido << endl;
if (invertido == original) cout << "Es capicua";
```
• `n % 10` da la última cifra y `n / 10` la quita.
• Con texto es más fácil: `string r(s.rbegin(), s.rend());` y comparas `s == r`.''',
    ),
    (
      ['area del circulo', 'area de un circulo', 'circulo'],
      'Área y perímetro del círculo',
      r'''```
double r;
cin >> r;
const double PI = 3.14159265358979;
cout << "Area: " << PI * r * r << endl;
cout << "Perimetro: " << 2 * PI * r;
```
• `pow(r, 2)` de `<cmath>` también sirve, pero `r * r` es más directo.''',
    ),
    (
      ['celsius', 'fahrenheit', 'temperatura'],
      'Celsius a Fahrenheit',
      r'''```
double c;
cout << "Grados Celsius: ";
cin >> c;
double f = c * 9 / 5 + 32;
cout << c << " C = " << f << " F";
```
• Ojo: `9 / 5` entre enteros da 1 en C++. Como `c` es `double`, `c * 9 / 5` sale con decimales.
• Al revés: `c = (f - 32) * 5 / 9;`''',
    ),
    (
      ['calculadora'],
      'Calculadora',
      r'''```
double a, b;
char op;
cout << "Operacion (ej: 3 + 4): ";
cin >> a >> op >> b;
switch (op) {
    case '+': cout << a + b; break;
    case '-': cout << a - b; break;
    case '*': cout << a * b; break;
    case '/':
        if (b != 0) cout << a / b;
        else cout << "No se puede dividir entre 0";
        break;
    default: cout << "Operacion no valida";
}
```
• `cin >> a >> op >> b` lee "3 + 4" con o sin espacios.''',
    ),
    (
      ['intercambiar', 'intercambio', 'swap'],
      'Intercambiar dos variables',
      r'''```
int a = 5, b = 8;
int aux = a;   // guardo a antes de pisarlo
a = b;
b = aux;
// ahora a = 8 y b = 5
```
• Con `<utility>`, `swap(a, b);` hace lo mismo.''',
    ),
    (
      ['vocales', 'contar vocales', 'cuenta las vocales'],
      'Contar vocales',
      r'''```
string texto;
getline(cin, texto);
int vocales = 0;
for (char letra : texto) {
    char l = tolower(static_cast<unsigned char>(letra));
    if (l == 'a' || l == 'e' || l == 'i' || l == 'o' || l == 'u') {
        vocales++;
    }
}
cout << "Tiene " << vocales << " vocales";
```
• `tolower` (de `<cctype>`) hace que las mayúsculas cuenten igual.
• Las vocales con tilde no entran así: en el texto son caracteres especiales.''',
    ),
    (
      [
        'mcd',
        'maximo comun divisor',
        'euclides',
        'mcm',
        'minimo comun multiplo',
      ],
      'Máximo común divisor (Euclides)',
      r'''```
int mcd(int a, int b) {
    while (b != 0) {
        int resto = a % b;
        a = b;
        b = resto;
    }
    return a;
}
// mcd(48, 18) = 6
```
• El MCD de a y b es el mismo que el de b y el resto: así hasta que el resto es 0.
• El mcm sale del MCD: `a / mcd(a, b) * b`.''',
    ),
    (
      ['potencia', 'elevar', 'elevado'],
      'Potencia',
      r'''```
double base;
int exponente;
cin >> base >> exponente;
double resultado = 1;
for (int i = 0; i < exponente; i++) {
    resultado *= base;
}
cout << resultado;
```
• Así funciona con exponentes enteros positivos. Para cualquier exponente: `pow(base, exponente)` de `<cmath>`.''',
    ),
    (
      ['digitos', 'cifras', 'contar digitos', 'contar cifras'],
      'Contar cifras',
      r'''```
long long n;
cin >> n;
if (n < 0) n = -n;
int cifras = 0;
do {
    cifras++;
    n /= 10;
} while (n > 0);
cout << "Tiene " << cifras << " cifras";
```
• El `do-while` hace que el 0 cuente como una cifra.''',
    ),
    (
      [
        'sumar dos numeros',
        'sumo dos numeros',
        'suma de dos numeros',
        'sumar 2 numeros',
        'suma de 2 numeros',
        'sumar numeros',
        'sumar',
        'sume',
      ],
      'Sumar dos números',
      r'''```
#include <iostream>
using namespace std;

int main() {
    double a, b;
    cout << "Primer numero: ";
    cin >> a;
    cout << "Segundo numero: ";
    cin >> b;
    cout << "La suma es " << a + b << endl;
    return 0;
}
```
• `double` para que sume también decimales; con `int`, solo enteros.
• Para restar, multiplicar o dividir, cambia el `+` por `-`, `*` o `/` (y cuida dividir entre cero).''',
    ),
  ];
}
