import 'package:flutter/material.dart';

/// Cuanto hay que dejar libre al final de una pantalla que vive bajo la barra
/// de navegacion flotante.
///
/// POR QUE: el Scaffold principal usa `extendBody: true`, o sea que el
/// contenido se dibuja POR DEBAJO de la barra, no encima. Cada pantalla se
/// despejaba con un numero puesto a ojo -96, 100, 110, 120 o 126 segun cual-
/// y ninguno sumaba el area segura del telefono.
///
/// En un movil con barra de gestos la cuenta real pasa de 120, asi que el
/// ultimo campo del formulario de publicar quedaba debajo de la barra: se
/// veia la mitad del texto y el boton de agregar no se podia tocar.
///
/// El Scaffold ya sabe cuanto ocupa su barra y lo publica en el padding del
/// cuerpo; `hueco_barra_navegacion_test.dart` lo comprueba. No hay que
/// estimarlo en cada pantalla: hay que leerlo.
///
/// En una pantalla apilada encima (sin barra) esto devuelve solo el area
/// segura, que es igual de correcto.
double huecoBarraNavegacion(BuildContext context, {double extra = 28}) =>
    MediaQuery.paddingOf(context).bottom + extra;
