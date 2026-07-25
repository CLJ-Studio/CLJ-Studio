import '../modelos/borrador_publicacion.dart';

/// Contrato local que luego enviará publicaciones al endpoint correspondiente.
class RepositorioPublicaciones {
  Future<bool> simularPublicacion(BorradorPublicacion borrador) async => true;
}
