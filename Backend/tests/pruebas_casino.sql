-- ============================================================================
-- PRUEBAS · fichas infladas no dan ventaja en la mesa de poker
--
-- La billetera del casino confia en lo que manda el telefono (la ruleta, el
-- blackjack y la pesca se juegan en el telefono, tambien sin red). Cualquiera
-- que llame a casino_sincronizar a mano puede inflar su numero. Eso se acepta
-- mientras no haya ranking de fichas: lo que importa es que en la mesa,
-- contra otras personas, nadie se siente con mas que los demas.
--
-- Si algun dia se muestra un ranking de fichas, esto deja de alcanzar: los
-- juegos del telefono tendrian que resolverse en el servidor.
--
-- COMO EJECUTAR: python Backend/tests/correr_pruebas.py (corre todos los
-- pruebas_*.sql). Todo va dentro de una transaccion que se revierte.
-- ============================================================================

begin;

do $$
declare
  v_tramposo uuid := gen_random_uuid();
  v_sala     uuid;
  v_fichas   bigint;
  v_mesa     integer;
begin
  raise notice '';
  raise notice '=== CASINO: FICHAS INFLADAS ===';

  insert into auth.users (id, email, raw_user_meta_data, instance_id,
                          aud, role, created_at, updated_at)
  values (v_tramposo, 'a2020000201@estudiantes.upsa.edu.bo', '{"full_name":"Tramposo"}',
          '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', now(), now());
  update public.profiles
     set full_name = 'Tramposo', whatsapp = '59170000201',
         career_id = (select id from public.careers order by id limit 1),
         onboarding_completed = true
   where id = v_tramposo;

  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_tramposo::text)::text, true);
  perform set_config('role', 'authenticated', true);

  -- Se inventa un billon de fichas llamando a la funcion a mano.
  perform public.casino_sincronizar(gen_random_uuid(), 1000000000000);
  select fichas into v_fichas from public.casino_billeteras where usuario_id = v_tramposo;
  if v_fichas < 1000000000000 then
    raise exception 'FALLO: la prueba supone una billetera inflada y tiene %', v_fichas;
  end if;
  raise notice '  ..   La billetera se puede inflar (conocido): %', v_fichas;

  -- En la mesa mas cara (100/200) no puede sentarse con mas de 100 ciegas.
  begin
    perform public.poker_crear_sala('Mesa de prueba', 200, 20001);
    raise exception 'FALLO: se sento con mas de 100 ciegas grandes';
  exception when others then
    if position('COMPRA_INVALIDA' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice '  OK   Con fichas infladas no se sienta con mas de 100 ciegas';

  v_sala := public.poker_crear_sala('Mesa de prueba', 200, 20000);
  select fichas into v_mesa from public.poker_asientos where usuario_id = v_tramposo;
  if v_mesa <> 20000 then
    raise exception 'FALLO: se sento con % y no con 20000', v_mesa;
  end if;

  -- Con fichas en la mesa no puede recargar para agrandar su pila.
  perform public.poker_recargar(v_sala, 20000);
  select fichas into v_mesa from public.poker_asientos where usuario_id = v_tramposo;
  if v_mesa <> 20000 then
    raise exception 'FALLO: recargo con fichas en la mesa y quedo con %', v_mesa;
  end if;
  raise notice '  OK   Con fichas en la mesa no puede recargar';

  -- Sin fichas en la mesa recarga, pero con el mismo tope.
  perform set_config('role', 'postgres', true);
  update public.poker_asientos set fichas = 0 where usuario_id = v_tramposo;
  perform set_config('role', 'authenticated', true);
  begin
    perform public.poker_recargar(v_sala, 20001);
    raise exception 'FALLO: recargo con mas de 100 ciegas grandes';
  exception when others then
    if position('COMPRA_INVALIDA' in sqlerrm) = 0 then raise; end if;
  end;
  raise notice '  OK   La recarga tiene el mismo tope';

  -- Y nadie mueve fichas de otro ni escribe directo en la billetera.
  begin
    update public.casino_billeteras set fichas = 5 where usuario_id = v_tramposo;
    raise exception 'FALLO: escribio directo en la billetera';
  exception when insufficient_privilege then
    null;
  end;
  begin
    perform public.casino_mover(v_tramposo, 1, 'a mano');
    raise exception 'FALLO: llamo a casino_mover desde afuera';
  exception when insufficient_privilege then
    null;
  end;
  raise notice '  OK   Nadie escribe la billetera ni mueve fichas por su cuenta';

  perform set_config('role', 'postgres', true);
end;
$$;

rollback;
