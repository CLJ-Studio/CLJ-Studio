import 'package:flutter/material.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../../../elementos_compartidos/animaciones/escala_al_presionar.dart';

/// La foto de MacIAs. Va dentro de la app y no se baja de la red: es la cara
/// del asistente y tiene que estar ahi aunque no haya senal.
const rutaFotoMacias = 'assets/images/marca/macias.jpg';

/// La foto redonda de MacIAs.
class AvatarMacias extends StatelessWidget {
  const AvatarMacias({
    this.tamano = 40,
    this.enLinea = false,
    this.anillo,
    this.fondo = Colors.white,
    super.key,
  });

  final double tamano;

  /// El punto verde de "disponible", como en cualquier chat. MacIAs lo
  /// esta siempre: responde aunque sean las tres de la manana.
  final bool enLinea;

  /// Un borde alrededor, para despegarla de un fondo oscuro.
  final Color? anillo;

  /// Lo que hay detras: el punto verde lleva un borde de ese color, que es
  /// lo que lo hace parecer recortado sobre la foto.
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final punto = tamano * .3;
    return Semantics(
      image: true,
      label: 'Foto de MacIAs',
      child: SizedBox.square(
        dimension: tamano,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ConfiguracionTema.crema,
                border: anillo == null
                    ? null
                    : Border.all(color: anillo!, width: 2),
                image: DecorationImage(
                  // La original mide 512 px; se decodifica a lo que se ve.
                  image: ResizeImage(
                    const AssetImage(rutaFotoMacias),
                    width: (tamano * escala).ceil(),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: SizedBox.square(dimension: tamano),
            ),
            if (enLinea)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: punto,
                  height: punto,
                  decoration: BoxDecoration(
                    color: ConfiguracionTema.interruptorActivo,
                    shape: BoxShape.circle,
                    border: Border.all(color: fondo, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La marca de verificado: la misma que lleva la cuenta institucional en
/// Configuracion, para que signifique lo mismo en toda la app.
///
/// El circulo blanco de atras es lo que hace que el visto se vea blanco sobre
/// cualquier fondo: el icono tiene el visto calado, y sobre el azul de la
/// cabecera se veia azul.
class InsigniaVerificado extends StatelessWidget {
  const InsigniaVerificado({this.tamano = 16, super.key});

  final double tamano;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: tamano,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: tamano * .5,
          height: tamano * .5,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          Icons.verified_rounded,
          size: tamano,
          color: ConfiguracionTema.interruptorActivo,
          semanticLabel: 'Verificado',
        ),
      ],
    ),
  );
}

/// "MacIAs" con su marca de verificado.
class NombreMacias extends StatelessWidget {
  const NombreMacias({this.estilo, super.key});

  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final tamano = estilo?.fontSize ?? 16;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('MacIAs', style: estilo),
        SizedBox(width: tamano * .3),
        InsigniaVerificado(tamano: tamano),
      ],
    );
  }
}

/// El acceso a MacIAs desde Ayuda.
///
/// Es lo primero de la pantalla y lo mas llamativo a proposito: responde al
/// instante, a cualquier hora, y resuelve casi todo sin esperar a que alguien
/// del equipo lea un WhatsApp.
class BotonChatMacias extends StatelessWidget {
  const BotonChatMacias({required this.alPresionar, super.key});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Chatea con MacIAs, asistente virtual verificado',
    excludeSemantics: true,
    child: EscalaAlPresionar(
      escala: .97,
      builder: (context, alResaltar) => Material(
        color: ConfiguracionTema.azulNoche,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alPresionar,
          onHighlightChanged: alResaltar,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 16, 10),
            child: Row(
              children: [
                AvatarMacias(
                  tamano: 46,
                  enLinea: true,
                  anillo: ConfiguracionTema.crema,
                  fondo: ConfiguracionTema.azulNoche,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Chatea con MacIAs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ConfiguracionTema.crema,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 5),
                          InsigniaVerificado(tamano: 17),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Asistente virtual · responde al instante',
                        maxLines: 2,
                        style: TextStyle(
                          color: Color(0xC7E6E1D5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: ConfiguracionTema.crema,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
