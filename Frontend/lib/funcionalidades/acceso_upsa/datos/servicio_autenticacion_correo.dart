import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso con el correo institucional y un código de un solo uso.
///
/// Sustituye al redirect a Google: la persona no sale de la aplicación, pide
/// el código, lo recibe en su buzón de la universidad y lo escribe aquí.
///
/// La restricción de dominio NO vive aquí ni en ninguna parte de Flutter: la
/// impone el trigger `validar_dominio_institucional`, que corre ANTES de
/// crear el usuario. Un correo de fuera de la UPSA ni siquiera llega a
/// recibir el código, porque el alta falla antes de enviarlo. Lo que sí se
/// comprueba aquí es el formato, para avisar antes de gastar un viaje.
class ServicioAutenticacionCorreo {
  const ServicioAutenticacionCorreo();

  static const dominio = 'estudiantes.upsa.edu.bo';

  SupabaseClient get _cliente => Supabase.instance.client;

  /// Arma el correo a partir del número de registro, o acepta uno completo.
  static String? normalizarCorreo(String entrada) {
    final texto = entrada.trim().toLowerCase();
    if (texto.isEmpty) return null;

    if (texto.contains('@')) {
      return texto.endsWith('@$dominio') ? texto : null;
    }

    // Solo el registro: 'a' opcional seguida de diez dígitos.
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{4}(11|12)\d{4}$').hasMatch(digitos)) return null;

    final anio = int.parse(digitos.substring(0, 4));
    if (anio < 2000 || anio > DateTime.now().year) return null;

    return 'a$digitos@$dominio';
  }

  /// Envía el código al buzón. Devuelve el motivo si no se pudo.
  Future<String?> enviarCodigo(String correo) async {
    try {
      await _cliente.auth.signInWithOtp(email: correo);
      return null;
    } on AuthException catch (fallo) {
      return _mensaje(fallo);
    } catch (_) {
      return 'No se pudo enviar el código. Revisa tu conexión.';
    }
  }

  /// Canjea el código por una sesión. Devuelve el motivo si no se pudo.
  Future<String?> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    try {
      await _cliente.auth.verifyOTP(
        email: correo,
        token: codigo.trim(),
        type: OtpType.email,
      );
      return null;
    } on AuthException catch (fallo) {
      return _mensaje(fallo);
    } catch (_) {
      return 'No se pudo verificar el código. Intenta de nuevo.';
    }
  }

  /// Traduce el error del servidor a algo que se entienda.
  ///
  /// El del dominio llega tal cual lo lanza el trigger, con su prefijo y el
  /// nombre del dominio: sin traducirlo, la pantalla mostraría un volcado.
  String _mensaje(AuthException fallo) {
    final texto = fallo.message;

    if (texto.contains('DOMINIO_NO_INSTITUCIONAL')) {
      return 'Solo se permite el acceso con tu correo @$dominio.';
    }
    if (texto.contains('CORREO_INVALIDO')) {
      return 'Ese correo no es válido.';
    }
    if (texto.toLowerCase().contains('expired')) {
      return 'El código caducó. Pide uno nuevo.';
    }
    if (texto.toLowerCase().contains('invalid')) {
      return 'El código no es correcto. Revísalo.';
    }
    // Supabase limita cuántos correos se piden seguidos.
    if (texto.toLowerCase().contains('rate limit') ||
        texto.toLowerCase().contains('security purposes')) {
      return 'Espera un momento antes de pedir otro código.';
    }
    return texto;
  }

  Future<void> cerrarSesion() => _cliente.auth.signOut();
}
