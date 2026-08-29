import 'package:flutter/material.dart';

/// Logotipo tipográfico compartido de U market.
///
/// La U conserva siempre el mayor peso visual. `market` usa la misma familia
/// Nunito, pero con un peso y un tono ligeramente más suaves.
class MarcaUMarket extends StatelessWidget {
  const MarcaUMarket({
    this.style,
    this.textAlign = TextAlign.start,
    this.colorU,
    this.colorMarket,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    super.key,
  });

  static const nombre = 'U market';

  final TextStyle? style;
  final TextAlign textAlign;
  final Color? colorU;
  final Color? colorMarket;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final estiloBase = DefaultTextStyle.of(
      context,
    ).style.merge(style).copyWith(fontFamily: 'Nunito');
    final colorBase =
        estiloBase.color ?? Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: nombre,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: estiloBase,
            children: [
              TextSpan(
                text: 'U',
                style: TextStyle(
                  color: colorU ?? colorBase,
                  fontWeight: FontWeight.w900,
                ),
              ),
              TextSpan(
                text: ' market',
                style: TextStyle(
                  color: colorMarket ?? colorBase.withValues(alpha: .78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }
}

/// Texto normal que aplica automáticamente el tratamiento de marca a cada
/// aparición de "U market" dentro de una frase.
class TextoConMarcaUMarket extends StatelessWidget {
  const TextoConMarcaUMarket(
    this.texto, {
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    super.key,
  });

  final String texto;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final estiloBase = DefaultTextStyle.of(
      context,
    ).style.merge(style).copyWith(fontFamily: 'Nunito');
    final colorBase =
        estiloBase.color ?? Theme.of(context).colorScheme.onSurface;
    final spans = <InlineSpan>[];
    var inicio = 0;

    while (true) {
      final indice = texto.indexOf(MarcaUMarket.nombre, inicio);
      if (indice < 0) {
        spans.add(TextSpan(text: texto.substring(inicio)));
        break;
      }
      if (indice > inicio) {
        spans.add(TextSpan(text: texto.substring(inicio, indice)));
      }
      spans.add(
        TextSpan(
          text: 'U',
          style: TextStyle(color: colorBase, fontWeight: FontWeight.w900),
        ),
      );
      spans.add(
        TextSpan(
          text: ' market',
          style: TextStyle(
            color: colorBase.withValues(alpha: .82),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      inicio = indice + MarcaUMarket.nombre.length;
    }

    return Text.rich(
      TextSpan(style: estiloBase, children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
