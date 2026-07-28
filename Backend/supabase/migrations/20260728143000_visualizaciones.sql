alter table public.stores
  add column if not exists view_count bigint not null default 0;

alter table public.products
  add column if not exists view_count bigint not null default 0;

create or replace function public.registrar_vista_producto(p_producto uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  total bigint;
begin
  update public.products p
     set view_count = p.view_count + 1
    from public.stores s
   where p.id = p_producto
     and s.id = p.store_id
     and s.owner_id <> auth.uid()
  returning p.view_count into total;

  if total is null then
    select view_count into total from public.products where id = p_producto;
  end if;
  return coalesce(total, 0);
end;
$$;

create or replace function public.registrar_vista_local(p_local uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  total bigint;
begin
  update public.stores
     set view_count = view_count + 1
   where id = p_local
     and owner_id <> auth.uid()
     and is_active
  returning view_count into total;

  if total is null then
    select view_count into total from public.stores where id = p_local;
  end if;
  return coalesce(total, 0);
end;
$$;

grant execute on function public.registrar_vista_producto(uuid) to authenticated;
grant execute on function public.registrar_vista_local(uuid) to authenticated;

create or replace view public.locales_publicos
with (security_invoker = off) as
  select
    s.id, s.name, s.description, s.category_id, s.emoji, s.color_hex,
    s.estimated_time, s.delivery_cost, s.is_open, s.rating_average,
    s.is_personal, s.logo_path, s.owner_id,
    c.name as categoria_nombre,
    p.full_name as vendedor_nombre,
    p.avatar_path as vendedor_avatar,
    (
      select pr.image_path
        from public.products pr
       where pr.store_id = s.id
         and pr.image_path is not null
         and pr.is_available
       order by pr.bumped_at desc
       limit 1
    ) as portada_path,
    s.view_count
  from public.stores s
  join public.profiles p on p.id = s.owner_id
  left join public.categories c on c.id = s.category_id
 where s.is_active;

grant select on public.locales_publicos to authenticated;
