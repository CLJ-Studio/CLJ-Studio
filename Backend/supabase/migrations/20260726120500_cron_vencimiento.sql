-- ============================================================================
-- 06 · Vencimiento automatico de pedidos (pg_cron)
-- ============================================================================
-- REQUISITO PREVIO: habilitar la extension pg_cron en el dashboard
--   Database -> Extensions -> buscar "pg_cron" -> Enable
-- Si no esta habilitada, esta migracion falla con "extension pg_cron is not
-- available". Habilitala y vuelve a correr.
--
-- Sin esto, un pedido que el vendedor nunca responde deja al comprador
-- esperando indefinidamente en PantallaContactandoVendedor.
-- ============================================================================

create extension if not exists pg_cron;

-- Cada minuto: marca 'vencido' todo pedido 'solicitado' cuya ventana expiro.
select cron.schedule(
  'vencer-pedidos-pendientes',
  '* * * * *',
  $$ select public.vencer_pedidos_pendientes(); $$
);

-- Para desprogramarlo:
--   select cron.unschedule('vencer-pedidos-pendientes');
-- Para ver el historial:
--   select * from cron.job_run_details order by start_time desc limit 20;
