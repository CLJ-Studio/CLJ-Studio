import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/tiempo_real/escucha_tabla.dart';
import 'mesa_poker.dart';

/// Lo que la mesa de poker le pide al servidor. El servidor es el arbitro:
/// baraja, reparte, valida cada jugada y paga; aqui solo se pide y se mira.
abstract class RepositorioPoker {
  Future<List<SalaPoker>> salas();

  /// Crea la mesa y se sienta con [fichas] de la billetera (sin indicarlo,
  /// las que sugiere la mesa).
  Future<String> crearSala(String nombre, int ciegaGrande, {int? fichas});
  Future<void> sentarse(String sala, {int? fichas});

  /// Al levantarse, las fichas de la mesa vuelven a la billetera.
  Future<void> levantarse(String sala);
  Future<EstadoMesaPoker> estado(String sala);

  /// Reparte si se puede (lo piden todos; reparte uno solo).
  Future<bool> empezarMano(String sala);

  /// retirarse, pasar, igualar, subir (a [monto]) o todo. Devuelve como
  /// quedo la mesa, o null si el servidor no lo dijo.
  Future<EstadoMesaPoker?> jugar(String sala, String accion, {int monto = 0});

  /// Pasa o retira a quien dejo vencer su turno.
  Future<bool> vencerTurno(String sala);
  Future<void> volver(String sala);

  /// Sin fichas en la mesa: compra de nuevo, de la billetera.
  Future<void> recargar(String sala, {int? fichas});

  /// Avisa cuando cambia algo en la mesa. Devuelve con que dejar de escuchar.
  VoidCallback escucharMesa(String sala, VoidCallback alCambiar);
  VoidCallback escucharSalas(VoidCallback alCambiar);
}

class RepositorioPokerSupabase implements RepositorioPoker {
  const RepositorioPokerSupabase();

  SupabaseClient get _cliente => Supabase.instance.client;

  @override
  Future<List<SalaPoker>> salas() async {
    final filas = await _cliente.rpc('poker_salas_abiertas') as List<dynamic>;
    return [
      for (final fila in filas)
        SalaPoker.desdeMapa((fila as Map).cast<String, dynamic>()),
    ];
  }

  @override
  Future<String> crearSala(
    String nombre,
    int ciegaGrande, {
    int? fichas,
  }) async =>
      await _cliente.rpc(
            'poker_crear_sala',
            params: {
              'p_nombre': nombre,
              'p_ciega_grande': ciegaGrande,
              'p_fichas': fichas,
            },
          )
          as String;

  @override
  Future<void> sentarse(String sala, {int? fichas}) => _cliente.rpc(
    'poker_sentarse',
    params: {'p_sala': sala, 'p_fichas': fichas},
  );

  @override
  Future<void> levantarse(String sala) =>
      _cliente.rpc('poker_levantarse', params: {'p_sala': sala});

  @override
  Future<EstadoMesaPoker> estado(String sala) async {
    final datos = await _cliente.rpc('poker_estado', params: {'p_sala': sala});
    return EstadoMesaPoker.desdeMapa((datos as Map).cast<String, dynamic>());
  }

  @override
  Future<bool> empezarMano(String sala) async =>
      await _cliente.rpc('poker_empezar_mano', params: {'p_sala': sala}) ==
      true;

  @override
  Future<EstadoMesaPoker?> jugar(
    String sala,
    String accion, {
    int monto = 0,
  }) async {
    final datos = await _cliente.rpc(
      'poker_jugar',
      params: {'p_sala': sala, 'p_accion': accion, 'p_monto': monto},
    );
    return datos is Map
        ? EstadoMesaPoker.desdeMapa(datos.cast<String, dynamic>())
        : null;
  }

  @override
  Future<bool> vencerTurno(String sala) async =>
      await _cliente.rpc('poker_vencer_turno', params: {'p_sala': sala}) ==
      true;

  @override
  Future<void> volver(String sala) =>
      _cliente.rpc('poker_volver', params: {'p_sala': sala});

  @override
  Future<void> recargar(String sala, {int? fichas}) => _cliente.rpc(
    'poker_recargar',
    params: {'p_sala': sala, 'p_fichas': fichas},
  );

  @override
  VoidCallback escucharMesa(String sala, VoidCallback alCambiar) {
    // Cada cambio de la mesa sube la version de su fila en poker_salas: un
    // solo aviso por jugada, en un canal propio de esta mesa. Antes eran dos
    // tablas con varios avisos por jugada cada una. El respaldo corto cubre
    // un canal caido: sin el, la mesa se quedaba esperando un aviso que no
    // llegaba.
    final escucha = EscuchaTabla(
      tabla: 'poker_salas',
      canal: 'poker_mesa_$sala',
      filtro: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: sala,
      ),
      alCambiar: alCambiar,
      respaldo: const Duration(seconds: 2),
      respaldoConCanalVivo: const Duration(seconds: 15),
      minimoEntreAvisos: const Duration(milliseconds: 60),
    )..iniciar();
    return escucha.detener;
  }

  @override
  VoidCallback escucharSalas(VoidCallback alCambiar) {
    // Cada jugada en cualquier mesa toca poker_salas: la lista se pone al
    // dia como mucho una vez por segundo.
    final escuchas = [
      EscuchaTabla(
        tabla: 'poker_salas',
        alCambiar: alCambiar,
        minimoEntreAvisos: const Duration(seconds: 1),
      ),
      EscuchaTabla(
        tabla: 'poker_asientos',
        alCambiar: alCambiar,
        minimoEntreAvisos: const Duration(seconds: 1),
      ),
    ];
    for (final escucha in escuchas) {
      escucha.iniciar();
    }
    return () {
      for (final escucha in escuchas) {
        escucha.detener();
      }
    };
  }
}

/// El error del servidor, dicho para personas.
String mensajePoker(Object error) {
  final texto = error.toString();
  final minimo = RegExp(r'SUBIDA_CORTA: el minimo es (\d+)').firstMatch(texto);
  if (minimo != null) return 'La subida mínima es a ${minimo.group(1)}.';
  return switch (texto) {
    _
        when texto.contains('PGRST202') ||
            texto.contains('poker_') && texto.contains('does not exist') =>
      'El póker todavía no está listo en el servidor.',
    _ when texto.contains('MESA_LLENA') => 'La mesa está llena.',
    _ when texto.contains('FICHAS_INSUFICIENTES') =>
      'No te alcanzan las fichas del casino para esta mesa.',
    _ when texto.contains('COMPRA_INVALIDA') =>
      'En esta mesa te sientas con entre 20 y 100 ciegas grandes.',
    _ when texto.contains('NO_ESTAS_SENTADO') => 'Ya no estás en esa mesa.',
    _ when texto.contains('PERFIL_INCOMPLETO') =>
      'Completa tu perfil antes de sentarte.',
    _ when texto.contains('SALA_INEXISTENTE') => 'Esa mesa ya no existe.',
    _ when texto.contains('NO_ES_TU_TURNO') => 'Todavía no es tu turno.',
    _ when texto.contains('NO_PUEDES_PASAR') =>
      'No puedes pasar: hay una apuesta.',
    _ when texto.contains('EN_UNA_MANO') =>
      'Espera a que termine la mano para recargar.',
    _ when texto.contains('CONTENIDO_NO_PERMITIDO') =>
      'Ese nombre no se puede usar.',
    _ when texto.contains('NOMBRE_INVALIDO') =>
      'El nombre de la mesa va de 3 a 30 letras.',
    _ when texto.contains('SIN_MANO') => 'Esa mano ya terminó.',
    _ => 'No se pudo. Revisa tu conexión e intenta de nuevo.',
  };
}
