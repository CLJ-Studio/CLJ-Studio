-- ============================================================================
-- 22 · El filtro tambien detecta el plural
-- ============================================================================
-- La comparacion por palabra completa exigia coincidencia exacta, asi que
-- "putas empanadas" pasaba limpio teniendo "puta" en la lista. Mantener las
-- dos formas de cada termino seria duplicar y olvidar la mitad: se acepta
-- una "s" final opcional en la propia expresion.
-- ============================================================================

create or replace function public.termino_ofensivo(p_texto text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with normalizado as (
    select public.normalizar_para_filtro(p_texto) as texto
  )
  select t.termino
    from public.terminos_bloqueados t, normalizado n
   where case
           when t.estricto
             then n.texto like '%' || public.normalizar_para_filtro(t.termino) || '%'
           else
             -- \m y \M son los limites de palabra; la "s?" cubre el plural.
             n.texto ~ ('\m' || public.normalizar_para_filtro(t.termino) || 's?\M')
         end
   limit 1;
$$;
