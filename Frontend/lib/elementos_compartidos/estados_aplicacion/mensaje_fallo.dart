/// Lo que se le dice a la persona cuando guardar algo falla.
///
/// El filtro de contenido rechaza en el servidor con CONTENIDO_NO_PERMITIDO, y
/// ese caso tiene que decirse tal cual. "No se pudo guardar el cambio" a secas
/// deja a la persona reintentando lo mismo, sin saber que el problema es una
/// palabra que puede cambiar.
String mensajeDeFallo(Object fallo, {required String porDefecto}) =>
    fallo.toString().contains('CONTENIDO_NO_PERMITIDO')
    ? 'Revisa el texto: tiene palabras que no se permiten.'
    : porDefecto;
