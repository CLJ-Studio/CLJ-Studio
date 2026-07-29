-- ============================================================================
-- 34 · Lo que se puede ver del perfil de otra persona
-- ============================================================================
-- El perfil publico tiene tres pestañas (publicaciones sueltas, local y me
-- gusta) pero las tres enseñaban la misma lista, porque solo se le pasaba el
-- local desde el que se habia abierto. Faltaban dos piezas del servidor.
--
-- 1. Los favoritos son estrictamente privados por RLS (`user_id = auth.uid()`),
--    y esa politica se queda tal cual: es la que garantiza que por defecto no
--    los vea nadie. Para quien SI decide enseñarlos hace falta una puerta
--    explicita, y eso es esta funcion.
--
-- 2. Un vendedor puede tener dos locales a la vez (su espacio personal y su
--    negocio). Se expone quien es el dueño en la vista publica para poder
--    pedir los dos y separar las pestañas.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Favoritos de alguien, solo si los hizo publicos.
-- ----------------------------------------------------------------------------
-- Devuelve ids y no filas completas a proposito: los productos ya son
-- legibles por cualquiera, asi que el cliente los pide por su cuenta y esta
-- funcion no tiene que replicar la forma de la tabla ni sus permisos.
--
-- Si `show_favorites` esta apagado devuelve vacio, que es indistinguible de
-- no tener ninguno. Quien lo apaga no revela ni siquiera cuantos tiene.
create or replace function public.favoritos_publicos(p_usuario uuid)
returns setof uuid
language sql
security definer
set search_path = public
stable
as $$
  select f.product_id
    from public.favorites f
    join public.profiles p on p.id = f.user_id
   where f.user_id = p_usuario
     and p.show_favorites;
$$;

revoke all on function public.favoritos_publicos(uuid) from public;
grant execute on function public.favoritos_publicos(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- La vista ya traia owner_id; se confirma que sigue ahi tras los cambios de
-- las migraciones 31 y 32, porque el perfil publico ahora depende de el para
-- encontrar los dos locales de la misma persona.
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from information_schema.columns
     where table_name = 'locales_publicos' and column_name = 'owner_id'
  ) then
    raise exception 'locales_publicos perdio owner_id: revisa la migracion 31';
  end if;
end;
$$;
