import '../funcionalidades/configuracion_usuario/modelos/usuario_upsa.dart';

/// Usuario simulado hasta disponer de autenticación real.
abstract final class UsuarioPrueba {
  static const UsuarioUpsa estudiante = UsuarioUpsa(
    nombre: 'Andrea',
    codigo: 'a2024113311',
    correo: 'a2024113311@estudiantes.upsa.edu.bo',
    carrera: 'Ingenieria de Sistemas',
  );
}
