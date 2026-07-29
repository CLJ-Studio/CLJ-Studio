-- ============================================================================
-- 32 · Que las notificaciones lleguen con destino de verdad
-- ============================================================================
-- El frontend ya sabe navegar a partir de store_id/product_id, pero dos
-- piezas del lado del servidor nunca llegaron a completarse cuando se
-- anadieron esas columnas:
--
-- 1. `notificar_nuevo_local()` es de ANTES de que `notifications` tuviera
--    store_id. Nunca se actualizo, asi que cada "Nuevo local en el campus"
--    nace sin saber de que local habla: ni la app ni el push tienen a donde
--    llevar a quien la toca.
--
-- 2. `disparar_push()` solo reenviaba order_id al pasar el aviso a la Edge
--    Function. Aunque la notificacion en la base ya tuviera store_id o
--    product_id, esos dos datos nunca cruzaban hacia el push.
-- ============================================================================

create or replace function public.notificar_nuevo_local()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_personal or not new.is_active then
    return new;
  end if;
  if tg_op = 'UPDATE' and not old.is_personal then
    return new;
  end if;

  insert into public.notifications (user_id, type, title, body, store_id)
  select p.id,
         'nuevo_local',
         'Nuevo local en el campus',
         new.emoji || ' ' || new.name || ' acaba de abrir. ¡Dale un vistazo!',
         new.id
    from public.profiles p
   where p.id <> new.owner_id
     and p.onboarding_completed;

  return new;
end;
$$;

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
    return new;
  end if;

  perform net.http_post(
    url     := v_config.url_funcion,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_config.clave_servicio
    ),
    body    := jsonb_build_object(
      'user_id',    new.user_id,
      'title',      new.title,
      'body',       new.body,
      'order_id',   new.order_id,
      'store_id',   new.store_id,
      'product_id', new.product_id
    )
  );

  return new;
end;
$$;
