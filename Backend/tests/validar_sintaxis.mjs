// Valida la sintaxis de las migraciones con el parser REAL de PostgreSQL
// (libpg_query). No necesita base de datos: atrapa typos antes del db push.
//
//   node tests/validar_sintaxis.mjs

import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = join(dirname(fileURLToPath(import.meta.url)), '..');

const { loadModule, parse } = await import('pgsql-parser');
await loadModule();

const archivos = [
  ...readdirSync(join(raiz, 'supabase', 'migrations'))
    .filter((n) => n.endsWith('.sql'))
    .sort()
    .map((n) => join('supabase', 'migrations', n)),
  join('supabase', 'seed.sql'),
];

let fallos = 0;

for (const relativo of archivos) {
  const sql = readFileSync(join(raiz, relativo), 'utf8');
  try {
    const arbol = await parse(sql);
    const sentencias = arbol?.stmts?.length ?? 0;
    console.log(`  OK   ${relativo}  (${sentencias} sentencias)`);
  } catch (error) {
    fallos++;
    console.error(`  FALLO ${relativo}`);
    console.error(`        ${error.message}`);
  }
}

console.log('');
if (fallos > 0) {
  console.error(`${fallos} archivo(s) con errores de sintaxis.`);
  process.exit(1);
}
console.log('Sintaxis valida en todos los archivos.');
