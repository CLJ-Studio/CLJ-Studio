# Cómo cambiar el logo de la app

El logo del búho va en estos archivos. Guarda tu imagen y **reemplázalos con
el mismo nombre** (deben ser PNG cuadrados):

| Archivo | Tamaño | Dónde se ve |
|---|---|---|
| `Icon-192.png` | 192×192 | Icono al instalar la PWA |
| `Icon-512.png` | 512×512 | Icono grande, pantalla de inicio |
| `Icon-maskable-192.png` | 192×192 | Android, recortado en círculo |
| `Icon-maskable-512.png` | 512×512 | Android, recortado en círculo |
| `../favicon.png` | 32×32 o 64×64 | Pestaña del navegador |

## Sobre los "maskable"

Android recorta el icono en círculo, óvalo o cuadrado según el teléfono. Para
esos dos archivos deja **margen alrededor del búho** (que ocupe cerca del 60%
del alto, centrado): si va al borde, el recorte le come las orejas.

Los que no son maskable pueden llevar el búho más grande.

## Después de reemplazarlos

```bash
git add Frontend/web
git commit -m "Nuevo logo del buho"
git push
```

Netlify vuelve a publicar solo. Si el icono viejo persiste, es el caché de la
PWA: desinstálala y vuelve a agregarla a la pantalla de inicio.
