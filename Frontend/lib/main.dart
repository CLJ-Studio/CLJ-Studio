import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'arbol_aplicacion/arbol_aplicacion.dart';

/// Punto de entrada de U market.
///
/// NO ES `async` Y NO PUEDE SERLO. Hasta que `runApp` corre no hay ni un solo
/// pixel de Flutter en pantalla: lo que se ve es el fondo del HTML, que es el
/// mismo crema del tema. Cualquier `await` puesto aqui arriba es tiempo en el
/// que la aplicacion existe pero no se ve, y si ese `await` tarda de mas o no
/// vuelve nunca, el crema se queda fijo y no hay forma de avisar de nada.
///
/// Por eso aqui solo queda lo que es instantaneo. Conectar con el servidor
/// -que es lo unico lento de verdad- ocurre YA DENTRO del arbol, con la
/// animacion de apertura puesta encima: el mismo tiempo de espera, pero
/// mirando algo.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // La app dibuja detras de la barra de estado y la de navegacion, como
  // cualquier app nativa. Sin esto quedaba una franja del color del sistema
  // arriba y la pantalla se veia recortada.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Limita la memoria retenida por fotografías en dispositivos modestos.
  PaintingBinding.instance.imageCache.maximumSize = 80;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  runApp(const ArbolAplicacion());
}

/// Acceso corto al cliente ya inicializado, usado por los repositorios.
SupabaseClient get supabase => Supabase.instance.client;
