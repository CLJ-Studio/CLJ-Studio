-- ============================================================================
-- 45 · Chat dentro del pedido
-- ============================================================================
-- Hasta ahora, aceptar un pedido soltaba el numero de WhatsApp y la
-- conversacion se iba de la aplicacion. Eso tiene tres costes: hay que dar el
-- telefono a un desconocido, lo acordado queda fuera de donde vive el pedido,
-- y la aplicacion no puede volver a saber nada de esa venta.
--
-- El chat vive PEGADO AL PEDIDO, no a las personas. No hay bandeja de
-- entrada ni conversaciones sueltas: cada hilo es de un pedido y dura lo que
-- dura el pedido.
--
-- CUANDO SE PUEDE ESCRIBIR
--   Solo con el pedido en 'aceptado' o 'por_confirmar'. Antes de aceptar no
--   hay trato que coordinar; despues de entregar, ya no hay nada que decir.
--
-- CUANDO DEJA DE VERSE
--   La misma policy de lectura exige esos dos estados. Al confirmarse la
--   entrega el hilo desaparece de la aplicacion SIN BORRARSE: las filas
--   siguen ahi para una disputa o para moderar. Cerrar y borrar no son lo
--   mismo, y aqui hace falta lo primero.
--
-- Requiere haber ejecutado antes 20260806120000.
-- ============================================================================

create table if not exists public.mensajes_pedido (
  id        uuid primary key default gen_random_uuid(),
  order_id  uuid not null references public.orders(id)   on delete cascade,
  autor_id  uuid not null references public.profiles(id) on delete cascade,
  cuerpo    text not null,
  creado_en timestamptz not null default now(),
  leido_en  timestamptz,

  constraint mensaje_no_vacio  check (length(trim(cuerpo)) > 0),
  constraint mensaje_no_enorme check (length(cuerpo) <= 1000)
);

-- El hilo se lee siempre igual: todo lo de un pedido, en orden.
create index if not exists mensajes_del_pedido_idx
  on public.mensajes_pedido (order_id, creado_en);

-- Para el contador de no leidos, que corre en cada carga de la pantalla.
create index if not exists mensajes_sin_leer_idx
  on public.mensajes_pedido (order_id, autor_id) where leido_en is null;

alter table public.mensajes_pedido enable row level security;

-- ----------------------------------------------------------------------------
-- Lectura · solo los dos del pedido, y solo mientras siga vivo
-- ----------------------------------------------------------------------------
-- Las dos condiciones van juntas a proposito. Si el cierre se hiciera solo en
-- la pantalla, el hilo seguiria siendo legible para cualquiera que llamara a
-- la API por su cuenta, y "se cierra" habria sido una decoracion.
drop policy if exists mensajes_lectura on public.mensajes_pedido;
create policy mensajes_lectura on public.mensajes_pedido
  for select to authenticated
  using (
    exists (
      select 1 from public.orders o
       where o.id = mensajes_pedido.order_id
         and (o.buyer_id = auth.uid() or o.seller_id = auth.uid())
         and o.status in ('aceptado', 'por_confirmar')
    )
  );

-- Marcar como leido es lo unico que se escribe directo: no cambia el
-- contenido de nadie, solo la marca de que ya se vio.
drop policy if exists mensajes_marcar_leido on public.mensajes_pedido;
create policy mensajes_marcar_leido on public.mensajes_pedido
  for update to authenticated
  using (
    autor_id <> auth.uid()
    and exists (
      select 1 from public.orders o
       where o.id = mensajes_pedido.order_id
         and (o.buyer_id = auth.uid() or o.seller_id = auth.uid())
         and o.status in ('aceptado', 'por_confirmar')
    )
  )
  with check (autor_id <> auth.uid());

-- Escribir NO tiene policy: pasa por enviar_mensaje(), que ademas filtra el
-- contenido. Un insert directo se saltaria el filtro.
revoke insert, delete on public.mensajes_pedido from anon, authenticated;
grant select, update on public.mensajes_pedido to authenticated;

-- ----------------------------------------------------------------------------
-- En vivo
-- ----------------------------------------------------------------------------
-- REPLICA IDENTITY FULL es obligatorio con RLS: sin la fila vieja completa, la
-- policy no puede evaluar los UPDATE y el evento no llega.
alter table public.mensajes_pedido replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'mensajes_pedido'
  ) then
    alter publication supabase_realtime add table public.mensajes_pedido;
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- Enviar
-- ----------------------------------------------------------------------------
create or replace function public.enviar_mensaje(
  p_order_id uuid,
  p_cuerpo   text
)
returns public.mensajes_pedido
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor    uuid := auth.uid();
  v_pedido   public.orders%rowtype;
  v_otro     uuid;
  v_termino  text;
  v_texto    text := trim(p_cuerpo);
  v_mensaje  public.mensajes_pedido;
  v_pendiente integer;
begin
  if v_actor is null then
    raise exception 'SESION_REQUERIDA' using errcode = '42501';
  end if;
  if v_texto is null or length(v_texto) = 0 then
    raise exception 'MENSAJE_VACIO' using errcode = '22023';
  end if;
  if length(v_texto) > 1000 then
    raise exception 'MENSAJE_MUY_LARGO' using errcode = '22023';
  end if;

  select * into v_pedido from public.orders where id = p_order_id;
  if not found then
    raise exception 'PEDIDO_INEXISTENTE' using errcode = '22023';
  end if;
  if v_actor not in (v_pedido.buyer_id, v_pedido.seller_id) then
    raise exception 'NO_PARTICIPAS_EN_ESTE_PEDIDO' using errcode = '42501';
  end if;
  if v_pedido.status not in ('aceptado', 'por_confirmar') then
    raise exception 'CHAT_CERRADO' using errcode = '42501';
  end if;

  -- El mismo filtro que el resto de la aplicacion. Sin esto, el chat seria el
  -- unico sitio donde se puede escribir lo que quieras sin que nada lo mire,
  -- y ademas es privado, o sea el mejor sitio posible para acosar a alguien.
  v_termino := public.termino_ofensivo(v_texto);
  if v_termino is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO' using errcode = '22023';
  end if;

  v_otro := case when v_actor = v_pedido.buyer_id
                 then v_pedido.seller_id else v_pedido.buyer_id end;

  insert into public.mensajes_pedido (order_id, autor_id, cuerpo)
  values (p_order_id, v_actor, v_texto)
  returning * into v_mensaje;

  -- Un aviso por rafaga, no uno por mensaje. Si ya hay algo mio sin leer, la
  -- otra persona ya fue avisada y todavia no ha mirado: repetirselo cinco
  -- veces mientras escribo cinco lineas solo consigue que silencie la
  -- aplicacion entera.
  select count(*) into v_pendiente
    from public.mensajes_pedido m
   where m.order_id = p_order_id
     and m.autor_id = v_actor
     and m.leido_en is null
     and m.id <> v_mensaje.id;

  if v_pendiente = 0 then
    insert into public.notifications (user_id, type, title, body, order_id)
    values (
      v_otro,
      'mensaje_pedido',
      'Mensaje sobre tu pedido',
      -- Se recorta: la notificacion es un aviso, no el mensaje.
      left(v_texto, 80) || case when length(v_texto) > 80 then '…' else '' end,
      p_order_id
    );
  end if;

  return v_mensaje;
end;
$$;

revoke all on function public.enviar_mensaje(uuid, text) from public;
grant execute on function public.enviar_mensaje(uuid, text) to authenticated;

-- ----------------------------------------------------------------------------
-- Marcar leido
-- ----------------------------------------------------------------------------
-- Solo lo del otro: marcar lo propio no significa nada.
create or replace function public.marcar_mensajes_leidos(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
begin
  update public.mensajes_pedido m
     set leido_en = now()
   where m.order_id = p_order_id
     and m.autor_id <> v_actor
     and m.leido_en is null
     and exists (
       select 1 from public.orders o
        where o.id = p_order_id
          and (o.buyer_id = v_actor or o.seller_id = v_actor)
     );
end;
$$;

revoke all on function public.marcar_mensajes_leidos(uuid) from public;
grant execute on function public.marcar_mensajes_leidos(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- Cuantos sin leer
-- ----------------------------------------------------------------------------
-- Por pedido, para pintar el distintivo en la lista sin traerse los mensajes.
create or replace function public.mensajes_sin_leer()
returns table (order_id uuid, sin_leer bigint)
language sql
stable
security definer
set search_path = public
as $$
  select m.order_id, count(*)
    from public.mensajes_pedido m
    join public.orders o on o.id = m.order_id
   where m.leido_en is null
     and m.autor_id <> auth.uid()
     and (o.buyer_id = auth.uid() or o.seller_id = auth.uid())
     and o.status in ('aceptado', 'por_confirmar')
   group by m.order_id;
$$;

revoke all on function public.mensajes_sin_leer() from public;
grant execute on function public.mensajes_sin_leer() to authenticated;

-- ----------------------------------------------------------------------------
-- El hilo, con el nombre de quien escribe
-- ----------------------------------------------------------------------------
-- La RLS de `profiles` solo deja leer la fila propia, asi que un join normal
-- devolveria vacio el nombre del otro. Corre como owner y expone unicamente
-- nombre y avatar: el WhatsApp sigue saliendo solo por get_contacto_pedido().
create or replace function public.leer_chat(p_order_id uuid)
returns table (
  id           uuid,
  autor_id     uuid,
  autor_nombre text,
  autor_avatar text,
  mio          boolean,
  cuerpo       text,
  creado_en    timestamptz,
  leido_en     timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
begin
  if not exists (
    select 1 from public.orders o
     where o.id = p_order_id
       and (o.buyer_id = v_actor or o.seller_id = v_actor)
       and o.status in ('aceptado', 'por_confirmar')
  ) then
    raise exception 'CHAT_CERRADO' using errcode = '42501';
  end if;

  return query
    select m.id,
           m.autor_id,
           p.full_name,
           p.avatar_path,
           m.autor_id = v_actor,
           m.cuerpo,
           m.creado_en,
           m.leido_en
      from public.mensajes_pedido m
      join public.profiles p on p.id = m.autor_id
     where m.order_id = p_order_id
     order by m.creado_en;
end;
$$;

revoke all on function public.leer_chat(uuid) from public;
grant execute on function public.leer_chat(uuid) to authenticated;
