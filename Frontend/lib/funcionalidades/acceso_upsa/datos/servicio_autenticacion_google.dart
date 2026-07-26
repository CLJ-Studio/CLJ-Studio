import 'package:supabase_flutter/supabase_flutter.dart';

/// Dispara el login real con Google via Supabase Auth.
///
/// La validacion del dominio institucional NO ocurre aqui ni en Flutter:
/// vive en un trigger Postgres (`validar_dominio_institucional`) que corre
/// ANTES de crear el usuario. Si el correo no es institucional, Supabase
/// nunca completa el alta y el redirect de vuelta trae un error en la URL,
/// que la pantalla de acceso interpreta (ver PantallaAccesoUpsa).
class ServicioAutenticacionGoogle {
  const ServicioAutenticacionGoogle();

  /// [correoSugerido] se envia como `login_hint`: Google preselecciona esa
  /// cuenta en su selector. Es solo una comodidad, no una restriccion.
  Future<void> iniciarSesion({String? correoSugerido}) {
    return Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      // En Flutter Web esto navega la pestaña entera a Google y vuelve aqui.
      redirectTo: Uri.base.origin,
      queryParams: {
        if (correoSugerido != null && correoSugerido.isNotEmpty)
          'login_hint': correoSugerido,
      },
    );
  }

  Future<void> cerrarSesion() => Supabase.instance.client.auth.signOut();
}
