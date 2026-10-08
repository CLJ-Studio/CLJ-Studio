{{flutter_js}}
{{flutter_build_config}}

/*
 * SKWASM EN UN SOLO HILO, A PROPOSITO.
 *
 * Con las cabeceras de aislamiento de netlify.toml, skwasm dibuja en un
 * hilo aparte, que era lo mas fluido. Pero en Flutter 3.44 el hilo principal
 * (que mide el texto) y el de dibujo comparten la cache de letras de Skia
 * sin protegerla, y en pantallas con mucho texto que cambia (el chat de
 * MacIAs) esa cache se corrompe: en un Galaxy A15 salieron letras cambiadas,
 * letras que faltaban y cortes de linea en medio de las palabras. Es el
 * defecto flutter/flutter#190039, que tambien puede congelar la pagina; el
 * arreglo llega en Flutter 3.48.
 *
 * Hasta actualizar Flutter, skwasm corre en un solo hilo: sigue siendo
 * WebAssembly (mas rapido que la version de JavaScript), solo sin el hilo
 * aparte. Al pasar a 3.48 o superior, se puede quitar `config` de aca.
 */
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    forceSingleThreadedSkwasm: true,
  },
});
