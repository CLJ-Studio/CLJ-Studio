import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/usuario_upsa.dart';

/// Lee el perfil real del usuario autenticado.
class RepositorioConfiguracion {
  /// Guarda que parte del perfil ve el resto. Solo el dueno puede: la RLS de
  /// `profiles` no deja escribir en otra fila.
  Future<void> guardarPrivacidad({
    required bool muestraVistas,
    required bool muestraFavoritos,
  }) async {
    final cliente = Supabase.instance.client;
    await cliente
        .from('profiles')
        .update({
          'show_view_count': muestraVistas,
          'show_favorites': muestraFavoritos,
        })
        .eq('id', cliente.auth.currentUser!.id);
  }

  const RepositorioConfiguracion();

  /// Pide la marca de egresado. Queda en revision hasta que un admin la
  /// apruebe: la app no puede escribir `es_egresado`.
  Future<void> solicitarEgresado() =>
      Supabase.instance.client.rpc('solicitar_egresado');

  Future<UsuarioUpsa> cargarPerfil() async {
    final cliente = Supabase.instance.client;
    final id = cliente.auth.currentUser!.id;

    // La RLS ya limita la consulta a la fila propia; el filtro por id
    // solo evita traer nada de mas si eso cambiara.
    // Todas las columnas y no una lista: asi el tipo de cuenta y el de
    // egresado llegan cuando existen, y si la migracion de las cuentas UPSA
    // no esta aplicada el perfil carga igual. Pedir una columna que no
    // existe tumba la consulta entera.
    final fila = await cliente
        .from('profiles')
        .select('*, careers(name)')
        .eq('id', id)
        .single();

    return UsuarioUpsa.desdeMapa(fila);
  }
}
