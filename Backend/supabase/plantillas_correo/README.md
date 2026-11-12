# Plantillas del correo de acceso de U market

La plantilla activa es
[`../templates/codigo_acceso.html`](../templates/codigo_acceso.html).
Se aplica **en dos sitios** del panel de Supabase:

    Authentication -> Emails -> Confirm sign up
    Authentication -> Emails -> Magic Link

Las dos, no una. `signInWithOtp()` no siempre manda el mismo correo:

| Situación | Plantilla que usa Supabase |
|---|---|
| La persona **nunca entró** — para Supabase es un alta | **Confirm sign up** |
| La persona **ya tenía cuenta** | **Magic Link** |

El código no puede intervenir en esa elección.

## El fallo que hubo

Solo estaba personalizada *Magic Link*. Quien ya tenía cuenta recibía sus seis
dígitos y **quien entraba por primera vez recibía la plantilla de fábrica**: en
inglés, con `{{ .ConfirmationURL }}` en vez de `{{ .Token }}`, o sea un enlace
donde la aplicación esperaba un código.

Fallaba solo con gente nueva. Es el peor momento posible para fallar, y el más
difícil de notar: probando con la cuenta de uno mismo nunca aparece.

## Cómo aplicarla

1. **Subject** (los dos): `Tu código de U market`
2. **Body**: pegar `../templates/codigo_acceso.html` entero al configurar un proyecto nuevo; para cambiar solo la marca, conservar el cuerpo activo y editar únicamente ese texto
3. Guardar
4. Repetir en la otra plantilla
5. Comprobar el nombre visible del remitente en SMTP: `U market`
6. Probar el acceso con una cuenta existente y el alta con una cuenta nueva

Lo único imprescindible es que el cuerpo contenga `{{ .Token }}`. Sin esa
variable no hay código, salga como salga el diseño.

El cambio de marca conserva el HTML, los estilos y las variables de cada
plantilla. Las versiones anteriores, `codigo_de_acceso.html` y
`../../plantillas_correo/codigo_acceso.html`, también usan U market; tienen
diseños distintos, así que no se deben intercambiar para cambiar solo el nombre.

Guardar un HTML o subirlo a GitHub no actualiza los correos del proyecto en
la nube. El asunto y el cuerpo deben quedar guardados en ambas plantillas de
Supabase. Netlify publica el frontend, no las plantillas de autenticación.

## Por qué el asunto dice "Tu código"

Describe la acción que espera la aplicación: copiar los seis dígitos. La
entrega del correo también depende de la configuración y la reputación del
remitente; cambiar el asunto por sí solo no garantiza que llegue a la bandeja
de entrada.
