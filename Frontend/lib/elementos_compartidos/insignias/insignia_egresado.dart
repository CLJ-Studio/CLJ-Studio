import 'package:flutter/material.dart';

/// La insignia dorada del egresado verificado: va junto al nombre, donde
/// sea que aparezca, como la de Instagram. Solo la llevan quienes un admin
/// verifico (lo dicen las vistas publicas: es_egresado, vendedor_egresado).
class InsigniaEgresado extends StatelessWidget {
  const InsigniaEgresado({this.tamano = 16, super.key});

  final double tamano;

  static const dorado = Color(0xFFE2A90F);

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Egresado verificado de la UPSA',
    child: Semantics(
      label: 'Egresado verificado',
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Detras del sello, para que la palomita se vea blanca en
            // cualquier fondo, claro u oscuro.
            Container(
              width: tamano * .52,
              height: tamano * .52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Icon(Icons.verified_rounded, size: tamano, color: dorado),
          ],
        ),
      ),
    ),
  );
}

/// Un nombre con la insignia al lado si es egresado verificado. Se usa
/// donde iba un Text, con el mismo maxLines que tenia.
///
/// Si el nombre puede ocupar varias lineas, la insignia va pegada a la
/// ultima palabra, como en Instagram (ver [nombreConInsigniaEnTexto]). En
/// una sola linea el nombre se corta antes que la insignia, que es lo que
/// no se puede perder.
class NombreConInsignia extends StatelessWidget {
  const NombreConInsignia(
    this.nombre, {
    required this.egresado,
    this.estilo,
    this.maxLines,
    this.textAlign,
    super.key,
  });

  final String nombre;
  final bool egresado;
  final TextStyle? estilo;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final corte = maxLines == null ? null : TextOverflow.ellipsis;
    if (!egresado) {
      return Text(
        nombre,
        style: estilo,
        maxLines: maxLines,
        overflow: corte,
        textAlign: textAlign,
      );
    }

    if (maxLines != 1) {
      return Text.rich(
        TextSpan(
          children: nombreConInsigniaEnTexto(
            nombre,
            egresado: true,
            estilo: estilo,
          ),
        ),
        style: estilo,
        maxLines: maxLines,
        overflow: corte,
        textAlign: textAlign,
      );
    }

    // Dentro de un texto la insignia crece con la letra del sistema; aca
    // afuera hay que escalarla igual.
    final letra =
        estilo?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final escala = MediaQuery.textScalerOf(context).scale(letra) / letra;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            nombre,
            style: estilo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            // Lo que ocupa el texto visible, no todo el lugar que le dan:
            // si el nombre se corta, la insignia va justo despues del "…".
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        ),
        SizedBox(width: letra * escala * .25),
        InsigniaEgresado(tamano: letra * escala * 1.05),
      ],
    );
  }
}

/// El nombre dentro de un texto que sigue ("De Ana Perez ✓ · Derecho").
/// `estilo` es el mismo que lleva ese Text.rich.
///
/// La ultima palabra y la insignia van en una sola pieza: el renglon puede
/// cortarse antes de ella, nunca entre las dos. Suelta, la insignia bajaba
/// sola al renglon siguiente cuando el nombre llenaba el anterior.
List<InlineSpan> nombreConInsigniaEnTexto(
  String nombre, {
  required bool egresado,
  TextStyle? estilo,
}) {
  if (!egresado) return [TextSpan(text: nombre)];

  final limpio = nombre.trimRight();
  final corte = limpio.lastIndexOf(' ') + 1;
  return [
    if (corte > 0) TextSpan(text: limpio.substring(0, corte)),
    WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _UltimaPalabra(limpio.substring(corte), estilo: estilo),
    ),
  ];
}

class _UltimaPalabra extends StatelessWidget {
  const _UltimaPalabra(this.palabra, {this.estilo});

  final String palabra;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final letra =
        DefaultTextStyle.of(context).style.merge(estilo).fontSize ?? 14;
    final tamano = letra * 1.05;
    // El texto de afuera ya escala esta pieza entera con la letra del
    // sistema: escalada aca tambien, quedaba mas grande que el resto.
    return MediaQuery.withNoTextScaling(
      child: Text.rich(
        TextSpan(
          text: palabra,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.only(left: tamano * .2, right: tamano * .1),
                child: InsigniaEgresado(tamano: tamano),
              ),
            ),
          ],
        ),
        style: estilo,
        softWrap: false,
      ),
    );
  }
}
