# Backend · CLJ Studio (UPSA Eat)

Backend en **Supabase / PostgreSQL** para la PWA Flutter que vive en [`../Frontend`](../Frontend).

Todo el esquema está diseñado contra los **widgets reales** del frontend, no contra
un diseño teórico. Cada tabla y columna documenta a qué modelo Dart corresponde.

---

## 1. Qué crear en Supabase (pasos manuales)

Estos pasos se hacen en el navegador, una sola vez.

### 1.1 Crear el proyecto

1. Entra a <https://supabase.com/dashboard> e inicia sesión.
2. **New project**:
   - **Name**: `clj-studio`
   - **Database password**: genera una fuerte y **guárdala** (la necesitas para migrar).
   - **Region**: `South America (São Paulo)` — la más cercana a Bolivia, menor latencia.
   - **Plan**: Free.
3. Espera ~2 minutos a que aprovisione.

### 1.2 Credenciales de Google (Google Cloud Console)

1. Ve a <https://console.cloud.google.com/> → crea un proyecto (ej. `clj-studio`).
2. **APIs y servicios → Pantalla de consentimiento OAuth**:
   - Tipo: **Externo**.
   - Nombre de la app, correo de soporte y correo del desarrollador.
3. **APIs y servicios → Credenciales → Crear credenciales → ID de cliente de OAuth**:
   - Tipo: **Aplicación web**.
   - **Orígenes autorizados de JavaScript**:
     ```
     http://localhost:5000
     https://<TU-REF>.supabase.co
     ```
   - **URI de redirección autorizados**:
     ```
     https://<TU-REF>.supabase.co/auth/v1/callback
     ```
4. Copia el **Client ID** y el **Client secret**.

> `<TU-REF>` es el identificador del proyecto: Supabase → *Project Settings → General → Reference ID*.

### 1.3 Habilitar SOLO Google en Supabase

En el dashboard → **Authentication → Sign In / Providers**:

| Proveedor | Estado | Motivo |
|---|---|---|
| **Google** | ✅ **Enabled** + Client ID y Secret | Único método permitido |
| **Email** | ❌ **Disabled** | Evita que alguien se registre saltándose el filtro de dominio |
| Phone, Anonymous, y el resto | ❌ Disabled | Ídem |

En **Authentication → URL Configuration**:
- **Site URL**: `http://localhost:5000`
- **Redirect URLs**: agrega `http://localhost:5000` (y luego la URL de producción).

### 1.4 Habilitar la extensión `pg_cron`

**Database → Extensions** → busca `pg_cron` → **Enable**.

Sin esto, la migración `...cron_vencimiento.sql` falla y los pedidos sin
respuesta nunca vencerían.

---

## 2. Aplicar el esquema

```bash
cd Backend
npm install                      # instala el Supabase CLI (ya hecho)

cp .env.example .env             # y rellena los valores
npx supabase login               # abre el navegador para autenticarte
npx supabase link --project-ref <TU-REF>
npx supabase db push             # aplica todas las migraciones
```

Cargar catálogos y demo:

```bash
npx supabase db execute --file supabase/seed.sql
```

> El bloque demo del seed (locales y productos) se **omite solo** si aún no hay
> ningún usuario registrado, porque `stores.owner_id` necesita un usuario real.
> Inicia sesión una vez con Google en la app y vuelve a correr el seed.

---

## 3. Verificar que la lógica crítica funciona

`tests/pruebas_logica_pedidos.sql` no prueba el "camino feliz": prueba los
escenarios donde el sistema se rompe y **debe** resistir.

| # | Qué verifica | Riesgo que cubre |
|---|---|---|
| 1 | Un `@gmail.com` no puede registrarse | Acceso de externos al campus |
| 2 | El total lo calcula el servidor ignorando el precio del cliente | Manipulación de precios |
| 3 | El WhatsApp **no** se revela antes de aceptar | Fuga de dato personal |
| 4 | Solo el vendedor acepta; el cliente no puede escribir `status` | Escalada de privilegios |
| 5 | Dos compradores, 1 en stock → solo uno se acepta | **Sobreventa** |
| 6 | Tras aceptar, sí se revela; un tercero nunca | Fuga de dato personal |
| 7 | Cancelar un pedido aceptado devuelve el stock | Inventario fantasma |
| 8 | Los pedidos sin respuesta vencen solos | Comprador esperando para siempre |

Ejecutar (necesita la cadena de conexión de *Project Settings → Database*):

```bash
psql "postgresql://postgres:<PASSWORD>@db.<TU-REF>.supabase.co:5432/postgres" \
     -f tests/pruebas_logica_pedidos.sql
```

Corre dentro de una transacción con `rollback` final: **no deja basura**.

---

## 4. Mapeo Frontend ↔ Backend

La regla: el frontend está en español, el esquema en inglés (como el modelo de
datos acordado). Esta es la tabla de traducción para los modelos Dart.

### `LocalUniversitario` ↔ `stores`

| Dart | SQL | Nota |
|---|---|---|
| `id` | `id` | `String` ↔ `uuid` |
| `nombre` | `name` | |
| `categoriaId` | `category_id` | |
| `categoria` | `categories.name` | vía join |
| `descripcion` | `description` | |
| `calificacion` | `rating_average` | |
| `tiempoEstimado` | `estimated_time` | |
| `estaAbierto` | `is_open` | |
| `costoEntrega` | `delivery_cost` | |
| `emoji` | `emoji` | |
| `colorHexadecimal` | `color_hex` | `bigint`: `0xFFFFE8D6` excede `int4` |

### `ProductoMarketplace` ↔ `products`

| Dart | SQL |
|---|---|
| `id` | `id` |
| `localId` | `store_id` |
| `nombre` | `name` |
| `descripcion` | `description` |
| `precio` | `price` |
| `emoji` | `emoji` |
| *(nuevo)* | `stock`, `kind`, `is_available` |

### `UsuarioUpsa` ↔ `profiles`

| Dart | SQL |
|---|---|
| `nombre` | `full_name` |
| `codigo` | `student_code` |
| `correo` | `email` |
| `carrera` | `career` |
| *(falta en la UI)* | `whatsapp` ← **requerido por el onboarding** |

### `CategoriaMarketplace` ↔ `categories`

`icono` es un `IconData` de Flutter: **no es serializable**. La base guarda
`icon_name` (ej. `lunch_dining_rounded`) y Dart lo mapea con un `switch`.
La categoría `'todas'` **no existe en la base**: es un filtro de UI.

---

## 5. Qué llama cada botón

| Widget / pantalla | Llamada al backend |
|---|---|
| `BotonContinuarGoogle` | `supabase.auth.signInWithOAuth(Provider.google)` |
| Onboarding (nuevo) | `rpc('completar_onboarding', {...})` |
| `PantallaInicioMarketplace` | `select` sobre `stores` + `categories` |
| `BarraBusquedaMarketplace` / `FiltrosLocales` | `select` con `ilike` + `category_id` |
| `PantallaDetalleLocal` | `select` sobre `products where store_id` |
| Corazón · `ControladorFavoritos` | `insert` / `delete` en `favorites` |
| `PantallaCrearLocal` (3 pasos) | `insert` en `stores` |
| `PantallaMiLocal` · inventario | `insert` / `update` en `products` |
| `BotonContinuarPedido` ("Contactar con el vendedor") | `rpc('crear_pedido', {items, ...})` |
| `PantallaContactandoVendedor` | **Realtime** sobre `orders` filtrando por `id` |
| ← atrás en esa pantalla | `rpc('cancelar_pedido')` |
| Vendedor: aceptar / rechazar | `rpc('aceptar_pedido')` / `rpc('rechazar_pedido')` |
| Botón WhatsApp (tras aceptar) | `rpc('get_contacto_pedido')` → devuelve `enlace_whatsapp` |

---

## 6. Decisiones de diseño

**Stock: se descuenta al ACEPTAR, no al solicitar.**
Al pedir no se reserva nada, así varios compradores pueden solicitar el mismo
producto y el vendedor elige. El descuento usa `UPDATE ... WHERE stock >= cantidad`,
que es atómico: si dos aceptaciones compiten, solo una gana.

**El estado `coordinating` del spec se eliminó.**
No tenía actor ni transición propia — "coordinar por WhatsApp" es una
*consecuencia visual* de `aceptado`. Un estado sin lógica solo añade bugs.

**Un pedido = un local.**
El carrito no puede mezclar productos de locales distintos. Simplifica la
entrega y evita que un vendedor vea ítems ajenos.

**El WhatsApp no se protege con RLS.**
Una política tipo "puedes ver perfiles con los que tienes pedidos" filtraría el
teléfono desde un pedido apenas `solicitado`. Se usa `get_contacto_pedido()`,
que exige ser parte **y** que el pedido esté aceptado.

**La `anon key` es pública por diseño.** La seguridad real son las RLS.
La que nunca debe salir del servidor es la `service_role`.

---

## 7. Pendientes conocidos del Frontend

Detectados al leer el código; hay que resolverlos para cerrar el MVP:

1. **No existe pantalla de Pedidos.** La navegación tiene 4 destinos
   (Inicio · Locales · Publicar · Configuración). Sin una pestaña de pedidos,
   el vendedor **no tiene dónde aceptar o rechazar**. Es el hueco más grande.
2. **No hay campana de notificaciones.** El encabezado solo tiene el carrito.
3. **Falta el campo WhatsApp** en el onboarding: `UsuarioUpsa` no lo tiene y es
   obligatorio para coordinar la entrega.
4. **Dos caminos de publicación que no se hablan**: `publicar_producto`
   (sin stock) y `mi_local` (con `cantidad`). Deben unificarse: publicar un
   producto es publicarlo *en tu local*.
5. **Costo de envío duplicado**: `ControladorCarritoCompras.costoEntrega = 3`
   está fijo, pero cada local tiene su `costoEntrega`. Debe leerse del local.
6. **El dominio está quemado en el cliente** (`ControladorAccesoUpsa.dominio`).
   Con Google Sign-In el correo lo entrega Google: el campo de código de
   estudiante ya no construye el correo, a lo sumo lo pre-valida visualmente.
7. **Sin Riverpod ni GoRouter**: hoy usa `ChangeNotifier` + singletons y
   `Navigator`. Funciona, pero conviene decidirlo antes de cablear Supabase.
