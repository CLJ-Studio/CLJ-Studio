"""Pasa a JPEG las fotos que quedaron guardadas en PNG.

POR QUE
-------
Hasta la version de septiembre de 2026 la aplicacion guardaba las fotos en
PNG, porque `dart:ui` no sabe generar otra cosa. PNG guarda pixel por pixel
sin perder nada: perfecto para un logotipo con texto, pesimo para una
fotografia. Las portadas del catalogo pesaban entre 800 KB y 1,4 MB cada una,
y el inicio descargaba veinte megabytes para mostrar miniaturas de 190 px.

La aplicacion ya sube en JPEG, pero las fotos viejas siguen pesando igual.
Esto las convierte de una vez.

QUE HACE
--------
1. Busca en el bucket `imagenes` todo lo que termine en .png
2. Lo descarga, lo convierte a JPEG y lo sube con el MISMO nombre y .jpg
3. Escribe `fotos_a_jpeg.sql` con los UPDATE que apuntan la base a las nuevas

QUE NO HACE
-----------
No borra los PNG viejos ni toca la base de datos. Si algo sale mal, todo
sigue funcionando como antes: las filas siguen apuntando al PNG hasta que
se ejecute el SQL. Los PNG se pueden borrar despues, con calma.

COMO SE USA
-----------
    pip install pillow requests
    python Backend/scripts/fotos_a_jpeg.py

Y despues, en el editor SQL de Supabase, pegar el contenido de
`fotos_a_jpeg.sql`.
"""
import io
import os
import sys

try:
    import requests
    from PIL import Image
except ImportError:
    sys.exit('Falta algo: pip install pillow requests')

AQUI = os.path.dirname(os.path.abspath(__file__))
ENV = os.path.join(AQUI, '..', '.env')
BUCKET = 'imagenes'
CALIDAD = 82

# Columnas que guardan una ruta del bucket. Si manana aparece otra, va aqui.
COLUMNAS = [
    ('public.products', 'image_path'),
    ('public.product_images', 'storage_path'),
    ('public.stores', 'logo_path'),
    ('public.profiles', 'avatar_path'),
]


def leer_env():
    if not os.path.exists(ENV):
        sys.exit('No encuentro Backend/.env')
    datos = {}
    for linea in io.open(ENV, encoding='utf-8'):
        linea = linea.strip()
        if not linea or linea.startswith('#') or '=' not in linea:
            continue
        clave, valor = linea.split('=', 1)
        datos[clave.strip()] = valor.strip()
    url = datos.get('SUPABASE_URL')
    # El proyecto migro al formato nuevo de claves; se acepta el viejo por si
    # alguien corre esto sobre una copia anterior.
    clave = datos.get('SUPABASE_SECRET_KEY') or datos.get('SUPABASE_SERVICE_ROLE_KEY')
    if not url or not clave:
        sys.exit('Faltan SUPABASE_URL o SUPABASE_SECRET_KEY en Backend/.env')
    return url.rstrip('/'), clave


def cabeceras(clave, extra=None):
    """Storage pide la clave en las DOS cabeceras.

    Con solo `Authorization` unas rutas responden y otras no: `apikey` es la
    que identifica al proyecto y `Authorization` la que da los permisos.
    """
    base = {'apikey': clave, 'Authorization': f'Bearer {clave}'}
    base.update(extra or {})
    return base


def explicar(respuesta):
    """El cuerpo del error dice mucho mas que el numero."""
    try:
        return f'{respuesta.status_code} {respuesta.json()}'
    except Exception:  # noqa: BLE001
        return f'{respuesta.status_code} {respuesta.text[:200]}'


def listar(url, clave, prefijo=''):
    """Devuelve todas las rutas del bucket. La API no recorre carpetas sola."""
    rutas = []
    pagina = 0
    while True:
        respuesta = requests.post(
            f'{url}/storage/v1/object/list/{BUCKET}',
            headers=cabeceras(clave),
            json={
                'prefix': prefijo,
                'limit': 100,
                'offset': pagina * 100,
                # Sin `sortBy` la API responde 400: no es opcional aunque el
                # orden no nos importe.
                'sortBy': {'column': 'name', 'order': 'asc'},
            },
            timeout=60,
        )
        if not respuesta.ok:
            sys.exit(f'Storage rechazo el listado: {explicar(respuesta)}')
        entradas = respuesta.json()
        if not entradas:
            break
        for entrada in entradas:
            nombre = entrada['name']
            completa = f'{prefijo}{nombre}' if prefijo else nombre
            # Sin `id` es una carpeta, no un archivo.
            if entrada.get('id') is None:
                rutas.extend(listar(url, clave, completa + '/'))
            else:
                rutas.append(completa)
        if len(entradas) < 100:
            break
        pagina += 1
    return rutas


def convertir(crudo):
    foto = Image.open(io.BytesIO(crudo))
    # JPEG no admite transparencia. Se apoya sobre blanco en vez de dejar que
    # el canal alfa termine saliendo negro.
    if foto.mode in ('RGBA', 'LA', 'P'):
        foto = foto.convert('RGBA')
        fondo = Image.new('RGB', foto.size, (255, 255, 255))
        fondo.paste(foto, mask=foto.split()[-1])
        foto = fondo
    else:
        foto = foto.convert('RGB')

    salida = io.BytesIO()
    foto.save(salida, 'JPEG', quality=CALIDAD, optimize=True, progressive=True)
    return salida.getvalue()


def main():
    url, clave = leer_env()
    print('Buscando fotos en PNG...')
    pngs = [r for r in listar(url, clave) if r.lower().endswith('.png')]
    print(f'Encontradas: {len(pngs)}\n')
    if not pngs:
        return

    publico = f'{url}/storage/v1/object/public/{BUCKET}/'
    hechas, antes, despues = [], 0, 0

    for ruta in pngs:
        nueva = ruta[:-4] + '.jpg'
        try:
            crudo = requests.get(publico + ruta, timeout=120).content
            jpeg = convertir(crudo)
            subida = requests.post(
                f'{url}/storage/v1/object/{BUCKET}/{nueva}',
                headers=cabeceras(clave, {
                    'Content-Type': 'image/jpeg',
                    # Un ano: cada ruta es unica, el archivo nunca cambia.
                    'Cache-Control': 'max-age=31536000',
                    # Por si se vuelve a correr sobre algo ya convertido.
                    'x-upsert': 'true',
                }),
                data=jpeg,
                timeout=120,
            )
            if not subida.ok:
                raise RuntimeError(explicar(subida))
            hechas.append((ruta, nueva))
            antes += len(crudo)
            despues += len(jpeg)
            print(f'  OK  {ruta.split("/")[-1]:<44} '
                  f'{len(crudo)//1024:>6} KB -> {len(jpeg)//1024:>5} KB')
        except Exception as fallo:  # noqa: BLE001
            print(f'  FALLA  {ruta}: {fallo}')

    if not hechas:
        print('\nNo se convirtio nada.')
        return

    # SQL explicito, ruta por ruta: un `replace` masivo tocaria tambien las
    # que fallaron y dejaria filas apuntando a archivos que no existen.
    lineas = [
        '-- Apunta la base a las fotos ya convertidas a JPEG.',
        '-- Generado por Backend/scripts/fotos_a_jpeg.py',
        f'-- {len(hechas)} archivos.',
        '',
        'begin;',
        '',
    ]
    for tabla, columna in COLUMNAS:
        lineas.append(f'-- {tabla}.{columna}')
        for vieja, nueva in hechas:
            lineas.append(
                f"update {tabla} set {columna} = '{nueva}' "
                f"where {columna} = '{vieja}';"
            )
        lineas.append('')
    lineas += [
        'commit;',
        '',
        '-- Comprobacion: deberia devolver cero filas.',
        '-- ' + ' union all '.join(
            f"select count(*) from {t} where {c} like '%.png'"
            for t, c in COLUMNAS
        ) + ';',
        '',
    ]

    destino = os.path.join(AQUI, 'fotos_a_jpeg.sql')
    io.open(destino, 'w', encoding='utf-8').write('\n'.join(lineas))

    print(f'\nConvertidas: {len(hechas)} de {len(pngs)}')
    print(f'Antes: {antes//1024} KB   Despues: {despues//1024} KB   '
          f'Reduccion: {round(100 - despues / antes * 100)}%')
    print(f'\nSQL listo en: {destino}')
    print('Pegalo en el editor SQL de Supabase para terminar.')
    print('Los PNG viejos siguen ahi: no se borra nada hasta comprobar.')


if __name__ == '__main__':
    main()
