import 'package:flutter/foundation.dart';

import '../datos/repositorio_onboarding.dart';
import '../modelos/borrador_onboarding.dart';
import '../modelos/carrera_upsa.dart';

/// Controla el formulario de onboarding, el catalogo de carreras y su envio.
class ControladorOnboarding extends ChangeNotifier {
  ControladorOnboarding(this._repositorio);
  final RepositorioOnboarding _repositorio;

  BorradorOnboarding borrador = const BorradorOnboarding();
  List<CarreraUpsa> carreras = const [];
  bool cargandoCarreras = true;
  bool enviando = false;
  String? errorServidor;

  /// Nombre que vino de la cuenta institucional. Si existe, el formulario
  /// lo muestra bloqueado: la universidad es la fuente autoritativa.
  String? nombreInstitucional;
  bool get nombreEsEditable => nombreInstitucional == null;

  /// Agrupa por facultad conservando el orden que llega del backend.
  Map<String, List<CarreraUpsa>> get carrerasPorFacultad {
    final agrupadas = <String, List<CarreraUpsa>>{};
    for (final carrera in carreras) {
      agrupadas.putIfAbsent(carrera.facultad, () => []).add(carrera);
    }
    return agrupadas;
  }

  Future<void> cargarDatosIniciales() async {
    try {
      carreras = await _repositorio.cargarCarreras();
      nombreInstitucional = await _repositorio.cargarNombreInstitucional();
      if (nombreInstitucional != null) {
        borrador = borrador.copiarCon(nombreCompleto: nombreInstitucional);
      }
    } catch (_) {
      errorServidor = 'No se pudieron cargar tus datos. Revisa tu conexión.';
    } finally {
      cargandoCarreras = false;
      notifyListeners();
    }
  }

  void actualizarNombre(String valor) {
    borrador = borrador.copiarCon(nombreCompleto: valor);
    notifyListeners();
  }

  void actualizarCarrera(String? valor) {
    borrador = borrador.copiarCon(carreraId: valor);
    notifyListeners();
  }

  void actualizarWhatsapp(String valor) {
    borrador = borrador.copiarCon(whatsapp: valor);
    notifyListeners();
  }

  Future<bool> enviar() async {
    if (!borrador.esValido) return false;

    enviando = true;
    errorServidor = null;
    notifyListeners();

    try {
      await _repositorio.completar(borrador);
      return true;
    } catch (error) {
      errorServidor = 'No se pudo guardar tu perfil. $error';
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
