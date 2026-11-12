-- ============================================================================
-- Devolver el stock de TODAS las lineas de un producto
--
-- restituir_stock hacia un UPDATE ... FROM order_items. Cuando un pedido
-- tiene dos lineas del mismo producto (dos sabores, desde las variantes de
-- septiembre), Postgres actualiza la fila del producto UNA sola vez, con una
-- de las lineas, la que caiga: la cantidad de la otra se perdia. Un pedido
-- aceptado de 2 empanadas de queso y 3 de carne, al cancelarse, devolvia 2 o
-- 3 en vez de 5. Al vendedor se le iba stock que nunca vendio, y pasa igual
-- al cancelar el comprador, el vendedor o al cerrar el local.
--
-- Ahora se suma por producto antes de devolver. Lo encontro la prueba 12 de
-- Backend/tests/pruebas_logica_pedidos.sql.
--
-- No repone lo que ya se perdio: no queda registro de cuanto fue. Quien vende
-- lo corrige editando el stock de su publicacion.
-- ============================================================================

create or replace function public.restituir_stock(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products p
     set stock = p.stock + lineas.cantidad
    from (
      select product_id, sum(quantity) as cantidad
        from public.order_items
       where order_id = p_order_id
       group by product_id
    ) lineas
   where lineas.product_id = p.id
     and p.kind = 'producto';
end;
$$;

-- Helper interno, como antes: lo llaman cancelar_pedido y cerrar_local.
revoke all on function public.restituir_stock(uuid) from public;
