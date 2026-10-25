-- ============================================================================
-- 60 · La insignia de egresado verificado, en todos lados
-- ============================================================================
-- Los egresados que verifico un admin (56) llevan una insignia dorada junto
-- al nombre, como la de Instagram, donde sea que aparezca: el buscador, su
-- perfil, sus locales, los pedidos, el chat, el directorio y el poker. Para
-- eso las vistas publicas tienen que decir quien es egresado:
--
--   perfiles_publicos  -> es_egresado
--   locales_publicos   -> vendedor_egresado
--   pedidos_detallados -> buyer_egresado y seller_egresado
--   poker_estado()     -> egresado, en cada asiento
--
-- Las vistas son las mismas de antes con una columna mas al final: "create
-- or replace view" no deja cambiar ni reordenar las que ya estan, y la app
-- lee por nombre. Mientras esta migracion no este aplicada, la app no
-- muestra la insignia y todo lo demas sigue igual.
--
-- Termina con pruebas dentro de la misma transaccion: si algo no da lo
-- esperado, no se aplica nada.
-- ============================================================================

begin;

create or replace view public.perfiles_publicos
with (security_invoker = off) as
  select p.id,
         p.full_name,
         p.avatar_emoji,
         c.name as career,
         p.is_on_campus,
         p.rating_average,
         p.rating_count,
         p.avatar_path,
         p.show_view_count,
         p.show_favorites,
         p.bio,
         p.es_egresado
    from public.profiles p
    left join public.careers c on c.id = p.career_id;

grant select on public.perfiles_publicos to authenticated;

create or replace view public.locales_publicos
with (security_invoker = off) as
  select s.id,
         s.name,
         s.description,
         s.category_id,
         s.emoji,
         s.color_hex,
         s.estimated_time,
         s.delivery_cost,
         s.is_open,
         s.rating_average,
         s.is_personal,
         s.logo_path,
         s.owner_id,
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
         s.view_count,
         s.campus_location,
         s.location_updated_at,
         p.show_view_count as vendedor_muestra_vistas,
         p.es_egresado as vendedor_egresado
    from public.stores s
    join public.profiles p on p.id = s.owner_id
    left join public.categories c on c.id = s.category_id
   where s.is_active;

grant select on public.locales_publicos to authenticated;

create or replace view public.pedidos_detallados
with (security_invoker = off) as
  select o.id,
         o.status,
         o.buyer_id,
         o.seller_id,
         o.store_id,
         o.subtotal,
         o.delivery_cost,
         o.total,
         o.buyer_note,
         o.meeting_point_note,
         o.expires_at,
         o.accepted_at,
         o.resolved_at,
         o.created_at,
         s.name as store_name,
         s.emoji as store_emoji,
         comprador.full_name as buyer_name,
         vendedor.full_name as seller_name,
         punto.name as meeting_point_name,
         coalesce((
           select json_agg(json_build_object(
                    'id', oi.id,
                    'product_name', oi.product_name,
                    'product_emoji', oi.product_emoji,
                    'unit_price', oi.unit_price,
                    'quantity', oi.quantity,
                    'line_total', oi.line_total
                  ) order by oi.product_name)
             from public.order_items oi
            where oi.order_id = o.id
         ), '[]'::json) as items,
         o.delivered_marked_by,
         o.delivered_marked_at,
         o.confirmed_by,
         comprador.es_egresado as buyer_egresado,
         vendedor.es_egresado as seller_egresado
    from public.orders o
    join public.stores s on s.id = o.store_id
    join public.profiles comprador on comprador.id = o.buyer_id
    join public.profiles vendedor on vendedor.id = o.seller_id
    left join public.campus_locations punto on punto.id = o.meeting_point_id
   where o.buyer_id = auth.uid() or o.seller_id = auth.uid();

grant select on public.pedidos_detallados to authenticated;

-- La mesa de poker: la misma de la 59, con "egresado" en cada asiento.
create or replace function public.poker_estado(p_sala uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_mano public.poker_manos;
begin
  select * into v_mano
    from public.poker_manos where sala_id = p_sala order by numero desc limit 1;

  return jsonb_build_object(
    'ahora', now(),
    'sala', (select to_jsonb(s) from public.poker_salas s where s.id = p_sala),
    'yo', (select posicion from public.poker_asientos
            where sala_id = p_sala and usuario_id = auth.uid()),
    'asientos', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'posicion', a.posicion,
               'usuario_id', a.usuario_id,
               'nombre', p.full_name,
               'avatar_path', p.avatar_path,
               'fichas', a.fichas,
               'afuera', a.afuera,
               'egresado', p.es_egresado
             ) order by a.posicion), '[]')
        from public.poker_asientos a
        join public.profiles p on p.id = a.usuario_id
       where a.sala_id = p_sala
    ),
    'mano', case when v_mano.id is null then null else to_jsonb(v_mano) end,
    'jugadores', (
      select coalesce(jsonb_agg(to_jsonb(j) order by j.posicion), '[]')
        from public.poker_jugadores j
       where j.mano_id = v_mano.id
    ),
    'mis_cartas', (
      select to_jsonb(c.cartas)
        from public.poker_cartas c
       where c.mano_id = v_mano.id and c.usuario_id = auth.uid()
    )
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- Pruebas: si algo no da lo esperado, no se aplica nada
-- ----------------------------------------------------------------------------
do $$
declare
  v_egresado uuid := gen_random_uuid();
  v_carrera  text;
  v_categoria text;
  v_sala     uuid;
  v_estado   jsonb;
begin
  begin
    -- Las columnas nuevas, en cada vista.
    if not exists (select 1 from information_schema.columns
                    where table_name = 'perfiles_publicos' and column_name = 'es_egresado')
       or not exists (select 1 from information_schema.columns
                    where table_name = 'locales_publicos' and column_name = 'vendedor_egresado')
       or not exists (select 1 from information_schema.columns
                    where table_name = 'pedidos_detallados' and column_name = 'buyer_egresado')
       or not exists (select 1 from information_schema.columns
                    where table_name = 'pedidos_detallados' and column_name = 'seller_egresado')
    then
      raise exception 'falta alguna columna de egresado en las vistas';
    end if;

    insert into public.institutional_domains (domain, label)
    values ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA')
    on conflict (domain) do nothing;
    select id into v_carrera from public.careers where is_active
     order by sort_order limit 1;
    if v_carrera is null then
      insert into public.careers (id, name, faculty)
      values ('prueba_insignia', 'Prueba', 'Prueba') returning id into v_carrera;
    end if;
    select id into v_categoria from public.categories order by sort_order limit 1;
    if v_categoria is null then
      insert into public.categories (id, name, icon_name)
      values ('prueba_insignia', 'Prueba', 'storefront') returning id into v_categoria;
    end if;

    insert into auth.users (id, email)
    values (v_egresado, 'a2004219992@estudiantes.upsa.edu.bo');
    update public.profiles
       set full_name = 'Egresada Insignia', career_id = v_carrera,
           whatsapp = '59170000008', onboarding_completed = true,
           es_egresado = true
     where id = v_egresado;
    insert into public.stores (owner_id, name, description, category_id, is_personal)
    values (v_egresado, 'Local Insignia', 'Prueba', v_categoria, true);

    if not (select es_egresado from public.perfiles_publicos where id = v_egresado) then
      raise exception 'perfiles_publicos no dice que es egresada';
    end if;
    if not (select vendedor_egresado from public.locales_publicos
             where owner_id = v_egresado limit 1) then
      raise exception 'locales_publicos no dice que la vendedora es egresada';
    end if;

    perform set_config('request.jwt.claim.sub', v_egresado::text, true);
    v_sala := public.poker_crear_sala('Mesa insignia', 20);
    v_estado := public.poker_estado(v_sala);
    if (v_estado -> 'asientos' -> 0 ->> 'egresado')::boolean is not true then
      raise exception 'el poker no dice que la del asiento es egresada: %',
        v_estado -> 'asientos';
    end if;

    raise exception 'PRUEBAS_OK';
  exception when raise_exception then
    if sqlerrm <> 'PRUEBAS_OK' then
      raise exception 'No se aplico nada. %', sqlerrm;
    end if;
  end;

  if exists (select 1 from auth.users where id = v_egresado) then
    raise exception 'quedaron datos de prueba';
  end if;

  raise notice 'Insignia de egresado probada: todo bien.';
end $$;

commit;
