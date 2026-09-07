import 'package:flutter_test/flutter_test.dart';
import 'package:upsa_eat/funcionalidades/onboarding_usuario/modelos/borrador_onboarding.dart';

/// La regla del nombre solo aplica a quien entra con el código al correo: esa
/// cuenta no trae nombre y el perfil se queda con el que se escriba aquí, sin
/// forma de cambiarlo después. Espeja completar_onboarding() en Postgres.
BorradorOnboarding conNombre(String nombre) => BorradorOnboarding(
  nombreCompleto: nombre,
  carreraId: 'ing-sistemas',
  whatsapp: '70012345',
);

void main() {
  test('acepta un nombre y un apellido', () {
    expect(conNombre('Juan Perez').error, isNull);
    expect(conNombre('Ana María Vaca Céspedes').error, isNull);
    expect(conNombre('Ana-María Vaca').error, isNull);
    expect(conNombre("Juan O'Connor").error, isNull);
  });

  test('rechaza el apodo suelto que dejaba pasar antes', () {
    expect(conNombre('MOMO').error, isNotNull);
    expect(conNombre('momo').error, isNotNull);
    expect(conNombre('Xx').error, isNotNull);
  });

  test('rechaza el código de registro y cualquier número', () {
    expect(conNombre('a2023115833').error, isNotNull);
    expect(conNombre('Juan 2').error, isNotNull);
    expect(conNombre('2023115833').error, isNotNull);
  });

  test('sigue pidiendo carrera y WhatsApp con el nombre correcto', () {
    const sinCarrera = BorradorOnboarding(
      nombreCompleto: 'Juan Perez',
      whatsapp: '70012345',
    );
    expect(sinCarrera.error, 'Selecciona tu carrera.');

    const telefonoCorto = BorradorOnboarding(
      nombreCompleto: 'Juan Perez',
      carreraId: 'ing-sistemas',
      whatsapp: '700',
    );
    expect(telefonoCorto.error, 'El número debe tener 8 dígitos.');
  });
}
