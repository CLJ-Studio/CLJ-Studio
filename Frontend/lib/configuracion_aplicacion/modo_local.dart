/// Interruptor temporal para diseñar y probar el frontend sin Supabase.
///
/// Debe permanecer desactivado en el código publicado para que la aplicación
/// inicialice Supabase y utilice exclusivamente los datos del backend.
abstract final class ModoLocal {
  static const activo = false;
}
