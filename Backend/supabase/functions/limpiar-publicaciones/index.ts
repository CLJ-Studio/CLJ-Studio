// Borra las publicaciones vencidas o vendidas hace mas de siete dias y
// despues sus fotos.
//
// En ese orden y no al reves: la base borra las filas y devuelve que fotos
// eran suyas, en una sola sentencia que respeta a quien justo vuelve a
// publicar. Si despues Storage falla, quedan fotos huerfanas, que no le
// rompen nada a nadie; borrar las fotos primero podia dejar publicada sin
// fotos una publicacion que alguien recupero en ese momento.
import { createClient } from 'jsr:@supabase/supabase-js@2';

type PublicacionLimpiada = {
  id: string;
  rutas: string[] | null;
};

// Storage acepta hasta 1000 archivos por llamada; 100 publicaciones con 12
// fotos cada una ya pasan ese tope.
const FOTOS_POR_TANDA = 500;

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const clavesAceptadas = [
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
  Deno.env.get('PUSH_CLAVE'),
].filter((clave): clave is string => !!clave);

const codificador = new TextEncoder();

// Compara sin cortar en el primer caracter distinto: el tiempo de respuesta
// no deja adivinar la clave de a poco.
function igualesSinFiltrar(a: string, b: string): boolean {
  const x = codificador.encode(a);
  const y = codificador.encode(b);
  let distinto = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    distinto |= (x[i] ?? 0) ^ (y[i] ?? 0);
  }
  return distinto === 0;
}

function autorizada(peticion: Request): boolean {
  const cabecera = peticion.headers.get('Authorization') ?? '';
  const clave = cabecera.startsWith('Bearer ') ? cabecera.slice(7) : '';
  if (!clave) return false;
  let valida = false;
  for (const aceptada of clavesAceptadas) {
    if (igualesSinFiltrar(clave, aceptada)) valida = true;
  }
  return valida;
}

Deno.serve(async (peticion) => {
  if (!autorizada(peticion)) {
    return new Response('no autorizado', { status: 401 });
  }

  try {
    const { data, error } = await supabase.rpc(
      'limpiar_publicaciones_vencidas',
      { p_limite: 100 },
    );
    if (error) {
      return Response.json({ error: 'No se pudieron borrar las publicaciones' }, {
        status: 500,
      });
    }

    const borradas = (data ?? []) as PublicacionLimpiada[];
    const rutas = [
      ...new Set(borradas.flatMap((publicacion) => publicacion.rutas ?? [])),
    ];

    let fotos = 0;
    let fotosSinBorrar = 0;
    for (let inicio = 0; inicio < rutas.length; inicio += FOTOS_POR_TANDA) {
      const tanda = rutas.slice(inicio, inicio + FOTOS_POR_TANDA);
      const { error: errorFotos } = await supabase.storage
        .from('imagenes')
        .remove(tanda);
      // Las filas ya no estan: una tanda que falla deja fotos huerfanas, no
      // publicaciones rotas. Se sigue con las demas y se informa cuantas.
      if (errorFotos) fotosSinBorrar += tanda.length;
      else fotos += tanda.length;
    }

    return Response.json(
      { publicaciones: borradas.length, fotos, fotos_sin_borrar: fotosSinBorrar },
      { status: fotosSinBorrar ? 502 : 200 },
    );
  } catch {
    // No incluir errores del proveedor: pueden contener nombres o rutas.
    return Response.json({ error: 'No se pudo completar la limpieza' }, {
      status: 500,
    });
  }
});
