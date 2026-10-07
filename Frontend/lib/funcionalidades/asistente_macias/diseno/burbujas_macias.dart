import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../configuracion_aplicacion/configuracion_tema.dart';
import '../modelos/mensaje_macias.dart';
import 'identidad_macias.dart';

/// Los colores del chat de MacIAs: los mismos del chat de los pedidos.
///
/// Son las dos conversaciones de la app y tienen que sentirse de la misma
/// familia. Lo que importa no es cada color suelto, sino que fondo,
/// cabecera y las dos burbujas se separen entre si, tambien en tema oscuro.
abstract final class ColoresChatMacias {
  static bool _oscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color fondo(BuildContext context) => _oscuro(context)
      ? const Color(0xFF383737)
      : ConfiguracionTema.cremaSuperficie;

  static Color cabecera(BuildContext context) =>
      _oscuro(context) ? ConfiguracionTema.grafito : Colors.white;

  static Color separador(BuildContext context) =>
      _oscuro(context) ? const Color(0xFF2E2D2D) : const Color(0xFFE3E0D8);

  static Color miBurbuja(BuildContext context) =>
      _oscuro(context) ? const Color(0xFF6E7260) : ConfiguracionTema.grafito;

  static Color suBurbuja(BuildContext context) =>
      _oscuro(context) ? const Color(0xFF565454) : ConfiguracionTema.crema;

  static Color suTexto(BuildContext context) =>
      _oscuro(context) ? ConfiguracionTema.crema : ConfiguracionTema.grafito;

  /// El panel de opciones dentro de la burbuja de MacIAs.
  static Color panel(BuildContext context) =>
      _oscuro(context) ? const Color(0x1FFFFFFF) : const Color(0x99FFFFFF);
}

/// El texto de MacIAs: **negritas**, `codigo en linea` y bloques de codigo
/// entre tres acentos graves, como en WhatsApp o cualquier editor.
///
/// Los bloques van en letra monoespaciada (Roboto Mono, incluida en la app)
/// y sin cortar las lineas: un `for` partido en dos ya no se entiende. Si
/// no entran, se desplazan de costado. Y llevan un boton para copiarlos,
/// que es lo primero que se quiere hacer con un ejemplo de codigo.
class TextoMacias extends StatelessWidget {
  const TextoMacias(this.texto, {required this.estilo, super.key});

  final String texto;
  final TextStyle estilo;

  static const fuenteCodigo = 'RobotoMono';

  @override
  Widget build(BuildContext context) {
    final trozos = texto.split('```');
    if (trozos.length == 1) return _prosa(context, texto);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (indice, trozo) in trozos.indexed)
          if (indice.isOdd)
            _BloqueCodigo(codigo: _limpiarBloque(trozo))
          else if (trozo.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: indice == 0 ? 0 : 8,
                bottom: indice == trozos.length - 1 ? 0 : 8,
              ),
              child: _prosa(context, trozo.trim()),
            ),
      ],
    );
  }

  /// Sin la linea del lenguaje ("cpp") ni los saltos de los bordes.
  static String _limpiarBloque(String trozo) {
    var codigo = trozo;
    final primerSalto = codigo.indexOf('\n');
    if (primerSalto >= 0 &&
        RegExp(r'^[a-z+]*$').hasMatch(codigo.substring(0, primerSalto))) {
      codigo = codigo.substring(primerSalto + 1);
    }
    return codigo.replaceFirst(RegExp(r'\s+$'), '');
  }

  Widget _prosa(BuildContext context, String parte) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondoCodigo = oscuro
        ? const Color(0x33FFFFFF)
        : const Color(0x14000000);
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    var negrita = false;
    var codigo = false;

    void cerrarTramo() {
      if (buffer.isEmpty) return;
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: codigo
              ? TextStyle(
                  fontFamily: fuenteCodigo,
                  fontSize: (estilo.fontSize ?? 15) - 1.5,
                  backgroundColor: fondoCodigo,
                )
              : negrita
              ? const TextStyle(fontWeight: FontWeight.w900)
              : null,
        ),
      );
      buffer.clear();
    }

    var i = 0;
    while (i < parte.length) {
      if (!codigo && parte.startsWith('**', i)) {
        cerrarTramo();
        negrita = !negrita;
        i += 2;
      } else if (parte[i] == '`') {
        cerrarTramo();
        codigo = !codigo;
        i++;
      } else {
        buffer.write(parte[i]);
        i++;
      }
    }
    cerrarTramo();
    return Text.rich(TextSpan(style: estilo, children: spans));
  }
}

class _BloqueCodigo extends StatelessWidget {
  const _BloqueCodigo({required this.codigo});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final color = ColoresChatMacias.suTexto(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: oscuro ? const Color(0x40000000) : const Color(0x0F000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              codigo,
              softWrap: false,
              style: TextStyle(
                fontFamily: TextoMacias.fuenteCodigo,
                fontSize: 12.5,
                height: 1.45,
                color: color,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codigo));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              },
              style: TextButton.styleFrom(
                foregroundColor: color.withValues(alpha: .75),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Copiar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que dice MacIAs.
class BurbujaDeMacias extends StatelessWidget {
  const BurbujaDeMacias({
    required this.mensaje,
    required this.primeraDelGrupo,
    required this.ultimaDelGrupo,
    required this.alElegir,
    required this.alAccion,
    super.key,
  });

  final MensajeMacias mensaje;
  final bool primeraDelGrupo;

  /// La foto va junto a la ultima burbuja seguida, donde esta la esquina
  /// recortada: asi se lee de quien es todo el bloque de una vez.
  final bool ultimaDelGrupo;

  final ValueChanged<OpcionMacias> alElegir;
  final ValueChanged<DestinoMacias> alAccion;

  @override
  Widget build(BuildContext context) {
    final color = ColoresChatMacias.suTexto(context);
    return Padding(
      padding: EdgeInsets.only(top: primeraDelGrupo ? 12 : 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 30,
            child: ultimaDelGrupo ? const AvatarMacias(tamano: 30) : null,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
              decoration: BoxDecoration(
                color: ColoresChatMacias.suBurbuja(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(ultimaDelGrupo ? 5 : 18),
                  bottomRight: const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextoMacias(
                    mensaje.texto,
                    estilo: TextStyle(color: color, fontSize: 15, height: 1.38),
                  ),
                  if (mensaje.opciones.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ListaOpcionesMacias(
                      opciones: mensaje.opciones,
                      alElegir: alElegir,
                    ),
                  ],
                  if (mensaje.acciones.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final accion in mensaje.acciones)
                          BotonAccionMacias(
                            accion: accion,
                            alPresionar: alAccion,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      mensaje.horaTexto,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: color.withValues(alpha: .6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Que una burbuja larga no llegue hasta el borde: el hueco del otro
          // lado es lo que deja claro de que lado esta cada quien.
          const SizedBox(width: 30),
        ],
      ),
    );
  }
}

/// Lo que escribe la persona.
class BurbujaPropia extends StatelessWidget {
  const BurbujaPropia({
    required this.mensaje,
    required this.primeraDelGrupo,
    required this.ultimaDelGrupo,
    super.key,
  });

  final MensajeMacias mensaje;
  final bool primeraDelGrupo;
  final bool ultimaDelGrupo;

  @override
  Widget build(BuildContext context) {
    const color = ConfiguracionTema.crema;
    return Padding(
      padding: EdgeInsets.only(top: primeraDelGrupo ? 12 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 56),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
              decoration: BoxDecoration(
                color: ColoresChatMacias.miBurbuja(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: Radius.circular(ultimaDelGrupo ? 5 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mensaje.texto,
                    style: const TextStyle(
                      color: color,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mensaje.horaTexto,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: color.withValues(alpha: .65),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: ConfiguracionTema.interruptorActivo.withValues(
                          alpha: .9,
                        ),
                        semanticLabel: 'Leído',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La lista numerada de una burbuja: se toca o se escribe su numero.
class ListaOpcionesMacias extends StatelessWidget {
  const ListaOpcionesMacias({
    required this.opciones,
    required this.alElegir,
    super.key,
  });

  final List<OpcionMacias> opciones;
  final ValueChanged<OpcionMacias> alElegir;

  @override
  Widget build(BuildContext context) => Material(
    // Material y no DecoratedBox: la onda del toque se pinta en el Material
    // de abajo, y una caja con color encima la tapaba entera. Sin onda, tocar
    // una opcion parecia no hacer nada hasta que llegaba la respuesta.
    color: ColoresChatMacias.panel(context),
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (indice, opcion) in opciones.indexed) ...[
          if (indice > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: 46,
              color: ColoresChatMacias.separador(context),
            ),
          _FilaOpcion(numero: indice + 1, opcion: opcion, alElegir: alElegir),
        ],
      ],
    ),
  );
}

class _FilaOpcion extends StatelessWidget {
  const _FilaOpcion({
    required this.numero,
    required this.opcion,
    required this.alElegir,
  });

  final int numero;
  final OpcionMacias opcion;
  final ValueChanged<OpcionMacias> alElegir;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final color = ColoresChatMacias.suTexto(context);
    return Semantics(
      button: true,
      label: 'Opción $numero: ${opcion.texto}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => alElegir(opcion),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: oscuro
                      ? ConfiguracionTema.crema
                      : ConfiguracionTema.grafito,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: TextStyle(
                    color: oscuro
                        ? ConfiguracionTema.grafito
                        : ConfiguracionTema.crema,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  opcion.texto,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: color.withValues(alpha: .45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un boton que lleva a otra parte de la app: "Abrir mis pedidos".
class BotonAccionMacias extends StatelessWidget {
  const BotonAccionMacias({
    required this.accion,
    required this.alPresionar,
    super.key,
  });

  final AccionMacias accion;
  final ValueChanged<DestinoMacias> alPresionar;

  static IconData iconoDe(DestinoMacias destino) => switch (destino) {
    DestinoMacias.carrito => Icons.shopping_cart_outlined,
    DestinoMacias.pedidos => Icons.receipt_long_outlined,
    DestinoMacias.chats => Icons.forum_outlined,
    DestinoMacias.favoritos => Icons.favorite_border_rounded,
    DestinoMacias.misPublicaciones => Icons.grid_view_rounded,
    DestinoMacias.editarPerfil => Icons.edit_outlined,
    DestinoMacias.privacidad => Icons.lock_outline_rounded,
    DestinoMacias.instalar => Icons.install_mobile_rounded,
    DestinoMacias.acercaDe => Icons.info_outline_rounded,
    DestinoMacias.whatsappSoporte => Icons.chat_rounded,
    DestinoMacias.correoSoporte => Icons.mail_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return FilledButton.icon(
      onPressed: () => alPresionar(accion.destino),
      style: FilledButton.styleFrom(
        backgroundColor: oscuro
            ? ConfiguracionTema.crema
            : ConfiguracionTema.grafito,
        foregroundColor: oscuro
            ? ConfiguracionTema.grafito
            : ConfiguracionTema.crema,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
      icon: Icon(iconoDe(accion.destino), size: 18),
      label: Text(accion.etiqueta),
    );
  }
}

/// Los tres puntos de "escribiendo".
class EscribiendoMacias extends StatefulWidget {
  const EscribiendoMacias({super.key});

  @override
  State<EscribiendoMacias> createState() => _EscribiendoMaciasState();
}

class _EscribiendoMaciasState extends State<EscribiendoMacias>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ola = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ola.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ColoresChatMacias.suTexto(context);
    return Semantics(
      liveRegion: true,
      label: 'MacIAs está escribiendo',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const AvatarMacias(tamano: 30),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: ColoresChatMacias.suBurbuja(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: AnimatedBuilder(
                animation: _ola,
                builder: (_, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var punto = 0; punto < 3; punto++)
                      _punto(color, (_ola.value - punto * .16) % 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cada punto sube y baja en su turno, como una ola.
  Widget _punto(Color color, double fase) {
    final subida = fase < .4 ? math.sin(fase / .4 * math.pi) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Transform.translate(
        offset: Offset(0, -4.5 * subida),
        child: Container(
          width: 7.5,
          height: 7.5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .35 + .5 * subida),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// La entrada de un mensaje nuevo: aparece y sube un poco desde su lado.
///
/// Solo la primera vez. Al desplazarse, la lista vuelve a construir las
/// burbujas que reaparecen, y animarlas de nuevo haria temblar toda la
/// conversacion.
class AparicionMensaje extends StatefulWidget {
  const AparicionMensaje({
    required this.animar,
    required this.desdeLaDerecha,
    required this.child,
    super.key,
  });

  final bool animar;
  final bool desdeLaDerecha;
  final Widget child;

  @override
  State<AparicionMensaje> createState() => _AparicionMensajeState();
}

class _AparicionMensajeState extends State<AparicionMensaje>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.animar ? 0 : 1,
  );
  late final Animation<double> _curva = CurvedAnimation(
    parent: _entrada,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animar) _entrada.forward();
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curva,
    child: widget.child,
    // La misma estructura antes, durante y despues: si al terminar se
    // devolviera la burbuja sola, Flutter la desmontaria y la volveria a
    // montar. En 1, la opacidad y las transformaciones no cuestan nada.
    builder: (_, hijo) {
      final t = _curva.value;
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: Transform.scale(
            scale: .94 + .06 * t,
            alignment: widget.desdeLaDerecha
                ? Alignment.bottomRight
                : Alignment.bottomLeft,
            child: hijo,
          ),
        ),
      );
    },
  );
}
