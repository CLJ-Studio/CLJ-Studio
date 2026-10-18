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

  /// Personal de la UPSA: pone su area o unidad en vez de carrera.
  bool esCuentaUpsa = false;

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
      final perfil = await _repositorio.cargarPerfilInicial();
      esCuentaUpsa = perfil.esCuentaUpsa;
      if (esCuentaUpsa) {
        // Al personal siempre se le pide el nombre: en el perfil solo esta
        // la parte del correo ("josebenavente"), que pasaria por un nombre
        // de verdad y quedaria bloqueado.
        borrador = borrador.copiarCon(esCuentaUpsa: true);
      } else {
        carreras = await _repositorio.cargarCarreras();
        nombreInstitucional = perfil.nombre;
        if (nombreInstitucional != null && nombreVieneDeLaCuenta) {
          borrador = borrador.copiarCon(nombreCompleto: nombreInstitucional);
        }
      }
    } catch (_) {
      errorServidor = 'No se pudieron cargar tus datos. Revisa tu conexión.';
    } finally {
      cargandoCarreras = false;
      notifyListeners();
    }
  }

  /// Si el nombre guardado es de verdad o solo el correo disfrazado.
  ///
  /// Con Google llegaba el nombre real y el campo era de solo lectura. Al
  /// entrar con un codigo por correo no hay nombre en ninguna parte, asi que
  /// el perfil se crea con la parte local del correo ("a2023115833") y hay
  /// que pedirlo. Enseñar eso como nombre y bloquearlo dejaria a media
  /// comunidad llamandose por su numero de registro.
  bool get nombreVieneDeLaCuenta {
    final nombre = nombreInstitucional?.trim() ?? '';
    if (nombre.isEmpty) return false;
    return !RegExp(r'^a?\d{6,}$').hasMatch(nombre);
  }

  void actualizarNombre(String valor) {
    borrador = borrador.copiarCon(nombreCompleto: valor);
    notifyListeners();
  }

  void actualizarCarrera(String? valor) {
    borrador = borrador.copiarCon(carreraId: valor);
    notifyListeners();
  }

  void actualizarArea(String valor) {
    borrador = borrador.copiarCon(area: valor);
    notifyListeners();
  }

  void actualizarWhatsapp(String valor) {
    borrador = borrador.copiarCon(whatsapp: valor);
    notifyListeners();
  }

  /// Las excepciones de completar_onboarding llegan con su prefijo y su
  /// explicacion tecnica pegados; sin traducirlas la pantalla muestra un
  /// volcado del servidor debajo del boton.
  String _mensajeDeError(Object error) {
    final texto = error.toString();
    if (texto.contains('CONTENIDO_NO_PERMITIDO')) {
      return 'Ese nombre no se puede usar. Escribe el tuyo real.';
    }
    if (texto.contains('NOMBRE_INVALIDO')) {
      return 'Escribe tu nombre y tu apellido, sin apodos.';
    }
    if (texto.contains('AREA_INVALIDA')) {
      return 'Escribe tu área o unidad.';
    }
    if (texto.contains('CARRERA_INVALIDA')) {
      return 'Selecciona una carrera de la lista.';
    }
    if (texto.contains('WHATSAPP_INVALIDO')) {
      return 'Revisa tu número de WhatsApp.';
    }
    return 'No se pudo guardar tu perfil. Intenta de nuevo.';
  }

  Future<bool> enviar() async {
    if (!borrador.esValido) return false;

    enviando = true;
    errorServidor = null;
    notifyListeners();

    try {
      if (esCuentaUpsa) {
        await _repositorio.completarUpsa(borrador);
      } else {
        await _repositorio.completar(borrador);
      }
      return true;
    } catch (error) {
      errorServidor = _mensajeDeError(error);
      return false;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }
}
