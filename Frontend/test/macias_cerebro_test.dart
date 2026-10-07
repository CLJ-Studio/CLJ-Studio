import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/cerebro_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/conocimiento_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/logica/memoria_macias.dart';
import 'package:upsa_eat/funcionalidades/asistente_macias/modelos/mensaje_macias.dart';

/// Las preguntas que ya muestra la pantalla de Ayuda. MacIAs las entiende si
/// alguien se las escribe, pero sus menus tienen que ofrecer OTRAS: es lo
/// que se pidio, y repetirlas en la misma pantalla seria relleno.
const _preguntasDeAyuda = [
  '¿Necesito abrir un local para vender?',
  '¿Cómo se paga?',
  '¿Quién ve mi número de WhatsApp?',
  'Mi publicación quedó muy abajo, ¿qué hago?',
  '¿Puedo ocultar algo sin borrarlo?',
  'No me llegan las notificaciones',
  'Alguien publicó algo ofensivo',
  '¿Cómo cancelo un pedido?',
];

/// Emojis y simbolos de ese estilo: se pidio sacarlos porque hacian ver el
/// chat "generado". Los signos tipograficos (•, √, ±, ∫, ⋮) no cuentan.
final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{20E3}]',
  unicode: true,
);

ContextoMacias _contexto({int hora = 15, MemoriaMacias? memoria}) =>
    ContextoMacias(
      nombre: 'Juan',
      ahora: DateTime(2026, 10, 7, hora, 30),
      version: '7.10.1530 beta',
      memoria: memoria,
    );

CerebroMacias _cerebro({int hora = 15, MemoriaMacias? memoria}) =>
    CerebroMacias(
      contexto: () => _contexto(hora: hora),
      memoria: memoria,
      azar: Random(7),
    );

String _todo(RespuestaMacias respuesta) =>
    respuesta.burbujas.map((burbuja) => burbuja.texto).join('\n');

void main() {
  group('lo que sabe MacIAs no tiene huecos', () {
    test('cada seccion apunta a cosas que existen', () {
      for (final seccion in ConocimientoMacias.secciones) {
        expect(seccion.temas, isNotEmpty, reason: seccion.id);
        for (final entrada in seccion.temas) {
          if (entrada == ConocimientoMacias.ordenMeme) continue;
          if (entrada.startsWith('s:')) {
            expect(
              ConocimientoMacias.seccion(entrada.substring(2)),
              isNotNull,
              reason: '${seccion.id} -> $entrada',
            );
            continue;
          }
          final tema = ConocimientoMacias.tema(entrada);
          expect(tema, isNotNull, reason: '${seccion.id} -> $entrada');
          expect(tema!.enMenu, isTrue, reason: '${seccion.id} -> $entrada');
        }
        if (seccion.padre != null) {
          expect(ConocimientoMacias.seccion(seccion.padre!), isNotNull);
        }
      }
    });

    test('cada tema relacionado existe y se puede ofrecer', () {
      for (final tema in ConocimientoMacias.temas) {
        for (final id in tema.relacionados) {
          final relacionado = ConocimientoMacias.tema(id);
          expect(relacionado, isNotNull, reason: '${tema.id} -> $id');
          expect(relacionado!.enMenu, isTrue, reason: '${tema.id} -> $id');
        }
      }
    });

    test('todo tema de menu esta en una sola seccion', () {
      for (final tema in ConocimientoMacias.temas.where((t) => t.enMenu)) {
        if (tema.id == ConocimientoMacias.humano) continue;
        final secciones = ConocimientoMacias.secciones.where(
          (seccion) => seccion.temas.contains(tema.id),
        );
        expect(secciones, hasLength(1), reason: tema.id);
      }
    });

    test('las claves ya estan escritas como las compara el cerebro', () {
      final todas = [
        for (final tema in ConocimientoMacias.temas)
          for (final clave in tema.claves) (tema.id, clave),
        for (final seccion in ConocimientoMacias.secciones)
          for (final clave in seccion.claves) (seccion.id, clave),
      ];
      for (final (duenio, clave) in todas) {
        final sinComodin = clave.replaceAll('*', '');
        expect(
          CerebroMacias.normalizar(sinComodin),
          sinComodin,
          reason: '$duenio: "$clave" tiene tildes, mayusculas o signos',
        );
      }
    });

    test('ningun menu repite las preguntas de Ayuda', () {
      final deAyuda = _preguntasDeAyuda.map(CerebroMacias.normalizar).toSet();
      for (final tema in ConocimientoMacias.temas.where((t) => t.enMenu)) {
        expect(
          deAyuda,
          isNot(contains(CerebroMacias.normalizar(tema.pregunta))),
        );
      }
    });

    test('todas las respuestas se arman bien, de dia y de noche', () {
      for (final hora in [9, 15, 23]) {
        final c = _contexto(hora: hora);
        for (final tema in ConocimientoMacias.temas) {
          for (final texto in [
            tema.respuesta(c),
            if (tema.ampliacion != null) tema.ampliacion!(c),
          ]) {
            expect(texto.trim(), isNotEmpty, reason: tema.id);
            expect(texto, isNot(matches(RegExp(r'\bnull\b'))), reason: tema.id);
            // Una negrita o un bloque de codigo sin cerrar se veria roto.
            final sinBloques = texto
                .split('```')
                .indexed
                .where((p) => p.$1.isEven)
                .map((p) => p.$2)
                .join();
            expect(
              '**'.allMatches(sinBloques).length.isEven,
              isTrue,
              reason: '${tema.id}: negrita sin cerrar',
            );
            expect(
              '```'.allMatches(texto).length.isEven,
              isTrue,
              reason: '${tema.id}: bloque de codigo sin cerrar',
            );
          }
        }
      }
    });

    test('ni una respuesta, menu o titulo tiene emojis', () {
      final c = _contexto();
      final textos = [
        for (final tema in ConocimientoMacias.temas) ...[
          tema.pregunta,
          tema.respuesta(c),
          if (tema.ampliacion != null) tema.ampliacion!(c),
          for (final accion in tema.acciones) accion.etiqueta,
        ],
        for (final seccion in ConocimientoMacias.secciones) ...[
          seccion.titulo,
          seccion.intro,
        ],
      ];
      for (final texto in textos) {
        expect(_emoji.hasMatch(texto), isFalse, reason: texto);
      }
    });

    test(
      'el menu principal tiene doce opciones y la ultima es una persona',
      () {
        final menu = ConocimientoMacias.menuPrincipal;
        expect(menu, hasLength(12));
        expect(menu[10].id, 's:extra');
        expect(menu.last.id, 't:${ConocimientoMacias.humano}');
      },
    );
  });

  group('la conversacion', () {
    test('saluda por el nombre y segun la hora', () {
      final manana = _cerebro(hora: 9).bienvenida();
      expect(_todo(manana), contains('¡Buenos días, Juan!'));
      expect(manana.burbujas.last.opciones, hasLength(12));
      expect(_todo(_cerebro(hora: 21).bienvenida()), contains('Buenas noches'));
    });

    test('un numero elige de la ultima lista que se mostro', () {
      final cerebro = _cerebro()..bienvenida();
      expect(_todo(cerebro.escribir('3')), contains('Sobre publicar'));
      // Ahora el 1 es el primer tema de esa seccion, no del menu principal.
      expect(cerebro.escribir('1').temaId, 'como_publicar');
    });

    test('el 12 del menu principal lleva a una persona', () {
      final cerebro = _cerebro()..bienvenida();
      final respuesta = cerebro.escribir('12');
      expect(respuesta.temaId, ConocimientoMacias.humano);
      final destinos = respuesta.burbujas.first.acciones.map((a) => a.destino);
      expect(destinos, contains(DestinoMacias.whatsappSoporte));
      expect(destinos, contains(DestinoMacias.correoSoporte));
    });

    test('las materias tienen sus propios menus, y se puede volver', () {
      final cerebro = _cerebro()..bienvenida();
      expect(_todo(cerebro.escribir('11')), contains('te ayudo a estudiar'));
      expect(_todo(cerebro.escribir('1')), contains('Álgebra'));
      final opciones = cerebro.opcionesVigentes.map((o) => o.id);
      expect(opciones, contains('s:extra'), reason: 'volver un nivel');
      expect(opciones.last, 'o:menu');
    });

    test('un numero que no esta en la lista se explica', () {
      final cerebro = _cerebro()..bienvenida();
      expect(_todo(cerebro.escribir('20')), contains('No tengo la opción 20'));
    });

    test('volver lleva a la seccion de la que se venia', () {
      final cerebro = _cerebro()..bienvenida();
      cerebro
        ..escribir('2')
        ..escribir('2');
      expect(_todo(cerebro.escribir('volver')), contains('pedidos'));
    });

    test('despues de responder ofrece temas parecidos, volver y el menu', () {
      final cerebro = _cerebro()..bienvenida();
      final respuesta = cerebro.escribir('¿cómo pongo sabores?');
      final opciones = respuesta.burbujas.last.opciones.map((o) => o.id);
      expect(opciones, contains('t:como_publicar'));
      expect(opciones, contains('o:volver'));
      expect(opciones.last, 'o:menu');
    });

    test('si no entiende, contesta corto, sin repetir el menu entero', () {
      final cerebro = _cerebro()..bienvenida();
      final primera = cerebro.escribir('zxqw plorf');
      expect(primera.burbujas.single.opciones, isEmpty);
      expect(_todo(primera), contains('menú'));

      final segunda = cerebro.escribir('blorf zxqw');
      expect(
        segunda.burbujas.last.opciones.first.id,
        't:${ConocimientoMacias.humano}',
      );
    });

    test('un saludo con pregunta contesta la pregunta y saluda', () {
      final respuesta = _cerebro().escribir(
        'Hola buenas tardes, ¿cómo publico?',
      );
      expect(respuesta.temaId, 'como_publicar');
      expect(respuesta.burbujas.first.texto, startsWith('¡Hola, Juan!'));
    });

    test('las cortesias tienen su respuesta', () {
      expect(
        _todo(_cerebro().escribir('muchas gracias!')),
        anyOf(contains('De nada'), contains('Para eso'), contains('gusto')),
      );
      expect(_todo(_cerebro().escribir('chau')), contains('Juan'));
      expect(_todo(_cerebro().escribir('ok')), contains('Perfecto'));
      expect(_todo(_cerebro().escribir('eres un tonto')), contains('Ouch'));
      expect(
        _todo(_cerebro().escribir('👍')),
        anyOf(contains('ayudado'), contains('Para eso estoy')),
      );
    });

    test('si dos temas encajan igual, pregunta cual', () {
      final respuesta = _cerebro().escribir('como instalo la app');
      final ids = respuesta.burbujas.single.opciones.map((o) => o.id);
      expect(ids, containsAll(['t:instalar_iphone', 't:instalar_android']));
    });

    test('lo que esta en Ayuda se entiende aunque no se ofrezca', () {
      expect(_cerebro().escribir('como pago?').temaId, 'faq_pago');
      expect(_cerebro().escribir('quiero cancelar').temaId, 'faq_cancelar');
    });

    test('"otro ejemplo" da otro sobre el mismo tema', () {
      final cerebro = _cerebro();
      cerebro.escribir('productos notables');
      final otro = cerebro.escribir('otro ejemplo');
      expect(otro.temaId, 'a_productos_notables');
      expect(_todo(otro), contains('(3a − 5b)²'));
      expect(
        cerebro.elegir(CerebroMacias.chipOtroEjemplo).temaId,
        'a_productos_notables',
      );
    });

    test('el tema anterior da contexto a la siguiente pregunta', () {
      final cerebro = _cerebro();
      cerebro.escribir('que es un puntero en c++');
      expect(cerebro.escribir('y los vectores?').temaId, 'p_arreglos');
    });
  });

  group('cuentas y ecuaciones dentro de la conversacion', () {
    test('calcula y resuelve sin salir del chat', () {
      expect(_todo(_cerebro().escribir('2+2')), contains('**4**'));
      expect(
        _todo(_cerebro().escribir('resuelve x^2 - 5x + 6 = 0')),
        contains('x₁ = 3, x₂ = 2'),
      );
    });

    test('un numero solo sigue siendo una opcion, no una cuenta', () {
      final cerebro = _cerebro()..bienvenida();
      expect(_todo(cerebro.escribir('3')), contains('Sobre publicar'));
    });

    test('"calcula" sin cuenta explica como usar la calculadora', () {
      expect(_cerebro().escribir('calcula').temaId, 'calculadora');
    });
  });

  group('memoria', () {
    test('recuerda como quiere que le digan, y lo usa', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(
        _todo(cerebro.escribir('me llamo Juan Diego')),
        contains('Juan Diego'),
      );
      expect(memoria.nombre, 'Juan Diego');
      expect(_todo(cerebro.escribir('como me llamo?')), contains('Juan Diego'));
      expect(_todo(cerebro.escribir('chau')), contains('Juan Diego'));
    });

    test('reconoce la carrera aunque la escriban corta', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(_todo(cerebro.escribir('estudio sistemas')), contains('Sistemas'));
      expect(memoria.carrera, 'Ingeniería de Sistemas');
      expect(_todo(cerebro.escribir('que estudio?')), contains('Sistemas'));
      // "estoy en la cafetería" no es una carrera.
      cerebro.escribir('estoy en la cafeteria');
      expect(memoria.carrera, 'Ingeniería de Sistemas');
    });

    test('pregunta si te gusta algo, y se acuerda de lo que contestas', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      final pregunta = cerebro.escribir('¿Te gusta la hamburguesa?');
      expect(_todo(pregunta), contains('hamburguesa'));
      expect(_todo(pregunta), contains('¿A ti te gusta?'));

      expect(_todo(cerebro.escribir('sí')), contains('Anotado'));
      expect(memoria.gustos, contains('hamburguesa'));
      expect(_todo(cerebro.escribir('que me gusta')), contains('hamburguesa'));
    });

    test('anota lo que no te gusta', () {
      final memoria = MemoriaMacias();
      _cerebro(memoria: memoria).escribir('odio el surazo');
      expect(memoria.disgustos, contains('surazo'));
    });

    test('olvida cuando se le pide', () {
      final memoria = MemoriaMacias(nombre: 'Ana', carrera: 'Derecho');
      final cerebro = _cerebro(memoria: memoria);
      expect(
        _todo(cerebro.escribir('olvida lo que sabes de mi')),
        contains('olvidé'),
      );
      expect(memoria.vacia, isTrue);
    });

    test('"¿qué sabes de mí?" cuenta lo que sabe', () {
      final memoria = MemoriaMacias(
        nombre: 'Ana',
        carrera: 'Derecho',
        gustos: ['pizza'],
      );
      final texto = _todo(
        _cerebro(memoria: memoria).escribir('que sabes de mi'),
      );
      expect(
        texto,
        allOf(contains('Ana'), contains('Derecho'), contains('pizza')),
      );
    });

    test('no acepta una groseria como nombre', () {
      final memoria = MemoriaMacias();
      _cerebro(memoria: memoria).escribir('me llamo idiota');
      expect(memoria.nombre, isNull);
    });
  });

  group('charla', () {
    test('contesta lo que no es de la app en vez de "no me la sé"', () {
      for (final mensaje in [
        'que hora es',
        'que dia es hoy',
        'cuantos años tienes',
        'tienes novia?',
        'cual es tu comida favorita',
        'que prefieres pizza o salteña',
        'tengo examen mañana',
        'tengo hambre',
      ]) {
        final texto = _todo(_cerebro().escribir(mensaje));
        expect(texto, isNot(contains('todavía')), reason: mensaje);
        expect(
          texto,
          isNot(contains('No tengo una respuesta')),
          reason: mensaje,
        );
      }
    });

    test('ante una crisis responde con cuidado y con a quien llamar', () {
      final memoria = MemoriaMacias(modoMeme: true);
      final texto = _todo(
        _cerebro(memoria: memoria).escribir('me quiero morir'),
      );
      expect(texto, contains('110'));
      expect(texto, contains('118'));
      // Sin bromas, aunque el modo meme este prendido.
      expect(texto, isNot(contains('Baldor')));
    });

    test('ninguna respuesta de charla trae emojis', () {
      final cerebro = _cerebro();
      for (final mensaje in [
        'hola',
        'te gusta la pizza',
        'que opinas del futbol',
        'estoy triste',
        'zxqw',
        'gracias',
        'chau',
        'como estas',
        'que hora es',
      ]) {
        expect(
          _emoji.hasMatch(_todo(cerebro.escribir(mensaje))),
          isFalse,
          reason: mensaje,
        );
      }
    });
  });

  group('modo meme', () {
    test('se prende y se apaga, y queda en la memoria', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria);
      expect(_todo(cerebro.escribir('modo meme')), contains('activado'));
      expect(memoria.modoMeme, isTrue);
      expect(_todo(cerebro.escribir('modo serio')), contains('desactivado'));
      expect(memoria.modoMeme, isFalse);
    });

    test('las respuestas siguen siendo las mismas, con una broma', () {
      final memoria = MemoriaMacias(modoMeme: true);
      final respuesta = _cerebro(
        memoria: memoria,
      ).escribir('productos notables');
      expect(respuesta.temaId, 'a_productos_notables');
      expect(respuesta.burbujas.first.texto, contains('(a + b)²'));
      expect(respuesta.burbujas.last.texto.split('\n').first, isNotEmpty);
    });

    test('la opcion del menu dice si prende o apaga', () {
      final memoria = MemoriaMacias();
      final cerebro = _cerebro(memoria: memoria)..bienvenida();
      cerebro.escribir('11');
      final meme = cerebro.opcionesVigentes.firstWhere(
        (o) => o.id == ConocimientoMacias.ordenMeme,
      );
      expect(meme.texto, 'Activar el modo meme');
      cerebro.elegir(meme);
      expect(memoria.modoMeme, isTrue);
    });
  });

  group('entiende como escribe la gente', () {
    // Pregunta -> tema que tiene que responder. Escritas como llegan a un
    // chat: sin tildes, con faltas, con o sin signos.
    const casos = {
      // La app
      'como hago un pedido': 'como_comprar',
      '¿Cómo compro algo?': 'como_comprar',
      'quiero comprar una empanada': 'como_comprar',
      'puedo pedir a dos locales a la vez': 'varios_locales',
      'el vendedor no responde': 'no_responde_vendedor',
      'el vendedor no me contesta en el chat': 'chat_sin_respuesta',
      'como busco algo': 'buscar',
      'puedo repetir un pedido': 'repetir_pedido',
      'para que sirve el corazon': 'favoritos',
      'donde veo mis pedidos': 'donde_pedidos',
      'que significa falta confirmar': 'estados',
      'como confirmo la entrega': 'confirmar_entrega',
      'como marco como entregado': 'confirmar_entrega',
      'como hablo con el vendedor': 'chat_vendedor',
      'como publico algo': 'como_publicar',
      'quiero vender': 'como_publicar',
      'mi producto tiene distintos tamaños': 'sabores',
      'que fotos subo': 'fotos',
      'que es el stock': 'stock',
      'como edito mi publicacion': 'editar_publicacion',
      'cuantas publicaciones puedo hacer': 'limite_publicaciones',
      'no me deja publicar': 'limite_publicaciones',
      'deje una publicacion a medias': 'borrador',
      'que gano con un local': 'que_es_local',
      'como abro mi local': 'crear_local',
      'como cambio mi ubicacion': 'ubicacion_local',
      'me llego un pedido como lo acepto': 'aceptar_pedidos',
      'cuanto vendi este mes': 'ventas',
      'quiero eliminar mi local': 'eliminar_local',
      'tips para vender mas': 'tips_vender',
      'como salgo en populares': 'ranking',
      'que son las visitas': 'visitas',
      'que puedo vender': 'ideas_vender',
      'donde me encuentro con el vendedor': 'punto_encuentro',
      'que zonas hay': 'zonas',
      'donde queda el local': 'donde_local',
      'como entro a la app': 'como_entrar',
      'como ingreso': 'como_entrar',
      'no me llega el codigo': 'como_entrar',
      'como cambio mi foto': 'editar_perfil',
      'quiero borrar mi cuenta': 'borrar_cuenta',
      'como cierro sesion': 'cerrar_sesion',
      'que datos guardan de mi': 'que_datos',
      'que ve la gente de mi perfil': 'perfil_publico',
      'se guardan mis chats': 'chats_guardados',
      'es seguro?': 'seguridad_encuentro',
      'como instalo en iphone': 'instalar_iphone',
      'como la instalo en android': 'instalar_android',
      'que notificaciones me llegan': 'notificaciones_avisos',
      'no me llegan las notis': 'faq_no_llegan',
      'que version tengo': 'version',
      'que no se puede publicar': 'reglas_publicar',
      'cobran comision?': 'comision',
      'es de la universidad?': 'oficial',
      'quien eres': 'quien_eres',
      'cuentame un chiste': 'chiste',
      'dime un dato curioso': 'dato_curioso',
      'quiero hablar con una persona': ConocimientoMacias.humano,
      'quien ve mi numero': 'faq_whatsapp',
      'mi publicacion quedo muy abajo': 'faq_relanzar',
      'alguien publico algo ofensivo': 'faq_reportar',
      // Algebra
      'como factorizo': 'a_factorizacion',
      'casos de factorizacion': 'a_factorizacion',
      'diferencia de cuadrados': 'a_diferencia_cuadrados',
      'trinomio cuadrado perfecto': 'a_trinomio_cuadrado',
      'formula general': 'a_cuadratica',
      'ecuaciones de segundo grado': 'a_cuadratica',
      'como despejo una ecuacion': 'a_ecuaciones_lineales',
      'sistema de ecuaciones': 'a_sistemas',
      'leyes de los exponentes': 'a_exponentes',
      'propiedades de logaritmos': 'a_logaritmos',
      'progresion geometrica': 'a_progresiones',
      'triangulo de pascal': 'a_binomio_newton',
      // Calculo
      'que es una integral': 'c_integral',
      'tabla de integrales': 'c_inmediatas',
      'integracion por partes': 'c_partes',
      'cambio de variable': 'c_sustitucion',
      'fracciones parciales': 'c_fracciones_parciales',
      'integral definida': 'c_definida',
      'area entre curvas': 'c_area',
      'volumen de revolucion': 'c_volumen',
      'integrales impropias': 'c_impropias',
      // C++
      'hola mundo en c++': 'p_hola',
      'como compilo': 'p_hola',
      'que es un puntero': 'p_punteros',
      'como hago un for': 'p_bucles',
      'como leo datos con cin': 'p_entrada_salida',
      'que es una clase': 'p_clases',
      'herencia y polimorfismo': 'p_herencia',
      'segmentation fault': 'p_errores',
      'como ordenar un vector': 'p_stl',
      'leer un archivo': 'p_archivos',
      // Con faltas y abreviaturas
      'pulbicar algo': 'como_publicar',
      'q pasa si no responde el vendedor': 'no_responde_vendedor',
      'MacIAs, ¿cómo pongo sabores?': 'sabores',
    };

    for (final MapEntry(key: pregunta, value: esperado) in casos.entries) {
      test('"$pregunta" → $esperado', () {
        final respuesta = _cerebro().escribir(pregunta);
        expect(
          respuesta.temaId,
          esperado,
          reason: 'respondio: ${_todo(respuesta)}',
        );
      });
    }

    test('una palabra que nombra una seccion abre la seccion', () {
      expect(_todo(_cerebro().escribir('pedidos')), contains('tus pedidos'));
      expect(_todo(_cerebro().escribir('Mi cuenta')), contains('tu cuenta'));
      expect(_todo(_cerebro().escribir('algebra')), contains('Álgebra'));
      expect(_todo(_cerebro().escribir('C++')), contains('C++'));
    });
  });
}
