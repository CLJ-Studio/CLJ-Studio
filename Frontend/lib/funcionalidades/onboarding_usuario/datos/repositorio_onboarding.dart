import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelos/borrador_onboarding.dart';
import '../modelos/carrera_upsa.dart';

/// Lee el catalogo de carreras y persiste el onboarding.
///
/// No se hace un UPDATE directo a `profiles`: la funcion completar_onboarding
/// normaliza el WhatsApp y valida en el servidor, que es la fuente de verdad.
class RepositorioOnboarding {
  const RepositorioOnboarding();

  /// El nombre que el trigger guardo al crear el perfil, y si la cuenta es
  /// del personal de la UPSA.
  ///
  /// El nombre vuelve null si es el codigo de estudiante de reserva: en ese
  /// caso el formulario si debe pedirlo. Se lee con `select()` entero y no
  /// columna por columna para no romper el registro si la migracion de las
  /// cuentas UPSA todavia no esta aplicada: sin `tipo_cuenta`, todos son
  /// estudiantes, como hasta ahora.
  Future<({String? nombre, bool esCuentaUpsa})> cargarPerfilInicial() async {
    final cliente = Supabase.instance.client;
    final fila = await cliente
        .from('profiles')
        .select()
        .eq('id', cliente.auth.currentUser!.id)
        .maybeSingle();

    final nombre = (fila?['full_name'] as String?)?.trim() ?? '';
    final esCodigoDeReserva = RegExp(r'^a\d{10}$').hasMatch(nombre);

    return (
      nombre: nombre.length >= 3 && !esCodigoDeReserva ? nombre : null,
      esCuentaUpsa: fila?['tipo_cuenta'] == 'upsa',
    );
  }

  Future<List<CarreraUpsa>> cargarCarreras() async {
    final filas = await Supabase.instance.client
        .from('careers')
        .select('id, name, faculty')
        .order('sort_order');

    return filas.map(CarreraUpsa.desdeMapa).toList();
  }

  /// El del personal de la UPSA: area o unidad en vez de carrera.
  Future<void> completarUpsa(BorradorOnboarding borrador) {
    return Supabase.instance.client.rpc(
      'completar_onboarding_upsa',
      params: {
        'p_full_name': borrador.nombreCompleto.trim(),
        'p_area': borrador.area.trim(),
        'p_whatsapp': borrador.whatsappNormalizado,
      },
    );
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
