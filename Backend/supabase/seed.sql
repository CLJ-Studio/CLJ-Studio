-- ============================================================================
-- SEED · datos de referencia + demo
-- ============================================================================
-- Replica los mocks del frontend (CategoriasPrueba, LocalesPrueba,
-- ProductosPrueba) para que al conectar Supabase la app se vea IGUAL.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Dominios institucionales · reemplaza al valor quemado en el cliente
-- ----------------------------------------------------------------------------
insert into public.institutional_domains (domain, label) values
  ('estudiantes.upsa.edu.bo', 'Estudiantes UPSA'),
  ('upsa.edu.bo',             'Docentes y staff UPSA')
on conflict (domain) do nothing;

-- ----------------------------------------------------------------------------
-- Categorias · CategoriasPrueba + 'libros'
-- OJO: el mock de categorias NO incluia 'libros', pero LocalesPrueba usa
-- categoriaId 'libros' (Libreria UPSA). Se agrega para que el filtro no
-- deje ese local huerfano.
-- 'todas' NO va en la base: es un filtro de UI, no una categoria real.
-- ----------------------------------------------------------------------------
insert into public.categories (id, name, icon_name, sort_order) values
  ('comida',     'Comida',              'lunch_dining_rounded', 1),
  ('tecnologia', 'Tecnologia',          'devices_rounded',      2),
  ('servicios',  'Servicios',           'handyman_rounded',     3),
  ('libros',     'Libros y papeleria',  'menu_book_rounded',    4)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- Puntos de encuentro seguros dentro del campus
-- (El frontend aun no tiene selector; queda listo para el modulo de pedidos.)
-- ----------------------------------------------------------------------------
insert into public.campus_locations (name, description, sort_order) values
  ('Bloque A - Recepcion',   'Entrada principal, siempre con personal',   1),
  ('Patio central',          'Zona abierta y concurrida',                 2),
  ('Cafeteria - Mesas',      'Area de mesas junto a la cafeteria',        3),
  ('Biblioteca - Ingreso',   'Puerta principal de la biblioteca',         4),
  ('Parqueo estudiantes',    'Solo en horario diurno',                    5)
on conflict do nothing;

-- ============================================================================
-- DEMO · locales y productos de LocalesPrueba / ProductosPrueba
-- ============================================================================
-- Requiere un usuario real: stores.owner_id apunta a profiles(id), que a su
-- vez apunta a auth.users. Por eso este bloque se salta solo si todavia no
-- hay ningun usuario registrado.
--
-- Para cargarlo: inicia sesion una vez con Google en la app y vuelve a
-- ejecutar este seed.
-- ============================================================================
do $$
declare
  v_owner uuid;
  v_cafeteria uuid;
  v_snack     uuid;
  v_tech      uuid;
  v_libreria  uuid;
  v_servicios uuid;
begin
  select id into v_owner from public.profiles order by created_at limit 1;

  if v_owner is null then
    raise notice 'SEED DEMO OMITIDO: registra un usuario y vuelve a correr el seed.';
    return;
  end if;

  -- Un unico dueno demo: el indice stores_un_local_por_dueno solo permite un
  -- local activo por persona, asi que los demas quedan is_active = false y
  -- sirven para poblar el feed visualmente.
  insert into public.stores (
    owner_id, name, description, category_id, emoji, color_hex,
    estimated_time, delivery_cost, is_open, is_active
  ) values
    (v_owner, 'Cafeteria Central', 'Desayunos, almuerzos y cafe para recargar energias.',
     'comida', '☕', 4294962902, '15–25 min', 3.0, true, true)
  returning id into v_cafeteria;

  insert into public.stores (
    owner_id, name, description, category_id, emoji, color_hex,
    estimated_time, delivery_cost, is_open, is_active
  ) values
    (v_owner, 'Snack Universitario', 'Opciones rapidas entre clases y bebidas frias.',
     'comida', '🥪', 4293458920, '10–20 min', 2.5, true, false),
    (v_owner, 'Tech Campus', 'Accesorios y soluciones para tus dispositivos.',
     'tecnologia', '💻', 4293389311, '20–35 min', 4.0, true, false),
    (v_owner, 'Libreria UPSA', 'Material de estudio, apuntes y articulos de escritorio.',
     'libros', '📚', 4294964671, '15–30 min', 3.5, false, false),
    (v_owner, 'Servicios Estudiantiles', 'Impresiones, diseño y apoyo para tus proyectos.',
     'servicios', '🖨️', 4294178559, '30–45 min', 0, true, false);

  select id into v_snack     from public.stores where name = 'Snack Universitario'     and owner_id = v_owner;
  select id into v_tech      from public.stores where name = 'Tech Campus'             and owner_id = v_owner;
  select id into v_libreria  from public.stores where name = 'Libreria UPSA'           and owner_id = v_owner;
  select id into v_servicios from public.stores where name = 'Servicios Estudiantiles' and owner_id = v_owner;

  -- Productos de ProductosPrueba (con stock, que el mock no tenia).
  insert into public.products (store_id, name, description, price, emoji, stock, kind) values
    (v_cafeteria, 'Cafe americano',         'Cafe recien preparado, 300 ml.',    12, '☕', 50, 'producto'),
    (v_cafeteria, 'Sandwich universitario', 'Jamon, queso y vegetales frescos.', 22, '🥪', 20, 'producto'),
    (v_snack,     'Jugo natural',           'Fruta de temporada, sin conservantes.', 15, '🥤', 30, 'producto'),
    (v_tech,      'Cable USB-C',            'Cable reforzado de carga y datos.', 45, '🔌', 12, 'producto'),
    (v_libreria,  'Cuaderno universitario', '100 hojas cuadriculadas.',          28, '📓', 40, 'producto'),
    (v_servicios, 'Impresion a color',      'Por hoja, papel bond A4.',           2, '🖨️',  0, 'servicio');

  raise notice 'SEED DEMO CARGADO para el usuario %', v_owner;
end;
$$;
