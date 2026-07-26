/// Datos del formulario de onboarding, listos para completar_onboarding().
class BorradorOnboarding {
  const BorradorOnboarding({
    this.nombreCompleto = '',
    this.carreraId,
    this.whatsapp = '',
  });

  final String nombreCompleto;
  final String? carreraId;
  final String whatsapp;

  BorradorOnboarding copiarCon({
    String? nombreCompleto,
    String? carreraId,
    String? whatsapp,
  }) => BorradorOnboarding(
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    carreraId: carreraId ?? this.carreraId,
    whatsapp: whatsapp ?? this.whatsapp,
  );

  /// Solo digitos, como los espera el backend.
  String get whatsappNormalizado => whatsapp.replaceAll(RegExp(r'\D'), '');

  /// Espeja las reglas de completar_onboarding() en Postgres para dar
  /// retroalimentacion inmediata sin esperar el viaje al servidor.
  String? get error {
    if (nombreCompleto.trim().length < 3) {
      return 'Escribe tu nombre completo.';
    }
    if (carreraId == null) {
      return 'Selecciona tu carrera.';
    }
    // Los celulares bolivianos son 8 digitos; el backend antepone el 591.
    if (whatsappNormalizado.length != 8) {
      return 'El número debe tener 8 dígitos.';
    }
    return null;
  }

  bool get esValido => error == null;
}
