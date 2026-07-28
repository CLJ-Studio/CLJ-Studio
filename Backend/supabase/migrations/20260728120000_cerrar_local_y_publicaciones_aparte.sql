-- ============================================================================
-- 26 · Cerrar el local, y separar publicaciones del catalogo del negocio
-- ============================================================================
-- Dos peticiones que van juntas porque tocan la misma restriccion.
--
-- 1. "Si publico un producto no deberia meterse en el local, una publicacion
--    es diferente a un producto del local."
--
--    Hasta ahora solo cabia UN store activo por persona, asi que abrir un
--    negocio convertia el espacio personal en ese negocio y todo lo que ya
--    se habia publicado a titulo personal pasaba a colgar de la marca. El
--    indice unico pasa a ser por (dueno, tipo): cada quien puede tener su
--    espacio personal Y su negocio a la vez, separados.
--
-- 2. "Tiene que haber la opcion de poder borrar el local."
--
--    Un DELETE de verdad es imposible en cuanto el local vendio algo:
--    orders.store_id es `on delete restrict` justamente para que el
--    historial del COMPRADOR no desaparezca porque el vendedor cierre. Y esa
--    proteccion tiene que quedarse: el historial de una compra no es del
--    vendedor solo, y no le toca a el borrarlo.
--
--    Asi que cerrar es `is_active = false`. Sale del catalogo, libera el
--    hueco del indice unico y conserva lo entregado. Lo que si se cancela
--    solo son los pedidos que segan vivos: quien espera una confirmacion
--    que ya no va a llegar tiene que enterarse, y su stock se devuelve.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Un espacio personal y un negocio por persona, en vez de uno solo.
-- ----------------------------------------------------------------------------
drop index if exists public.stores_un_local_por_dueno;

create unique index stores_un_local_por_dueno
  on public.stores(owner_id, is_personal) where is_active;

-- ----------------------------------------------------------------------------
-- cerrar_local · lo dispara el boton "Cerrar el local" de Tu local
-- ----------------------------------------------------------------------------
create or replace function public.cerrar_local(p_local uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor  uuid := auth.uid();
  v_pedido public.orders%rowtype;
begin
  -- El espacio personal no se cierra: es el contenedor de las publicaciones
  -- sueltas, y sin el la persona no podria volver a publicar nada.
  if not exists (
    select 1 from public.stores
     where id = p_local and owner_id = v_actor
       and is_active and not is_personal
  ) then
    raise exception 'LOCAL_AJENO_O_INEXISTENTE' using errcode = '42501';
  end if;

  -- Los pedidos vivos se cancelan uno a uno y no en bloque: cada comprador
  -- necesita su aviso, su evento en el historial y su stock devuelto.
  for v_pedido in
    select * from public.orders
     where store_id = p_local
       and status in ('solicitado', 'aceptado')
     for update
  loop
    -- El stock solo se descuenta al aceptar, asi que solo ahi hay algo que
    -- devolver. Hacerlo siempre inflaria el inventario con los pedidos que
    -- nunca llegaron a confirmarse.
    if v_pedido.status = 'aceptado' then
      perform public.restituir_stock(v_pedido.id);
    end if;

    update public.orders
       set status = 'cancelado', resolved_at = now()
     where id = v_pedido.id;

    perform public.registrar_evento_pedido(
      v_pedido.id,
      v_actor,
      v_pedido.status,
      'cancelado',
      v_pedido.buyer_id,
      'pedido_cancelado',
      'Pedido cancelado',
      'El vendedor cerró su local, así que tu pedido se canceló.'
    );
  end loop;

  -- Las publicaciones se retiran del catalogo con el local. El feed ya
  -- filtra por local activo, pero dejarlas disponibles haria que cualquier
  -- consulta que no lo haga las siguiera mostrando.
  update public.products set is_available = false where store_id = p_local;

  update public.stores
     set is_active = false, is_open = false
   where id = p_local;
end;
$$;

revoke all on function public.cerrar_local(uuid) from public;
grant execute on function public.cerrar_local(uuid) to authenticated;
