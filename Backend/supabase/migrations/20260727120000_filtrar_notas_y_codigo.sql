-- ============================================================================
-- 25 · Filtrar tambien las notas del pedido, y validar el codigo de estudiante
-- ============================================================================
-- 1. El filtro solo miraba productos y locales. El punto de encuentro y la
--    nota del comprador son texto libre que la otra parte SI lee, asi que
--    era la via abierta para insultar ("en tu culo lucas").
--
-- 2. El codigo institucional no es cualquier secuencia de 10 digitos: son
--    4 del año, 2 del periodo (11 = primer semestre, 12 = segundo) y 4
--    correlativos. Aceptar cualquier numero permitia inventarse cuentas.
-- ============================================================================

create or replace function public.validar_contenido_pedido()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_termino text;
begin
  v_termino := public.termino_ofensivo(
    coalesce(new.meeting_point_note, '') || ' ' || coalesce(new.buyer_note, '')
  );

  if v_termino is not null then
    raise exception 'CONTENIDO_NO_PERMITIDO: revisa el texto de tu pedido'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

create trigger validar_contenido_del_pedido
  before insert or update of meeting_point_note, buyer_note on public.orders
  for each row execute function public.validar_contenido_pedido();

-- ----------------------------------------------------------------------------
-- Formato real del codigo: a + año(4) + periodo(11|12) + correlativo(4)
-- ----------------------------------------------------------------------------
alter table public.profiles drop constraint profiles_student_code_formato;
alter table public.profiles add constraint profiles_student_code_formato
  check (student_code is null or student_code ~ '^a\d{4}(11|12)\d{4}$');

-- El trigger de alta usa el mismo patron: un correo que no lo cumpla entra
-- sin codigo en vez de guardar uno invalido.
create or replace function public.crear_perfil_de_usuario_nuevo()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_local  text;
  v_codigo text;
begin
  v_local := split_part(new.email, '@', 1);

  v_codigo := case
                when v_local ~ '^a\d{4}(11|12)\d{4}$' then v_local
                else null
              end;

  insert into public.profiles (id, email, student_code, full_name, avatar_emoji)
  values (
    new.id,
    new.email,
    v_codigo,
    public.normalizar_nombre(
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        nullif(trim(new.raw_user_meta_data->>'name'), ''),
        v_local
      )
    ),
    '🎓'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;
