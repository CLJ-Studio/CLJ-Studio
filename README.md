# CLJ Studio · UPSA Eat

Marketplace interno para la comunidad UPSA: los estudiantes abren su local,
publican productos y coordinan la entrega dentro del campus. **No hay pasarela
de pagos**: el pago se acuerda entre las partes por WhatsApp.

```
CLJ Studio/
├── Frontend/   PWA en Flutter Web
└── Backend/    Supabase (PostgreSQL, Auth, Realtime)
```

---

## Arrancar el proyecto

### 1. Frontend

```bash
cd Frontend
flutter pub get
flutter run -d chrome --web-port 5000
```

> El puerto **5000** no es opcional: es el que está registrado como origen
> autorizado en Google OAuth y en Supabase. Con otro puerto, el login falla.

### 2. Backend

**No hay que instalar ni levantar nada.** Supabase corre en la nube y ambos
nos conectamos al mismo proyecto: la base de datos, los usuarios y los pedidos
son compartidos y están siempre disponibles, sin importar quién tenga la PC
encendida.

Solo se trabaja en `Backend/` para **cambiar el esquema**:

```bash
cd Backend
npm install
npx supabase login --token <TU_ACCESS_TOKEN>
npx supabase link --project-ref tujqaxohgpeoxxezbzzp
npx supabase db push        # aplica las migraciones pendientes
npm run validar             # valida la sintaxis SQL sin tocar la base
```

---

## Sobre las claves

| Clave | ¿Va al repo? | Por qué |
|---|---|---|
| `SUPABASE_URL` | ✅ Sí | Es la dirección pública del proyecto |
| **Publishable key** (`sb_publishable_…`) | ✅ Sí | Es **pública por diseño**: viaja dentro del bundle web de todas formas. Lo que protege los datos son las políticas RLS, no ocultar esta clave |
| Secret key (`sb_secret_…`) | ❌ Nunca | Ignora todas las RLS |
| Google OAuth secret | ❌ Nunca | Va en `Backend/.env` (ignorado por git) |
| Access token de Supabase | ❌ Nunca | Personal, cada quien genera el suyo |

Las dos primeras están en
[`Frontend/lib/configuracion_aplicacion/configuracion_supabase.dart`](Frontend/lib/configuracion_aplicacion/configuracion_supabase.dart),
así que **al clonar el repo la app funciona sin configurar nada**.

Para las dos últimas: copia `Backend/.env.example` como `Backend/.env` y
rellena los valores (solo hacen falta para tocar el esquema, no para correr
la app).

---

## Cómo está armado

**Un pedido = un local.** El carrito no mezcla vendedores: simplifica la
entrega y evita que alguien vea ítems que no le corresponden.

**El cliente nunca escribe estados ni stock.** `orders` solo tiene permiso de
lectura desde la app. Crear, aceptar, rechazar y cancelar pasan por funciones
`SECURITY DEFINER` que validan quién es el actor y descuentan inventario de
forma atómica, para que dos compradores no puedan llevarse la misma unidad.

**El WhatsApp no es público.** No se protege con RLS (una política del tipo
"puedes ver a quien te hizo un pedido" lo filtraría desde una solicitud sin
aceptar). Sale únicamente por `get_contacto_pedido()`, que exige ser parte del
pedido **y** que esté aceptado.

**La identidad la respalda la universidad.** El dominio institucional se valida
en un trigger sobre `auth.users`, antes de crear al usuario: un `@gmail.com`
nunca llega a existir. El nombre lo entrega Google y el servidor lo conserva
aunque el cliente mande otro.

Los detalles del esquema, el mapeo Dart ↔ SQL y qué llama cada botón están en
[`Backend/README.md`](Backend/README.md).

---

## Pendientes

- Notificaciones: la tabla y los eventos ya existen; falta la campana en la
  interfaz. Web Push/FCM queda para una fase posterior.
- Fotos de productos: hoy se usan emojis. `product_images` y Supabase Storage
  están preparados pero sin conectar.
- Reputación: `rating_average` existe en `profiles` y `stores`, falta el flujo
  para calificar tras la entrega.
