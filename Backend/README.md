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

### 1.2 Correo saliente (SMTP)

El acceso es por **código de un solo uso al correo institucional**, así que el
proyecto necesita poder mandar correos. El SMTP que trae Supabase de fábrica
tiene un límite muy bajo y no sirve más que para probar.

En el dashboard → **Project Settings → Authentication → SMTP Settings**:

- **Enable Custom SMTP**: activado.
- Host, puerto, usuario y contraseña del proveedor que uses.
- **Sender email** y **Sender name**: es lo que ve quien recibe el correo.

La contraseña va en `Backend/.env` (ignorado por git), nunca en el repo.

> Los correos desde un dominio genérico caen en spam con facilidad. Un dominio
> propio con SPF y DKIM lo resuelve; ver las recomendaciones del
> [README principal](../README.md).

### 1.2.1 Las plantillas del correo · SON DOS

En **Authentication → Emails** hay que pegar la misma plantilla
([`supabase/plantillas_correo/codigo_de_acceso.html`](supabase/plantillas_correo/codigo_de_acceso.html))
en **dos** sitios:

| Plantilla | Cuándo la manda Supabase |
|---|---|
| **Confirm signup** | La persona entra por **primera vez**: para Supabase es un alta |
| **Magic Link** | La persona **ya tenía cuenta**: es un reingreso |

`signInWithOtp()` elige una u otra sin que el código pueda intervenir. Esto ya
falló una vez: solo estaba personalizada *Magic Link*, así que quien ya tenía
cuenta recibía su código y **quien entraba por primera vez recibía la plantilla
de fábrica, en inglés y con un enlace en lugar de seis dígitos**. Fallaba solo
con gente nueva, que es el peor momento posible para fallar.

El código va en la plantilla como `{{ .Token }}`. Si esa variable no está, no
hay código que valga: el correo sale con un enlace y la app sigue pidiendo seis
dígitos que nunca llegan.

El asunto de las dos: **`Tu codigo de UPSA Eat`**.

### 1.2.2 Que no caiga en spam

Mandar desde una cuenta `@gmail.com` por SMTP es lo que más pesa: Gmail ve un
remitente que dice ser de Gmail pero llega por otra vía, y lo marca. Ordenado
de más a menos efectivo:

1. **Dominio propio con SPF y DKIM.** ~12 USD al año. Es el único arreglo de
   verdad; el resto son parches.
2. **Sender email idéntico** a la cuenta que autentica el SMTP. Si no coinciden,
   el castigo es automático.
3. **Asunto sin palabras marcadas.** Nada de "verifica", "confirma", "urgente"
   ni signos de admiración.
4. Mientras tanto, decirle a la gente que mire en Spam y marque *No es spam*:
   cada vez que alguien lo hace, la reputación del remitente mejora.

### 1.3 Habilitar SOLO el correo en Supabase

En el dashboard → **Authentication → Sign In / Providers**:

| Proveedor | Estado | Motivo |
|---|---|---|
| **Email** | ✅ **Enabled**, con *Confirm email* activado | Único método permitido |
| Google | ❌ **Disabled** | Se usó al principio y se retiró: obligaba a tener cuenta de Google y no aportaba nada que el dominio institucional no valide ya |
| Phone, Anonymous, y el resto | ❌ Disabled | Ídem |

El filtro de dominio **no depende de esta pantalla**: vive en un trigger sobre
`auth.users` (`20260726120200_validacion_dominio.sql`), que corre antes de crear
al usuario. Aunque alguien habilitara otro proveedor por error, un correo de
fuera del campus seguiría sin poder existir.

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
> Inicia sesión una vez en la app y vuelve a correr el seed.

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
| `BotonAccesoCorreo` | `supabase.auth.signInWithOtp(email)` |
| `CampoCodigoVerificacion` | `supabase.auth.verifyOTP(token)` |
| Onboarding (nuevo) | `rpc('completar_onboarding', {...})` |
| `PantallaInicioMarketplace` | `select` sobre `locales_publicos` + `categories` |
| `BarraBusquedaMarketplace` / `FiltrosLocales` | `select` con `ilike` + `category_id` |
| `PantallaDetalleLocal` | `select` sobre `products where store_id` |
| Corazón · `ControladorFavoritos` | `insert` / `delete` en `favorites` |
| `PantallaCrearLocal` (3 pasos) | `insert` en `stores` |
| `PantallaMiLocal` · inventario | `insert` / `update` en `products` |
| `PantallaAdministrarLocal` | `rpc('actualizar_local')` / `rpc('cerrar_local')` |
| `PantallaPublicarProducto` | `insert` en `products` con `category_id` |
| `AccionesPublicacion` (editar · ocultar · relanzar · eliminar) | `update` / `delete` en `products` |
| Perfil público · `PantallaPerfilVendedor` | `rpc('favoritos_publicos')` + vistas públicas |
| Campana · `ControladorNotificaciones` | `select` sobre `notifications` + Realtime |
| `BotonContinuarPedido` ("Contactar con el vendedor") | `rpc('crear_pedido', {items, ...})` |
| `PantallaContactandoVendedor` | **Realtime** sobre `orders` filtrando por `id` |
| ← atrás en esa pantalla | `rpc('cancelar_pedido')` |
| Vendedor: aceptar / rechazar | `rpc('aceptar_pedido')` / `rpc('rechazar_pedido')` |
| "Marcar como entregado / recibido" | `rpc('marcar_entregado')` → deja el pedido `por_confirmar` |
| "Sí, lo recibí / lo entregué" | `rpc('confirmar_entrega')` → solo lo acepta la otra parte |
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

**Una publicación NO es un producto del local.** Cada persona tiene dos
espacios: el personal (`is_personal = true`) y, si lo abre, su local. Publicar
desde uno no toca al otro. El índice único es
`(owner_id, is_personal) where is_active`, no `(owner_id)`.

**La entrega la cierran las dos partes.** `marcar_entregado()` ya no cierra el
pedido: lo pasa a `por_confirmar` y anota quién marcó. `confirmar_entrega()` la
llama el otro, y rechaza a quien ya habló. Una tarea horaria cierra en silencio
lo que lleve más de 24 h esperando.

**Cerrar un local no borra su fila.** `orders.store_id` es `on delete restrict`,
así que un borrado real fallaría en cuanto el local tuviera un pedido. Se
desactiva, se cancelan los pedidos vivos, se repone el stock de los que estaban
aceptados y se avisa a cada comprador.

**Permisos en dos capas.** El proyecto tiene la exposición automática apagada:
cada objeto nuevo necesita su `grant` explícito además de la RLS. El patrón es
siempre `revoke all … from public; grant execute … to authenticated;`. Una
función sin `grant` se crea bien y falla recién al usarse.

**Realtime bajo RLS necesita `REPLICA IDENTITY FULL`.** Sin eso, los `UPDATE`
llegan sin las columnas viejas y la política no puede evaluarlos: la pantalla
no se entera de nada.

---

## 7. Estado del frontend

Los siete pendientes que listaba esta sección quedaron resueltos: hay pantalla
de Pedidos con sus dos pestañas, campana de notificaciones con Web Push, el
WhatsApp se pide en el onboarding, el costo de entrega se lee del local y el
acceso pasa por código al correo institucional.

Dos aclaraciones sobre lo que decía antes, porque se decidió al revés:

- **Los dos caminos de publicación NO se unificaron.** Publicar algo suelto y
  cargar un producto al local son cosas distintas a propósito, y el catálogo lo
  distingue. Unificarlos habría borrado la diferencia entre "vendo esto una vez"
  y "esto es mi negocio".
- **Sigue sin Riverpod ni GoRouter**, con `ChangeNotifier` y `Navigator`. A esta
  escala funciona bien y cambiarlo ahora sería mover todo sin ganar nada.

Las ideas para lo que viene están en el [README principal](../README.md).
