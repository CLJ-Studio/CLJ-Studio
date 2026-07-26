import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/borrador_onboarding.dart';
import '../modelos/carrera_upsa.dart';

/// Lee el catalogo de carreras y persiste el onboarding.
///
/// No se hace un UPDATE directo a `profiles`: la funcion completar_onboarding
/// normaliza el WhatsApp y valida en el servidor, que es la fuente de verdad.
class RepositorioOnboarding {
  const RepositorioOnboarding();

  /// Nombre que el trigger tomo de la cuenta de Google al crear el perfil.
  ///
  /// Devuelve null si Google no entrego nombre y quedo el codigo de
  /// estudiante como reserva: en ese caso el formulario si debe pedirlo.
  Future<String?> cargarNombreInstitucional() async {
    final cliente = Supabase.instance.client;
    final fila = await cliente
        .from('profiles')
        .select('full_name')
        .eq('id', cliente.auth.currentUser!.id)
        .maybeSingle();

    final nombre = (fila?['full_name'] as String?)?.trim() ?? '';
    final esCodigoDeReserva = RegExp(r'^a\d{10}$').hasMatch(nombre);

    return nombre.length >= 3 && !esCodigoDeReserva ? nombre : null;
  }

  Future<List<CarreraUpsa>> cargarCarreras() async {
    final filas = await Supabase.instance.client
        .from('careers')
        .select('id, name, faculty')
        .order('sort_order');

    return filas.map(CarreraUpsa.desdeMapa).toList();
  }

  Future<void> completar(BorradorOnboarding borrador) {
    return Supabase.instance.client.rpc(
      'completar_onboarding',
      params: {
        'p_full_name': borrador.nombreCompleto.trim(),
        'p_career_id': borrador.carreraId,
        'p_whatsapp': borrador.whatsappNormalizado,
      },
    );
  }
}
