-- ============================================================================
-- 14b · Notificar a la comunidad cuando abre un local
-- ============================================================================
-- Dispara cuando nace un local FORMAL o cuando un espacio personal se
-- convierte en uno. Los espacios personales no anuncian nada: se crean por
-- detras al publicar y avisarian ruido sin valor.
--
-- El INSERT masivo es aceptable a escala de campus (cientos de perfiles);
-- si la comunidad creciera a decenas de miles, esto pasaria a un fan-out
-- diferido en Edge Functions.
-- ============================================================================

create or replace function public.notificar_nuevo_local()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Solo locales formales: al insertarse como tal, o al convertirse.
  if new.is_personal or not new.is_active then
    return new;
  end if;
  if tg_op = 'UPDATE' and not old.is_personal then
    return new;  -- ya era formal: una edicion normal no se anuncia
  end if;

  insert into public.notifications (user_id, type, title, body)
  select p.id,
         'nuevo_local',
         'Nuevo local en el campus',
         new.emoji || ' ' || new.name || ' acaba de abrir. ¡Dale un vistazo!'
    from public.profiles p
   where p.id <> new.owner_id
     and p.onboarding_completed;

  return new;
end;
$$;

create trigger notificar_local_nuevo
  after insert or update of is_personal on public.stores
  for each row execute function public.notificar_nuevo_local();

-- La app solo debe poder marcar como leida, no reescribir el contenido.
revoke update on public.notifications from authenticated;
grant update (read_at) on public.notifications to authenticated;
