/// Lo que se le dice a la persona cuando guardar algo falla.
///
/// El filtro de contenido rechaza en el servidor con CONTENIDO_NO_PERMITIDO, y
/// ese caso tiene que decirse tal cual. "No se pudo guardar el cambio" a secas
/// deja a la persona reintentando lo mismo, sin saber que el problema es una
/// palabra que puede cambiar. Lo mismo con las fechas de las publicaciones.
String mensajeDeFallo(Object fallo, {required String porDefecto}) {
  final texto = fallo.toString();
  if (texto.contains('CONTENIDO_NO_PERMITIDO')) {
    return 'Revisa el texto: tiene palabras que no se permiten.';
  }
  if (texto.contains('VENCIMIENTO_INVALIDO')) {
    return 'Esa fecha ya pasó: elige otra.';
  }
  if (texto.contains('PUBLICACION_VENCIDA')) {
    return 'Venció: elige hasta cuándo se ve para volver a publicarla.';
  }
  if (texto.contains('STOCK_INVALIDO')) {
    return 'Para volver a publicarla hace falta al menos una unidad.';
  }
  return porDefecto;
}
