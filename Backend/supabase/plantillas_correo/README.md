# Plantillas del correo de acceso

`codigo_de_acceso.html` va pegado **en dos sitios** del panel de Supabase:

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

1. **Subject** (los dos): `Tu codigo de UPSA Eat`
2. **Body**: borrar todo lo que haya y pegar `codigo_de_acceso.html` entero
3. Guardar
4. Repetir en la otra plantilla
5. Probar **con una cuenta nueva**, no con la propia

Lo único imprescindible es que el cuerpo contenga `{{ .Token }}`. Sin esa
variable no hay código, salga como salga el diseño.

## Por qué el asunto no dice "verifica" ni "confirma"

Son de las palabras con más peso en el filtro de spam de Gmail, y el correo ya
sale con una desventaja: un remitente `@gmail.com` enviado por SMTP externo.
Mientras no haya dominio propio con SPF y DKIM, conviene no sumar motivos.
