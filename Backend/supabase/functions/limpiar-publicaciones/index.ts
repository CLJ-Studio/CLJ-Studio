// Las RPC seleccionan las publicaciones vencidas hace mas de siete dias.
// Storage debe terminar antes de borrar las filas para poder reintentar.
import { createClient } from 'jsr:@supabase/supabase-js@2';

type PublicacionParaLimpiar = {
  id: string;
  rutas: string[];
};

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
    const { data, error } = await supabase.rpc('publicaciones_para_limpiar', {
      p_limite: 100,
    });
    if (error) {
      return Response.json({ error: 'No se pudieron consultar las publicaciones' }, {
        status: 500,
      });
    }

    const pendientes = (data ?? []) as PublicacionParaLimpiar[];
    if (!pendientes.length) {
      return Response.json({ publicaciones: 0, fotos: 0 });
    }

    const rutas = [...new Set(pendientes.flatMap((publicacion) => publicacion.rutas))];
    if (rutas.length) {
      const { error: errorFotos } = await supabase.storage
        .from('imagenes')
        .remove(rutas);
      if (errorFotos) {
        return Response.json({ error: 'No se pudieron borrar las fotos' }, {
          status: 500,
        });
      }
    }

    const { data: publicaciones, error: errorBorrado } = await supabase.rpc(
      'borrar_publicaciones',
      { p_ids: pendientes.map((publicacion) => publicacion.id) },
    );
    if (errorBorrado) {
      return Response.json({ error: 'No se pudieron borrar las publicaciones' }, {
        status: 500,
      });
    }

    return Response.json({ publicaciones, fotos: rutas.length });
  } catch {
    // No incluir errores del proveedor: pueden contener nombres o rutas.
    return Response.json({ error: 'No se pudo completar la limpieza' }, {
      status: 500,
    });
  }
});
