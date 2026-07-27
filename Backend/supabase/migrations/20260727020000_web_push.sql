-- ============================================================================
-- 15 · Web Push: suscripciones y disparo automatico
-- ============================================================================
-- Las notificaciones in-app solo se ven con la app abierta. Para que el
-- telefono suene con la app cerrada hace falta el estandar Web Push: el
-- navegador registra una suscripcion (endpoint + claves de cifrado) y el
-- servidor le envia mensajes a traves de ella.
--
-- El envio NO puede hacerse desde SQL: Web Push exige firmar un JWT ES256 y
-- cifrar el contenido (AES128GCM). Eso vive en la Edge Function `enviar-push`;
-- aqui solo se guarda la suscripcion y se dispara la llamada.
-- ============================================================================

create table public.push_subscriptions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  -- URL unica que el navegador entrega; identifica al dispositivo.
  endpoint   text not null unique,
  p256dh     text not null,
  auth       text not null,
  created_at timestamptz not null default now()
);

create index push_subscriptions_usuario_idx on public.push_subscriptions(user_id);

alter table public.push_subscriptions enable row level security;

create policy suscripciones_propias on public.push_subscriptions
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, delete on public.push_subscriptions to authenticated;

-- ----------------------------------------------------------------------------
-- pg_net permite hacer peticiones HTTP desde Postgres sin bloquear la
-- transaccion que las origina: el pedido se acepta al instante y el envio
-- del push viaja aparte.
-- ----------------------------------------------------------------------------
create extension if not exists pg_net with schema extensions;

-- Configuracion del proyecto, leida por el trigger. Se guarda en una tabla
-- (y no en el codigo) para no incrustar la clave de servicio en una funcion.
create table public.configuracion_push (
  id                 boolean primary key default true,
  url_funcion        text not null,
  clave_servicio     text not null,
  constraint configuracion_push_fila_unica check (id)
);

alter table public.configuracion_push enable row level security;
-- Sin policies: nadie la lee desde el cliente. Solo el trigger, que corre
-- como owner y por tanto ignora RLS.

-- ----------------------------------------------------------------------------
-- Cada notificacion nueva dispara el envio push al dueno del aviso.
-- ----------------------------------------------------------------------------
create or replace function public.disparar_push()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_config public.configuracion_push%rowtype;
begin
  select * into v_config from public.configuracion_push limit 1;
  if not found then
    return new;  -- push no configurado: la app sigue funcionando igual
  end if;

  perform net.http_post(
    url     := v_config.url_funcion,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_config.clave_servicio
    ),
    body    := jsonb_build_object(
      'user_id',  new.user_id,
      'title',    new.title,
      'body',     new.body,
      'order_id', new.order_id
    )
  );

  return new;
end;
$$;

create trigger enviar_push_al_notificar
  after insert on public.notifications
  for each row execute function public.disparar_push();
