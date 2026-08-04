-- Rankings diarios: una vista por persona, elemento y dia de Bolivia.

alter table public.product_views
  add column if not exists viewed_on date not null
  default ((timezone('America/La_Paz', now()))::date);

alter table public.store_views
  add column if not exists viewed_on date not null
  default ((timezone('America/La_Paz', now()))::date);

-- Conserva la fecha real de las vistas que ya existian antes de esta mejora,
-- en vez de hacer que todo el historial parezca ocurrido el dia del despliegue.
update public.product_views
set viewed_on = (timezone('America/La_Paz', created_at))::date;
update public.store_views
set viewed_on = (timezone('America/La_Paz', created_at))::date;

alter table public.product_views drop constraint if exists product_views_pkey;
alter table public.store_views drop constraint if exists store_views_pkey;
alter table public.product_views
  add constraint product_views_pkey primary key (product_id, user_id, viewed_on);
alter table public.store_views
  add constraint store_views_pkey primary key (store_id, user_id, viewed_on);

create index if not exists product_views_daily_ranking
  on public.product_views (viewed_on, product_id);
create index if not exists store_views_daily_ranking
  on public.store_views (viewed_on, store_id);

create or replace function public.registrar_vista_producto(p_producto uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_hoy date := (timezone('America/La_Paz', now()))::date;
  v_total bigint;
begin
  if v_actor is not null and not exists (
    select 1 from public.products p
    join public.stores s on s.id = p.store_id
    where p.id = p_producto and s.owner_id = v_actor
  ) then
    insert into public.product_views (product_id, user_id, viewed_on)
    values (p_producto, v_actor, v_hoy)
    on conflict do nothing;
  end if;

  select count(*) into v_total from public.product_views
  where product_id = p_producto and viewed_on = v_hoy;
  return v_total;
end;
$$;

create or replace function public.registrar_vista_local(p_local uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_hoy date := (timezone('America/La_Paz', now()))::date;
  v_total bigint;
begin
  if v_actor is not null and not exists (
    select 1 from public.stores where id = p_local and owner_id = v_actor
  ) then
    insert into public.store_views (store_id, user_id, viewed_on)
    select p_local, v_actor, v_hoy
    where exists (
      select 1 from public.stores
      where id = p_local and is_active and not is_personal
    )
    on conflict do nothing;
  end if;

  select count(*) into v_total from public.store_views
  where store_id = p_local and viewed_on = v_hoy;
  return v_total;
end;
$$;

create or replace function public.productos_populares_hoy(p_limite integer default 20)
returns table (id uuid, vistas bigint)
language sql
stable
security definer
set search_path = public
as $$
  select pv.product_id, count(*)::bigint
  from public.product_views pv
  join public.products p on p.id = pv.product_id
  join public.stores s on s.id = p.store_id
  where pv.viewed_on = (timezone('America/La_Paz', now()))::date
    and p.is_available and s.is_active
  group by pv.product_id
  order by count(*) desc, pv.product_id
  limit greatest(0, least(coalesce(p_limite, 20), 100));
$$;

create or replace function public.locales_mas_vistos_hoy(p_limite integer default 20)
returns table (id uuid, vistas bigint)
language sql
stable
security definer
set search_path = public
as $$
  select sv.store_id, count(*)::bigint
  from public.store_views sv
  join public.stores s on s.id = sv.store_id
  where sv.viewed_on = (timezone('America/La_Paz', now()))::date
    and s.is_active and not s.is_personal
  group by sv.store_id
  order by count(*) desc, sv.store_id
  limit greatest(0, least(coalesce(p_limite, 20), 100));
$$;

revoke all on function public.registrar_vista_producto(uuid) from public;
revoke all on function public.registrar_vista_local(uuid) from public;
revoke all on function public.productos_populares_hoy(integer) from public;
revoke all on function public.locales_mas_vistos_hoy(integer) from public;
grant execute on function public.registrar_vista_producto(uuid) to authenticated;
grant execute on function public.registrar_vista_local(uuid) to authenticated;
grant execute on function public.productos_populares_hoy(integer) to authenticated;
grant execute on function public.locales_mas_vistos_hoy(integer) to authenticated;
