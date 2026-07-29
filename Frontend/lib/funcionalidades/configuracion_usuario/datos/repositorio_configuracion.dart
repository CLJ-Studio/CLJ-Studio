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

  Future<UsuarioUpsa> cargarPerfil() async {
    final cliente = Supabase.instance.client;
    final id = cliente.auth.currentUser!.id;

    // La RLS ya limita la consulta a la fila propia; el filtro por id
    // solo evita traer nada de mas si eso cambiara.
    final fila = await cliente
        .from('profiles')
        .select(
          'full_name, student_code, email, avatar_emoji, whatsapp, '
          'is_on_campus, avatar_path, show_view_count, show_favorites, '
          'bio, careers(name)',
        )
        .eq('id', id)
        .single();

    return UsuarioUpsa.desdeMapa(fila);
  }
}
