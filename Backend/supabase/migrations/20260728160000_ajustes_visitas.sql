-- ============================================================================
-- 28 · Ajustes sobre el conteo de visitas
-- ============================================================================
-- Complementa 20260728143000_visualizaciones.sql. Se deja aparte y no se
-- edita aquel para que ejecutar los dos en orden funcione tanto si el
-- anterior ya se aplico como si no.
--
-- 1. Las dos funciones de visitas quedaron ejecutables por PUBLIC, que es lo
--    que pasa cuando solo se hace GRANT y no se revoca antes. Al ser
--    SECURITY DEFINER, eso permite que cualquiera sin sesion infle el
--    contador, y ese contador es justo el que decide que locales salen como
--    destacados en el inicio. El resto de funciones del proyecto ya siguen
--    este patron.
--
-- 2. El inicio ordena los destacados por visitas. Sin indice, cada carga
--    recorre la tabla entera de locales.
-- ============================================================================

revoke all on function public.registrar_vista_producto(uuid) from public;
revoke all on function public.registrar_vista_local(uuid)    from public;

grant execute on function public.registrar_vista_producto(uuid) to authenticated;
grant execute on function public.registrar_vista_local(uuid)    to authenticated;

create index if not exists stores_visitas_idx
  on public.stores(view_count desc) where is_active;
