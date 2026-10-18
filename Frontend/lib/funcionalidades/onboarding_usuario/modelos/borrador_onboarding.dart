/// Datos del formulario de onboarding, listos para completar_onboarding().
class BorradorOnboarding {
  const BorradorOnboarding({
    this.nombreCompleto = '',
    this.carreraId,
    this.whatsapp = '',
    this.area = '',
    this.esCuentaUpsa = false,
  });

  final String nombreCompleto;
  final String? carreraId;
  final String whatsapp;

  /// Area o unidad del personal de la UPSA ("Incubadora de Empresas").
  final String area;

  /// El personal de la UPSA no tiene carrera: pone su area o unidad.
  final bool esCuentaUpsa;

  BorradorOnboarding copiarCon({
    String? nombreCompleto,
    String? carreraId,
    String? whatsapp,
    String? area,
    bool? esCuentaUpsa,
  }) => BorradorOnboarding(
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    carreraId: carreraId ?? this.carreraId,
    whatsapp: whatsapp ?? this.whatsapp,
    area: area ?? this.area,
    esCuentaUpsa: esCuentaUpsa ?? this.esCuentaUpsa,
  );

  /// Solo digitos, como los espera el backend.
  String get whatsappNormalizado => whatsapp.replaceAll(RegExp(r'\D'), '');

  /// Una letra, con las tildes y la ñ que llevan los apellidos de aqui.
  static const _letra = r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]';

  /// Una parte del nombre: palabra de dos letras o mas, o compuesta con
  /// guion o apostrofo ("Ana-María", "O'Connor"). El apostrofo va DENTRO de
  /// la parte, no separando: si no, "O'Connor" se leeria como una "O" suelta.
  static const _parte = '($_letra{2,}|$_letra+([\'-]$_letra+)+)';

  /// Nombre y apellido: al menos dos partes separadas por espacio. Es la
  /// misma regla que aplica completar_onboarding() en Postgres.
  static final _nombreReal = RegExp('^$_parte( $_parte)+\$');

  /// Espeja las reglas de completar_onboarding() en Postgres para dar
  /// retroalimentacion inmediata sin esperar el viaje al servidor.
  String? get error {
    final nombre = nombreCompleto.trim();
    if (nombre.isEmpty) {
      return 'Escribe tu nombre completo.';
    }
    // El campo solo se pide cuando la cuenta no trajo nombre, y entonces es
    // lo unico que identifica a la persona ante quien le va a entregar algo
    // en mano: un apodo suelto no sirve.
    if (!_nombreReal.hasMatch(nombre)) {
      return 'Escribe tu nombre y tu apellido, sin apodos.';
    }
    if (nombre.length > 60) {
      return 'Ese nombre es demasiado largo.';
    }
    if (esCuentaUpsa) {
      final area = this.area.trim();
      if (area.length < 2) return 'Escribe tu área o unidad.';
      if (area.length > 60) return 'El nombre del área es demasiado largo.';
    } else if (carreraId == null) {
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
