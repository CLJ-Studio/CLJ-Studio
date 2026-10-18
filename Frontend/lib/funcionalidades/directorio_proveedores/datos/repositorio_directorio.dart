import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../modelos/proveedor_upsa.dart';
import '../modelos/solicitud_egresado.dart';

/// Lo que ve la UPSA, y lo que cada emprendimiento elige mostrarle.
///
/// Quien ve el directorio lo decide el servidor: puedo_ver_directorio() y
/// directorio_proveedores() revisan la cuenta. La app solo esconde la
/// entrada a quien igual no podria abrirlo.
class RepositorioDirectorio {
  const RepositorioDirectorio();

  SupabaseClient get _cliente => Supabase.instance.client;

  /// Personal de la UPSA o admin. Mientras la migracion de las cuentas UPSA
  /// no este aplicada la funcion no existe, y la respuesta es no.
  Future<bool> puedoVerDirectorio() async {
    try {
      return await _cliente.rpc('puedo_ver_directorio') == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ProveedorUpsa>> cargar() async {
    final filas = await _cliente.rpc('directorio_proveedores') as List<dynamic>;
    return filas
        .cast<Map<String, dynamic>>()
        .map(ProveedorUpsa.desdeMapa)
        .toList(growable: false);
  }

  /// Quienes pidieron la marca de egresado y esperan que un admin los
  /// verifique. Solo para admins: el servidor rechaza a cualquier otro.
  Future<List<SolicitudEgresado>> solicitudesEgresado() async {
    final filas = await _cliente.rpc('solicitudes_egresado') as List<dynamic>;
    return filas
        .cast<Map<String, dynamic>>()
        .map(SolicitudEgresado.desdeMapa)
        .toList(growable: false);
  }

  /// Los egresados ya verificados, para poder quitarle la marca a alguien.
  Future<List<SolicitudEgresado>> egresadosVerificados() async {
    final filas = await _cliente.rpc('egresados_verificados') as List<dynamic>;
    return filas
        .cast<Map<String, dynamic>>()
        .map(SolicitudEgresado.desdeMapa)
        .toList(growable: false);
  }

  Future<void> resolverEgresado(
    String usuarioId, {
    required bool aprobar,
  }) async {
    await _cliente.rpc(
      'resolver_egresado',
      params: {'p_usuario': usuarioId, 'p_aprobar': aprobar},
    );
    // Un admin que se resuelve a si mismo lo ve al instante, sin esperar el
    // aviso que le llega por la red.
    if (usuarioId == _cliente.auth.currentUser?.id) {
      await SesionUsuario.instancia.cargar(forzar: true);
    }
  }

  /// El negocio propio y lo que le ofrece a la UPSA. Null si no hay negocio,
  /// o si la migracion todavia no agrego las columnas: entonces la opcion
  /// no se muestra.
  Future<OfertaUpsa?> cargarOfertaPropia() async {
    final fila = await _cliente
        .from('stores')
        .select()
        .eq('owner_id', _cliente.auth.currentUser!.id)
        .eq('is_personal', false)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (fila == null || !fila.containsKey('ofrece_a_upsa')) return null;

    return OfertaUpsa(
      localId: fila['id'] as String,
      activa: (fila['ofrece_a_upsa'] as bool?) ?? false,
      texto: (fila['oferta_upsa'] as String?) ?? '',
    );
  }

  /// La RLS de `stores` solo deja escribir en el local propio, y el texto
  /// pasa por el mismo filtro de contenido que el nombre del local.
  Future<void> guardarOfertaPropia(OfertaUpsa oferta) async {
    final texto = oferta.texto.trim();
    await _cliente
        .from('stores')
        .update({
          'ofrece_a_upsa': oferta.activa,
          'oferta_upsa': texto.isEmpty ? null : texto,
        })
        .eq('id', oferta.localId);
  }
}
