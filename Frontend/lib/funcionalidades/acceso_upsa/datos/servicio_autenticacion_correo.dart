import 'package:supabase_flutter/supabase_flutter.dart';

/// Como termino el pedido del codigo.
///
/// "Salio" o "fallo" no alcanza. Si se corta la red, el correo pudo salir
/// igual; y si el servidor frena por pedirlo seguido, es porque ya hay uno
/// en el buzon. En esos dos casos hay que dejar escribir el codigo: volver
/// al primer paso dejaba a la persona con el codigo en la mano y sin donde
/// ponerlo.
sealed class EnvioCodigo {
  const EnvioCodigo();
}

/// El servidor confirmo que lo mando.
final class CodigoEnviado extends EnvioCodigo {
  const CodigoEnviado();
}

/// No manda otro todavia porque ya mando uno hace menos de un minuto, y ese
/// sigue sirviendo.
final class CodigoReciente extends EnvioCodigo {
  const CodigoReciente([this.segundos]);

  /// Cuanto falta para poder pedir otro, si el servidor lo dijo.
  final int? segundos;
}

/// No se sabe si salio: se corto la conexion o el servidor no contesto bien.
final class EnvioSinConfirmar extends EnvioCodigo {
  const EnvioSinConfirmar({required this.porRed});

  /// Ni siquiera hubo respuesta: fue la conexion del telefono.
  final bool porRed;
}

/// No salio, por algo que reintentar enseguida no arregla.
final class EnvioRechazado extends EnvioCodigo {
  const EnvioRechazado(this.motivo);

  final String motivo;
}

/// Por que no se pudo entrar con el codigo.
final class FalloVerificacion {
  const FalloVerificacion(this.mensaje, {this.codigoMalo = false});

  final String mensaje;

  /// Lo rechazo el servidor: no es ese codigo o ya vencio. Si es false, el
  /// codigo puede estar bien y lo que fallo fue la conexion.
  final bool codigoMalo;
}

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
  const ServicioAutenticacionCorreo([this.cliente]);

  /// Solo para las pruebas; la aplicacion usa el de `Supabase.instance`.
  final SupabaseClient? cliente;

  static const dominio = 'estudiantes.upsa.edu.bo';

  /// Mas que esto sin respuesta es una conexion colgada: mejor decirlo que
  /// dejar la rueda girando para siempre.
  static const _esperaMaxima = Duration(seconds: 25);

  SupabaseClient get _cliente => cliente ?? Supabase.instance.client;

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

  /// Pide que el codigo llegue al buzon.
  Future<EnvioCodigo> enviarCodigo(String correo) async {
    try {
      await _cliente.auth.signInWithOtp(email: correo).timeout(_esperaMaxima);
      return const CodigoEnviado();
    } on AuthException catch (fallo) {
      return clasificarEnvio(fallo);
    } catch (_) {
      // Se acabo la espera, o fallo algo antes de llegar al servidor.
      return const EnvioSinConfirmar(porRed: true);
    }
  }

  /// Canjea el código por una sesión. Devuelve el motivo si no se pudo.
  Future<FalloVerificacion?> verificarCodigo({
    required String correo,
    required String codigo,
  }) async {
    try {
      await _cliente.auth
          .verifyOTP(email: correo, token: codigo.trim(), type: OtpType.email)
          .timeout(_esperaMaxima);
      return null;
    } on AuthException catch (fallo) {
      return clasificarVerificacion(fallo);
    } catch (_) {
      return const FalloVerificacion(_sinConexionAlVerificar);
    }
  }

  static const _sinConexionAlVerificar =
      'Se cortó la conexión. Tu código sigue sirviendo: toca Verificar e '
      'ingresar para probar de nuevo.';

  /// Traduce el error del servidor al pedir el codigo.
  ///
  /// Nunca devuelve el texto tal cual: un corte de red llega como
  /// "ClientException: Failed to fetch, uri=...", y eso era lo que veia la
  /// persona en pantalla.
  static EnvioCodigo clasificarEnvio(AuthException fallo) {
    final texto = fallo.message;
    final bajo = texto.toLowerCase();

    // El aviso del trigger del dominio llega con su prefijo. Cuando el
    // servidor no deja ver el detalle llega como "Database error saving new
    // user", con un 500: tambien es un no definitivo, no un corte.
    if (texto.contains('DOMINIO_NO_INSTITUCIONAL')) {
      return const EnvioRechazado(
        'Solo se permite el acceso con tu correo @$dominio.',
      );
    }
    if (texto.contains('CORREO_INVALIDO') ||
        fallo.code == 'email_address_invalid') {
      return const EnvioRechazado('Ese correo no es válido.');
    }
    if (bajo.contains('database error saving new user')) {
      return const EnvioRechazado(
        'No se pudo crear tu cuenta con ese correo. Revisa tu número de '
        'registro.',
      );
    }

    // Sin respuesta (statusCode null): sin señal, se corto, o la aplicacion
    // paso a segundo plano a mitad del pedido. Con un 5xx contesto el
    // servidor, pero sin decir si el correo salio.
    if (fallo is AuthRetryableFetchException) {
      return EnvioSinConfirmar(porRed: fallo.statusCode == null);
    }

    // "For security purposes, you can only request this after 42 seconds":
    // a este correo ya le salio uno hace menos de un minuto.
    if (bajo.contains('security purposes')) {
      final segundos = RegExp(r'(\d+)\s*second').firstMatch(bajo)?.group(1);
      return CodigoReciente(segundos == null ? null : int.parse(segundos));
    }
    // El mismo codigo de error sirve para el tope de correos de todo el
    // proyecto por hora, que no dice nada de este correo en particular.
    if (fallo.code == 'over_email_send_rate_limit' ||
        bajo.contains('email rate limit')) {
      return const EnvioRechazado(
        'Se mandaron muchos códigos en la última hora. Prueba de nuevo en '
        'unos minutos.',
      );
    }
    if (fallo.code == 'over_request_rate_limit' ||
        bajo.contains('rate limit')) {
      return const EnvioRechazado(
        'Hubo demasiados intentos seguidos. Espera unos minutos y vuelve a '
        'probar.',
      );
    }
    if (fallo.code
        case 'signup_disabled' || 'otp_disabled' || 'email_provider_disabled') {
      return const EnvioRechazado(
        'El acceso con código está apagado por ahora. Avísanos para '
        'revisarlo.',
      );
    }
    // El codigo de error entre parentesis: si alguien manda una captura,
    // dice que paso sin mostrarle a nadie un volcado.
    final codigo = fallo.code;
    return EnvioRechazado(
      'No se pudo enviar el código${codigo == null ? '' : ' ($codigo)'}. '
      'Intenta de nuevo en un momento.',
    );
  }

  /// Traduce el error del servidor al canjear el codigo.
  static FalloVerificacion clasificarVerificacion(AuthException fallo) {
    if (fallo is AuthRetryableFetchException) {
      return const FalloVerificacion(_sinConexionAlVerificar);
    }
    final bajo = fallo.message.toLowerCase();
    // El servidor contesta lo mismo para un codigo mal escrito y para uno
    // vencido ("Token has expired or is invalid"). Decir "caduco, pide uno
    // nuevo" ante un digito equivocado hacia pedir otro, y el nuevo deja sin
    // valor el del correo anterior.
    if (fallo.code == 'otp_expired' ||
        bajo.contains('expired') ||
        bajo.contains('invalid')) {
      return const FalloVerificacion(
        'Ese código no sirve. Revisa que sea el del último correo que te '
        'llegó; si es de hace rato, pide otro.',
        codigoMalo: true,
      );
    }
    if (fallo.code == 'over_request_rate_limit' ||
        bajo.contains('rate limit')) {
      return const FalloVerificacion(
        'Hubo demasiados intentos seguidos. Espera unos minutos y vuelve a '
        'probar.',
      );
    }
    final codigo = fallo.code;
    return FalloVerificacion(
      'No se pudo verificar el código${codigo == null ? '' : ' ($codigo)'}. '
      'Intenta de nuevo.',
    );
  }

  Future<void> cerrarSesion() => _cliente.auth.signOut();
}
