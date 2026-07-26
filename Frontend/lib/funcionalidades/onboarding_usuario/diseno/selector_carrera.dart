import 'package:flutter/material.dart';

import '../modelos/carrera_upsa.dart';

const _verde = Color(0xFF5C8A63);
const _verdeSuave = Color(0xFFE7F2E8);
const _grisTexto = Color(0xFF7C827E);

/// Campo que abre una hoja deslizable con todas las carreras.
///
/// Se prefirio una hoja al menu nativo de DropdownButton porque este ultimo
/// recorta los nombres largos ("Ingenieria Informatica Administrativa") y no
/// deja separar las facultades con claridad.
class SelectorCarrera extends StatelessWidget {
  const SelectorCarrera({
    required this.carrerasPorFacultad,
    required this.carreraId,
    required this.alSeleccionar,
    required this.cargando,
    super.key,
  });

  final Map<String, List<CarreraUpsa>> carrerasPorFacultad;
  final String? carreraId;
  final ValueChanged<String> alSeleccionar;
  final bool cargando;

  CarreraUpsa? get _seleccionada {
    for (final carreras in carrerasPorFacultad.values) {
      for (final carrera in carreras) {
        if (carrera.id == carreraId) return carrera;
      }
    }
    return null;
  }

  Future<void> _abrirHoja(BuildContext context) async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _HojaCarreras(
        carrerasPorFacultad: carrerasPorFacultad,
        carreraId: carreraId,
      ),
    );
    if (elegida != null) alSeleccionar(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final carrera = _seleccionada;

    return InkWell(
      onTap: cargando ? null : () => _abrirHoja(context),
      borderRadius: BorderRadius.circular(28),
      child: InputDecorator(
        // Reutiliza el InputDecorationTheme para que se vea identico a los
        // demas campos del formulario.
        decoration: InputDecoration(
          labelText: 'Carrera',
          prefixIcon: const Icon(Icons.school_outlined),
          suffixIcon: cargando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              : const Icon(Icons.expand_more_rounded),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: carrera == null
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF79A780), width: 2),
          ),
        ),
        // El label flota solo si hay contenido; sin esto se solaparia
        // con el texto del marcador de posicion.
        isEmpty: false,
        child: Text(
          carrera?.nombre ?? 'Selecciona tu carrera',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: carrera == null ? FontWeight.w500 : FontWeight.w700,
            color: carrera == null ? _grisTexto : const Color(0xFF292A29),
          ),
        ),
      ),
    );
  }
}

/// Contenido de la hoja: lista con scroll agrupada por facultad.
class _HojaCarreras extends StatelessWidget {
  const _HojaCarreras({
    required this.carrerasPorFacultad,
    required this.carreraId,
  });

  final Map<String, List<CarreraUpsa>> carrerasPorFacultad;
  final String? carreraId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .72,
      minChildSize: .45,
      maxChildSize: .92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          // Asa que indica que la hoja se puede arrastrar.
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3DD),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 6),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'Selecciona tu carrera',
                style: TextStyle(
                  color: Color(0xFF252825),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Divider(height: 22),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
              children: [
                for (final entrada in carrerasPorFacultad.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Text(
                      entrada.key.toUpperCase(),
                      style: const TextStyle(
                        color: _grisTexto,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                  for (final carrera in entrada.value)
                    _FilaCarrera(
                      carrera: carrera,
                      seleccionada: carrera.id == carreraId,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCarrera extends StatelessWidget {
  const _FilaCarrera({required this.carrera, required this.seleccionada});

  final CarreraUpsa carrera;
  final bool seleccionada;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: seleccionada ? _verdeSuave : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(carrera.id),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  carrera.nombre,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: seleccionada ? _verde : const Color(0xFF292A29),
                    fontWeight: seleccionada
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
              if (seleccionada)
                const Icon(
                  Icons.check_circle_rounded,
                  color: _verde,
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
