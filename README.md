# CLJ Studio · UPSA Eat

Marketplace interno para la comunidad UPSA: los estudiantes publican lo que
venden y coordinan la entrega dentro del campus. **No hay pasarela de pagos**:
el pago se acuerda entre las partes por WhatsApp.

```
CLJ Studio/
├── Frontend/   PWA en Flutter Web  →  Netlify
└── Backend/    Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
```

Versión actual: **30.7.1 beta** · el número es la fecha (día.mes.entrega), así
que `30.7.1` es la primera entrega del 30 de julio. Se ve dentro de la app, en
Ajustes, para poder distinguir *"el arreglo no funciona"* de *"el arreglo
todavía no llegó a este teléfono"*.

---

## Qué hace hoy

**Dos formas de vender, separadas de verdad.** Se puede publicar algo suelto
(*uso personal*) o abrir un local con nombre, descripción y ubicación. Son dos
espacios distintos: publicar desde el local no mezcla con lo personal ni al
revés, y el catálogo lo dice en cada tarjeta.

**Acceso por correo institucional con código.** Se escribe el correo `@upsa`,
llega un código de 6 dígitos y se entra. El dominio se valida en un trigger
sobre `auth.users`, antes de crear al usuario: un `@gmail.com` nunca llega a
existir. El dispositivo recuerda las cuentas usadas y el código sobrevive a que
salgas de la app a leer el correo.

**Pedidos con entrega cerrada por las dos partes.** Uno marca la entrega, el
otro la confirma, y recién ahí se cierra. Queda guardado quién marcó y quién
confirmó. Si nadie contesta en 24 h se cierra solo y en silencio.

**Notificaciones que llevan a algún lado.** Web Push real (VAPID + Edge
Function) y campana dentro de la app. Cada aviso guarda a dónde va, así que
tocarlo abre el pedido, el local o la publicación de la que habla.

**Instalable en Android y iOS.** Android usa el `beforeinstallprompt` nativo;
iOS no lo tiene, así que la app explica el paso de *Compartir → Añadir a
pantalla de inicio*.

**Fotos.** Galería por publicación y foto de perfil con recorte circular antes
de subir, en Supabase Storage.

**Y además:** favoritos, vistas únicas por usuario (no por recarga), catorce
categorías, buscador, punto de entrega elegible entre los puntos del campus,
modo oscuro, perfiles públicos con biografía, y dos interruptores de privacidad
(mostrar vistas, mostrar favoritos).

---

## Arrancar el proyecto

### Frontend

```bash
cd Frontend
flutter pub get
flutter run -d chrome --web-port 5000
```

> El puerto **5000** no es opcional: es el que está registrado como origen
> autorizado en Supabase. Con otro puerto, el login falla.

### Backend

**No hay que instalar ni levantar nada.** Supabase corre en la nube y ambos nos
conectamos al mismo proyecto: la base de datos, los usuarios y los pedidos son
compartidos y están siempre disponibles, sin importar quién tenga la PC
encendida.

Solo se trabaja en `Backend/` para **cambiar el esquema**:

```bash
cd Backend
npm install
npm run validar             # valida la sintaxis SQL sin tocar la base
```

Las migraciones se aplican **a mano**, pegándolas en el SQL Editor de Supabase
en orden de nombre. Escribir el archivo no es terminar la tarea: hasta que no
se ejecuta, la app sigue hablando con el esquema viejo.

> Si una migración solo agrega valores a un `enum`, va en su propio archivo:
> Postgres no deja usar un valor de enum recién creado dentro de la misma
> transacción que lo creó.

### Desplegar

Netlify compila solo con cada push a `main` (ver [`netlify.toml`](netlify.toml)).
El commit se inyecta en el build como `VERSION_APP`, y el service worker hace
`skipWaiting` para que nadie se quede con una copia vieja en caché.

---

## Sobre las claves

| Clave | ¿Va al repo? | Por qué |
|---|---|---|
| `SUPABASE_URL` | ✅ Sí | Es la dirección pública del proyecto |
| **Publishable key** (`sb_publishable_…`) | ✅ Sí | Es **pública por diseño**: viaja dentro del bundle web de todas formas. Lo que protege los datos son las políticas RLS, no ocultar esta clave |
| **VAPID pública** | ✅ Sí | Va en el navegador; su par privada es la que firma |
| Secret key (`sb_secret_…`) | ❌ Nunca | Ignora todas las RLS |
| VAPID privada | ❌ Nunca | Firma los envíos push |
| Contraseña SMTP | ❌ Nunca | Manda correos en nombre del proyecto |
| Access token de Supabase | ❌ Nunca | Personal, cada quien genera el suyo |

Las públicas están en
[`Frontend/lib/configuracion_aplicacion/configuracion_supabase.dart`](Frontend/lib/configuracion_aplicacion/configuracion_supabase.dart),
así que **al clonar el repo la app funciona sin configurar nada**.

Para las privadas: copiá `Backend/.env.example` como `Backend/.env` y rellená
los valores. Solo hacen falta para tocar el esquema o desplegar funciones, no
para correr la app.

---

## Cómo está armado

**Un pedido = un local.** El carrito no mezcla vendedores: simplifica la entrega
y evita que alguien vea ítems que no le corresponden.

**El cliente nunca escribe estados ni stock.** `orders` solo tiene permiso de
lectura desde la app. Crear, aceptar, rechazar, cancelar, entregar y confirmar
pasan por funciones `SECURITY DEFINER` que validan quién es el actor y
descuentan inventario de forma atómica, para que dos compradores no puedan
llevarse la misma unidad.

**La entrega la cierran dos personas.** Antes cualquiera de las partes daba el
pedido por entregado y se cerraba solo con eso: se podía dar por entregado algo
que nunca se entregó. Ahora quien entrega marca, el otro confirma, y `orders`
guarda las dos firmas por separado.

**El WhatsApp no es público.** No se protege con RLS (una política del tipo
"puedes ver a quien te hizo un pedido" lo filtraría desde una solicitud sin
aceptar). Sale únicamente por `get_contacto_pedido()`, que exige ser parte del
pedido **y** que esté aceptado o en curso.

**Los permisos son dos capas, no una.** El proyecto tiene la exposición
automática apagada: cada objeto nuevo necesita su `grant` explícito además de la
RLS. El patrón es siempre `revoke all … from public; grant execute … to
authenticated;`. Una función sin `grant` no falla al crearse — falla al usarse.

**La privacidad se apaga sin dejar rastro.** Los favoritos son estrictamente
privados en RLS; `favoritos_publicos()` es la única puerta, y devuelve vacío
cuando el interruptor está apagado. Así "no quiero mostrarlos" y "no tengo" se
ven igual desde afuera.

**Nada de bucles de navegación.** Un perfil abre una publicación, que abre el
local, que abría el perfil otra vez, y ahí quedabas girando. Las pantallas que
ya vienen de un perfil marcan al vendedor como no navegable.

Los detalles del esquema, el mapeo Dart ↔ SQL y qué llama cada botón están en
[`Backend/README.md`](Backend/README.md).

---

## Hacia dónde puede crecer

Ideas en orden de lo que más devolvería por el trabajo que cuesta. No son
agujeros: la app funciona sin ninguna de estas.

### Lo que ya está a un paso

**Reputación de verdad.** Ahora que la entrega la confirman los dos y queda
guardado quién dijo qué, una calificación por fin significa algo: solo puede
calificar quien participó de un pedido que se cerró. Las columnas
`rating_average` y `rating_count` ya existen en `profiles` y `stores` esperando
el flujo. Es lo que más cambia la app de "un tablón de anuncios" a "un lugar
donde sabés a quién comprarle".

**Horarios del local.** Hoy el local se abre y se cierra a mano, y quien se
olvida aparece abierto a las 3 de la mañana. Un horario declarado ("lunes a
viernes, 10 a 14") lo abriría y cerraría solo. Es una columna y una condición en
la vista del catálogo.

**Volver a pedir.** Los pedidos cerrados ya tienen todo lo necesario para
repetirse con un toque. En un campus la gente pide casi siempre lo mismo.

### Cuando haya más gente adentro

**Paginación del catálogo.** Hoy trae 120 publicaciones de una y filtra en el
teléfono. Con doscientas publicaciones sigue andando; con mil, la primera carga
se nota en el WiFi de la U. La solución es paginar por `bumped_at` (keyset, no
`offset`, que se degrada solo).

**Búsqueda en el servidor.** El buscador compara texto en el dispositivo, así
que solo encuentra dentro de lo que ya se bajó. Un `tsvector` con índice GIN en
Postgres busca sobre todo el catálogo, aguanta acentos y tolera que escribas
"empanda".

**Imágenes más livianas.** Es lo que más datos consume hoy: se sube la foto tal
como sale de la cámara. Generar una miniatura al subir y servir WebP haría que
el catálogo cargue notablemente más rápido en datos móviles.

### Confianza

**Reportar una publicación.** Hay un filtro de palabras, que atrapa lo obvio y
nada más. Un botón de reportar le da salida a lo que el filtro no ve, y de paso
avisa qué hay que revisar sin tener que mirar todo.

**Un panel mínimo de moderación.** Una vista con lo reportado y dos botones. No
hace falta más mientras seamos un campus.

**Dominio propio.** Los correos de acceso salen desde un SMTP genérico y a veces
caen en spam, que es la peor primera impresión posible. Un dominio propio con
SPF y DKIM cuesta unos 12 USD al año y lo resuelve.

### Para saber si va bien

**Guardar qué se busca y no aparece.** Es la señal más barata y más honesta que
existe: dice qué falta en el catálogo sin preguntarle nada a nadie.

**Registro de errores.** Cuando algo falla en el teléfono de otra persona, hoy
nos enteramos por WhatsApp y con suerte una captura.

**Un par de pruebas donde duele.** No hace falta cubrir todo: alcanza con las
funciones de pedidos, que son las que manejan stock y dinero, y son justamente
las que más cambiaron.

### Para trabajar de a dos

**Ramas en vez de empujar a `main`.** Ya nos pisamos cambios más de una vez.
Proteger `main` y trabajar con PRs cuesta cinco minutos de configurar.

**Repartir las carpetas por escrito.** En la práctica ya está repartido
(frontend / backend), pero no está dicho en ningún lado, y lo que no está
escrito se olvida justo cuando hay apuro.

---

*Hecho por CLJ Studio para la comunidad UPSA.*
