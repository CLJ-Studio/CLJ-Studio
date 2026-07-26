import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../elementos_compartidos/sesion/sesion_usuario.dart';
import '../../onboarding_usuario/datos/repositorio_onboarding.dart';
import '../../onboarding_usuario/diseno/selector_carrera.dart';
import '../../onboarding_usuario/modelos/carrera_upsa.dart';

/// Edición de los datos que el estudiante sí controla.
///
/// Nombre, correo y código no aparecen: los define la cuenta institucional.
class PantallaEditarPerfil extends StatefulWidget {
  const PantallaEditarPerfil({super.key});

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  static const _repositorioCarreras = RepositorioOnboarding();

  final _whatsapp = TextEditingController();
  List<CarreraUpsa> _carreras = const [];
  String? _carreraId;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _whatsapp.dispose();
    super.dispose();
  }

  Map<String, List<CarreraUpsa>> get _porFacultad {
    final agrupadas = <String, List<CarreraUpsa>>{};
    for (final carrera in _carreras) {
      agrupadas.putIfAbsent(carrera.facultad, () => []).add(carrera);
    }
    return agrupadas;
  }

  Future<void> _cargar() async {
    try {
      _carreras = await _repositorioCarreras.cargarCarreras();

      final perfil = SesionUsuario.instancia.perfil;
      if (perfil != null) {
        // El WhatsApp se guarda con el 591 delante; el campo muestra solo
        // los 8 digitos locales, igual que en el onboarding.
        final digitos = perfil.whatsapp;
        _whatsapp.text = digitos.startsWith('591') && digitos.length > 8
            ? digitos.substring(3)
            : digitos;

        _carreraId = _carreras
            .where((c) => c.nombre == perfil.carrera)
            .map((c) => c.id)
            .firstOrNull;
      }
    } catch (_) {
      _error = 'No se pudieron cargar tus datos.';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_carreraId == null) {
      setState(() => _error = 'Selecciona tu carrera.');
      return;
    }
    if (_whatsapp.text.replaceAll(RegExp(r'\D'), '').length != 8) {
      setState(() => _error = 'El número debe tener 8 dígitos.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.rpc(
        'actualizar_perfil',
        params: {'p_career_id': _carreraId, 'p_whatsapp': _whatsapp.text},
      );
      // Refresca la copia compartida para que el resto de la app la vea.
      await SesionUsuario.instancia.cargar(forzar: true);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo guardar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFEFEFE),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFEFEFE),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Editar perfil',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: _cargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _DatosInstitucionales(),
                    const SizedBox(height: 26),
                    SelectorCarrera(
                      carrerasPorFacultad: _porFacultad,
                      carreraId: _carreraId,
                      alSeleccionar: (valor) =>
                          setState(() => _carreraId = valor),
                      cargando: false,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _whatsapp,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp',
                        hintText: '70012345',
                        prefixText: '+591 ',
                        prefixStyle: TextStyle(
                          color: Color(0xFF292A29),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Solo se comparte con la otra parte después de aceptar '
                      'un pedido.',
                      style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
                    ),
                    const SizedBox(height: 22),
                    const _InterruptorCampus(),
                    if (_error case final String mensaje) ...[
                      const SizedBox(height: 14),
                      Text(
                        mensaje,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF5C8A63),
                          shape: const StadiumBorder(),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}

/// Datos que vienen de la cuenta institucional y no se editan.
class _DatosInstitucionales extends StatelessWidget {
  const _DatosInstitucionales();

  @override
  Widget build(BuildContext context) {
    final perfil = SesionUsuario.instancia.perfil;
    if (perfil == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 18,
                color: Color(0xFF5C8A63),
              ),
              const SizedBox(width: 8),
              Text(
                perfil.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Color(0xFF252825),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            perfil.correo,
            style: const TextStyle(color: Color(0xFF7C827E), fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text(
            'Estos datos vienen de tu cuenta institucional y no se pueden '
            'cambiar.',
            style: TextStyle(color: Color(0xFF9A9A9A), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Estado "en campus / fuera": se guarda al instante, sin botón.
class _InterruptorCampus extends StatefulWidget {
  const _InterruptorCampus();

  @override
  State<_InterruptorCampus> createState() => _InterruptorCampusState();
}

class _InterruptorCampusState extends State<_InterruptorCampus> {
  late bool _enCampus = SesionUsuario.instancia.perfil?.enCampus ?? false;
  bool _guardando = false;

  Future<void> _cambiar(bool valor) async {
    setState(() {
      _enCampus = valor;
      _guardando = true;
    });
    try {
      // Es la unica columna de `profiles` con permiso de escritura directa:
      // un interruptor sin nada que validar.
      await Supabase.instance.client
          .from('profiles')
          .update({'is_on_campus': valor})
          .eq('id', Supabase.instance.client.auth.currentUser!.id);
      await SesionUsuario.instancia.cargar(forzar: true);
    } catch (_) {
      if (mounted) setState(() => _enCampus = !valor);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: _enCampus,
    onChanged: _guardando ? null : _cambiar,
    contentPadding: EdgeInsets.zero,
    activeThumbColor: const Color(0xFF5C8A63),
    secondary: const Icon(
      Icons.location_on_outlined,
      color: Color(0xFF5C8A63),
    ),
    title: const Text(
      'Estoy en el campus',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: const Text(
      'Les indica a los compradores que puedes entregar ahora.',
      style: TextStyle(fontSize: 12),
    ),
  );
}
