/// Credenciales del proyecto Supabase.
///
/// La publishableKey es publica por diseno (equivalente a la antigua "anon
/// key"): puede viajar dentro del bundle web sin riesgo porque la proteccion
/// real vive en las politicas RLS del backend, no en ocultar esta clave.
///
/// Se pasan por --dart-define para no commitear nada y poder usar valores
/// distintos en desarrollo/produccion sin tocar el codigo:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://tujqaxohgpeoxxezbzzp.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
abstract final class ConfiguracionSupabase {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tujqaxohgpeoxxezbzzp.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_HUgvzw_cOV4vS8WUkzXX2Q_pTurdJar',
  );
}
