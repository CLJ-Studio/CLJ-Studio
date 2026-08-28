-- ============================================================================
-- 47 · Los chats cerrados, para quien modera
-- ============================================================================
-- El chat ya se cierra solo y se guarda entero. Lo que faltaba era la otra
-- mitad: poder leerlo despues.
--
-- COMO ESTABA
--   `mensajes_lectura` exige que el pedido siga en 'aceptado' o
--   'por_confirmar'. Al confirmarse la entrega el hilo deja de ser legible
--   para los dos participantes, que es lo que se queria: la bandeja no se
--   llena de conversaciones muertas.
--
--   Pero esa policy no tenia excepcion para nadie, asi que un chat cerrado no
--   lo podia leer NI un administrador. Guardado y a la vez inalcanzable, que
--   para una disputa es lo mismo que no tenerlo.
--
-- LO QUE NO SE HACE
--   No se toca la policy. Abrirla a los administradores dejaria que leyeran
--   cualquier conversacion EN CURSO desde la propia aplicacion, sin dejar
--   rastro. Las funciones de abajo son la unica puerta, exigen ser
--   administrador y hay que pedir un pedido concreto.
--
-- QUE SIGNIFICA ESTO PARA QUIEN ESCRIBE
--   Que la conversacion no es secreta: se conserva y alguien puede leerla si
--   hay un problema con ese pedido. La aplicacion lo dice en el chat, porque
--   dejar creer que es privado seria mentir.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Buscar una conversacion
-- ----------------------------------------------------------------------------
-- Devuelve las conversaciones que TIENEN mensajes, cerradas o no, con los dos
-- nombres para poder encontrarla sin saberse el id del pedido de memoria.
create or replace function public.listar_chats_moderacion(
  p_limite integer default 50
)
returns table (
  order_id     uuid,
  estado       text,
  comprador    text,
  vendedor     text,
  local        text,
  mensajes     bigint,
  primero_en   timestamptz,
  ultimo_en    timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.soy_administrador() then
    raise exception 'SOLO_ADMINISTRADORES' using errcode = '42501';
  end if;

  return query
    select o.id,
           o.status::text,
           comprador.full_name,
           vendedor.full_name,
           s.name,
           count(m.id),
           min(m.creado_en),
           max(m.creado_en)
      from public.orders o
      join public.mensajes_pedido m on m.order_id = o.id
      join public.stores   s         on s.id = o.store_id
      join public.profiles comprador on comprador.id = o.buyer_id
      join public.profiles vendedor  on vendedor.id  = o.seller_id
     group by o.id, o.status, comprador.full_name, vendedor.full_name, s.name
     order by max(m.creado_en) desc
     limit greatest(p_limite, 1);
end;
$$;

revoke all on function public.listar_chats_moderacion(integer) from public;
grant execute on function public.listar_chats_moderacion(integer) to authenticated;

-- ----------------------------------------------------------------------------
-- Leer una conversacion entera
-- ----------------------------------------------------------------------------
-- Igual que `leer_chat()` pero sin la condicion del estado: aqui el sentido es
-- justamente poder ver lo que ya se cerro.
create or replace function public.leer_chat_moderacion(p_order_id uuid)
returns table (
  autor_id     uuid,
  autor        text,
  es_vendedor  boolean,
  cuerpo       text,
  creado_en    timestamptz,
  leido_en     timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.soy_administrador() then
    raise exception 'SOLO_ADMINISTRADORES' using errcode = '42501';
  end if;

  return query
    select m.autor_id,
           p.full_name,
           m.autor_id = o.seller_id,
           m.cuerpo,
           m.creado_en,
           m.leido_en
      from public.mensajes_pedido m
      join public.orders   o on o.id = m.order_id
      join public.profiles p on p.id = m.autor_id
     where m.order_id = p_order_id
     order by m.creado_en;
end;
$$;

revoke all on function public.leer_chat_moderacion(uuid) from public;
grant execute on function public.leer_chat_moderacion(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- Como se usa desde el editor SQL
-- ----------------------------------------------------------------------------
--   -- Las ultimas conversaciones con mensajes:
--   select * from public.listar_chats_moderacion(50);
--
--   -- Una conversacion entera, con el id que salga de la anterior:
--   select * from public.leer_chat_moderacion('pega-aqui-el-order_id');
--
-- Desde el editor SQL las funciones corren como owner y `soy_administrador()`
-- devuelve falso porque no hay sesion. Para consultarlas ahi, se lee la tabla
-- directo:
--
--   select p.full_name, m.cuerpo, m.creado_en
--     from public.mensajes_pedido m
--     join public.profiles p on p.id = m.autor_id
--    where m.order_id = 'pega-aqui-el-order_id'
--    order by m.creado_en;
--
-- Las funciones son para cuando exista el panel dentro de la aplicacion.
-- ----------------------------------------------------------------------------
