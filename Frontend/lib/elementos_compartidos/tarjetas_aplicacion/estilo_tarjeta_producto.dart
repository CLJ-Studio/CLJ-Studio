import 'package:flutter/material.dart';

import '../../configuracion_aplicacion/configuracion_tema.dart';

/// El aspecto comun de toda tarjeta de publicacion.
///
/// POR QUE EXISTE: la misma publicacion se dibujaba distinta en cada lista.
/// El nombre iba a 14 y peso 800 en el inicio, a 15 y peso 900 en el catalogo
/// de un local; el precio a 15 terracota aqui, a 18 gris alla, a 20 en "mis
/// publicaciones". Nadie lo decidio: cada pantalla se escribio por separado y
/// eligio numeros parecidos pero no iguales, y eso es justo lo que se nota
/// sin saber nombrarlo. Teniendo un solo sitio donde estan, dejan de separarse.
///
/// Las esquinas tambien viven aqui, por lo mismo: estaban a 18, 22, 24 y 26
/// segun la pantalla, y ademas demasiado redondeadas.
abstract final class EstiloTarjetaProducto {
  /// Antes 18 en la cuadricula y 22 en el inicio. Baja y se unifica: pasado
  /// cierto punto la esquina redonda deja de verse cuidada y empieza a comerse
  /// la foto.
  static const double radio = 16;

  static BorderRadius get borde => BorderRadius.circular(radio);

  /// Nombre de la publicacion. Dos lineas como mucho, en todas partes.
  static TextStyle nombre(BuildContext context) => TextStyle(
    color: _principal(context),
    fontSize: 15,
    height: 1.12,
    fontWeight: FontWeight.w800,
  );

  /// El precio: lo que se busca con la mirada, asi que es lo unico con color
  /// propio.
  ///
  /// En tema oscuro no puede ser terracota: sobre grafito son dos marrones
  /// casi iguales y el numero se pierde.
  static TextStyle precio(BuildContext context) => TextStyle(
    color: _esOscuro(context)
        ? ConfiguracionTema.crema
        : ConfiguracionTema.terracota,
    fontSize: 17,
    fontWeight: FontWeight.w900,
  );

  /// Descripcion corta, vendedor, y demas datos de acompanamiento.
  static TextStyle apoyo(BuildContext context) => TextStyle(
    color: _secundario(context),
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static bool _esOscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color _principal(BuildContext context) => _esOscuro(context)
      ? ConfiguracionTema.crema
      : ConfiguracionTema.grafito;

  static Color _secundario(BuildContext context) => _esOscuro(context)
      ? ConfiguracionTema.salviaClara
      : ConfiguracionTema.grisCalido;
}
