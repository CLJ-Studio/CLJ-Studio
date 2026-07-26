-- ============================================================================
-- 01 · Extensiones y tipos base
-- ============================================================================
-- Se ejecuta primero: define el vocabulario que usan todas las demas tablas.
-- ============================================================================

create extension if not exists pgcrypto;      -- gen_random_uuid()
create extension if not exists pg_trgm;       -- busqueda por texto en el feed

-- Estados del pedido.
-- Nota de diseno: se colapso 'coordinating' del spec original. "Coordinar por
-- WhatsApp" es una CONSECUENCIA VISUAL de 'aceptado', no un estado propio:
-- no tenia transicion ni actor que lo disparara, solo anadia superficie de bugs.
create type public.estado_pedido as enum (
  'solicitado',   -- comprador envio la solicitud, vendedor aun no responde
  'aceptado',     -- vendedor acepto -> se libera el contacto de WhatsApp
  'rechazado',    -- vendedor rechazo
  'cancelado',    -- comprador cancelo
  'vencido',      -- nadie respondio dentro de la ventana de tiempo
  'entregado'     -- entrega confirmada, pedido cerrado
);

-- El frontend ya tiene SelectorTipoPublicacion con 'Producto' | 'Servicio'.
create type public.tipo_publicacion as enum ('producto', 'servicio');

create type public.tipo_notificacion as enum (
  'pedido_recibido',    -- para el vendedor
  'pedido_aceptado',    -- para el comprador
  'pedido_rechazado',
  'pedido_cancelado',
  'pedido_vencido',
  'pedido_entregado'
);
