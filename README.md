# UPSA Eat

**El mercado que ya existe en el campus, con un lugar donde vivir.**

Marketplace para la Universidad Privada de Santa Cruz de la Sierra. Los
estudiantes publican lo que venden, quien compra encarga desde la aplicación y
la entrega se coordina entre los dos, dentro del campus.

Hecho por **CLJ Studio**.

---

## La problemática

En la UPSA ya se vende. Empanadas antes del primer parcial, cuñapés a media
mañana, el libro de Cálculo del semestre pasado, clases particulares, uñas,
tortas por encargo. Todo eso pasa hoy, todos los días, sin ninguna herramienta
detrás.

El canal es el estado de WhatsApp y la historia de Instagram. Y ese canal tiene
cinco problemas que nadie puede resolver publicando más:

**Se borra en 24 horas.** Quien vende vuelve a subir la misma foto cada mañana.
Lo que no se vio ese día, no existió.

**Solo llega a los contactos.** Si no te tiene agendado, no se entera. Alguien
que vende en el Bloque C y alguien con hambre en el Bloque C pueden no cruzarse
nunca, estando a treinta metros.

**No se puede buscar.** Nadie puede preguntar *"¿quién está vendiendo algo
salado ahora?"*. Hay que acordarse de quién vende qué, y revisar historias una
por una.

**No hay stock.** Escribes, esperas veinte minutos, y te contestan que ya se
acabó. El vendedor recibe diez mensajes por tres porciones y tiene que decirle
que no a siete personas, a mano.

**No hay ninguna señal de confianza.** Nadie sabe si esa persona entrega, si
llega a tiempo, si el producto se parece a la foto. Y para vender hay que dar
el número de teléfono a desconocidos.

El resultado es un mercado real, activo y con demanda comprobada, funcionando
con las herramientas equivocadas. Quien vende no puede crecer más allá de su
agenda de contactos; quien compra no puede encontrar lo que ya está a treinta
metros suyo.

---

## Qué es UPSA Eat

Una aplicación **exclusiva de la comunidad UPSA** donde ese mercado tiene
catálogo, buscador, stock, pedidos y un registro de lo que pasó.

Se entra con el correo institucional. Nadie de afuera puede entrar, ni
registrarse, ni ver lo que hay adentro.

Y hay tres cosas que **deliberadamente no hace**:

| No es | Por qué |
|---|---|
| Una app de delivery | No hay repartidores. Se entregan entre ellos, en el campus, donde ya están los dos |
| Una pasarela de pagos | El pago se acuerda entre las partes, como ya lo hacen. Sin comisiones, sin intermediario, sin encarecer una empanada de 5 Bs |
| Una red social | No hay muro, ni seguidores, ni likes públicos. Se viene a comprar y a vender |

Lo que resuelve es lo que falta: **que se encuentren, que sepan qué hay, y que
lo que se acordó quede escrito.**

---

## Cómo funciona

**Quien vende** elige entre dos formas, y no son la misma:

- **Publicación personal** — vendo mi calculadora, una vez. No monta un negocio
- **Local** — mi emprendimiento, con nombre, descripción, ubicación en el
  campus y catálogo propio

Publica con foto, precio, cantidad y categoría. Dice en qué bloque está. Cuando
llega un pedido, lo acepta o lo rechaza; al aceptarlo, el stock se descuenta
solo.

**Quien compra** entra y ve todo lo publicado hoy en el campus. Busca por
producto, por local o por persona. Filtra por categoría. Guarda favoritos.
Encarga eligiendo el punto de entrega — Bloque A, Mozza, Jatata — y espera la
respuesta en pantalla, en tiempo real.

**Cuando se aceptó**, recién ahí se libera el WhatsApp de la contraparte, para
que cuadren la hora. Se encuentran, se entregan, y **los dos confirman**.

---

## Qué lo hace distinto

No es "otro marketplace". Estas siete decisiones son las que lo separan de
poner un catálogo en Instagram, y cada una responde a un problema real:

**1 · La identidad la respalda la universidad, no un formulario.**
El correo institucional se valida en un *trigger* de la base de datos, antes de
que el usuario exista. Un `@gmail.com` no es que sea rechazado: nunca llega a
crearse. Eso convierte un mercado abierto de desconocidos en un mercado cerrado
de compañeros — que es exactamente lo que hace razonable encontrarse con alguien
para darle comida y recibir dinero.

**2 · El pago fuera de la aplicación, a propósito.**
Meter una pasarela obligaría a constituir una empresa, cobrar comisión y
encarecer un producto de 5 Bs. Aquí la aplicación resuelve el descubrimiento y
el compromiso; el dinero sigue el camino que ya funciona.

**3 · La entrega la cierran los dos.**
En casi cualquier marketplace, el vendedor marca "entregado" y el pedido se
cierra. Aquí uno marca y **el otro tiene que confirmar**. Queda guardado quién
dijo qué. Es lo que hará que una calificación futura signifique algo, en vez de
ser una estrella que se pone sola.

**4 · El teléfono no es público.**
No aparece en ningún perfil. Se libera únicamente a la contraparte de un pedido
ya aceptado. Vender sin repartir tu número es algo que el estado de WhatsApp no
puede ofrecer.

**5 · El stock lo lleva el servidor, no la buena fe.**
El descuento es atómico: si dos personas aceptan a la vez la última porción,
solo una gana. Nadie vende lo que ya no tiene.

**6 · El filtro entiende cómo se insulta aquí.**
No es una lista de groserías de España bajada de internet. Reconoce jerga
local, diminutivos, aumentativos, abreviaturas y letras cambiadas — *petecitos*,
*OGT*, *marikon*, *put0*. Y está afinado para no bloquear a nadie que venda
**pito de cañahua** o **peras**, que es el error que hace inservible a un filtro
en un campus boliviano.

**7 · Se instala sin pasar por ninguna tienda.**
Es una PWA: se abre con un enlace y se agrega a la pantalla de inicio. Sin
descarga de 100 MB, sin Play Store, sin App Store, sin revisión de nadie. En un
campus donde los datos móviles se cuidan y los teléfonos son de todo tipo, eso
es la diferencia entre que la usen y que no.

---

## Qué hace hoy

**Dos espacios de venta separados de verdad.** Publicar desde el local no
mezcla con lo personal ni al revés, y el catálogo lo dice en cada tarjeta.

**Acceso con código al correo institucional.** Seis dígitos, sin contraseña que
recordar ni cuenta de Google que hacerse. El dispositivo recuerda las cuentas
usadas y el código sobrevive a que salgas de la app a leer el correo.

**Pedidos completos.** Carrito, punto de entrega, aceptar o rechazar, stock
atómico, vencimiento automático si nadie responde, y confirmación de entrega
por las dos partes.

**Notificaciones que llevan a algún lado.** Web Push real y campana dentro de
la app. Cada aviso sabe a dónde va: tocarlo abre el pedido, el local o la
publicación de la que habla.

**Catálogo con buscador.** Búsqueda por producto, local, persona y categoría,
tolerante a acentos. Favoritos. Vistas únicas por usuario, no por recarga.
Catorce categorías. Paginación.

**Fotos.** Galería por publicación, visor con zoom, y foto de perfil con
recorte circular antes de subir.

**Perfiles públicos** con biografía, publicaciones y dos interruptores de
privacidad: mostrar vistas y mostrar favoritos.

**Instalable en Android y iOS**, y modo oscuro en toda la aplicación.

---

## Estado

**Beta abierta**, en uso real dentro del campus.

Versión actual: **3.8.2 beta**. El número es la fecha — día.mes.entrega — así
que `3.8.2` es la segunda entrega del 3 de agosto. Se ve dentro de la app, en
Ajustes, para poder distinguir *"el arreglo no funciona"* de *"el arreglo
todavía no llegó a este teléfono"*.

```
CLJ Studio/
├── Frontend/   PWA en Flutter Web  →  Netlify
└── Backend/    Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
```

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

Las decisiones de arriba, vistas por dentro. Aquí no está el *por qué importa*
sino el *cómo se sostiene*, que es lo que hay que entender antes de tocar nada.

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

**UPSA Eat** · Universidad Privada de Santa Cruz de la Sierra
Un proyecto de **CLJ Studio**.
