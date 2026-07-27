-- ============================================================================
-- 18 · Realtime que de verdad emite
-- ============================================================================
-- Sintoma: nada se actualizaba solo; todo exigia recargar.
--
-- Dos causas:
--
-- 1. Solo `orders` y `notifications` estaban publicadas. El feed, el
--    inventario y los favoritos jamas tuvieron Realtime.
--
-- 2. Todas tenian REPLICA IDENTITY por defecto, que solo escribe la clave
--    primaria en el WAL. Con RLS activa, Realtime necesita la fila ANTERIOR
--    completa para decidir si el evento le corresponde a quien escucha: sin
--    ella descarta los UPDATE en silencio. Por eso aceptar un pedido nunca
--    llegaba en vivo aunque `orders` si estuviera publicada.
--
-- REPLICA IDENTITY FULL encarece un poco la escritura (guarda la fila vieja
-- entera). A escala de campus es irrelevante frente a tener una app que
-- responde sola.
-- ============================================================================

alter table public.orders        replica identity full;
alter table public.notifications replica identity full;
alter table public.stores        replica identity full;
alter table public.products      replica identity full;
alter table public.favorites     replica identity full;
alter table public.order_items   replica identity full;

-- Las que faltaban en la publicacion.
alter publication supabase_realtime add table public.stores;
alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.favorites;
alter publication supabase_realtime add table public.order_items;
